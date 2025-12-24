%% OPTIMIZACIÓN MULTIVISTA 3DGS CON TRAYECTORIA 3D
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

% --- NUEVO: Historial para trayectoria ---
trajectory = zeros(1000, 3); 

% 3. Hiperparámetros base
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

fprintf('Iniciando optimización refinada con registro de trayectoria...\n');

for it = 1:iterations
    % Guardar posición actual en el historial
    trajectory(it, :) = G(1:3);

    % --- A. LEARNING RATE DECAY ---
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

    % --- E. Actualización con Momentum ---
    lrs = [lr_pos, lr_pos, lr_pos, lr_scale];
    v_G(1:4) = momentum * v_G(1:4) - lrs .* grad;
    G(1:4) = G(1:4) + v_G(1:4);

    % --- F. Restricciones ---
    G(4) = max(G(4), 0.01); 
    G(3) = max(G(3), 0.1);  

    % --- G. Visualización 2D en tiempo real ---
    if mod(it, 10) == 0
        subplot(1,3,1);
        imshow(img); 
        title(['Render Actual (Cam ', num2str(idx), ')']);
        
        subplot(1,3,2);
        imshow(target_img); 
        title('Ground Truth (Objetivo)');
        
        subplot(1,3,3);
        plot(loss_history(1:it), 'Color', [0.8 0 0], 'LineWidth', 1.2);
        title(sprintf('Iter %d | Loss: %.6f', it, loss));
        xlabel('Iteración'); grid on;
        
        drawnow limitrate;
    end
end

fprintf('✓ Optimización finalizada. Generando visualización 3D...\n');

% --- H. PLOT 3D DE TRAYECTORIA ---
figure('Color', 'w', 'Name', 'Trayectoria de la Gaussiana en el Espacio');
hold on; grid on; axis equal;

% 1. Dibujar las cámaras para referencia
for i = 1:num_cams
    % La posición de la cámara en el mundo es C = -R' * t
    C = -cams(i).R' * cams(i).t;
    plot3(C(1), C(2), C(3), 'k^', 'MarkerSize', 8, 'LineWidth', 1.5);
    text(C(1), C(2), C(3), [' Cam', num2str(i)], 'FontSize', 8);
end

% 2. Dibujar la línea de trayectoria
plot3(trajectory(:,1), trajectory(:,2), trajectory(:,3), 'b-', 'LineWidth', 2);

% 3. Resaltar Inicio y Fin
plot3(trajectory(1,1), trajectory(1,2), trajectory(1,3), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
text(trajectory(1,1), trajectory(1,2), trajectory(1,3), ' INICIO', 'Color', 'g', 'FontWeight', 'bold');

plot3(trajectory(end,1), trajectory(end,2), trajectory(end,3), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
text(trajectory(end,1), trajectory(end,2), trajectory(end,3), ' FINAL', 'Color', 'r', 'FontWeight', 'bold');

% 4. Configuración de vista
view(3);
xlabel('X Mundo'); ylabel('Y Mundo'); zlabel('Z Mundo');
title('Movimiento de la Gaussiana durante la Optimización');
legend('Cámaras', 'Recorrido', 'Punto Inicial', 'Punto Final', 'Location', 'northeastoutside');

rotate3d on;