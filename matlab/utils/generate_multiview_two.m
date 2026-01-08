%% GENERADOR DE DATASET: 2 GAUSSIANAS (GT)
clear; clc;
setup_paths;

W = 640; H = 480;
num_cams = 8; % Aumentamos a 8 para que sea más robusto con 2 objetos

% 1. Definimos el Ground Truth con DOS filas
% Pos: [x y z] | Scale | RGB | Opacity
G_gt = [
     0.15,  0.0, 1.0,  0.07,   1, 0, 0,   1.0;  % Gaussiana 1: Roja a la derecha
    -0.15,  0.0, 1.0,  0.07,   0, 0, 1,   0.7   % Gaussiana 2: Azul a la izquierda
];

% El objetivo de las cámaras es el centro entre ambas (el origen aprox)
target_pos = [0, 0, 1.0]'; 
cams = create_camera_ring(num_cams, 1.2, W, H, target_pos);

if ~exist('../data/targets', 'dir')
    mkdir('../data/targets');
end

% 2. Renderizar y guardar
fprintf('Generando dataset con 2 objetos...\n');
for i = 1:num_cams
    % El renderizador recibe la matriz completa y proyecta ambas
    img = render_mex(G_gt, cams(i).K, cams(i).R, cams(i).t, W, H);
    imwrite(img, sprintf('../data/targets/cam%02d.png', i));
end

save('../data/cameras.mat', 'cams');
disp('✓ Dataset con 2 Gaussianas generado en ../data/targets/');