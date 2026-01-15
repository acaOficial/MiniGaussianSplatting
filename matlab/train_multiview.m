%% OPTIMIZACIÓN MULTIVISTA: 1, 2, 3 O 10 GAUSSIANAS

clear; clc; close all;
addpath('../cpp');

% ===============
% CONFIGURACIÓN:
% ===============

% ---- OPCIÓN 1: UNA GAUSSIANA ----
%G = [0.1, 0.1, 1.1,  0.1,  1, 0, 0,  1.0];   % Gaussiana única (Roja)

% ---- OPCIÓN 2: DOS GAUSSIANAS ----
 G = [ 0.2,  0.1, 1.1,  0.1,  1, 0, 0,  1.0;   % Gaussiana 1 (Roja)
      -0.2, -0.1, 1.1,  0.1,  0, 0, 1,  0.7];  % Gaussiana 2 (Azul)
%
% ---- OPCIÓN 3: TRES GAUSSIANAS ----
%G = [ 0.25,  0.1, 1.1,  0.08,  1, 0, 0,  1.0;   % Gaussiana 1 (Roja)
%      0.0,   0.0, 1.1,  0.08,  0, 1, 0,  1.0;   % Gaussiana 2 (Verde)
%     -0.25, -0.1, 1.1,  0.08,  0, 0, 1,  1.0];  % Gaussiana 3 (Azul)

% ---- OPCIÓN 4: DIEZ GAUSSIANAS ----
%G = [
 %    % Fila superior
 %    -0.32,  0.15, 1.1,  0.06,   1.0, 0.0, 0.0,   1.0;  % Roja
 %    -0.16,  0.15, 1.1,  0.06,   1.0, 0.5, 0.0,   1.0;  % Naranja
  %    0.0,   0.15, 1.1,  0.06,   1.0, 1.0, 0.0,   1.0;  % Amarilla
  %    0.16,  0.15, 1.1,  0.06,   0.0, 1.0, 0.0,   1.0;  % Verde
   %   0.32,  0.15, 1.1,  0.06,   0.0, 1.0, 1.0,   1.0;  % Cian
   %  % Fila inferior
   %  -0.32, -0.15, 1.1,  0.06,   0.0, 0.0, 1.0,   1.0;  % Azul
   %  -0.16, -0.15, 1.1,  0.06,   0.5, 0.0, 1.0,   1.0;  % Púrpura
   %   0.0,  -0.15, 1.1,  0.06,   1.0, 0.0, 1.0,   1.0;  % Magenta
   %   0.16, -0.15, 1.1,  0.06,   1.0, 0.5, 0.5,   1.0;  % Rosa
   %   0.32, -0.15, 1.1,  0.06,   0.5, 0.5, 1.0,   1.0   % Lavanda
 %];

% ===========================================================================
% 1. CONFIGURACIÓN DE ESCENA Y CÁMARdAS
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
save_renders_every = 5;

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

fprintf('Carpetas de renders creadas en: %s\n', renders_dir);

% ===========================================================================
% 3.2. VISUALIZACIÓN INICIAL DE LA ESCENA
% ===========================================================================
plot_initial_scene(G, cams);

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
    tic;
    
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
    
    % --- GUARDaAR RENDERS CADA N ITERACIONES ---
    if mod(it, save_renders_every) == 0
        % Renderizar y guardar las cámaras
        for cam_idx = 1:num_cams
            render_img = render_mex(G, cams(cam_idx).K, cams(cam_idx).R, cams(cam_idx).t, W, H);
            save_path = fullfile(renders_dir, sprintf('cam%02d', cam_idx), sprintf('iter_%04d.png', it));
            imwrite(render_img, save_path);
        end
    end
    
    % --- CÁLCULO DE GRADIeENTES ---
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
    time_history(it) = toc * 1000;
    
    % --- PRINT DE ESTADO ---
    if mod(it, print_every) == 0 || it == 1
        print_iteration_info(it, G, loss, psnr_val, time_history(it));
    end
    
    % --- VISUALIZACIÓN ---
    if mod(it, 20) == 0
        plot_training_progress(img, target_img, it, loss_history, psnr_history, ...
                               mse_history, time_history, hFig);
    end
end

fprintf('✓ Optimización completada\n\n');

% ===========================================================================
% 6. VISUALIZACIÓN 3D FINAL
% ===========================================================================
if num_g == 1
    plot_trajectories(trajectory, [], num_g);
else
    plot_trajectories([], traj_history, num_g);
end

print_final_results(G, loss_history, psnr_history, mse_history, time_history, renders_dir);
