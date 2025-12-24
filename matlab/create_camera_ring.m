function cams = create_camera_ring(num_cams, radius, W, H)

    f = 500;
    cx = W / 2;
    cy = H / 2;

    cams = struct([]);

    for i = 1:num_cams
        theta = 2*pi*(i-1)/num_cams;

        % Cámara en círculo, detrás del origen
        C = [
            radius * cos(theta);
            radius * sin(theta);
            -2.0                 % CLAVE: cámara detrás
        ];

        R = eye(3);              % mirando +Z
        t = -R * C;

        cams(i).K = [f 0 cx; 0 f cy; 0 0 1];
        cams(i).R = R;
        cams(i).t = t;
        cams(i).W = W;
        cams(i).H = H;
    end
end
