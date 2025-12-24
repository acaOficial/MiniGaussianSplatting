%% OPTIMIZACIÓN MULTIVISTA: 2 GAUSSIANAS
clear; clc; close all;
setup_paths;

% 1. Configuración de Escena y Cámaras
W = 640; H = 480;
load('../data/cameras.mat', 'cams'); 
num_cams = length(cams);
targets = cell(num_cams, 1);
for i = 1:num_cams
    targets{i} = im2double(imread(sprintf('../data/targets/cam%02d.png', i)));
end

% 2. Inicialización de 2 Gaussianas (Filas independientes)
% G = [x, y, z,  scale,  r, g, b,  opacity]
G = [ 0.2,  0.1, 1.1,  0.1,  1, 0, 0,  1.0;   % Gaussiana 1 (Roja)
     -0.2, -0.1, 1.1,  0.1,  0, 0, 1,  1.0];  % Gaussiana 2 (Azul)

num_g = size(G, 1); % Cantidad de gaussianas (2)
iterations = 1000;

% --- NUEVO: Historial para 2 trayectorias ---
traj1 = zeros(iterations, 3);
traj2 = zeros(iterations, 3);

% 3. Hiperparámetros
lr_pos_init = 0.05;      
lr_scale_init = 0.005;   
momentum = 0.9;
v_G = zeros(size(G)); % Velocidad ahora es 2x8
eps = 1e-3;             

hFig = figure('Color', 'w', 'Name', '3DGS: 2 Gaussianas', 'Position', [100, 100, 1200, 400]);
loss_history = zeros(iterations, 1);
cam_stack = [];

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

    % --- C. Render y Loss (El renderizador debe recibir la matriz G completa) ---
    img = render_mex(G, cams(idx).K, cams(idx).R, cams(idx).t, W, H);
    loss = compute_loss(img, target_img);
    loss_history(it) = loss;

    % --- D. Gradientes para AMBAS Gaussianas ---
    grad_G = zeros(size(G)); 
    % Solo optimizamos los primeros 4 parámetros (XYZ y Scale) de cada una
    for g_idx = 1:num_g
        for p_idx = 1:4
            Gp = G;
            Gp(g_idx, p_idx) = Gp(g_idx, p_idx) + eps;
            img_p = render_mex(Gp, cams(idx).K, cams(idx).R, cams(idx).t, W, H);
            loss_p = compute_loss(img_p, target_img);
            grad_G(g_idx, p_idx) = (loss_p - loss) / eps;
        end
    end

    % --- E. Actualización con Momentum ---
    lrs = [lr_pos, lr_pos, lr_pos, lr_scale, 0, 0, 0, 0]; % No tocamos RGB ni Alpha
    v_G = momentum * v_G - lrs .* grad_G;
    G = G + v_G;

    % --- F. Constraints ---
    G(:, 4) = max(G(:, 4), 0.01); % Escala mínima
    G(:, 3) = max(G(:, 3), 0.1);  % Z mínimo

    % --- G. Visualización ---
    if mod(it, 20) == 0
        subplot(1,3,1); imshow(img); title('Render (2 Gaussianas)');
        subplot(1,3,2); imshow(target_img); title('Ground Truth');
        subplot(1,3,3); plot(loss_history(1:it), 'r'); title('Convergencia');
        drawnow limitrate;
    end
end

% --- H. PLOT 3D ---
figure('Color', 'w'); hold on; grid on; axis equal;
plot3(traj1(:,1), traj1(:,2), traj1(:,3), 'r-', 'LineWidth', 2); % Trayectoria G1
plot3(traj2(:,1), traj2(:,2), traj2(:,3), 'b-', 'LineWidth', 2); % Trayectoria G2
legend('Gaussiana 1 (Roja)', 'Gaussiana 2 (Azul)');
title('Recorrido de las 2 Gaussianas');
view(3); rotate3d on;