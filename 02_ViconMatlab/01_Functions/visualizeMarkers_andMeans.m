function [h] = visualizeMarkers_andMeans (viconPointStruct,meanStruct, pointsInfo,fileLength,startingFrame,visualize_yes)
% visualizeMarkers
%   This script takes a vicon point struct and displays all markers in a 3d
%   plot. Works best for less than 10 markers. The animation can be stopped
%   by pressing 'escape' any time to return.

% Input:    ViconPointStruct: A Vicon .c3d read with btkGetPoints()
%           pointsInfo: Vicon metadata read also with btkGetPoints()
%           fileLength: Metadata acquired by btkGetLastFrame
%           startingFrame: The frame the visualisation starts from
% Output:   3d Scatterplot with drawnow

if visualize_yes == 1 
    h = figure;
    
    % Access all the markers as a list
    fieldsPoints = fieldnames(viconPointStruct);
    fieldsMean = fieldnames(meanStruct);
    
    
    % Estimate frame per frame duration
    delta = 1 / pointsInfo.frequency;
    %% Estimate real time replay factor (try to replay data with 23 fps)
    jumps = floor(pointsInfo.frequency / 23);
    
    % Cycle through each frame
    for k = startingFrame:jumps:fileLength
        % Scatter the marker points in black
        for i = 1:numel(fieldsPoints)
            field = fieldsPoints{i}; % Define actual field
            x = viconPointStruct.(field)(k,1);
            y = viconPointStruct.(field)(k,2);
            z = viconPointStruct.(field)(k,3);
            
            % Save them in array for plotting
            plot_objects(i,1) = x;
            plot_objects(i,2) = y;
            plot_objects(i,3) = z;
            
        end
        
        % Scatter the means in red
        for i = 1:numel(fieldsMean)
            field = fieldsMean{i}; % Define actual field
            x = meanStruct.(field)(k,1);
            y = meanStruct.(field)(k,2);
            z = meanStruct.(field)(k,3);
            % Scatterplot of the xyz position of the current marker
            
            plot_objects_mean(i,1) = x;
            plot_objects_mean(i,2) = y;
            plot_objects_mean(i,3) = z;
            
        end
        
        % Plot the markers from both structs
        h = scatter3(plot_objects(:,1),plot_objects(:,2),plot_objects(:,3),5,'filled','black');
        h = scatter3(plot_objects_mean(:,1), plot_objects_mean(:,2), plot_objects_mean(:,3), 'filled','red');
        hold on % Keep the points alive
        
        % Set display angle for scatter plot
        view(45,45);
        
        % Set axis labes
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('Tracked markers and segment means');
        
        % Fix axis to area
        axis([0 4000 500 2000 500 2000]);        % axis([xmin xmax ymin ymax zmin zmax])
        
        
        pause(delta*jumps) %Pause after each plot to stay with real time
        
        %% Check if escape key has been pressed
        key = get(gcf,'CurrentKey');
        if(strcmp (key , 'escape'));
            return
        else
            key = [];
        end
        
        
    end
end

end

