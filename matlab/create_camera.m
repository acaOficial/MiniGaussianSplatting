function cam = create_camera(W, H)
    f = 500;
    cx = W / 2;
    cy = H / 2;

    cam.K = [
        f  0  cx;
        0  f  cy;
        0  0  1
    ];

    cam.R = eye(3);
    cam.t = [0; 0; 0];

    cam.W = W;
    cam.H = H;
end
