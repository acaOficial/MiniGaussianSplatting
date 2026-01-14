function print_final_results(G, loss_history, psnr_history, mse_history, time_history, renders_dir)
% PRINT_FINAL_RESULTS Imprime los resultados finales del entrenamiento
%
% Inputs:
%   G             - Matriz final de gaussianas [N x 8]
%   loss_history  - Historial completo de loss
%   psnr_history  - Historial completo de PSNR
%   mse_history   - Historial completo de MSE
%   time_history  - Historial completo de tiempos
%   renders_dir   - Directorio donde se guardaron los renders

    num_g = size(G, 1);
    
    fprintf('==================================================================\n');
    fprintf('RESULTADOS FINALES\n');
    fprintf('==================================================================\n');
    
    for g_idx = 1:num_g
        fprintf('Gaussiana %d:\n', g_idx);
        fprintf('  Posición: [%.4f, %.4f, %.4f]\n', G(g_idx, 1), G(g_idx, 2), G(g_idx, 3));
        fprintf('  Escala: %.4f\n', G(g_idx, 4));
        fprintf('  Color: [%.2f, %.2f, %.2f]\n', G(g_idx, 5), G(g_idx, 6), G(g_idx, 7));
        fprintf('  Opacidad: %.4f\n', G(g_idx, 8));
    end
    
    fprintf('\nMÉTRICAS FINALES:\n');
    fprintf('  Loss final: %.6f\n', loss_history(end));
    fprintf('  PSNR final: %.2f dB\n', psnr_history(end));
    fprintf('  MSE final: %.6f\n', mse_history(end));
    
    fprintf('\nMÉTRICAS PROMEDIO:\n');
    fprintf('  Loss medio: %.6f\n', mean(loss_history));
    fprintf('  PSNR medio: %.2f dB\n', mean(psnr_history));
    fprintf('  MSE medio: %.6f\n', mean(mse_history));
    fprintf('  Tiempo medio por iteración: %.2f ms\n', mean(time_history));
    fprintf('  Tiempo total: %.2f segundos\n', sum(time_history)/1000);
    
    fprintf('\nRenders guardados en: %s\n', renders_dir);
    fprintf('==================================================================\n');
end
