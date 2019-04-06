%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Eyetracking Pipeline (Andrea Tanzstudie)
% Ralf Kredel
% Version: 0.2
% Stand: 15.04.14
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Aufräumen
close all;
clear all;
clc;

%Videoframerate
% fps_vid = 25;

% Informationen über die Ausführungsumgebung
actualDir = cd;

% Pfadinformationen hinzufügen, damit Matlab weiss, wo die verwendeten
% Funktionen zu finden sind.
addpath(actualDir);
addpath(fullfile(actualDir,'toolboxen'));
addpath(fullfile(actualDir,'toolboxen','basic'));
addpath(fullfile(actualDir,'toolboxen','eyetracking'));
addpath(fullfile(actualDir,'toolboxen','digMe'));
% addpath(fullfile(actualDir,'toolboxen','btk','share','btk-0.2','Wrapping','Matlab','btk'));
addpath(fullfile(actualDir,'toolboxen','btk3'));

% addpath(fullfile(actualDir,'toolboxen','btk4','@Common'));

% Pfad zu den Daten
% condition = 'vs';
%Vicon Daten
pName = fullfile(actualDir,'data','Vicon');
% Adjustments
adjPath = fullfile(actualDir,'data','Adjustment');

%Zwischendatenpfad
pNameSave = fullfile(actualDir,'data','C3D_Gaze');


% Auslesen der File-Infos:
dir_struct = dir (fullfile(pName,'v*'));

[VPNfolder,sorted_index] = sortrows({dir_struct.name}');
% Falls alle Verzeichnisse aufgelistet werden, die ersten beiden
% (current/parent) herauslöschen


% Ergebniszähler initialisieren
cnter = 2;

for m=5
    
    %m = 1:length(VPNfolder)
    % Interessierende Files auswählen
    %dir_struct = dir (fullfile(pName,VPNfolder{m},'Patient 1','Test',sprintf('%s_cond*.c3d',VPNfolder{m})));
    dir_struct = dir (fullfile(pName,VPNfolder{m},'Patient 1','Test',sprintf('%s_cond*_fouette.c3d',VPNfolder{m})));
    [filenames,sorted_index] = sortrows({dir_struct.name}');
    
    
    for l = 1:length(filenames)
        close all;drawnow
        %jeweiligen Filename erzeugen
        fName = fullfile(pName,VPNfolder{m},'Patient 1','Test',filenames{l});
        
        fName
        
        
        clear temp dprModel;
        % Erzeuge "handle" auf das File
        h = btkReadAcquisition(fName);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % lese Kameradaten aus
        % Länge der Markerdaten
        fileLength = btkGetLastFrame(h);
        % Markerdaten
        [temp.kinData pointsInfo] = btkGetPoints(h);
        % marker aufnahmefrequenz:
        fps_m = pointsInfo.frequency;
        
        clear pointsInfo;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % lese analoge Daten aus (unterschiedliche Aufnahmefrequenz!)
        % Länge der analogen Daten
        analogLength = btkGetAnalogFrameNumber(h);
        % Daten auslesen äquivalent zu "bktGetPoints"
        [temp.rawData analogsInfo] = btkGetAnalogs(h);
        % analogdatenaufnahmefrequenz
        fps_a = analogsInfo.frequency;
        analogLength = length(temp.rawData);
        
        btkDeleteAcquisition(h);
        
        
        %         temp.filtKinData = filterKinematics(temp.kinData,0); % sgolay mit 3,41
        temp.filtKinData = filterKinematicsButter(temp.kinData,fps_m,8,20);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Load adjustment files
        dir_struct = dir (fullfile(adjPath,'*.mat'));
        [adj_files,sorted_index] = sortrows({dir_struct.name}');
        %check index of adjustment files
        idx = find(strncmp(adj_files,filenames{l},3));
        
        adjData = load(fullfile(adjPath,adj_files{idx(1)}));
        %wenn mehr als ein File für eine Person
        if length(idx) == 2
            fileTest = adj_files{idx(2)};
            blockNextAdjust = str2double(fileTest(end-4));
            if str2double(filenames{l}(9)) == blockNextAdjust
                adjData = load(fullfile(adjPath,adj_files{idx(2)}));
            end
        end
        temp.screenCoord = adjData.screenCoord;
        temp.headRotAdj = adjData.headRotAdj;
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % create new acquisition
        h = btkNewAcquisition(0,size(temp.kinData.left,1),0,fps_a/fps_m);
        btkSetFrequency(h,fps_m);
        btkSetAnalogSampleNumberPerFrame(h, 5);
        
        % add Markers to new acquisition
        names = fieldnames(temp.kinData);
        for t = 1:length(names)
            t_value = double(getfield(temp.kinData,names{t}));
            btkAppendPoint(h, 'Marker', names{t},t_value);
        end
        
        %headMarkerfiltered
        btkAppendPoint(h, 'Marker', 'fLeft',double(temp.filtKinData.left));
        btkAppendPoint(h, 'Marker', 'fRight',double(temp.filtKinData.right));
        btkAppendPoint(h, 'Marker', 'fTop',double(temp.filtKinData.top));
        %screenCoordinates
        btkAppendPoint(h, 'Marker', 'screen_UL',repmat(temp.screenCoord(1,:),fileLength,1));
        btkAppendPoint(h, 'Marker', 'screen_DL',repmat(temp.screenCoord(2,:),fileLength,1));
        btkAppendPoint(h, 'Marker', 'screen_DR',repmat(temp.screenCoord(3,:),fileLength,1));
        btkAppendPoint(h, 'Marker', 'screen_UR',repmat(temp.screenCoord(4,:),fileLength,1));
        
        %calculate position of fixation cross
        %         fp0 = mean(temp.screenCoord(:,1));
        %         fp1 = (((mean(temp.screenCoord(3:4,2))-mean(temp.screenCoord(1:2,2)))/2)+mean(temp.screenCoord(1:2,2))) ;
        %         fp2 = ((mean(temp.screenCoord([1 4],3))-mean(temp.screenCoord(2:3,3))) * (1-((288-50)/(576-50)))) + mean(temp.screenCoord(2:3,3)); %288 Pixel von Oben ist der Mittelpunkt des Fixationspunktes
        %         fixPoint = repmat([fp0 fp1  fp2 ],fileLength,1);
        
        %% Rolf, June 8, 2014
        
        % Concatenate all hip markers along 3rd dimension
        hip3D = cat(3,temp.filtKinData.LASI,temp.filtKinData.LPSI,temp.filtKinData.RASI,temp.filtKinData.RPSI);
        
        % Calculate the center of mass of the four hip markers
        hip_cm = nanmean(hip3D,3);
        
        % Calculate the vector connecting (1) mean(LASI,LPSI) with (2) mean(RASI,RPSI). This will be the vector that determines the rotation angle relative to the frontal plane.
        hip_leftright = nanmean(hip3D(:,:,1:2),3)-nanmean(hip3D(:,:,3:4),3);
        
%         % Plot pelvis @ n-th frame
%         figure(1)
%         set (gcf, 'Units', 'normalized', 'outerposition', [0,0,1,1]);
%         frame = 1; % ... n-th frame
%         % draw pelvis
%         line(shiftdim(hip3D(frame,1,[1 3 4 2 1 4 2 3])),shiftdim(hip3D(frame,2,[1 3 4 2 1 4 2 3])),'color','r','linewidth',2);
%         hold on
%         % draw pelvis transversal axis
%         plot([0 hip_leftright(frame,1)]+nanmean(hip3D(frame,1,3:4),3),[0 hip_leftright(frame,2)]+nanmean(hip3D(frame,2,3:4),3),'k','linewidth',2)
%         % draw pelvis cm
%         plot(hip_cm(frame,1),hip_cm(frame,2),'*g','markersize',10,'linewidth',2)
%         xlabel('x [mm]');ylabel('y [mm]');axis equal;grid on;
%         title(['Pelvis position @ sample ',num2str(frame),' (',fName,')']);
%         legend('pelvis','pelvis transversal axis','pelvis cm');
%         % label pelvis markers
%         pelvislabels = {'LASI';'LPSI';'RASI';'RPSI'};
%         for i_pl = 1:4
%             text(shiftdim(hip3D(frame,1,i_pl))+2,shiftdim(hip3D(frame,2,i_pl)),pelvislabels{i_pl}, 'Color', 'k','fontweight','bold','fontsize',12);
%         end
%         pause
        
        % Calculate angle of the transversal hip axis relative to the frontal
        % position (positive angles imply leftward rotation).
        hip_angle = angle2d(repmat([0 1],length(hip_leftright),1),hip_leftright(:,1:2));
        %hip_angle = -hip_angle; % this simply to simulate the other rotation direction...
        time = [1:length(hip_angle)]/fps_m;
        
%         % Plot hip angle time series
%         figure(2)
%         set (gcf, 'Units', 'normalized', 'outerposition', [0,0,1,1]);
%         plot(time,hip_angle,'color',[.8 .8 .8],'linewidth',2)
%         xlabel('time [s]')
%         ylabel('hip angle [degrees] - positive angle represents counterclockwise rotation')
%         grid on;hold on;shg
        
        % find peaks in hip angle
        [peaks,locs] = findpeaks(hip_angle,'minpeakheight',150);
        plot(time(locs),hip_angle(locs),'or','linewidth',2)
        
        % find relevant zero-crossings based on peaks
        
        neg_hip_angle = find(hip_angle<=0);
        if hip_angle(locs(1)+1)<0; % counterclockwise rotation
            zc = nan(length(locs)-1,1);
            for i_zc = 2:length(locs)
                % locate last zero-crossing before peak
                zc_index = find(neg_hip_angle<locs(i_zc),1,'last');
                zc(i_zc-1) = neg_hip_angle(zc_index);
            end
        else % clockwise rotation
            zc = nan(length(locs)-1,1); % with most participants it can be: zc = nan(length(locs),1);
            for i_zc = 1:length(locs)-1 % with most participants it can be: i_zc = 1:length(locs)
                % locate first zero-crossing after peak
                zc_index = find(neg_hip_angle>locs(i_zc),1,'first');
                zc(i_zc) = neg_hip_angle(zc_index);
            end
        end
        
%         % draw a marker at each zero-crossing
%         plot(time(zc),hip_angle(zc),'og','linewidth',2)
        
        % make sure that four sandwiched fouettes can be selected, and subsequently select them
        if length(zc)<5
            error('Can''t select four valid rotations: total number of rotations might be too small')
        else
            start = zc(1);stop = zc(5);
        end
        
        % calculate average time per fouette in seconds
        time_per_fouette = (stop-start)/(4*fps_m);

%         % draw hip_angle in relevant range
%         plot(time(start:stop),hip_angle(start:stop),'k','linewidth',2)
%         % label the start and stop zero-crossings
%         text(time(start)+.1,hip_angle(start),'start','fontweight','bold')
%         text(time(stop)+.1,hip_angle(stop),'stop','fontweight','bold')
%         % and add a title and legend to the figure
%         title(['Hip rotation time series with relevant window (',fName,')'])
%         legend('hip angle','peaks','zero-crossings','relevant range')
%         pause

    
        
        %Berechnung Stabilität in der Pirouette, eingefügt von Andrea Schärli 6. Juni 2014
        
        % Calculations:
        
        %% Calculate Ellipse areas
        [~,~,head_ellipse_area]=confellipse2([temp.filtKinData.top(start:stop,1),temp.filtKinData.top(start:stop,2)],.95,0);
        [~,~,leftToe_ellipse_area]=confellipse2([temp.filtKinData.leftToe(start:stop,1),temp.filtKinData.leftToe(start:stop,2)],.95,0);
        [~,~,rightToe_ellipse_area]=confellipse2([temp.filtKinData.rightToe(start:stop,1),temp.filtKinData.rightToe(start:stop,2)],.95,0);
        [~,~,COM_ellipse_area]=confellipse2([hip_cm(start:stop,1),hip_cm(start:stop,2)],.95,0);

%         % 95% ellipse area: first caluculate average of x- and y-values:
%         %head:
%         head_top_x_avg=nanmean(temp.filtKinData.top(start:stop,1));
%         head_top_y_avg=nanmean(temp.filtKinData.top(start:stop,2));
%         %toe: Achtung: check, wer anders um dreht, da ist es dann rightToe!!!!
%         leftToe_x_avg=nanmean(temp.filtKinData.leftToe(start:stop,1));
%         leftToe_y_avg=nanmean(temp.filtKinData.leftToe(start:stop,2));
%         rightToe_x_avg=nanmean(temp.filtKinData.rightToe(start:stop,1));
%         rightToe_y_avg=nanmean(temp.filtKinData.rightToe(start:stop,2));
%         %estimated COM:
%         COM_x_avg=nanmean(hip_cm(start:stop,1));
%         COM_y_avg=nanmean(hip_cm(start:stop,2));
%         
%         %second: subtract averages from data to determine x- and y- mean relative
%         %head:
%         head_top_x_avg_rel=temp.filtKinData.top(start:stop,1) - head_top_x_avg;
%         head_top_y_avg_rel=temp.filtKinData.top(start:stop,2) - head_top_y_avg;
%         %toe:
%         leftToe_x_avg_rel=temp.filtKinData.leftToe(start:stop,1) - leftToe_x_avg;
%         leftToe_y_avg_rel=temp.filtKinData.leftToe(start:stop,2) - leftToe_y_avg;
%         rightToe_x_avg_rel=temp.filtKinData.rightToe(start:stop,1) - rightToe_x_avg;
%         rightToe_y_avg_rel=temp.filtKinData.rightToe(start:stop,2) - rightToe_y_avg;
%         %estimated COM:
%         COM_x_avg_rel=hip_cm(start:stop,1) - COM_x_avg;
%         COM_y_avg_rel=hip_cm(start:stop,2) - COM_y_avg;
%         
%         %third: Calculate the standard deviation of markers_top_x_avg_rel and of
%         %markers_top_y_avg_rel:
%         %head:
%         head_top_x_avg_rel_std=std(head_top_x_avg_rel);
%         head_top_y_avg_rel_std=std(head_top_y_avg_rel);
%         %toe:
%         leftToe_x_avg_rel_std=std(leftToe_x_avg_rel);
%         leftToe_y_avg_rel_std=std(leftToe_y_avg_rel);
%         rightToe_x_avg_rel_std=std(rightToe_x_avg_rel);
%         rightToe_y_avg_rel_std=std(rightToe_y_avg_rel);
%         %estimated COM:
%         COM_x_avg_rel_std=std(COM_x_avg_rel);
%         COM_y_avg_rel_std=std(COM_y_avg_rel);
%         
%         %fourth: Calculate the covariance of markers_Top_X_avg_rel and markers_top_y_avg_rel
%         %head:
%         a=length(head_top_x_avg_rel)-1;
%         head_top_x_y_avg_rel_cov=sqrt(sum(((head_top_x_avg_rel).^2).*((head_top_y_avg_rel.^2))))/a;
%         %toe:
%         a=length(leftToe_x_avg_rel)-1;
%         leftToe_x_y_avg_rel_cov=sqrt(sum(((leftToe_x_avg_rel).^2).*((leftToe_y_avg_rel.^2))))/a;
%         a=length(rightToe_x_avg_rel)-1;
%         rightToe_x_y_avg_rel_cov=sqrt(sum(((rightToe_x_avg_rel).^2).*((rightToe_y_avg_rel.^2))))/a;
%         %estimated COM:
%         a=length(COM_x_avg_rel)-1;
%         COM_x_y_avg_rel_cov=sqrt(sum(((COM_x_avg_rel).^2).*((COM_y_avg_rel.^2))))/a;
%         
%         
%         %fifth: Calculate an intermediate value D:
%         %head:
%         head_top_avg_rel_D=sqrt(((head_top_x_avg_rel_std)^2+(head_top_y_avg_rel_std)^2)^2 - 4*(((head_top_x_avg_rel_std)^2)*((head_top_y_avg_rel_std)^2)-(head_top_x_y_avg_rel_cov)^2));
%         %toe:
%         leftToe_avg_rel_D=sqrt(((leftToe_x_avg_rel_std)^2+(leftToe_y_avg_rel_std)^2)^2 - 4*(((leftToe_x_avg_rel_std)^2)*((leftToe_y_avg_rel_std)^2)-(leftToe_x_y_avg_rel_cov)^2));
%         rightToe_avg_rel_D=sqrt(((rightToe_x_avg_rel_std)^2+(rightToe_y_avg_rel_std)^2)^2 - 4*(((rightToe_x_avg_rel_std)^2)*((rightToe_y_avg_rel_std)^2)-(rightToe_x_y_avg_rel_cov)^2));
%         %estimated COM:
%         COM_avg_rel_D=sqrt(((COM_x_avg_rel_std)^2+(COM_y_avg_rel_std)^2)^2 - 4*(((COM_x_avg_rel_std)^2)*((COM_y_avg_rel_std)^2)-(COM_x_y_avg_rel_cov)^2));
%         
%         %sixth: The intermediate value F=3.00 from table of F statistic at a
%         %confidence level of 1-alpha. where alpha=0.05 when the sample size>120
%         F=3.00;
%         
%         %seventh: Calculate the length of the major and minor axis:
%         %head:
%         head_top_ellipse_major=sqrt(F*((head_top_x_avg_rel_std)^2+(head_top_y_avg_rel_std)^2+head_top_avg_rel_D));
%         head_top_ellipse_minor=sqrt(F*((head_top_x_avg_rel_std)^2+(head_top_y_avg_rel_std)^2-head_top_avg_rel_D));
%         %toe:
%         leftToe_ellipse_major=sqrt(F*((leftToe_x_avg_rel_std)^2+(leftToe_y_avg_rel_std)^2+leftToe_avg_rel_D));
%         leftToe_ellipse_minor=sqrt(F*((leftToe_x_avg_rel_std)^2+(leftToe_y_avg_rel_std)^2-leftToe_avg_rel_D));
%         rightToe_ellipse_major=sqrt(F*((rightToe_x_avg_rel_std)^2+(rightToe_y_avg_rel_std)^2+rightToe_avg_rel_D));
%         rightToe_ellipse_minor=sqrt(F*((rightToe_x_avg_rel_std)^2+(rightToe_y_avg_rel_std)^2-rightToe_avg_rel_D));
%         %estimated COM:
%         COM_ellipse_major=sqrt(F*((COM_x_avg_rel_std)^2+(COM_y_avg_rel_std)^2+COM_avg_rel_D));
%         COM_ellipse_minor=sqrt(F*((COM_x_avg_rel_std)^2+(COM_y_avg_rel_std)^2-COM_avg_rel_D));
%         
%         %eigth: Calculate the area of the 95% ellipse
%         %head
%         head_ellipse_area=(2*3.1415963*F)*sqrt(((head_top_x_avg_rel_std)^2)*((head_top_y_avg_rel_std)^2)-((head_top_x_y_avg_rel_cov)^2));
%         %toe:
%         leftToe_ellipse_area=(2*3.1415963*F)*sqrt(((leftToe_x_avg_rel_std)^2)*((leftToe_y_avg_rel_std)^2)-((leftToe_x_y_avg_rel_cov)^2));
%         rightToe_ellipse_area=(2*3.1415963*F)*sqrt(((rightToe_x_avg_rel_std)^2)*((rightToe_y_avg_rel_std)^2)-((rightToe_x_y_avg_rel_cov)^2));
%         %estimated COM:
%         COM_ellipse_area=(2*3.1415963*F)*sqrt(((COM_x_avg_rel_std)^2)*((COM_y_avg_rel_std)^2)-((COM_x_y_avg_rel_cov)^2));
        
        
        %% ...and save calculated variables for export:
        exp_head_ellipse_area{m,l} =  head_ellipse_area;
        exp_leftToe_ellipse_area{m,l} =  leftToe_ellipse_area;
        exp_rightToe_ellipse_area{m,l} =  rightToe_ellipse_area;
        exp_COM_ellipse_area{m,l} =  COM_ellipse_area;
        exp_average_time_fouette{m,l} = time_per_fouette;
        
        
        middlePoint = mean(temp.screenCoord(:,:));
        middlePoint = repmat(middlePoint,fileLength,1);
        
        
        screen.L = mean(temp.screenCoord(1:2,2));
        screen.R = mean(temp.screenCoord(3:4,2));
        screen.U = mean(temp.screenCoord([1 4],3));
        screen.D = mean(temp.screenCoord(2:3,3));
        screen.C = mean(temp.screenCoord(:,:));
        screen.distY = screen.L - screen.R;
        screen.distZ = screen.U - screen.D;
       
        
        %headrotation
        [points pointsinfo] = btkAppendPoint(h, 'Marker', 'headrot_1x',repmat(temp.headRotAdj(1,:),fileLength,1));
        [points pointsinfo] = btkAppendPoint(h, 'Marker', 'headrot_2x',repmat(temp.headRotAdj(2,:),fileLength,1));
        [points pointsinfo] = btkAppendPoint(h, 'Marker', 'headrot_3x',repmat(temp.headRotAdj(3,:),fileLength,1));
        %eyedata
        [analogs analogInfo] = btkAppendAnalog(h, 'LEVERT',temp.rawData.LEVERT);
        [analogs analogInfo] = btkAppendAnalog(h, 'LEHORI',temp.rawData.LEHORI);
        [analogs analogInfo] = btkAppendAnalog(h, 'REVERT',temp.rawData.REVERT);
        [analogs analogInfo] = btkAppendAnalog(h, 'REHORI',temp.rawData.REHORI);
        %         btkAppendAnalog(h, 'REVERT',temp.rawData(:,3));
        %         btkAppendAnalog(h, 'REHORI',temp.rawData(:,4));
        [analogs analogInfo] = btkAppendAnalog(h, 'C1',temp.rawData.C1);
        [analog analogInfo] = btkAppendAnalog(h, 'C2',temp.rawData.C2);
        analogLength = btkGetAnalogFrameNumber(h);
        
        
        % Augenrotationen
        rawData = [analog.LEVERT analog.LEHORI];
        % Blink bereinigen, filtern (abhängig von bino und mono cam
        if str2double(VPNfolder{m}(2:3)) < 10 %kleiner 10 ist monokular mit Eyetracker auf der rechten Seite
            [anaData interpStart interpStop] = processRawEyeData(rawData,fps_a,fps_m,false);
        else
            [anaData interpStart interpStop] = processRawEyeData(rawData,fps_a,fps_m,true);
            rawData2 = [analog.REVERT analog.REHORI];
            [anaData2 interpStart2 interpStop2] = processRawEyeData(rawData2,fps_a,fps_m,true);
        end
        % jetzt auf 200Hz gesampelte Augendaten:
        levert = anaData(:,1);
        lehori = anaData(:,2);
        revert = anaData(:,1);
        rehori = anaData(:,2);
        
        %letzter Parameter ist die Distanz des Fixationspunktes vom Auge in
        %mm
        %head: Kopforientierung
        %eye: Augenposition
        %gaze: Gazeposition
        %gazePoint: gazePosition am Screen
        %in: 1/0 wenn Gaze in Screen (vielleicht nicht funktional)
        if str2double(VPNfolder{m}(2:3)) < 10 %kleiner 10 ist monokular mit Eyetracker auf der rechten Seite
            [head eye gaze gazePoint in] = calculateGazePositionDistance(points.fLeft,points.fRight,points.fTop,temp.headRotAdj,levert,lehori,temp.screenCoord,2000,true);
            meanGaze = gazePoint;
            meanGazeNP = gaze;
            meanEye = eye;
            meanIn = in;
        else  % ab 10 Binokular
            [head eye gaze gazePoint in] = calculateGazePositionDistance(points.fLeft,points.fRight,points.fTop,temp.headRotAdj,levert,lehori,temp.screenCoord,2000,false);
            [head2 eye2 gaze2 gazePoint2 in2] = calculateGazePositionDistance(points.fLeft,points.fRight,points.fTop,temp.headRotAdj,revert,rehori,temp.screenCoord,2000,true);
            meanGaze = [];
            meanGaze(1,:,:) = gazePoint;
            meanGaze(2,:,:) = gazePoint2;
            meanGaze = squeeze(mean(meanGaze,1));
            meanIn = [];
            meanIn(1,:,:) = in;
            meanIn(2,:,:) = in2;
            meanIn = squeeze(mean(meanIn,1));
            meanGazeNP = [];
            meanGazeNP(1,:,:) = gaze;
            meanGazeNP(2,:,:) = gaze2;
            meanGazeNP = squeeze(mean(meanGazeNP,1));
            meanEye = [];
            meanEye(1,:,:) = eye;
            meanEye(2,:,:) = eye2;
            meanEye = squeeze(mean(meanEye,1));
            btkAppendPoint(h, 'Marker', 'eye2',eye2);
            btkAppendPoint(h, 'Marker', 'gazeR',gaze2);
            btkAppendPoint(h, 'Marker', 'gazePoint2',gazePoint2);
        end
        
        %add gazevector
        btkAppendPoint(h, 'Marker', 'eye',eye);
        btkAppendPoint(h, 'Marker', 'gaze',gaze);
        btkAppendPoint(h, 'Marker', 'gazePoint',gazePoint);
        
        btkAppendPoint(h, 'Marker', 'meanGaze',meanGaze);
        btkAppendPoint(h, 'Marker', 'meanEye',meanEye);
        
        inAna = interp1(in,1:0.2:fileLength+0.8)'; % change to analog resolution
        btkAppendAnalog(h,'gazeInScreen',inAna);
        
      %  [points pointsinfo] = btkAppendPoint(h, 'Marker', 'inScreen',repmat(meanIn,1,3));
      %30. September: geht nur bei subject 7???, sonst Fehlermeldungen

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Fixation Detection Algorithm (innerhalb 3° und min 60ms)
        meanGaze(meanIn==0,:)=NaN;
        meanEye(meanIn==0,:)=NaN;
        [fixation das]= findFixIDT(meanEye,meanGaze,3,12,start,stop,0);
        fixation = linkFixations(fixation,3,80);
        fixLocation = nan(fileLength,3);
        for fCnt = 1:size(fixation,2)
            fixLocation(fixation(fCnt).start:fixation(fCnt).stop,:) = repmat(fixation(fCnt).position,length(fixation(fCnt).start:fixation(fCnt).stop),1);
        end
        [points pointsinfo] = btkAppendPoint(h, 'Marker', 'fixLocation',fixLocation);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Andre Export, Fixation Data to one variable; better use Saccade
        %Detection
%         for i=1:size(fixation,2)
%            fix_exp(i,1) = fixation(1,i).start; 
%            fix_exp(i,2) = fixation(1,i).stop; 
%            fix_exp(i,3:5) = fixation(1,i).position; 
%         end
%         
%         %Take only relevat Fixation (Start4Fouette.Stop4Fouette
%         fix_4fouette = [];
%         tmp_start = [];
%         tmp_stop = [];
%         tmp_start = find(fix_exp(:,1) > start,1,'first');
%         tmp_stop = find(fix_exp(:,1) > stop,1,'first');
%         if isempty(tmp_stop)
%             tmp_stop = size(fix_exp,1);
%         end
%         fix_4fouette = fix_exp(tmp_start:tmp_stop,:);
%         
%         exp_fixLocation{m,l} =  fixLocation;
%         exp_fixation{m,l} = fixation;
%         exp_fix4fouette{m,1} = fix_4fouette;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Saccade Detection
        
% Saccade Detection Algorithm based on Instantaneous Angle Calculation
        % PARAMETERS
        %select axis for angle calculation
        % 0: vert and hori
        % 1: hori
        % 2: vert
        AXIS = 0;
        %select frequency of data collection (SamplingRate)
        FREQUENCY = fps_m;
        %display figure with detected saccades
        % 1: show
        % : do not show
        SHOWPLOT = 0; 

        
        % INPUT DATA
        lEye = [];
        % Sakkaden nur für 4 Piroutten (start:stop)
        lehori(meanIn==0)=NaN;
        levert(meanIn==0)=NaN;
        lEye (:,1) = lehori(start:stop,1);
        lEye (:,2) = levert(start:stop,1);
        
        %saccades:
        %1st col: start Saccade (data index)
        %2nd col: end Saccade (data index)
        %3rd col: end Glissade (data index)
        %4th col: type of Glissade (0: low vel / 1:high vel)
        [saccades saccCounter] = saccadeDetect(lEye,SHOWPLOT,FREQUENCY,AXIS);
        %Schauen welche EINHEIT??%%
        
        % Sakkadendetektion in original Zeitlinie (+start)
        saccades(:,1) = saccades(:,1)+ start;
        saccades(:,2) = saccades(:,2)+ start;

        % Berechnung von "Fixationen" (Sakkadenzwischenräume)
        for i = 1: size(saccades,1)-1
            fixSaccades(i,1) = saccades(i,2)+1;
            fixSaccades(i,2) = saccades(i+1,1)-1;
        end
        
        % Berechnung Fixationsdauer (in Spalte 3, in ms)
           fixSaccades(:,3) = (fixSaccades(:,2)-fixSaccades(:,1)).*5;

         % Elimination von Fixationen unterhalb Threshold von (im Moment) 50 ms   
        for i = size(fixSaccades,1):-1:1
            if fixSaccades(i,3) < 50
                fixSaccades(i,:) = [];
            end
        end
        
        % Berechnung Position Fixation
        for i = 1:size(fixSaccades,1)
            fixSaccades(i,4) = nanmean(meanGaze(fixSaccades(i,1):fixSaccades(i,2),1));
            fixSaccades(i,5) = nanmean(meanGaze(fixSaccades(i,1):fixSaccades(i,2),2));
            fixSaccades(i,6) = nanmean(meanGaze(fixSaccades(i,1):fixSaccades(i,2),3));
        end
        
        for i=size(fixSaccades,1):-1:1
            if fixSaccades(i,5) > screen.C(1,2)+screen.L || fixSaccades(i,5) < screen.C(1,2)+screen.R
                fixSaccades(i,:) = [];
            end
        end
        
        exp_fixSaccades{m,1} = fixSaccades;
        
        
        %         %digitized data
        %         if str2double(filenames{l}(10:11)) > 5
        %             dprIndex = (str2double(filenames{l}(10:11))-6)*12 + str2double(filenames{l}(14:15));
        %         else
        %             dprIndex = (str2double(filenames{l}(10:11))-1)*12 + str2double(filenames{l}(14:15));
        %         end
        %
        %         if strcmp(condition,'vs')
        %             dprFile = sprintf('%s_vs.dpr',Reihung_Szenen_2013_VS{dprIndex,1});
        %
        %         else
        %             dprFile = sprintf('%s_vs.dpr',Reihung_Szenen_2013_TS{dprIndex,1});
        %         end
        %         %make gender specific dpr filenames
        %         dprFile = [filenames{l}(1) dprFile(2:end)];
        %
        %         DM_version = 'new';
        %         dprModel = getDigCoords(fullfile(dprPath,dprFile),screen,DM_version);
        %         digiData = length(dprModel.coords(1,:,1));
        %
        %
        %         sceneOffset = (380 + 360);
        %         %add scene and fixation Information
        %         fixCross = zeros(analogLength,1);
        %         fixCross(1:(sceneOffset*5)) = 1;
        %
        %         fixPointScene = fixPoint;
        %         fixPointScene(sceneOffset:end,:) = NaN;
        %         %and add it as marker
        %         [points pointsinfo] = btkAppendPoint(h, 'Marker', 'screen_FixCross',fixPointScene);
        %
        %
        %
        %
        %         startNaN = sceneOffset ; %690%;380; %400 (2s fix) -20 (audiotrigger bug)
        %
        %         stopNaN = fileLength-startNaN-digiData;%audioIdxTrial(trialIdx,2);
        %         if stopNaN <= 0
        %             dprModel.coords = dprModel.coords(:,1:end+stopNaN,:);
        %         end
        %
        %
        %         for dprIdx = 1:length(dprModel.names)
        %             dprCoords = [nan(startNaN,3) ; squeeze(dprModel.coords(dprIdx,:,:)) ; nan(stopNaN,3)];
        %             [points pointsinfo] = btkAppendPoint(h, 'Marker', dprModel.names{dprIdx},dprCoords );
        %         end
        %
        %         sceneInfo = zeros(analogLength,1);
        %         sceneEnd = (audioIdxTrial(1,2)-20)*fps_a/fps_m;  % 20 vicon frames late as trigger is upside-down
        %         sceneInfo(sceneOffset *5:sceneEnd) = 1; % 20 vicon frames = 100 analog frames, subtract as well
        %
        %         [analogs analogInfo] = btkAppendAnalog(h, 'fixCross',fixCross);
        %         [analogs analogInfo] = btkAppendAnalog(h, 'sceneInfo',sceneInfo);
        
        
        
        %         % hier erzeugen wir unsere Ergebnismatrix, die wir dann nach Excel exportieren
        %         result(1,:) = {'VPN' 'File' 'Länge' 'maxTrial' 'Trial' 'fixIdxVid Start' 'fixIdxVid Stop' 'audioIdxVid Start' 'audioIdxVid Stop' 'delta Start' 'delta  Stop' 'audioIdxTrial Start' 'audioIdxTrial Stop' 'deltaTrialStart' 'deltaTrialStop' 'startFrame' 'numFrames' 'error'};
        %         result(cnter,:) = {VPNfolder{m} filenames{l} fileLength size(audioIdxTrial,1) trialIdx fixationIdxVideo(trialIdx,1) fixationIdxVideo(trialIdx,2) audioIdxVideo(trialIdx,1) audioIdxVideo(trialIdx,2) deltaIdxFixation(trialIdx,1) deltaIdxFixation(trialIdx,2) audioIdxTrial(trialIdx,1) audioIdxTrial(trialIdx,2) audioIdxTrial(trialIdx,1)-audioIdxVideo(trialIdx,1)  audioIdxTrial(trialIdx,2)-audioIdxVideo(trialIdx,2) startFrame numFrames error};
        %         cnter = cnter +1;
        
        %Speichern der Gazedisplay C3Ds
        btkWriteAcquisition(h,fullfile(pNameSave,sprintf('%s_gaze.c3d',filenames{l}(1:end-4)))) ; % write it to a new file
        % immer wieder den "Handle" löschen, damit der Speicher freigegeben
        % werden kann
        btkDeleteAcquisition(h);
        
    end
end

% myExportFile = fullfile(actualDir,'Messergebnisse.xlsx');
% xlswrite(myExportFile,result);