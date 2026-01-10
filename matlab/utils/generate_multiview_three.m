%% GENERADOR DE DATASET: 3 GAUSSIANAS (GT)
clear; clc;
setup_paths;

W = 640; H = 480;
num_cams = 8; % 8 cámaras para cubrir bien la escena

% 1. Definimos el Ground Truth con TRES filas
% Pos: [x y z] | Scale | RGB | Opacity
G_gt = [
     0.20,  0.0, 1.0,  0.06,   1, 0, 0,   1.0;  % Gaussiana 1: Roja (derecha)
     0.0,   0.0, 1.0,  0.06,   0, 1, 0,   1.0;  % Gaussiana 2: Verde (centro)
    -0.20,  0.0, 1.0,  0.06,   0, 0, 1,   1.0   % Gaussiana 3: Azul (izquierda)
];

% El objetivo de las cámaras es el centro de la escena
target_pos = [0, 0, 1.0]'; 
cams = create_camera_ring(num_cams, 1.2, W, H, target_pos);

if ~exist('../data/targets', 'dir')
    mkdir('../data/targets');
end

% 2. Renderizar y guardar
fprintf('Generando dataset con 3 gaussianas...\n');
for i = 1:num_cams
    % El renderizador recibe la matriz completa y proyecta las 3 gaussianas
    img = render_mex(G_gt, cams(i).K, cams(i).R, cams(i).t, W, H);
    imwrite(img, sprintf('../data/targets/cam%02d.png', i));
    fprintf('  - Cámara %d/%d renderizada\n', i, num_cams);
end

save('../data/cameras.mat', 'cams');
fprintf('\n✓ Dataset con 3 Gaussianas generado en ../data/targets/\n');
fprintf('  - %d imágenes target generadas\n', num_cams);
fprintf('  - Ground Truth:\n');
fprintf('    G1 (Roja):  [%.2f, %.2f, %.2f], scale=%.3f\n', G_gt(1,1:4));
fprintf('    G2 (Verde): [%.2f, %.2f, %.2f], scale=%.3f\n', G_gt(2,1:4));
fprintf('    G3 (Azul):  [%.2f, %.2f, %.2f], scale=%.3f\n', G_gt(3,1:4));
