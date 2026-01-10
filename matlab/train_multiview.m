%% OPTIMIZACIÓN MULTIVISTA: 1, 2, 3 O 10 GAUSSIANAS
% Script unificado para entrenar con múltiples gaussianas
% Simplemente comenta/descomenta la sección que desees usar

clear; clc; close all;

% Agregar carpeta cpp al path de MATLAB
addpath('../cpp');

% ===========================================================================
% CONFIGURACIÓN: ELIGE NÚMERO DE GAUSSIANAS
% ===========================================================================

% ---- OPCIÓN 1: UNA GAUSSIANA ----
G = [0.1, 0.1, 1.1,  0.1,  1, 0, 0,  1.0];   % Gaussiana única (Roja)

% ---- OPCIÓN 2: DOS GAUSSIANAS ----
% G = [ 0.2,  0.1, 1.1,  0.1,  1, 0, 0,  1.0;   % Gaussiana 1 (Roja)
%      -0.2, -0.1, 1.1,  0.1,  0, 0, 1,  0.7];  % Gaussiana 2 (Azul)
%
% ---- OPCIÓN 3: TRES GAUSSIANAS ----
%G = [ 0.25,  0.1, 1.1,  0.08,  1, 0, 0,  1.0;   % Gaussiana 1 (Roja)
%      0.0,   0.0, 1.1,  0.08,  0, 1, 0,  1.0;   % Gaussiana 2 (Verde)
%     -0.25, -0.1, 1.1,  0.08,  0, 0, 1,  1.0];  % Gaussiana 3 (Azul)

% ---- OPCIÓN 4: DIEZ GAUSSIANAS (2 filas de 5) ----
%G = [
     % Fila superior
 %    -0.32,  0.15, 1.1,  0.06,   1.0, 0.0, 0.0,   1.0;  % Roja
 %    -0.16,  0.15, 1.1,  0.06,   1.0, 0.5, 0.0,   1.0;  % Naranja
 %     0.0,   0.15, 1.1,  0.06,   1.0, 1.0, 0.0,   1.0;  % Amarilla
 %     0.16,  0.15, 1.1,  0.06,   0.0, 1.0, 0.0,   1.0;  % Verde
 %     0.32,  0.15, 1.1,  0.06,   0.0, 1.0, 1.0,   1.0;  % Cian
 %    % Fila inferior
 %    -0.32, -0.15, 1.1,  0.06,   0.0, 0.0, 1.0,   1.0;  % Azul
%     -0.16, -0.15, 1.1,  0.06,   0.5, 0.0, 1.0,   1.0;  % Púrpura
%      0.0,  -0.15, 1.1,  0.06,   1.0, 0.0, 1.0,   1.0;  % Magenta
%      0.16, -0.15, 1.1,  0.06,   1.0, 0.5, 0.5,   1.0;  % Rosa
 %     0.32, -0.15, 1.1,  0.06,   0.5, 0.5, 1.0,   1.0   % Lavanda
 %];

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
save_renders_every = 5;  % Guardar renders cada N iteraciones

lr_pos_init = 0.01;      
lr_scale_init = 0.001;   
momentum = 0.7;
v_G = zeros(size(G));
eps = 1e-3;

% ===========================================================================
% 3.1. CONFIGURACIÓN DE CARPETAS PARA GUARDAR RENDERS
% ===========================================================================
renders_dir = '../results/renders';
if ~exist(renders_dir, 'dir')
    mkdir(renders_dir);
end

% Crear carpetas para cada cámara
for i = 1:num_cams
    cam_dir = fullfile(renders_dir, sprintf('cam%02d', i));
    if ~exist(cam_dir, 'dir')
        mkdir(cam_dir);
    end
end

fprintf('✓ Carpetas de renders creadas en: %s\n', renders_dir);

% ===========================================================================
% 3.2. VISUALIZACIÓN INICIAL DE LA ESCENA
% ===========================================================================
figure('Color', 'w', 'Name', 'Configuración Inicial de la Escena', 'Position', [100, 100, 800, 600]);
hold on; grid on; axis equal;
xlabel('X'); ylabel('Y'); zlabel('Z');
title('Posición Inicial: Gaussianas y Cámaras');
view(3); rotate3d on;

% Plotear gaussianas en su posición inicial
for g_idx = 1:num_g
    pos = G(g_idx, 1:3);
    rgb = G(g_idx, 5:7);
    
    % Punto grande con el color de la gaussiana
    plot3(pos(1), pos(2), pos(3), 'o', 'MarkerSize', 15, ...
          'MarkerFaceColor', rgb, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    
    % Etiqueta
    text(pos(1), pos(2), pos(3)+0.05, sprintf('G%d', g_idx), ...
         'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
end

% Plotear cámaras
for cam_idx = 1:num_cams
    % Posición de la cámara (centro óptico)
    cam_pos = -cams(cam_idx).R' * cams(cam_idx).t;
    
    % Cámara como pirámide verde
    plot3(cam_pos(1), cam_pos(2), cam_pos(3), '^', 'MarkerSize', 10, ...
          'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
    
    % Dirección de vista (eje Z de la cámara)
    view_dir = cams(cam_idx).R(3, :)';
    quiver3(cam_pos(1), cam_pos(2), cam_pos(3), ...
            view_dir(1)*0.1, view_dir(2)*0.1, view_dir(3)*0.1, ...
            'g', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
end

legend('Gaussianas', 'Cámaras', 'Location', 'best');
drawnow;
fprintf('✓ Visualización inicial mostrada\n');

% ===========================================================================
% 4. CONFIGURACIÓN DE VISUALIZACIÓN
% ===========================================================================
hFig = figure('Color', 'w', 'Name', sprintf('3DGS: %d Gaussiana(s)', num_g), ...
              'Position', [100, 100, 1600, 800]);
loss_history = zeros(iterations, 1);
psnr_history = zeros(iterations, 1);
mse_history = zeros(iterations, 1);
time_history = zeros(iterations, 1);
cam_stack = [];

fprintf('Iniciando optimización...\n');
fprintf('%-10s | %-10s | %-25s | %-10s\n', 'Iter', 'Loss', 'Posición (X,Y,Z)', 'Escala');
fprintf('--------------------------------------------------------------------------\n');

% ===========================================================================
% 5. LOOP DE OPTIMIZACIÓN
% ===========================================================================
for it = 1:iterations
    tic; % Iniciar medición de tiempo
    
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
    
    % --- RENDER Y MÉTRICAS ---
    img = render_mex(G, cams(idx).K, cams(idx).R, cams(idx).t, W, H);
    [loss, psnr_val, mse_val] = compute_metrics(img, target_img);
    loss_history(it) = loss;
    psnr_history(it) = psnr_val;
    mse_history(it) = mse_val;
    
    % --- GUARDAR RENDERS CADA N ITERACIONES ---
    if mod(it, save_renders_every) == 0
        % Renderizar y guardar TODAS las cámaras
        for cam_idx = 1:num_cams
            render_img = render_mex(G, cams(cam_idx).K, cams(cam_idx).R, cams(cam_idx).t, W, H);
            save_path = fullfile(renders_dir, sprintf('cam%02d', cam_idx), sprintf('iter_%04d.png', it));
            imwrite(render_img, save_path);
        end
    end
    
    % --- CÁLCULO DE GRADIENTES ---
    grad_G = zeros(size(G));
    
    for g_idx = 1:num_g
        % Gradientes para posición (XYZ) y escala
        for p_idx = 1:4
            Gp = G;
            Gp(g_idx, p_idx) = Gp(g_idx, p_idx) + eps;
            img_p = render_mex(Gp, cams(idx).K, cams(idx).R, cams(idx).t, W, H);
            loss_p = compute_metrics(img_p, target_img);
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
    
    % --- MEDICIÓN DE TIEMPO ---
    time_history(it) = toc * 1000; % Convertir a milisegundos
    
    % --- PRINT DE ESTADO ---
    if mod(it, print_every) == 0 || it == 1
        fprintf('Iter: %04d | Loss: %.6f | PSNR: %.2f dB | Time: %.1f ms\n', ...
                it, loss, psnr_val, time_history(it));
        for g_idx = 1:num_g
            pos_str = sprintf('[%.3f, %.3f, %.3f]', G(g_idx, 1), G(g_idx, 2), G(g_idx, 3));
            fprintf('  G%d -> Pos: %-25s | Scale: %.4f\n', g_idx, pos_str, G(g_idx, 4));
        end
        fprintf('--------------------------------------------------------------------------\n');
    end
    
    % --- VISUALIZACIÓN ---
    if mod(it, 20) == 0
        set(0, 'CurrentFigure', hFig);
        
        % Fila 1: Imágenes y tiempo
        subplot(2,3,1); imshow(img); title(sprintf('Render It: %d', it));
        subplot(2,3,2); imshow(target_img); title('Ground Truth');
        subplot(2,3,3); 
        plot(time_history(1:it), 'g', 'LineWidth', 2); 
        title('Tiempo por Iteración'); xlabel('Iteración'); ylabel('Tiempo (ms)'); grid on;
        
        % Fila 2: Métricas
        subplot(2,3,4); 
        plot(loss_history(1:it), 'r', 'LineWidth', 2); 
        title('Loss'); xlabel('Iteración'); ylabel('Loss'); grid on;
        
        subplot(2,3,5); 
        plot(psnr_history(1:it), 'b', 'LineWidth', 2); 
        title('PSNR'); xlabel('Iteración'); ylabel('PSNR (dB)'); grid on;
        
        subplot(2,3,6); 
        plot(mse_history(1:it), 'm', 'LineWidth', 2); 
        title('MSE'); xlabel('Iteración'); ylabel('MSE'); grid on;
        
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
    for g_idx = 1:num_g
        traj = squeeze(traj_history(:, :, g_idx));
        color = colors(mod(g_idx-1, length(colors)) + 1);
        
        % Trayectoria
        plot3(traj(:,1), traj(:,2), traj(:,3), [color '-'], 'LineWidth', 2, 'DisplayName', sprintf('G%d', g_idx));
        
        % Punto de inicio (verde) - sin leyenda
        plot3(traj(1,1), traj(1,2), traj(1,3), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g', 'HandleVisibility', 'off');
        
        % Punto final (del mismo color que la trayectoria) - sin leyenda
        plot3(traj(end,1), traj(end,2), traj(end,3), [color 'o'], 'MarkerSize', 8, 'MarkerFaceColor', color, 'HandleVisibility', 'off');
    end
    legend('show');
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
fprintf('\nMÉTRICAS FINALES:\n');
fprintf('  Loss final: %.6f\n', loss_history(end));
fprintf('  PSNR final: %.2f dB\n', psnr_history(end));
fprintf('  MSE final: %.6f\n', mse_history(end));
fprintf('\nMÉTRICAS PROMEDIO:\n');
fprintf('  Loss medio: %.6f\n', mean(loss_history));
fprintf('  PSNR medio: %.2f dB\n', mean(psnr_history));
fprintf('  MSE medio: %.6f\n', mean(mse_history));
fprintf('  Tiempo medio por iteración: %.2f ms\n', mean(time_history));
fprintf('  Tiempo total: %.2f segundos\n', sum(time_history)/1000);
fprintf('\nRenders guardados en: %s\n', renders_dir);
fprintf('==================================================================\n');
