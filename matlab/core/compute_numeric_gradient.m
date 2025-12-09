function grad = compute_numeric_gradient(gauss, cam, target)
% COMPUTE_NUMERIC_GRADIENT
% Devuelve struct con gradientes numéricos para cada gaussian.

    eps = 1e-3;       % paso para derivada numérica
    N = size(gauss.pos,1);

    % Inicializar gradiente vacío con misma estructura
    grad.pos     = zeros(size(gauss.pos));
    grad.scale   = zeros(N,1);
    grad.color   = zeros(size(gauss.color));
    grad.opacity = zeros(N,1);

    % Convertir escena actual → matriz G
    G0 = [gauss.pos, gauss.scale, gauss.color, gauss.opacity];
    img0 = render_mex_wrapper(G0, cam);
    L0 = compute_loss(img0, target);

    % ============================
    % 1. GRADIENTE DE POSICIÓN
    % ============================
    for i = 1:N
        for dim = 1:3

            gauss_eps = gauss;
            gauss_eps.pos(i,dim) = gauss.pos(i,dim) + eps;

            G = [gauss_eps.pos, gauss_eps.scale, gauss_eps.color, gauss_eps.opacity];
            img = render_mex_wrapper(G, cam);
            L = compute_loss(img, target);

            grad.pos(i,dim) = (L - L0) / eps;
        end
    end

    % ============================
    % 2. GRADIENTE DE ESCALA
    % ============================
    for i = 1:N
        gauss_eps = gauss;
        gauss_eps.scale(i) = gauss.scale(i) + eps;

        G = [gauss_eps.pos, gauss_eps.scale, gauss_eps.color, gauss_eps.opacity];
        img = render_mex_wrapper(G, cam);
        L = compute_loss(img, target);

        grad.scale(i) = (L - L0) / eps;
    end

    % ============================
    % 3. GRADIENTE DEL COLOR (r,g,b)
    % ============================
    for i = 1:N
        for cdim = 1:3
            gauss_eps = gauss;
            gauss_eps.color(i,cdim) = gauss.color(i,cdim) + eps;

            G = [gauss_eps.pos, gauss_eps.scale, gauss_eps.color, gauss_eps.opacity];
            img = render_mex_wrapper(G, cam);
            L = compute_loss(img, target);

            grad.color(i,cdim) = (L - L0) / eps;
        end
    end

    % ============================
    % 4. GRADIENTE OPACIDAD
    % ============================
    for i = 1:N
        gauss_eps = gauss;
        gauss_eps.opacity(i) = gauss.opacity(i) + eps;

        G = [gauss_eps.pos, gauss_eps.scale, gauss_eps.color, gauss_eps.opacity];
        img = render_mex_wrapper(G, cam);
        L = compute_loss(img, target);

        grad.opacity(i) = (L - L0) / eps;
    end
end
