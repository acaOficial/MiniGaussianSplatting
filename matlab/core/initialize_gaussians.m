function gaussians = initialize_gaussians(pos_file)

    % Cargar posiciones
    data = load(pos_file);  % debe contener variable "pos"
    pos = data.pos;

    N = size(pos,1);

    gaussians = struct( ...
        'pos', pos, ...               % posiciones cargadas
        'scale', 0.02 * ones(N,1), ... % escala inicial por defecto
        'color', 0.5 * ones(N,3), ...  % gris neutro inicial
        'opacity', 0.5 * ones(N,1) ... % alpha inicial
    );

end
