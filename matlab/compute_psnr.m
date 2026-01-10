function psnr_val = compute_psnr(img, target)
% COMPUTE_PSNR
% Calcula el Peak Signal-to-Noise Ratio entre dos imágenes
% 
% Inputs:
%   img    - Imagen renderizada
%   target - Imagen objetivo (ground truth)
%
% Output:
%   psnr_val - Valor PSNR en dB

    img = im2double(img);
    target = im2double(target);
    
    % Calcular MSE
    mse = mean((img(:) - target(:)).^2);
    
    % Evitar división por cero
    if mse < 1e-10
        psnr_val = 100;  % Imágenes casi idénticas
    else
        % PSNR = 10 * log10(MAX^2 / MSE)
        % Para imágenes normalizadas [0,1], MAX = 1
        psnr_val = 10 * log10(1 / mse);
    end
end
