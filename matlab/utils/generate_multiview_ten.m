%% GENERADOR DE DATASET: 10 GAUSSIANAS (GT)
clear; clc;
setup_paths;

W = 640; H = 480;
num_cams = 12; % Más cámaras para capturar bien las 10 gaussianas

% 1. Definimos el Ground Truth con DIEZ filas
% Distribuidas en dos filas de 5 gaussianas cada una
% Pos: [x y z] | Scale | RGB | Opacity

G_gt = [
    % Fila superior (Y = 0.12)
    -0.30,  0.12, 1.0,  0.05,   1.0, 0.0, 0.0,   1.0;  % G1: Roja
    -0.15,  0.12, 1.0,  0.05,   1.0, 0.5, 0.0,   1.0;  % G2: Naranja
     0.0,   0.12, 1.0,  0.05,   1.0, 1.0, 0.0,   1.0;  % G3: Amarilla
     0.15,  0.12, 1.0,  0.05,   0.0, 1.0, 0.0,   1.0;  % G4: Verde
     0.30,  0.12, 1.0,  0.05,   0.0, 1.0, 1.0,   1.0;  % G5: Cian
    
    % Fila inferior (Y = -0.12)
    -0.30, -0.12, 1.0,  0.05,   0.0, 0.0, 1.0,   1.0;  % G6: Azul
    -0.15, -0.12, 1.0,  0.05,   0.5, 0.0, 1.0,   1.0;  % G7: Púrpura
     0.0,  -0.12, 1.0,  0.05,   1.0, 0.0, 1.0,   1.0;  % G8: Magenta
     0.15, -0.12, 1.0,  0.05,   1.0, 0.5, 0.5,   1.0;  % G9: Rosa
     0.30, -0.12, 1.0,  0.05,   0.5, 0.5, 1.0,   1.0   % G10: Lavanda
];

% El objetivo de las cámaras es el centro de la escena
target_pos = [0, 0, 1.0]'; 
cams = create_camera_ring(num_cams, 1.5, W, H, target_pos);

if ~exist('../data/targets', 'dir')
    mkdir('../data/targets');
end

% 2. Renderizar y guardar
fprintf('Generando dataset con 10 gaussianas...\n');
for i = 1:num_cams
    % El renderizador recibe la matriz completa y proyecta las 10 gaussianas
    img = render_mex(G_gt, cams(i).K, cams(i).R, cams(i).t, W, H);
    imwrite(img, sprintf('../data/targets/cam%02d.png', i));
    fprintf('  - Cámara %d/%d renderizada\n', i, num_cams);
end

save('../data/cameras.mat', 'cams');
fprintf('\n✓ Dataset con 10 Gaussianas generado en ../data/targets/\n');
fprintf('  - %d imágenes target generadas\n', num_cams);
fprintf('  - 10 gaussianas distribuidas en 2 filas\n');
fprintf('  - Colores: Rojo, Naranja, Amarillo, Verde, Cian, Azul, Púrpura, Magenta, Rosa, Lavanda\n');
