function [loss, psnr, mse] = compute_metrics(img, target)

% Calcula todas las métricas de evaluación: Loss, PSNR y MSE
%
% Inputs:
%   img    - Imagen renderizada
%   target - Imagen objetivo
%
% Outputs:
%   loss   - Loss combinado (L1 + D-SSIM) como en 3DGS
%   psnr   - Peak Signal-to-Noise Ratio en dB
%   mse    - Mean Squared Error

    img = im2double(img);
    target = im2double(target);
    
    % ========== LOSS (L1 + D-SSIM) ==========
    lambda = 0.2;  % peso para D-SSIM (del paper 3DGS)
    
    % L1 Loss
    l1_loss = mean(abs(img(:) - target(:)));
    
    % D-SSIM (1 - SSIM)
    try
        ssim_val = ssim(img, target);
        d_ssim = (1 - ssim_val) / 2;
    catch
        warning('SSIM no disponible, usando MSE');
        d_ssim = mean((img(:) - target(:)).^2);
    end
    
    % Loss combinado (ecuación del paper 3DGS)
    loss = (1 - lambda) * l1_loss + lambda * d_ssim;
    
    % ========== MSE ==========
    mse = mean((img(:) - target(:)).^2);
    
    % ========== PSNR ==========
    if mse < 1e-10
        psnr = 100;  % Las imágenes son casi las mismas
    else
        psnr = 10 * log10(1 / mse);
    end
end
