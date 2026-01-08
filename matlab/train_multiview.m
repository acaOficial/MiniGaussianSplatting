%% OPTIMIZACIÓN MULTIVISTA: 2 GAUSSIANAS
clear; clc; close all;
% setup_paths; % Asegúrate de que esta función esté disponible o comentada si no es necesaria

% Agregar carpeta cpp al path de MATLAB
addpath('../cpp');

% 1. Configuración de Escena y Cámaras
W = 640; H = 480;
% Simulamos carga de datos (ajusta a tu ruta real)
load('../data/cameras.mat', 'cams'); 
num_cams = length(cams);
targets = cell(num_cams, 1);
for i = 1:num_cams
    targets{i} = im2double(imread(sprintf('../data/targets/cam%02d.png', i)));
end

% 2. Inicialización de 2 Gaussianas
% G = [x, y, z,  scale,  r, g, b,  opacity]
G = [ 0.2,  0.1, 1.1,  0.1,  1, 0, 0,  1.0;   % Gaussiana 1 (Roja)
     -0.2, -0.1, 1.1,  0.1,  0, 0, 1,  1.0];  % Gaussiana 2 (Azul)

num_g = size(G, 1); 
iterations = 1000;
print_every = 50; % Frecuencia de los prints en consola

% --- Historial para trayectorias ---
traj1 = zeros(iterations, 3);
traj2 = zeros(iterations, 3);

% 3. Hiperparámetros
lr_pos_init = 0.01;       % Reducido de 0.05
lr_scale_init = 0.001;    % Reducido de 0.005
momentum = 0.7;           % Reducido de 0.9 para menos inercia
v_G = zeros(size(G)); 
eps = 1e-3;             

hFig = figure('Color', 'w', 'Name', '3DGS: 2 Gaussianas', 'Position', [100, 100, 1200, 400]);
loss_history = zeros(iterations, 1);
cam_stack = [];

fprintf('Iniciando optimización...\n');
fprintf('%-10s | %-10s | %-25s | %-10s\n', 'Iter', 'Loss', 'Posición (X,Y,Z)', 'Escala');
fprintf('--------------------------------------------------------------------------\n');

for it = 1:iterations
    % Guardar trayectorias
    traj1(it, :) = G(1, 1:3);
    traj2(it, :) = G(2, 1:3);

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

    % --- C. Render y Loss ---
    img = render_mex(G, cams(idx).K, cams(idx).R, cams(idx).t, W, H);
    loss = compute_loss(img, target_img);
    loss_history(it) = loss;

    % --- D. Gradientes para AMBAS Gaussianas ---
    grad_G = zeros(size(G)); 
    for g_idx = 1:num_g
        for p_idx = 1:4
            Gp = G;
            Gp(g_idx, p_idx) = Gp(g_idx, p_idx) + eps;
            img_p = render_mex(Gp, cams(idx).K, cams(idx).R, cams(idx).t, W, H);
            loss_p = compute_loss(img_p, target_img);
            grad_G(g_idx, p_idx) = (loss_p - loss) / eps;
        end
    end
    
    % Gradient clipping para evitar saltos grandes
    max_grad = 1.0;  % Reducido de 5.0 para mayor estabilidad
    grad_G = max(min(grad_G, max_grad), -max_grad);

    % --- E. Actualización con Momentum ---
    lrs = [lr_pos, lr_pos, lr_pos, lr_scale, 0, 0, 0, 0]; 
    v_G = momentum * v_G - lrs .* grad_G;
    G = G + v_G;

    % --- F. Constraints ---
    G(:, 4) = max(min(G(:, 4), 0.15), 0.02); % Escala entre 0.02 y 0.15
    G(:, 1) = max(min(G(:, 1), 0.4), -0.4);  % X entre -0.4 y 0.4
    G(:, 2) = max(min(G(:, 2), 0.3), -0.3);  % Y entre -0.3 y 0.3
    G(:, 3) = max(min(G(:, 3), 1.3), 0.9);   % Z entre 0.9 y 1.3 (cerca de inicio)

    % --- NUEVO: Print de estado ---
    if mod(it, print_every) == 0 || it == 1
        fprintf('Iter: %04d | Loss: %.6f\n', it, loss);
        for g_idx = 1:num_g
            pos_str = sprintf('[%.3f, %.3f, %.3f]', G(g_idx, 1), G(g_idx, 2), G(g_idx, 3));
            fprintf('  G%d -> Pos: %-25s | Scale: %.4f\n', g_idx, pos_str, G(g_idx, 4));
        end
        fprintf('--------------------------------------------------------------------------\n');
    end

    % --- G. Visualización ---
    if mod(it, 20) == 0
        set(0, 'CurrentFigure', hFig);
        subplot(1,3,1); imshow(img); title(sprintf('Render It: %d', it));
        subplot(1,3,2); imshow(target_img); title('Ground Truth');
        subplot(1,3,3); plot(loss_history(1:it), 'r'); title('Convergencia');
        drawnow limitrate;
    end
end

% --- H. PLOT 3D ---
figure('Color', 'w'); hold on; grid on; axis equal;
plot3(traj1(:,1), traj1(:,2), traj1(:,3), 'r-', 'LineWidth', 2); 
plot3(traj2(:,1), traj2(:,2), traj2(:,3), 'b-', 'LineWidth', 2); 
legend('Gaussiana 1 (Roja)', 'Gaussiana 2 (Azul)');
title('Recorrido de las 2 Gaussianas');
view(3); rotate3d on;