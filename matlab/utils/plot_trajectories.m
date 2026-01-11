function plot_trajectories(trajectory, traj_history, num_g)
% PLOT_TRAJECTORIES Visualiza las trayectorias 3D de las gaussianas
%
% Inputs:
%   trajectory    - Trayectoria para una gaussiana (si num_g == 1)
%   traj_history  - Trayectorias para múltiples gaussianas (si num_g > 1)
%   num_g         - Número de gaussianas

    figure('Color', 'w', 'Name', 'Trayectorias 3D'); 
    hold on; grid on; axis equal;
    xlabel('X'); ylabel('Y'); zlabel('Z');
    title(sprintf('Recorrido de %d Gaussiana(s)', num_g));
    view(3); rotate3d on;
    
    if num_g == 1
        % Una gaussiana: plotear su trayectoria
        plot3(trajectory(:,1), trajectory(:,2), trajectory(:,3), 'r-', 'LineWidth', 2);
        plot3(trajectory(1,1), trajectory(1,2), trajectory(1,3), 'go', ...
              'MarkerSize', 10, 'MarkerFaceColor', 'g');
        plot3(trajectory(end,1), trajectory(end,2), trajectory(end,3), 'ro', ...
              'MarkerSize', 10, 'MarkerFaceColor', 'r');
        legend('Trayectoria', 'Inicio', 'Final');
    else
        % Múltiples gaussianas
        colors = ['r', 'b', 'g', 'm', 'c', 'y'];
        for g_idx = 1:num_g
            traj = squeeze(traj_history(:, :, g_idx));
            color = colors(mod(g_idx-1, length(colors)) + 1);
            
            % Trayectoria
            plot3(traj(:,1), traj(:,2), traj(:,3), [color '-'], ...
                  'LineWidth', 2, 'DisplayName', sprintf('G%d', g_idx));
            
            % Punto de inicio (verde)
            plot3(traj(1,1), traj(1,2), traj(1,3), 'go', ...
                  'MarkerSize', 8, 'MarkerFaceColor', 'g', 'HandleVisibility', 'off');
            
            % Punto final
            plot3(traj(end,1), traj(end,2), traj(end,3), [color 'o'], ...
                  'MarkerSize', 8, 'MarkerFaceColor', color, 'HandleVisibility', 'off');
        end
        legend('show');
    end
end
