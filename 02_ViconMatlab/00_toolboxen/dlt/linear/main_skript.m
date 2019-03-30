clear all;
close all;


% Referenzrahmen Punkte Bezeichnungen und Koordinaten
hArray = { %name  %x    %y    %z
          'A' ,    0,    0,    0 ;...
          'AB',  500,    0,    0 ;...
          'B' , 1000,    0,    0 ;...
          'BC', 1500,    0,    0 ;...
          'C' , 2000,    0,    0 ;...
          'CD', 2000,  500,    0 ;...
          'D' , 2000, 1000,    0 ;...
          'DE', 1500, 1000,    0 ;...
          'E' , 1000, 1000,    0 ;...
          'EF',  500, 1000,    0 ;...
          'F' ,    0, 1000,    0 ;...
          'BE', 1000,  500,    0 ;...
          'AF',    0,  500,    0 ;...

          'G' ,    0,    0,  500 ;...
          'H' , 1000,    0,  500 ;...
          'I' , 2000,    0,  500 ;...
          'J' , 2000, 1000,  500 ;...
          'K' , 1000, 1000,  500 ;...
          'L' ,    0, 1000,  500 ;...

          'M' ,    0,    0, 1000 ;...
          'MN',  500,    0, 1000 ;...
          'N' , 1000,    0, 1000 ;...
          'NO', 1500,    0, 1000 ;...
          'O' , 2000,    0, 1000 ;...
          'OP', 2000,  500, 1000 ;...
          'P' , 2000, 1000, 1000 ;...
          'PQ', 1500, 1000, 1000 ;...
          'Q' , 1000, 1000, 1000 ;...
          'QR',  500, 1000, 1000 ;...
          'R' ,    0, 1000, 1000 ;...
          'RS', 1000,  500, 1000 ;...
          'S' ,    0,  500, 1000 ;...

          'T' ,    0,    0, 1500 ;...
          'U' , 1000,    0, 1500 ;...
          'V' , 2000,    0, 1500 ;...
          'W' , 2000, 1000, 1500 ;...
          'X' , 1000, 1000, 1500 ;...
          'Y' ,    0, 1000, 1500 ;...
          %Z not used
          'AA'  ,    0,    0, 2000 ;...
          'AABB',  500,    0, 2000 ;...
          'BB'  , 1000,    0, 2000 ;...
          'BBCC', 1500,    0, 2000 ;...
          'CC'  , 2000,    0, 2000 ;...
          'CCDD', 2000,  500, 2000 ;...
          'DD'  , 2000, 1000, 2000 ;...
          'DDEE', 1500, 1000, 2000 ;...
          'EE'  , 1000, 1000, 2000 ;...
          'EEFF',  500, 1000, 2000 ;...
          'FF'  ,    0, 1000, 2000 ;...
          'BBEE', 1000,  500, 2000 ;...
          'AAFF',    0,  500, 2000 ;...
          };

% erzeuge homogene Koordinaten
for i = 1:51    
    worldCoord(i,:) = [hArray{i,2:4}];
end
 worldCoord(:,end+1) = 1;

 worldCoord = worldCoord';


load('imgCoordCam1new')          
imgCoordCam1 = imgCoordArray';
imgCoordCam1(end+1,:) = 1;
load('imgCoordCam2new')          
imgCoordCam2 = imgCoordArray';
imgCoordCam2(end+1,:) = 1;
load('imgCoordCam3new')          
imgCoordCam3 = imgCoordArray';
imgCoordCam3(end+1,:) = 1;
load('imgCoordCam4new')          
imgCoordCam4 = imgCoordArray';
imgCoordCam4(end+1,:) = 1;

clear i hArray imgCoordArray;

%calculate projection matrices
P{1} = CalibNormDLT(imgCoordCam1(:,1:2:end), worldCoord(:,1:2:end));
P{2} = CalibNormDLT(imgCoordCam2(:,1:2:end), worldCoord(:,1:2:end));
P{3} = CalibNormDLT(imgCoordCam3(:,1:2:end), worldCoord(:,1:2:end));
P{4} = CalibNormDLT(imgCoordCam4(:,1:2:end), worldCoord(:,1:2:end));


figure(1); grid on; axis equal; hold on; 

% erzeuge Kameraparameter aus den Projektionsmatrizen
for i = 1:4
[C(i,:),T(i,:),R(i,:,:),K(i,:,:)] = decompose_p( P{i} );
end
%draw camera centers
scatter3(C(:,1),C(:,2),C(:,3));
% plot viewing axes
for i=1:4
  axis_dir = R(i,3,:); % 3rd row of i-th rotation matrix
  axis_len = 0.4*norm(C(i,:));  
  endpoint = C(i,:)+axis_len*squeeze(axis_dir)';
  line([C(i,1),endpoint(1)],[C(i,2),endpoint(2)],[C(i,3),endpoint(3)]);
  text(C(i,1),C(i,2),C(i,3),sprintf('%4d',i),'Color','k');
end
clear axis_dir axis_len endpoint;



%show theoretical worldCoords
scatter3(worldCoord(1,:),worldCoord(2,:),worldCoord(3,:),'ok');

%linear reconstruct Image Coordinates
X = uP2Xdlt(P,{imgCoordCam1, imgCoordCam2,imgCoordCam3,imgCoordCam4})
%and draw them
scatter3(X(1,:),X(2,:),X(3,:),'r+');

view(45,20);
axis([-3000 5000 -2000 4000 0 3000]);
%axis equal;
title('Camera Positions and Calibration Cube calc. with DLT');
hold off;

% do error calculation
% calculate Root Mean Square Error
rmserr = 0;
loopcnt = 0;
for i = 1:2:51
distance(i)  = norm(worldCoord(:,i)-X(:,i));
rmserr = rmserr + distance(i);
loopcnt = loopcnt +1;
end
rmserr = rmserr/loopcnt;

rmserrnocal = 0;
loopcnt = 0;
for i = 2:2:51
distance(i)  = norm(worldCoord(:,i)-X(:,i));
rmserrnocal = rmserrnocal + distance(i);
loopcnt = loopcnt +1;
end
rmserrnocal = rmserrnocal/loopcnt;








