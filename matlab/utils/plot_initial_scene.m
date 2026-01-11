function plot_initial_scene(G, cams)
% PLOT_INITIAL_SCENE Visualiza la configuración inicial de gaussianas y cámaras
%
% Inputs:
%   G    - Matriz de gaussianas [N x 8] donde cada fila: [x,y,z,scale,r,g,b,alpha]
%   cams - Array de estructuras de cámaras con campos K, R, t

    num_g = size(G, 1);
    num_cams = length(cams);
    
    figure('Color', 'w', 'Name', 'Configuración Inicial de la Escena', ...
           'Position', [100, 100, 800, 600]);
    hold on; grid on; axis equal;
    xlabel('X'); ylabel('Y'); zlabel('Z');
    title('Posición Inicial: Gaussianas y Cámaras');
    view(3); rotate3d on;
    
    % Plotear gaussianas
    for g_idx = 1:num_g
        pos = G(g_idx, 1:3);
        rgb = G(g_idx, 5:7);
        
        plot3(pos(1), pos(2), pos(3), 'o', 'MarkerSize', 15, ...
              'MarkerFaceColor', rgb, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        
        text(pos(1), pos(2), pos(3)+0.05, sprintf('G%d', g_idx), ...
             'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
    
    % Plotear cámaras
    for cam_idx = 1:num_cams
        cam_pos = -cams(cam_idx).R' * cams(cam_idx).t;
        
        plot3(cam_pos(1), cam_pos(2), cam_pos(3), '^', 'MarkerSize', 10, ...
              'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
        
        view_dir = cams(cam_idx).R(3, :)';
        quiver3(cam_pos(1), cam_pos(2), cam_pos(3), ...
                view_dir(1)*0.1, view_dir(2)*0.1, view_dir(3)*0.1, ...
                'g', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
    end
    
    legend('Gaussianas', 'Cámaras', 'Location', 'best');
    drawnow;
end
