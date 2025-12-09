function L = compute_loss(img, target)
    L = mean((double(img(:)) - double(target(:))).^2);
end
