function generate_target_from_scene()

    % Ruta del script
    script_path = fileparts(mfilename('fullpath'));
    
    % Ruta al proyecto (un nivel encima)
    project_root = fileparts(script_path);

    % Añadir TODO el proyecto al path
    addpath(genpath(project_root));

    data_path = fullfile(project_root, "data");
    if ~exist(data_path, "dir")
        mkdir(data_path)
    end

    gauss = initialize_gaussians_full(fullfile(data_path, "positions.mat"));
    cam   = load_camera(fullfile(data_path, "camera.mat"));

    save(fullfile(data_path, "initial_scene.mat"), "gauss", "cam");

    G = [gauss.pos, gauss.scale, gauss.color, gauss.opacity];
    img = render_mex(G, cam.K, cam.R, cam.t, cam.resolution(2), cam.resolution(1));

    img8 = uint8(255 * mat2gray(img));
    imwrite(img8, fullfile(data_path, "target.png"));

    imshow(img8)
    title("Target generado desde la escena inicial")
end
