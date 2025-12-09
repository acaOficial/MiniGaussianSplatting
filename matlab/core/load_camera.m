function cam = load_camera(cam_file)
    data = load(cam_file);

    cam.K = data.K;
    cam.R = data.R;
    cam.t = data.t;
    cam.resolution = data.resolution;
end
