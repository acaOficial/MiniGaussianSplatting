function plot_training_progress(img, target_img, it, loss_history, psnr_history, mse_history, time_history, hFig)
% PLOT_TRAINING_PROGRESS Actualiza la visualización del progreso de entrenamiento
%
% Inputs:
%   img           - Imagen renderizada actual
%   target_img    - Imagen objetivo (ground truth)
%   it            - Iteración actual
%   loss_history  - Historial de loss
%   psnr_history  - Historial de PSNR
%   mse_history   - Historial de MSE
%   time_history  - Historial de tiempos
%   hFig          - Handle de la figura

    set(0, 'CurrentFigure', hFig);
    
    % Fila 1: Imágenes y tiempo
    subplot(2,3,1); 
    imshow(img); 
    title(sprintf('Render It: %d', it));
    
    subplot(2,3,2); 
    imshow(target_img); 
    title('Ground Truth');
    
    subplot(2,3,3); 
    plot(time_history(1:it), 'g', 'LineWidth', 2); 
    title('Tiempo por Iteración'); 
    xlabel('Iteración'); 
    ylabel('Tiempo (ms)'); 
    grid on;
    
    % Fila 2: Métricas
    subplot(2,3,4); 
    plot(loss_history(1:it), 'r', 'LineWidth', 2); 
    title('Loss'); 
    xlabel('Iteración'); 
    ylabel('Loss'); 
    grid on;
    
    subplot(2,3,5); 
    plot(psnr_history(1:it), 'b', 'LineWidth', 2); 
    title('PSNR'); 
    xlabel('Iteración'); 
    ylabel('PSNR (dB)'); 
    grid on;
    
    subplot(2,3,6); 
    plot(mse_history(1:it), 'm', 'LineWidth', 2); 
    title('MSE'); 
    xlabel('Iteración'); 
    ylabel('MSE'); 
    grid on;
    
    drawnow limitrate;
end
