function img8 = render_mex_wrapper(G, cam)

    % Llamada al MEX (imagen en double, rango arbitrario)
    img = render_mex(G, cam.K, cam.R, cam.t, cam.resolution(2), cam.resolution(1));

    % Normalizar rango [0,1] porque MATLAB no sabe interpretar valores float
    img = mat2gray(img);

    % Convertir a uint8 para mostrar e igualar formato del target
    img8 = uint8(255 * img);

end
