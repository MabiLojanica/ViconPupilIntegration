function [head eye gaze gazePoint in] = calculateGazePositionDistance(fLeft,fRight,fTop,headRotAdj,levert,lehori,screenCoord,gazeLength,rightEyeTrue)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % HOLY GRAIL (:_:)  : GAZE VECTOR CALCULATION
        % calc head_Pos _Rot (OK == Vicon)
        headOrigin = ((fLeft - fRight) ./ 2) + fRight;
        headZDir = fLeft - headOrigin;
        temp =  fTop - headOrigin;
        headXDir = cross(temp,headZDir);
        headYDir = cross(headZDir,headXDir);

        [head.R head.t] = createLocalReferenceFrame(headOrigin, headXDir, headYDir, headZDir);        
        clear  temp headXDir headYDir headZDir;
        headRaw = head.R;

        lenData = length(levert);
        
        % add initial rotation adjustment
        for mn = 1:lenData
            head.R(mn,:,:) = headRotAdj * squeeze(head.R(mn,:,:));
        end


        %calculate eye vecs (atan calc already done)
%         levert = eyerot(:,1);
%         lehori = eyerot(:,2);
        eyeDist = 65;
%         gazeLength = 100;
        if rightEyeTrue
            leftEyePosRaw =  [0            ;-(eyeDist/2); 0];
            leftEyeGazeRaw = [gazeLength   ;-(eyeDist/2); 0];
            
        else
            leftEyePosRaw =  [0            ;(eyeDist/2); 0];
            leftEyeGazeRaw = [gazeLength   ;(eyeDist/2); 0];
        end
        leftEyeGazeLocal = leftEyeGazeRaw - leftEyePosRaw;
        
        mn = 1;
        
        for mn = 1:lenData
            rotmat = rotation_matrix(lehori(mn),[0 0 1]);
            rotmat = rotmat * rotation_matrix(levert(mn),[0 1 0]);
            leftEyeGaze = ((leftEyeGazeRaw-leftEyePosRaw)' * rotmat)';

            %shift to head local coordinate system
            leftEyeGaze = leftEyeGaze+leftEyePosRaw;

            %rotate head
            leftEyeGaze = (leftEyeGaze' * squeeze(head.R(mn,:,:)))';
            leftEyePos =  (leftEyePosRaw' * squeeze(head.R(mn,:,:)))';

            %add global translation
            leftEyePos = leftEyePos + head.t(mn,:)';
            leftEyeGaze = leftEyeGaze + head.t(mn,:)';
            gaze(mn,:) = leftEyeGaze;
            eye(mn,:) = leftEyePos;
            leftGazeCoord = [leftEyePos leftEyeGaze]';
            [in(mn),gazePoint(mn,:)] = checkInScreen (screenCoord, leftGazeCoord);        
        end
end
        