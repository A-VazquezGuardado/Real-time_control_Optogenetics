% This code generates the mice's body elongation and compression between head and back, 
% and the bending curvature between head, neck and back from data generated from 
% DeepLab Cut by Mingzheng Wu 

% Author: Yiyuan Yang    
% September 9th 2019

clear all
load micebody_deeplabcut % Load data file from DeepLab Cut, the data is also provided in the package

% Data sort by body length
Bodylength = abs(Head{:,1}-Back{:,1}); % calculat the x coordinates distance between head and back
Avg_bodylength = mean(Bodylength); % average x distance
Max_bodylength = max(Bodylength); % max x distance
A = linspace(1,90034,90034); % Generates sorting vector
A = A'; % reverse matrix
Bodylength_sort = [Bodylength, A]; % Assign sorting number for x coordinates distance between head and back
Bodylength_sort = sortrows(Bodylength_sort); % sort x coordinate distance in ascending order
Bodylength_final = Bodylength_sort(fix(90034*0.9):90034,:); % Pick the top 10% largest x coordinate distance as estimate frames 
% where animal’s major axis oriented perpendicular to the camera. Data selection based on experimental observation. 

% Data selected

Head_calculate = Head(Bodylength_final(:,2),:); % Select respective head coordinates
Neck_calculate = Neck(Bodylength_final(:,2),:); % Select respective neck coordinates
Back_calculate = Back(Bodylength_final(:,2),:); % Select respective back coordinates

% Distance calculation

Head_Coordinates = table2array(Head_calculate); % Data Conversion
Neck_Coordinates = table2array(Neck_calculate); % Data Conversion
Back_Coordinates = table2array(Back_calculate); % Data Conversion

% Distance between head neck and back

for i=1:1:9005
    Head_Neck(i) = norm(Head_Coordinates(i,:)-Neck_Coordinates(i,:));
    Neck_Back(i) = norm(Neck_Coordinates(i,:)-Back_Coordinates(i,:));
    Head_Back(i) = norm(Head_Coordinates(i,:)-Back_Coordinates(i,:));
end

% Body Elongation & Compression calculation

Body_calculation = Head_Neck+Neck_Back;
Body_strain = (Body_calculation - mean(Body_calculation))./median(Body_calculation); % Body Elongation & Compression
Body_select = Body_strain(find(Body_strain <0.6));% Eliminate outlier data

% Curvature calculation from geometrical theoreom

 s = (Head_Neck+Neck_Back+Head_Back)/2;
 A = sqrt(s.*(s-Head_Neck).*(s-Neck_Back).*(s-Head_Back)); % Area of triangle P1P2P3
 R = Head_Neck.*Neck_Back.*Head_Back./(4.*A); % Radius of curvature at P2
 R_select =R(find(R <1000)); % Eliminate outlier data
 R_select_radius = R_select*0.03048; % Convert unit to cm
  