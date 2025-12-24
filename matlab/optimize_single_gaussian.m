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
lr_pos_init   = 0.2;     % learning rate inicial para x,y,z
lr_scale_init = 0.02;    % learning rate inicial para scale
lr_decay      = 0.999;   % decay MUY suave (0.995 era demasiado agresivo)
eps = 1e-3;              % paso para diferencias finitas
num_iters = 1000;

% Early stopping
patience = 30;           % iteraciones sin mejora antes de parar (reducido)
min_improvement = 1e-5;  % mejora mínima (menos estricto para parar antes)

loss_history = zeros(num_iters,1);
best_loss = inf;
no_improve_count = 0;

% -----------------------------
% Optimización con LR decay y early stopping
% -----------------------------
for it = 1:num_iters

    img = render_mex(G, cam.K, cam.R, cam.t, cam.W, cam.H);
    loss = compute_loss(img, target);
    loss_history(it) = loss;

    % Learning rate con decay exponencial
    lr_pos = lr_pos_init * (lr_decay ^ it);
    lr_scale = lr_scale_init * (lr_decay ^ it);

    fprintf('Iter %03d | loss = %.6f | pos = [%.3f %.3f %.3f] | scale = %.4f | lr_pos = %.5f\n', ...
            it, loss, G(1), G(2), G(3), G(4), lr_pos);

    % Early stopping: verificar mejora
    if loss < best_loss - min_improvement
        best_loss = loss;
        no_improve_count = 0;
    else
        no_improve_count = no_improve_count + 1;
    end
    
    if no_improve_count >= patience
        fprintf('Early stopping en iteración %d (sin mejora en %d iters)\n', it, patience);
        loss_history = loss_history(1:it);
        break;
    end

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
