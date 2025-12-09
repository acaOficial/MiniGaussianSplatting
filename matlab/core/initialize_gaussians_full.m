function gaussians = initialize_gaussians_full(gaussians_file)

    data = load(gaussians_file);

    if ~isfield(data, "pos")
        error("El archivo debe contener al menos el campo 'pos'.");
    end

    pos = data.pos;
    N = size(pos,1);

    gaussians = struct();
    gaussians.pos = pos;

    if isfield(data, "scale")
        gaussians.scale = data.scale;
    else
        gaussians.scale = 0.02 * ones(N,1);
        fprintf(" [INFO] Campo 'scale' no encontrado. Usando valor por defecto.\n");
    end

    if isfield(data, "color")
        gaussians.color = data.color;
    else
        gaussians.color = 0.5 * ones(N,3);
        fprintf(" [INFO] Campo 'color' no encontrado. Usando gris por defecto.\n");
    end

    if isfield(data, "opacity")
        gaussians.opacity = data.opacity;
    else
        gaussians.opacity = 0.5 * ones(N,1);
        fprintf(" [INFO] Campo 'opacity' no encontrado. Usando alpha por defecto.\n");
    end

end
