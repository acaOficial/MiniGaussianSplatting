function print_iteration_info(it, G, loss, psnr_val, time_ms)
% PRINT_ITERATION_INFO Imprime información de la iteración actual
%
% Inputs:
%   it        - Número de iteración
%   G         - Matriz de gaussianas [N x 8]
%   loss      - Valor de loss actual
%   time_ms   - Tiempo de la iteración lisegundos

    num_g = size(G, 1);
    
    fprintf('Iter: %04d | Loss: %.6f | PSNR: %.2f dB | Time: %.1f ms\n', ...
            it, loss, psnr_val, time_ms);
    
    for g_idx = 1:num_g
        pos_str = sprintf('[%.3f, %.3f, %.3f]', G(g_idx, 1), G(g_idx, 2), G(g_idx, 3));
        fprintf('  G%d -> Pos: %-25s | Scale: %.4f\n', g_idx, pos_str, G(g_idx, 4));
    end
    
    fprintf('--------------------------------------------------------------------------\n');
end
