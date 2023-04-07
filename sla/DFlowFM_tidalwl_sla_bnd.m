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

%% 2. Get harmonics from TPXO global tidal model

% define bnd start and end
model_startdate=datenum(1999,02,01,0,0,0);
model_enddate=model_startdate+datenum(days(28));
tt=datetime(model_startdate,'convertfrom','datenum'):minutes(10):datetime(model_enddate,'convertfrom','datenum');

% create water level time series
Model='Model_tpxo9';
for i=1:length(lat_bnd)
    curbnd=char(strcat('pt_',num2str(i)));
    [z.(curbnd),conList]=tmd_tide_pred(Model,datenum(tt),lat(i),lon(i),'z');
end

%% 3. Get sea level anomaly from HYCOM model
nc='...\data_1999.nc4'
time=ncread(nc,'time');time=(hours(time) + datetime('2000-01-01 00:00:00'));
eta=ncread(nc,'surf_el');eta=permute(eta,[2 1 3]);
lonh=ncread(nc,'lon');
lath=ncread(nc,'lat');

%% 3. Extract HYCOM values for each bnd point

% find the corresponding dates in the HYCOM dataset
tnum=datenum(time);
t1=find(tnum==model_startdate);
t2=find(tnum==model_enddate);
t=time(t1:t2)';

model_startd=datetime(model_startdate,'convertfrom','datenum');
formatOut = 'yyyy-mm-dd';
model_startd=datestr(model_startd,formatOut)

% Extract HYCOM values for each bnd point
for c=1:length(lat_bnd)

        % Find the closest LAT to our bnd lat points, same for lon
        curbnd=char(strcat('pt_',num2str(c)));
        dist    = abs(lath - lat(c));
        minDist = min(dist);
        K     = find(dist == minDist);
        dist    = abs(lonh - lon(c));
        minDist = min(dist);
        J     = find(dist == minDist);

    % Transform data into timeseries
    nn=1;
    for n=t1:t2
        newval_eta.(curbnd)(nn)=eta(K,J,n);
        nn=nn+1;
    end
end

%% 4. Interp HYCOM time to water level time series from TPXO

for c=1:length(lat_bnd)
    curbnd=char(strcat('pt_',num2str(c)));
    eta_hyc_int.(curbnd)=interp1(datenum(t),newval_eta.(curbnd)-mean(newval_eta.(curbnd)),datenum(tt),'nearest');
end 

%% 5. Combine the two time series to get the tidal water level incorporating the sea level anomalies
for c=1:length(lat_bnd) 

    curbnd=char(strcat('pt_',num2str(c)));
    tt_tpxo=timetable(tt',z.(curbnd));
    tt_hyc=timetable(tt',eta_hyc_int.(curbnd)');

    wl_f.(curbnd)=tt_tpxo.Var1+tt_hyc.Var1;
    plot(wl_f.(curbnd)); hold on
end 


%% 6. Write .bc file   
% the .bc takes a time vector that is defined as the number of minutes
% since the reference date "minut"

for i=1:length(tt_tpxo.Time)
   minut(i)=((datenum(tt_tpxo.Time(i))-datenum(tt_tpxo.Time(1)))*86400)/60;
end 

path=['yourpath']

fileID = fopen([path,'\tidal_wl_sla.bc'],'w');

for c=1:length(lat_bnd)
    
    curbnd=char(strcat('pt_',num2str(c)));
  if c>=10;

    A={
    '[forcing]'
    ['Name                            = L00001_00',num2str(c)]
    'Function                        = timeseries'
    'Time-interpolation      	     = linear'
    'Quantity                        = time'
    ['Unit                            = minutes since ',num2str(model_startd)]
    'Quantity                        = waterlevelbnd'
    'Unit                            = m'}
else

    A={
    '[forcing]'
    ['Name                            = L00001_00',num2str(c)]
    'Function                        = timeseries'
    'Time-interpolation      	     = linear'
    'Quantity                        = time'
    ['Unit                            = minutes since ',num2str(model_startd)]
    'Quantity                        = waterlevelbnd'
    'Unit                            = m'}    

  end
    
  B=[round((minut')),wl_f.(curbnd)];

  fprintf(fileID,'%s\n',A{:});
  bout = strrep(mat2str(B),';','\n');
  bout = strip(bout,'['); 
  bout = strip(bout,']'); 
  bout = strip(bout,' '); 
  fprintf(fileID,[bout '\n']); 
end
    fclose(fileID);
