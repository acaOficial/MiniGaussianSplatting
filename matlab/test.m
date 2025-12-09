cam = load_camera("../../data/actual/camera.mat");
gauss = initialize_gaussians("../../data/actual/positions.mat");

for i = 1:size(gauss.pos,1)
    X = gauss.pos(i,:)';
    Xc = cam.R * X + cam.t;
    fprintf("Gauss %d → Zc = %.3f\n", i, Xc(3));
end
