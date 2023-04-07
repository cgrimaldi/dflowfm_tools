%%% Written by Camille Grimaldi, April 2023
% This MATLAB Script writes .bc file from BRAN output for Delf3D Felxible
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

%% 2. Load data from BRAN2020 (see BRAN2020 download)
load ..\uv_1994_10_11.mat
t=datetime(BRAN.t,'convertfrom','datenum');
t = dateshift(t,'start','hour','nearest');
tnum=datenum(t);

% define bnd start and end
model_startdate=datenum(1994,10,05,12,0,0);
model_enddate=model_startdate+datenum(days(55));

% find the corresponding dates in the BRAN dataset
t1=find(tnum==model_startdate);
t2=find(tnum==model_enddate);
t=datetime(BRAN.t,'convertfrom','datenum')';

model_startd=datetime(model_startdate,'convertfrom','datenum');
formatOut = 'yyyy-mm-dd';
model_startd=datestr(model_startd,formatOut)

% the .bc takes a time vector that is defined as the number of minutes
% since the reference date "minut"
for i=t1:t2
   minut(i-t1+1)=((tnum(i)-model_startdate)*86400)/60;
end 

%% 3. Extract cawcr values for each bnd point

for c=1:length(LAT) % read the last point of the pol as also the first!

        % Find the closest LAT to our bnd lat points, same for lon
        curbnd=char(strcat('pt_',num2str(c)));
        dist    = abs(lat - LAT(c));
        minDist = min(dist);
        K     = find(dist == minDist);
        dist    = abs(lon - LON(c));
        minDist = min(dist);
        J     = find(dist == minDist);

    % Transform data into timeseries
    nn=1;
    for n=t1:t2
        newval_u.(curbnd)(nn)=BRAN.u(K,J,n);newval_v.(curbnd)(nn)=BRAN.v(K,J,n);
        nn=nn+1;
    end
end


%% 4. Write to .bcw file
path=['yourpath']

fileID = fopen([path,'\uxuy.bc'],'w');

for c=1:length(LAT)
    
    curbnd=char(strcat('pt_',num2str(c)));
   

if c>=10;

    A={
    '[forcing]'
    ['Name                            = L000001_00',num2str(c)]
    'Function                        = timeseries'
    'Time-interpolation      	     = linear'
    'Quantity                        = time'
    ['Unit                            = minutes since ',num2str(model_startd)]
    'Vector     			         = uxuyadvectionvelocitybnd:ux,uy'
    'Quantity                        = ux'
    'Unit                            = -'
    'Quantity                        = uy'
    'Unit                            = -'}
else

    A={
    '[forcing]'
    ['Name                            = L000001_000',num2str(c)]
    'Function                        = timeseries'
    'Time-interpolation      	     = linear'
    'Quantity                        = time'
    ['Unit                            = minutes since ',num2str(model_startd)]
    'Vector     			         = uxuyadvectionvelocitybnd:ux,uy'
    'Quantity                        = ux'
    'Unit                            = -'
    'Quantity                        = uy'
    'Unit                            = -'}    

end 
    B=[(minut'),newval_u.(curbnd)',newval_v.(curbnd)'];
    fprintf(fileID,'%s\n',A{:});
    fprintf(fileID,strrep(mat2str(B),';',' \n '));
end
    fclose(fileID);
    