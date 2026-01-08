%% OPTIMIZACIÓN MULTIVISTA: 1 O 2 GAUSSIANAS
% Script unificado para entrenar con 1 o 2 gaussianas
% Simplemente comenta/descomenta la sección que desees usar

clear; clc; close all;

% Agregar carpeta cpp al path de MATLAB
addpath('../cpp');

% ===========================================================================
% CONFIGURACIÓN:ELIGE NÚMERO DE GAUSSIANAS
% ===========================================================================

% ---- OPCIÓN 1: UNA GAUSSIANA ----
G = [0.1, 0.1, 1.1,  0.1,  1, 0, 0,  1.0];   % Gaussiana única (Roja)

% ---- OPCIÓN 2: DOS GAUSSIANAS ----
% G = [ 0.2,  0.1, 1.1,  0.1,  1, 0, 0,  1.0;   % Gaussiana 1 (Roja)
%      -0.2, -0.1, 1.1,  0.1,  0, 0, 1,  1.0];  % Gaussiana 2 (Azul)

% ===========================================================================
% 1. CONFIGURACIÓN DE ESCENA Y CÁMARAS
% ===========================================================================
W = 640; H = 480;
load('../data/cameras.mat', 'cams'); 
num_cams = length(cams);
targets = cell(num_cams, 1);
for i = 1:num_cams
    targets{i} = im2double(imread(sprintf('../data/targets/cam%02d.png', i)));
end

% ===========================================================================
% 2. CONFIGURACIÓN DINÁMICA SEGÚN NÚMERO DE GAUSSIANAS
% ===========================================================================
num_g = size(G, 1);
fprintf('==================================================================\n');
fprintf('MODO: %d GAUSSIANA(S)\n', num_g);
fprintf('==================================================================\n\n');

% Historial para trayectorias
if num_g == 1
    trajectory = zeros(1000, 3);
else
    traj_history = zeros(1000, 3, num_g);
end

% ===========================================================================
% 3. HIPERPARÁMETROS
% ===========================================================================
iterations = 1000;
print_every = 50;

lr_pos_init = 0.01;      
lr_scale_init = 0.001;   
momentum = 0.7;
v_G = zeros(size(G));
eps = 1e-3;

% ===========================================================================
% 4. CONFIGURACIÓN DE VISUALIZACIÓN
% ===========================================================================
hFig = figure('Color', 'w', 'Name', sprintf('3DGS: %d Gaussiana(s)', num_g), ...
              'Position', [100, 100, 1200, 400]);
loss_history = zeros(iterations, 1);
cam_stack = [];

fprintf('Iniciando optimización...\n');
fprintf('%-10s | %-10s | %-25s | %-10s\n', 'Iter', 'Loss', 'Posición (X,Y,Z)', 'Escala');
fprintf('--------------------------------------------------------------------------\n');

% ===========================================================================
% 5. LOOP DE OPTIMIZACIÓN
% ===========================================================================
for it = 1:iterations
    % Guardar trayectorias
    if num_g == 1
        trajectory(it, :) = G(1:3);
    else
        for g_idx = 1:num_g
            traj_history(it, :, g_idx) = G(g_idx, 1:3);
        end
    end
    
    % LR Decay
    decay = 0.1^(1/iterations);
    lr_pos = lr_pos_init * (decay ^ it);
    lr_scale = lr_scale_init * (decay ^ it);
    
    % Selección de Cámara
    if isempty(cam_stack)
        cam_stack = randperm(num_cams);
    end
    idx = cam_stack(1);
    cam_stack = cam_stack(2:end);
    target_img = targets{idx};
    
    % --- RENDER Y LOSS ---
    img = render_mex(G, cams(idx).K, cams(idx).R, cams(idx).t, W, H);
    loss = compute_loss(img, target_img);
    loss_history(it) = loss;
    
    % --- CÁLCULO DE GRADIENTES ---
    grad_G = zeros(size(G));
    
    for g_idx = 1:num_g
        % Gradientes para posición (XYZ) y escala
        for p_idx = 1:4
            Gp = G;
            Gp(g_idx, p_idx) = Gp(g_idx, p_idx) + eps;
            img_p = render_mex(Gp, cams(idx).K, cams(idx).R, cams(idx).t, W, H);
            loss_p = compute_loss(img_p, target_img);
            grad_G(g_idx, p_idx) = (loss_p - loss) / eps;
        end
    end
    
    % Gradient clipping
    max_grad = 1.0;
    grad_G = max(min(grad_G, max_grad), -max_grad);
    
    % --- ACTUALIZACIÓN CON MOMENTUM ---
    lrs = [lr_pos, lr_pos, lr_pos, lr_scale, 0, 0, 0, 0];
    v_G = momentum * v_G - lrs .* grad_G;
    G = G + v_G;
    
    % --- CONSTRAINTS ---
    G(:, 4) = max(min(G(:, 4), 0.15), 0.02); % Escala entre 0.02 y 0.15
    G(:, 1) = max(min(G(:, 1), 0.4), -0.4);  % X entre -0.4 y 0.4
    G(:, 2) = max(min(G(:, 2), 0.3), -0.3);  % Y entre -0.3 y 0.3
    G(:, 3) = max(min(G(:, 3), 1.3), 0.9);   % Z entre 0.9 y 1.3
    
    % --- PRINT DE ESTADO ---
    if mod(it, print_every) == 0 || it == 1
        fprintf('Iter: %04d | Loss: %.6f\n', it, loss);
        for g_idx = 1:num_g
            pos_str = sprintf('[%.3f, %.3f, %.3f]', G(g_idx, 1), G(g_idx, 2), G(g_idx, 3));
            fprintf('  G%d -> Pos: %-25s | Scale: %.4f\n', g_idx, pos_str, G(g_idx, 4));
        end
        fprintf('--------------------------------------------------------------------------\n');
    end
    
    % --- VISUALIZACIÓN ---
    if mod(it, 20) == 0
        set(0, 'CurrentFigure', hFig);
        subplot(1,3,1); imshow(img); title(sprintf('Render It: %d', it));
        subplot(1,3,2); imshow(target_img); title('Ground Truth');
        subplot(1,3,3); plot(loss_history(1:it), 'r', 'LineWidth', 2); 
        title('Convergencia'); grid on;
        drawnow limitrate;
    end
end

fprintf('✓ Optimización completada\n\n');

% ===========================================================================
% 6. VISUALIZACIÓN 3D FINAL
% ===========================================================================
figure('Color', 'w', 'Name', 'Trayectorias 3D'); 
hold on; grid on; axis equal;
xlabel('X'); ylabel('Y'); zlabel('Z');
title(sprintf('Recorrido de %d Gaussiana(s)', num_g));
view(3); rotate3d on;

if num_g == 1
    % Una gaussiana: plotear su trayectoria
    plot3(trajectory(:,1), trajectory(:,2), trajectory(:,3), 'r-', 'LineWidth', 2);
    plot3(trajectory(1,1), trajectory(1,2), trajectory(1,3), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    plot3(trajectory(end,1), trajectory(end,2), trajectory(end,3), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    legend('Trayectoria', 'Inicio', 'Final');
else
    % Múltiples gaussianas: plotear cada una con diferente color
    colors = ['r', 'b', 'g', 'm', 'c', 'y'];
    legend_entries = {};
    for g_idx = 1:num_g
        traj = squeeze(traj_history(:, :, g_idx));
        color = colors(mod(g_idx-1, length(colors)) + 1);
        plot3(traj(:,1), traj(:,2), traj(:,3), [color '-'], 'LineWidth', 2);
        legend_entries{end+1} = sprintf('G%d', g_idx);
    end
    legend(legend_entries{:});
end

fprintf('==================================================================\n');
fprintf('RESULTADOS FINALES\n');
fprintf('==================================================================\n');
for g_idx = 1:num_g
    fprintf('Gaussiana %d:\n', g_idx);
    fprintf('  Posición: [%.4f, %.4f, %.4f]\n', G(g_idx, 1), G(g_idx, 2), G(g_idx, 3));
    fprintf('  Escala: %.4f\n', G(g_idx, 4));
    fprintf('  Color: [%.2f, %.2f, %.2f]\n', G(g_idx, 5), G(g_idx, 6), G(g_idx, 7));
    fprintf('  Opacidad: %.4f\n', G(g_idx, 8));
end
fprintf('Loss final: %.6f\n', loss_history(end));
fprintf('==================================================================\n');
