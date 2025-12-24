function loss = compute_loss(img, target)
% COMPUTE_LOSS
% Calcula la pérdida MSE entre imagen render y target

    img    = im2double(img);
    target = im2double(target);

    diff = img - target;
    loss = mean(diff(:).^2);
end
