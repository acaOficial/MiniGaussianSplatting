%% GENERADOR UNIFICADO DE DATASETS MULTIVIEW
clear; clc;
setup_paths;

W = 640; H = 480;

% ==============
% CONFIGURACIÓN: 
% ==============

% ---- OPCIÓN 1: UNA GAUSSIANA ----
%num_cams = 5;
%G_gt = [
%    0.0  0.0  1.0   0.08   1 0 0   1.0
%];

% ---- OPCIÓN 2: DOS GAUSSIANAS ----
 num_cams = 8;
 G_gt = [
      0.15,  0.0, 1.0,  0.07,   1, 0, 0,   1.0;  % Gaussiana 1: Roja a la derecha
     -0.15,  0.0, 1.0,  0.07,   0, 0, 1,   0.7   % Gaussiana 2: Azul a la izquierda
 ];

% ---- OPCIÓN 3: TRES GAUSSIANAS ----
 %num_cams = 8;
 %G_gt = [
 %     0.20,  0.0, 1.0,  0.06,   1, 0, 0,   1.0;  % Gaussiana 1: Roja (derecha)
 %     0.0,   0.0, 1.0,  0.06,   0, 1, 0,   1.0;  % Gaussiana 2: Verde (centro)
 %    -0.20,  0.0, 1.0,  0.06,   0, 0, 1,   1.0   % Gaussiana 3: Azul (izquierda)
 %];

% ---- OPCIÓN 4: DIEZ GAUSSIANAS ----
% num_cams = 12;
 %G_gt = [
     % Fila superior (Y = 0.12)
  %   -0.30,  0.12, 1.0,  0.05,   1.0, 0.0, 0.0,   1.0;  % G1: Roja
   %  -0.15,  0.12, 1.0,  0.05,   1.0, 0.5, 0.0,   1.0;  % G2: Naranja
   %   0.0,   0.12, 1.0,  0.05,   1.0, 1.0, 0.0,   1.0;  % G3: Amarilla
    %  0.15,  0.12, 1.0,  0.05,   0.0, 1.0, 0.0,   1.0;  % G4: Verde
    %  0.30,  0.12, 1.0,  0.05,   0.0, 1.0, 1.0,   1.0;  % G5: Cian
     
    % % Fila inferior (Y = -0.12)
   %  -0.30, -0.12, 1.0,  0.05,   0.0, 0.0, 1.0,   1.0;  % G6: Azul
    % -0.15, -0.12, 1.0,  0.05,   0.5, 0.0, 1.0,   1.0;  % G7: Púrpura
   %  0.0,  -0.12, 1.0,  0.05,   1.0, 0.0, 1.0,   1.0;  % G8: Magenta
    %  0.15, -0.12, 1.0,  0.05,   1.0, 0.5, 0.5,   1.0;  % G9: Rosa
   %   0.30, -0.12, 1.0,  0.05,   0.5, 0.5, 1.0,   1.0   % G10: Lavanda
 %];

% ===========================================================================
% GENERACIÓN DEL DATASET
% ===========================================================================

num_g = size(G_gt, 1);
fprintf('Generandorf dataset con %d gaussiana(s)...\n', num_g);

% Calcular posición objetivo (centro de las gaussianas)
if num_g == 1
    target_pos = G_gt(1:3)';
    cam_radius = 1.0;
else
    target_pos = mean(G_gt(:, 1:3), 1)';
    cam_radius = 1.2;
end

% Crear anillo de cámaras
cams = create_camera_ring(num_cams, cam_radius, W, H, target_pos);

% Crear directorio de targets si no existe
if ~exist('../data/targets', 'dir')
    mkdir('../data/targets');
end

% Renderizar y guardar imágenes desde cada cámara
for i = 1:num_cams
    img = render_mex(G_gt, cams(i).K, cams(i).R, cams(i).t, W, H);
    imwrite(img, sprintf('../data/targets/cam%02d.png', i));
    fprintf('  - Cámara %d/%d renderizada\n', i, num_cams);
end

% Guardar configuración de cámaras
save('../data/cameras.mat', 'cams');

fprintf('\n Dataset generado exitosamente\n');
fprintf('  - Gaussianas: %d\n', num_g);
fprintf('  - Cámaras: %d\n', num_cams);
fprintf('  - Resolución: %dx%d\n', W, H);
fprintf('  - Archivos en: ../data/targets/\n');
