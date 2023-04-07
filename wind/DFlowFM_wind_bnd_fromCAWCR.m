%%% Written by Camille Grimaldi, April 2023
% This MATLAB Script writes .wnd file from CAWCR (https://data.csiro.au/collection/csiro:39819) output for Delf3D Felxible
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

% permute wind output so that the time column is in position 1
uwnd=permute(uwnd,[3,2,1]);
vwnd=permute(vwnd,[3,2,1]);

% resize cawcr to match our model start and end dates
uwind=uwnd(t1:t2,:,:);
vwind=vwnd(t1:t2,:,:);


%% 3. Write meteo files for D3DFM
% delft3d_io_meteo_write.m is in Open Earth Toolbox

[X,Y]=meshgrid(lon,lat);
[x,y] = convertCoordinates(X,Y,'CS1.code',4326,'CS2.code',32750);

tim=tnum(t1:t2);
datemeteo=datenum(model_startdate); % model reference date

% write .wnd files
Dx = delft3d_io_meteo_write('xwnd_feb99.wnd', tim, x, y, uwind, 'filetype', 'meteo_on_equidistant_grid', 'quantity', 'x_wind', 'newgrid', 1, 'refdatenum', datemeteo,'grid_unit', 'm');
Dy = delft3d_io_meteo_write('ywnd_feb99.wnd', tim, x, y, vwind, 'filetype', 'meteo_on_equidistant_grid', 'quantity', 'y_wind', 'newgrid', 1, 'refdatenum', datemeteo,'grid_unit', 'm');
