function []=gcmfaces_lines_zonal(varargin);
%object:    define the set of quasi longitudinal lines
%           along which transports will integrated;
%           LATS_MASKS that will be added to mygrid.
%           LONS_MASKS that will be added to mygrid.
%optional input:
%           LATS_VAL is the latitudes vector ([-89:89]' by default)
%           LONS_VAL is the latitudes vector ([-179.5:179.5]' by default)

global mygrid;

if nargin>0; LATS_VAL=varargin{1}; else; LATS_VAL=[-89:89]'; end;
if nargin>1; LONS_VAL=varargin{2}; else; LONS_VAL=[-179.5:179.5]'; end;

if iscell(LONS_VAL);
    warning('gcmfaces_lines_zonal now takes LONS_VAL as 2nd argument');
    LONS_VAL=[-179.5:179.5]';
end;

MSKS_NAM={'mskCint','mskCedge','mskWedge','mskSedge'};    

for iy=1:length(LATS_VAL);

    mskCint=1*(mygrid.YC>=LATS_VAL(iy));
    [mskCedge,mskWedge,mskSedge]=gcmfaces_edge_mask(mskCint);

    for im=1:length(MSKS_NAM);
      eval(['tmp1.' MSKS_NAM{im} '=' MSKS_NAM{im} ';']);
    end;
    tmp1.lat=LATS_VAL(iy);

    %store:
    if iy==1;
        LATS_MASKS=tmp1;
    else;
        LATS_MASKS(iy)=tmp1;
    end;
    
end;

for iy=1:length(LONS_VAL);

    mskCint=1*(sin(deg2rad(mygrid.XC-LONS_VAL(iy)))>=0);
    [mskCedge,mskWedge,mskSedge]=gcmfaces_edge_mask(mskCint);
    tmp1=1*(cos(deg2rad(mygrid.XC-LONS_VAL(iy)))>0);
    mskCedge=mskCedge.*tmp1;
    tmp1=1*(cos(deg2rad(mygrid.XG-LONS_VAL(iy)))>0);
    mskWedge=mskWedge.*tmp1;
    tmp1=1*(cos(deg2rad(mygrid.XC-LONS_VAL(iy)))>0);
    mskSedge=mskSedge.*tmp1;

    clear tmp1;
    for im=1:length(MSKS_NAM);
      eval(['tmp1.' MSKS_NAM{im} '=' MSKS_NAM{im} ';']);
    end;
    tmp1.lon=LONS_VAL(iy);

    %store:
    if iy==1;
        LONS_MASKS=tmp1;
    else;
        LONS_MASKS(iy)=tmp1;
    end;
    
end;

mygrid.LATS_MASKS=LATS_MASKS;
mygrid.LONS_MASKS=LONS_MASKS;
mygrid.LATS=[mygrid.LATS_MASKS.lat]';
mygrid.LONS=[mygrid.LONS_MASKS.lon]';

