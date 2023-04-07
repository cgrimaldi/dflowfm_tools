%%% Written by Camille Grimaldi, April 2023
% This MATLAB Script writes .bc file from TPXO output for Delf3D Felxible
% Mesh boundary conditions

clear all;clc
addpath(genpath('..\OpenEarthToolbox'));

%% 1. Import lon lat from the boundary polygon 

f = fopen ('DFM_bnd.pol');
C = textscan(f,'%n %n %s','Delimiter',',','HeaderLines', 8)
fclose(f); 
lon =C{1, 1};  
lat =C{1, 2};

% convert from UTM to DEG
[LON,LAT] = convertCoordinates(lon,lat,'CS1.code',32750,'CS2.code',4326);

%% 2. Get harmonics from TPXO global tidal model
addpath(genpath('...\TPXO9'));

Model='Model_tpxo9';type='z'

[amp,Gph,D,conList]=tmd_extract_HC(Model,LAT,LON,type);


%% 3. Write .bc file

path=['yourpath'] % Change to your path

conList = {'M2', 'S2', 'N2', 'K2', 'K1','O1','P1','Q1','MM','MF','M4','MN4','MS4 ','2N2 ','S1'}'; % Pick the consitituents

fileID = fopen([path,'\WaterLevel.bc'],'w');

for c=1:length(LAT)
    
    curbnd=char(strcat('pt_',num2str(c)));
   

if c>=10;

    A={
    '[forcing]'
    ['Name                            = L000001_00',num2str(c)]
    'Function                        = astronomic'
    'Quantity                        = astronomic component'
    'Unit                            = - '
    'Quantity                        = waterlevelbnd amplitude'
    'Unit                            = m'
    'Quantity                        = waterlevelbnd phase'
    'Unit                            = deg'}
else

    A={
    '[forcing]'
    ['Name                            = L000001_000',num2str(c)]
    'Function                        = astronomic'
    'Quantity                        = astronomic component'
    'Unit                            = - '
    'Quantity                        = waterlevelbnd amplitude'
    'Unit                            = m'
    'Quantity                        = waterlevelbnd phase'
    'Unit                            = deg'}    

end 
    B={
    ['A0	'  ,'	0','	0']
    ['M2	',num2str(amp(1,c)),'	',num2str(Gph(1,c))]
    ['S2	',num2str(amp(2,c)),'	',num2str(Gph(2,c))]
    ['N2	',num2str(amp(3,c)),'	',num2str(Gph(3,c))]
    ['K2	',num2str(amp(4,c)),'	',num2str(Gph(4,c))]
    ['K1	',num2str(amp(5,c)),'	',num2str(Gph(5,c))]
    ['O1	',num2str(amp(6,c)),'	',num2str(Gph(6,c))]
    ['P1	',num2str(amp(7,c)),'	',num2str(Gph(7,c))]
    ['Q1	',num2str(amp(8,c)),'	',num2str(Gph(8,c))]
    ['MM	',num2str(amp(9,c)),'	',num2str(Gph(9,c))]
    ['MF	',num2str(amp(10,c)),'	',num2str(Gph(10,c))]
    ['M4	',num2str(amp(11,c)),'	',num2str(Gph(11,c))]
    ['MN4	',num2str(amp(12,c)),'	',num2str(Gph(12,c))]
    ['MS4	',num2str(amp(13,c)),'	',num2str(Gph(13,c))]
    ['2N2	',num2str(amp(14,c)),'	',num2str(Gph(14,c))]
    ['S1	',num2str(amp(15,c)),'	',num2str(Gph(15,c))]}

    fprintf(fileID,'%s\n',A{:});
    fprintf(fileID,'%s\n',B{:});
end
    fclose(fileID);
    
    
 % NOTE: To import in GUI, open the .pli file and add a frt time as
 % astronomical to import the .bc file !!