function loss = compute_loss(img, target)
% COMPUTE_LOSS
% Calcula la pérdida combinada L1 + D-SSIM como en 3DGS
% Loss = (1 - lambda) * L1 + lambda * D-SSIM
% donde lambda = 0.2 (valor del paper original)

    img    = im2double(img);
    target = im2double(target);

    % Parámetros
    lambda = 0.2;  % peso para D-SSIM (del paper 3DGS)
    
    % L1 Loss
    l1_loss = mean(abs(img(:) - target(:)));
    
    % D-SSIM (1 - SSIM)
    % SSIM requiere Image Processing Toolbox
    % Si no está disponible, caemos a MSE
    try
        ssim_val = ssim(img, target);
        d_ssim = (1 - ssim_val) / 2;  % normalizado a [0,1]
    catch
        % Fallback a MSE si SSIM no está disponible
        warning('SSIM no disponible, usando MSE');
        d_ssim = mean((img(:) - target(:)).^2);
    end
    
    % Loss combinado (ecuación del paper 3DGS)
    loss = (1 - lambda) * l1_loss + lambda * d_ssim;
end
