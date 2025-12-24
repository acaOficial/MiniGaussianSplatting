clear; clc;
setup_paths;

% -----------------------------
% Cámara
% -----------------------------
cam = create_camera(640, 480);

% -----------------------------
% Cargar target
% -----------------------------
target = imread('../data/target.png');
target = im2double(target);

% -----------------------------
% Gaussiana inicial (mal colocada)
% -----------------------------
G = [
    0.3  0.2  1.5   0.08   1 0 0   1.0
];

% -----------------------------
% Hiperparámetros
% -----------------------------
lr_pos   = 0.2;   % x,y,z
lr_scale = 0.02;  % scale (MUCHO más pequeño)
eps = 1e-3;     % paso para diferencias finitas
num_iters = 1000;

loss_history = zeros(num_iters,1);

% -----------------------------
% Optimización
% -----------------------------
for it = 1:num_iters

    img = render_mex(G, cam.K, cam.R, cam.t, cam.W, cam.H);
    loss = compute_loss(img, target);
    loss_history(it) = loss;

    fprintf('Iter %03d | loss = %.6f | pos = [%.3f %.3f %.3f] | scale = %.4f\n', ...
            it, loss, G(1), G(2), G(3), G(4));

    % Gradiente por diferencias finitas
    for d = 1:4  % x, y, z, scale
        Gp = G;
        Gp(d) = Gp(d) + eps;

        img_p = render_mex(Gp, cam.K, cam.R, cam.t, cam.W, cam.H);
        loss_p = compute_loss(img_p, target);

        grad = (loss_p - loss) / eps;

        if d <= 3
            % posición
            G(d) = G(d) - lr_pos * grad;
        else
            % scale
            G(d) = G(d) - lr_scale * grad;
        end
    end

    G(4) = max(G(4), 0.03);

end

% -----------------------------
% Visualización
% -----------------------------
figure;
plot(loss_history, 'LineWidth', 2);
xlabel('Iteración');
ylabel('Loss (MSE)');
title('Convergencia de la optimización');
grid on;

figure;
subplot(1,2,1);
imshow(target);
title('Target');

subplot(1,2,2);
imshow(img);
title('Resultado final');
