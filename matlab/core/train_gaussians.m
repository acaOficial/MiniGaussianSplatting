function train_gaussians()

    gauss = initialize_gaussians("../../data/actual/positions.mat");
    cam   = load_camera("../../data/actual/camera.mat");
    target = imread("../../data/target_1.png");

    lr = 0.0005;
    iters = 200;

    loss_history = zeros(iters,1);
    psnr_history = zeros(iters,1);

    if ~exist("train_frames","dir")
        mkdir train_frames;
    end

    for i = 1:iters

        % --- Render ---
        G = [gauss.pos, gauss.scale, gauss.color, gauss.opacity];
        img = render_mex_wrapper(G, cam);

        % --- Métricas ---
        loss = compute_loss(img, target);
        loss_history(i) = loss;
        psnr_history(i) = compute_psnr(img, target);

        % --- Gradiente ---
        grad = compute_numeric_gradient(gauss, cam, target);
        gauss = update_gaussians(gauss, grad, lr);

        % --- Logging ---
        mean_grad = mean(abs([grad.pos(:); grad.scale(:); grad.color(:); grad.opacity(:)]));
        fprintf("Iter %d | Loss %.6f | PSNR %.2f dB | MeanGrad %.5f\n", ...
               i, loss, psnr_history(i), mean_grad);

        % --- Visualización ---
        if mod(i,10)==0
            figure(1); clf;

            subplot(1,2,1);
            imshow(uint8(target));
            title("Target");

            subplot(1,2,2);
            imshow(uint8(img));
            title(sprintf("Render @ iter %d", i));

            drawnow;
        end

        % --- Guardar frames ---
        if mod(i,20)==0
            imwrite(uint8(img), sprintf("train_frames/frame_%04d.png", i));
        end
    end

    % --- Curvas ---
    figure;
    subplot(2,1,1); plot(loss_history); title("Loss");
    subplot(2,1,2); plot(psnr_history); title("PSNR");

end
