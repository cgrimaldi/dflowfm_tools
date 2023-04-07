%%% Written by Camille Grimaldi, April 2023
% This MATLAB Script writes .bcw file from CAWCR (https://data.csiro.au/collection/csiro:39819) bndput for Delf3D Felxible
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

%% 2. Load data from CAWCR (see CAWCR download)
load ..\ww3_aus_4m_199902.mat
t=datetime(time,'convertfrom','datenum');
t = dateshift(t,'start','hour','nearest');
tnum=datenum(t);

% define bnd start and end
model_startdate=datenum(1999,02,01,0,0,0);
model_enddate=model_startdate+datenum(days(28));

% find the corresponding dates in the CAWCR dataset
t1=find(tnum==model_startdate);
t2=find(tnum==model_enddate);
t=datetime(time,'convertfrom','datenum')';

%% 3. Extract cawcr values for each bnd point

for c=1:length(LAT)

    curbnd=char(strcat('pt_',num2str(c)));

    % the .bcw takes a time vector that is defined as the number of minutes
    % since the reference date "minut"
    for j=t1(i):t2(i)
       minut(j-t1(i)+1)=((time(j)-datenum(model_startdate(i)))*86400)/60;
    end 


    % Find the closest LAT to our bnd lat points, same for lon
    for n=1:length(hs)
        dist    = abs(lat - LAT(c));
        minDist = min(dist);
        J     = find(dist == minDist);
    
        dist    = abs(lon - LON(c));
        minDist = min(dist);
        K     = find(dist == minDist);

        % Transform into timeseries
        newval_hs.(curbnd)(n)=hs(K,J,n);newval_fp.(curbnd)(n)=1./fp(K,J,n);
        newval_dir.(curbnd)(n)=dir(K,J,n);newval_spr.(curbnd)(n)=spr(K,J,n);
    
    end

newval_hs.(curbnd)=newval_hs.(curbnd)(t1:t2);
newval_fp.(curbnd)=newval_fp.(curbnd)(t1:t2);
newval_dir.(curbnd)=newval_dir.(curbnd)(t1:t2);
newval_spr.(curbnd)=newval_spr.(curbnd)(t1:t2);

end

%% 4. Here we are writting four bnd conditions: North, East, West, South (bnd structure)
% Defining which points in DFM_bnd.pol match with each boundary orientation 

    % write sbndh bnd (pt 1 to 3 in DFM_bnd.pol); adjust to your bnd file
    bnd.south =[minut',newval_hs.pt_1',newval_hs.pt_2',newval_hs.pt_3',...
    newval_fp.pt_1',newval_fp.pt_2',newval_fp.pt_3',...
    newval_dir.pt_1',newval_dir.pt_2',newval_dir.pt_3',...
    newval_spr.pt_1',newval_spr.pt_2',newval_spr.pt_3'];

    % write east bnd (pt 3 to 5 in DFM_bnd.pol); adjust to your bnd file
    bnd.east =[minut',newval_hs.pt_3',newval_hs.pt_4',newval_hs.pt_5',...
    newval_fp.pt_3',newval_fp.pt_4',newval_fp.pt_5',...
    newval_dir.pt_3',newval_dir.pt_4',newval_dir.pt_5',...
    newval_spr.pt_3',newval_spr.pt_4',newval_spr.pt_5'];

    % write north bnd (pt 5 to 7 in DFM_bnd.pol); adjust to your bnd file
    bnd.north =[minut',newval_hs.pt_5',newval_hs.pt_6',newval_hs.pt_7',...
    newval_fp.pt_5',newval_fp.pt_6',newval_fp.pt_7',...
    newval_dir.pt_5',newval_dir.pt_6',newval_dir.pt_7',...
    newval_spr.pt_5',newval_spr.pt_6',newval_spr.pt_7'];

    % write west bnd (pt 7 to 9 in DFM_bnd.pol); adjust to your bnd file
    bnd.west =[minut',newval_hs.pt_7',newval_hs.pt_8',newval_hs.pt_9',...
    newval_fp.pt_7',newval_fp.pt_8',newval_fp.pt_9',...
    newval_dir.pt_7',newval_dir.pt_8',newval_dir.pt_9',...
    newval_spr.pt_7',newval_spr.pt_8',newval_spr.pt_9'];



%% 5. Write to .bcw file
formatbnd = 'yyyymmdd';
path=['yourpath']


% read standard .bcw file
fid = fopen('Waves_std.bcw','r'); % empty bnd file to fill in
MyText = textscan(fid,'%s','delimiter','\n');
fclose(fid);
MyText=MyText{:};
MyText{3}=char(['reference-time       ' datestr(model_startdate,formatbnd)])
MyText{22}=char(['reference-time       ' datestr(model_startdate,formatbnd)])
MyText{41}=char(['reference-time       ' datestr(model_startdate,formatbnd)])
MyText{60}=char(['reference-time       ' datestr(model_startdate,formatbnd)])


% Write .bcw file

fil=strcat([path,'Waves.bcw']) % file name path

% append north boundary
dlmwrite(fil,char(MyText{1:18,:}),'delimiter', '%s\n')
dlmwrite(fil, bnd.north, '-append','delimiter', '\t')

% append east boundary
dlmwrite(fil,char(MyText{20:37,:}),'-append','delimiter', '%s\n')
dlmwrite(fil, bnd.east, '-append','delimiter', '\t')

% append south boundary
dlmwrite(fil,char(MyText{39:56,:}),'-append','delimiter', '%s\n')
dlmwrite(fil, bnd.south, '-append','delimiter', '\t')

% append west boundary
dlmwrite(fil,char(MyText{58:75,:}),'-append','delimiter', '%s\n')
dlmwrite(fil, bnd.west, '-append','delimiter', '\t')
