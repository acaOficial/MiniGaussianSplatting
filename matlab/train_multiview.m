%% OPTIMIZACIÓN MULTIVISTA 3DGS (VERSIÓN FINAL REFINADA)
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

% 2. Inicialización de la Gaussiana
% Posición x,y,z | Escala | R,G,B | Opacidad
G = [0.1, 0.1, 1.1,  0.1,  1, 0, 0,  1.0]; 

% 3. Hiperparámetros base (Valores iniciales)
iterations = 1000;
lr_pos_init = 0.05;      
lr_scale_init = 0.005;   
momentum = 0.9;
v_G = zeros(size(G));
eps = 1e-3;             

% 4. Preparación de Visualización Comparativa
hFig = figure('Color', 'w', 'Name', '3DGS: Render vs Ground Truth', 'Position', [100, 100, 1200, 400]);
loss_history = zeros(iterations, 1);
cam_stack = [];

fprintf('Iniciando optimización refinada con LR Decay...\n');

for it = 1:iterations
    % --- A. LEARNING RATE DECAY (Simulando update_learning_rate de 3DGS) ---
    % Reduce el LR gradualmente para evitar oscilaciones al final
    decay = 0.1^(1/iterations);
    lr_pos = lr_pos_init * (decay ^ it);
    lr_scale = lr_scale_init * (decay ^ it);

    % --- B. Selección de Cámara (Estocástico) ---
    if isempty(cam_stack)
        cam_stack = randperm(num_cams);
    end
    idx = cam_stack(1);
    cam_stack = cam_stack(2:end);
    
    current_cam = cams(idx);
    target_img = targets{idx};

    % --- C. Render y Loss ---
    img = render_mex(G, current_cam.K, current_cam.R, current_cam.t, W, H);
    loss = compute_loss(img, target_img);
    loss_history(it) = loss;

    % --- D. Gradiente por Diferencias Finitas ---
    grad = zeros(1, 4);
    for d = 1:4
        Gp = G;
        Gp(d) = Gp(d) + eps;
        img_p = render_mex(Gp, current_cam.K, current_cam.R, current_cam.t, W, H);
        loss_p = compute_loss(img_p, target_img);
        grad(d) = (loss_p - loss) / eps;
    end

    % --- E. Actualización con Momentum y LR actual ---
    lrs = [lr_pos, lr_pos, lr_pos, lr_scale];
    v_G(1:4) = momentum * v_G(1:4) - lrs .* grad;
    G(1:4) = G(1:4) + v_G(1:4);

    % --- F. Restricciones de seguridad ---
    G(4) = max(G(4), 0.01); 
    G(3) = max(G(3), 0.1);  

    % --- G. Visualización Comparativa (Side-by-Side) ---
    if mod(it, 10) == 0
        % Render Actual
        subplot(1,3,1);
        imshow(img); 
        title(['Render Actual (Cam ', num2str(idx), ')']);
        
        % Ground Truth original
        subplot(1,3,2);
        imshow(target_img); 
        title('Ground Truth (Objetivo)');
        
        % Gráfica de convergencia
        subplot(1,3,3);
        plot(loss_history(1:it), 'Color', [0.8 0 0], 'LineWidth', 1.2);
        title(sprintf('Loss: %.6f | LR: %.4f', loss, lr_pos));
        xlabel('Iteración'); grid on;
        
        drawnow limitrate;
    end
end

fprintf('✓ Optimización finalizada. XYZ final: [%.3f %.3f %.3f]\n', G(1), G(2), G(3));