function gaussians = update_gaussians(gaussians, grad, lr)
    gaussians.pos = gaussians.pos - lr * grad.pos;
    gaussians.scale = gaussians.scale - lr * grad.scale;
end
