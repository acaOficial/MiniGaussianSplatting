clear; clc;
setup_paths;

% =========================================================
% CONFIG
% =========================================================
load('../data/cameras.mat');   % cams
num_cams = length(cams);

targets = cell(num_cams,1);
for i = 1:num_cams
    targets{i} = im2double(imread(sprintf('../data/targets/cam%02d.png', i)));
end

% Gaussiana inicial (mal)
% x y z scale r g b opacity
G = [0.3 0.2 1.5 0.08 1 0 0 1.0];

num_iters     = 100;

% --- Multi-view speed tricks ---
batch_cams    = min(3, num_cams);   % usa solo 3 cams por iteración (minibatch)
pixel_stride  = 4;                 % usa 1 de cada 4 píxeles en x e y (subsample)

% --- Two-phase schedule ---
freeze_scale_until = 150;          % hasta esta iter, NO optimices scale

% --- Finite differences ---
eps_pos   = 2e-3;                  % más grande => grad más "fuerte" (pos)
eps_scale = 2e-3;                  % idem scale

% --- Adam (separado para pos y scale) ---
lr_pos_init   = 0.20;              % Adam permite LR menor pero efectivo
lr_scale_init = 0.05;
lr_decay      = 0.999;             % decay suave

beta1 = 0.9;
beta2 = 0.999;
eps_adam = 1e-8;

m = zeros(1,4);
v = zeros(1,4);

% --- Backtracking ---
max_backtrack = 4;
backtrack_factor = 0.5;

loss_history = zeros(num_iters,1);

% Precompute pixel indices for subsample (same for all cams)
H = cams(1).H; W = cams(1).W;
rows = 1:pixel_stride:H;
cols = 1:pixel_stride:W;

% =========================================================
% TRAIN LOOP
% =========================================================
for it = 1:num_iters

    % pick random camera minibatch
    cam_ids = randperm(num_cams, batch_cams);

    % forward loss with current G
    loss = compute_multiview_loss_subsample(G, cams, targets, cam_ids, rows, cols);
    loss_history(it) = loss;

    % lr schedule
    lr_pos   = lr_pos_init   * (lr_decay^it);
    lr_scale = lr_scale_init * (lr_decay^it);

    optimize_scale = (it > freeze_scale_until);

    fprintf('Iter %04d | loss=%.6f | G=[%.3f %.3f %.3f s=%.4f] | cams=%s | scale_opt=%d\n', ...
        it, loss, G(1), G(2), G(3), G(4), mat2str(cam_ids), optimize_scale);

    % --------
    % Compute gradients (central differences)
    % --------
    gradG = zeros(1,4);

    % x,y,z
    for d = 1:3
        gradG(d) = central_diff_grad(G, d, eps_pos, cams, targets, cam_ids, rows, cols);
    end

    % scale
    if optimize_scale
        gradG(4) = central_diff_grad(G, 4, eps_scale, cams, targets, cam_ids, rows, cols);
    else
        gradG(4) = 0;
    end

    % --------
    % Adam update proposal
    % --------
    G_new = G;
    for d = 1:4
        if d == 4 && ~optimize_scale
            continue;
        end

        m(d) = beta1*m(d) + (1-beta1)*gradG(d);
        v(d) = beta2*v(d) + (1-beta2)*(gradG(d)^2);

        mhat = m(d) / (1 - beta1^it);
        vhat = v(d) / (1 - beta2^it);

        lr = (d <= 3) * lr_pos + (d == 4) * lr_scale;

        G_new(d) = G(d) - lr * (mhat / (sqrt(vhat) + eps_adam));
    end

    % clamp scale
    G_new(4) = max(G_new(4), 0.03);

    % --------
    % Backtracking if loss got worse
    % --------
    cur_bt = 0;
    best_G = G_new;
    best_loss = compute_multiview_loss_subsample(best_G, cams, targets, cam_ids, rows, cols);

    while best_loss > loss && cur_bt < max_backtrack
        cur_bt = cur_bt + 1;

        % pull back towards previous G
        best_G(1:4) = G(1:4) + (best_G(1:4) - G(1:4)) * backtrack_factor;
        best_G(4) = max(best_G(4), 0.03);

        best_loss = compute_multiview_loss_subsample(best_G, cams, targets, cam_ids, rows, cols);
    end

    % accept
    G = best_G;

end

% =========================================================
% PLOTS + FINAL RENDER (all cams)
% =========================================================
figure;
plot(loss_history, 'LineWidth', 2);
xlabel('Iteración'); ylabel('Loss');
title('Convergencia (multiview fast)');
grid on;

% show final renders (first 4 cams)
show_n = min(4, num_cams);
figure;
for i = 1:show_n
    img = render_mex(G, cams(i).K, cams(i).R, cams(i).t, cams(i).W, cams(i).H);
    subplot(2, show_n, i);
    imshow(targets{i}); title(sprintf('Target cam%02d', i));
    subplot(2, show_n, show_n+i);
    imshow(img); title(sprintf('Render cam%02d', i));
end

disp('Final G = ');
disp(G);

% =========================================================
% FUNCTIONS
% =========================================================
function loss = compute_multiview_loss_subsample(G, cams, targets, cam_ids, rows, cols)
    loss = 0;
    for k = 1:length(cam_ids)
        c = cam_ids(k);
        img = render_mex(G, cams(c).K, cams(c).R, cams(c).t, cams(c).W, cams(c).H);
        loss = loss + mse_subsample(img, targets{c}, rows, cols);
    end
    loss = loss / length(cam_ids);
end

function g = central_diff_grad(G, d, eps, cams, targets, cam_ids, rows, cols)
    Gp = G; Gm = G;
    Gp(d) = Gp(d) + eps;
    Gm(d) = Gm(d) - eps;

    lp = compute_multiview_loss_subsample(Gp, cams, targets, cam_ids, rows, cols);
    lm = compute_multiview_loss_subsample(Gm, cams, targets, cam_ids, rows, cols);

    g = (lp - lm) / (2*eps);
end

function e = mse_subsample(img, target, rows, cols)
    % Works for grayscale or RGB
    img_s = img(rows, cols, :);
    tgt_s = target(rows, cols, :);
    diff = img_s - tgt_s;
    e = mean(diff(:).^2);
end
