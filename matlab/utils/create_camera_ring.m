function cams = create_camera_ring(num_cams, radius, W, H, target)
% Convención:
%   X_cam = R * X_world + t
%   t = -R * C
%   Eje óptico = +Z

    if nargin < 5
        target = [0; 0; 1];
    end

    f  = 500;
    cx = W / 2;
    cy = H / 2;

    cams = struct([]);
    world_up = [0; 0; 1];

    for i = 1:num_cams
        theta = 2*pi*(i-1)/num_cams;
        phi = pi/6 + (i-1)*pi/12;

        % Centro de cámara en distribución esférica
        C = [ ...
            target(1) + radius * sin(phi) * cos(theta); ...
            target(2) + radius * sin(phi) * sin(theta); ...
            target(3) + radius * cos(phi) ];
        
        % Se aleja en -Z para garantizar Zc > 0
        C(3) = C(3) - 1.0;

        % Dirección hacia el target
        forward = (target - C);
        forward = forward / norm(forward);

        % Se evita degeneracióon
        if abs(dot(forward, world_up)) > 0.99
            world_up = [0; 1; 0];
        end

        right = cross(world_up, forward);
        right = right / norm(right);

        up = cross(forward, right);
        up = up / norm(up);

        % World -> Camera
        R = [right'; up'; forward'];
        t = -R * C;

        cams(i).K = [f 0 cx; 0 f cy; 0 0 1];
        cams(i).R = R;
        cams(i).t = t;
        cams(i).W = W;
        cams(i).H = H;
    end
end
