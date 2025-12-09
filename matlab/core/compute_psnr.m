function psnr_val = compute_psnr(img, target)
% COMPUTE_PSNR  Computa el PSNR entre dos imágenes.
%
%   img     → render actual (uint8 o double)
%   target  → imagen objetivo
%
%   Devuelve el PSNR en decibelios (dB)

    % Convertir a double para cálculo
    img = double(img);
    target = double(target);

    % Asegurar imágenes del mismo tamaño
    if ~isequal(size(img), size(target))
        error("compute_psnr: Las imágenes deben tener el mismo tamaño.");
    end

    % MSE
    mse = mean((img(:) - target(:)).^2);

    % Evitar división por cero
    if mse == 0
        psnr_val = Inf;
        return
    end

    % Rango máximo para uint8
    MAX_I = 255;

    psnr_val = 10 * log10((MAX_I^2) / mse);
end
