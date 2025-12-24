clear; clc;
setup_paths;

W = 640; H = 480;
num_cams = 5;

cams = create_camera_ring(num_cams, 1.0, W, H);

G_gt = [
    0.0  0.0  1.0   0.08   1 0 0   1.0
];

if ~exist('../data/targets', 'dir')
    mkdir('../data/targets');
end

for i = 1:num_cams
    img = render_mex(G_gt, cams(i).K, cams(i).R, cams(i).t, W, H);
    imwrite(img, sprintf('../data/targets/cam%02d.png', i));
end

save('../data/cameras.mat', 'cams');
disp('✓ Targets multiview generados');
