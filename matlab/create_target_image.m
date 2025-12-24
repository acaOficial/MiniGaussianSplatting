function target = create_target_image()
% CREATE_TARGET_IMAGE
% Genera y guarda una imagen objetivo (ground truth)

    setup_paths;

    cam = create_camera(640, 480);

    % Escena "ideal"
    G = [
        0.0  0.0  1.0   0.08   1 0 0   1.0
    ];

    target = render_mex(G, cam.K, cam.R, cam.t, cam.W, cam.H);

    if ~exist('../data', 'dir')
        mkdir('../data');
    end

    imwrite(target, '../data/target.png');
    fprintf('✓ Target guardado en data/target.png\n');
end
