function mse_val = compute_mse(img, target)
% COMPUTE_MSE
% Calcula el Mean Squared Error entre dos imágenes
% 
% Inputs:
%   img    - Imagen renderizada
%   target - Imagen objetivo (ground truth)
%
% Output:
%   mse_val - Valor MSE

    img = im2double(img);
    target = im2double(target);
    
    % Calcular MSE
    mse_val = mean((img(:) - target(:)).^2);
end
