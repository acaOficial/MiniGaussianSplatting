%pos = [
%     0.0   0.0   1.0;
%     0.5   0.0   1.0;
%     -0.5   0.0   1.0;
%     0.0   0.5   1.0;
%     0.0  -0.5   1.0;
%     ];

%save("../data/positions.mat", "pos");

%pos = [
%     0.0   0.0   1.0;
%     0.5   0.0   1.5;
%     -0.5   1.0   1.0;
%     0.0   0.5   1.0;
%     1.0  -0.5   1.0;
%     ];

% save("../data/positions.mat", "pos");


%pos = [
%     0.0    0.0    1.0;   % centro
%     0.5    0.0    1.0;   % derecha
%    -0.5    0.0    1.0;   % izquierda
%     0.0    0.5    1.0;   % arriba
%     0.0   -0.5    1.0;   % abajo
%];

% Escalas adecuadas (tamaño medio-alto para test)
%scale = [
%    0.06;
%    0.05;
%    0.1;
%    0.055;
%    0.15
%];

% Colores RGB (vivos y diferenciados)
%color = [
%    1.0  0.2  0.2;   % rojo suave
%    0.2  1.0  0.2;   % verde
%    0.2  0.2  1.0;   % azul
%    1.0  1.0  0.2;   % amarillo
%   1.0  0.2  1.0    % magenta
%];

% Opacidad (entre 0 y 1)
%opacity = [
%    0.9;
%    0.85;
%    0.85;
%    0.9;
%    0.9
%];

% Guardar todo junto en un archivo
%save("../data/positions.mat", "pos", "scale", "color", "opacity");



H = 480;
W = 640;

f = 500;
cx = W/2;
cy = H/2;

K = [f 0 cx;
     0 f cy;
     0 0 1];

R = eye(3);
t = [2; 1; 2];

resolution = [H W];

save("../data/camera.mat", "K", "R", "t", "resolution");
