function []=interp2nctiles(dirDiags,listDo,iterateOverFiles,latlon1D);
% INTERP2CNTILES(dirDiags,listDo); 
%   creates netcdf files from interpolated 
%   fields that were created by process2interp. The 
%   input vector process2interp specifies the file subset
%   to be processed (1:length(listInterp) by default).
%   iterateOverFiles (optional)- set to 1 if files should be processed one
%       time step at a time
%
% note: this routine overrides mygrid with mygrid_latlon 
%   after storing the reference grid in mygrid_orig

gcmfaces_global; global mygrid_orig;

if isempty(mygrid_orig); mygrid_orig=mygrid; end;
if isempty(whos('iterateOverFiles')); iterateOverFiles=1; end;
if isempty(whos('latlon1D')); latlon1D=0; end;

lon=[-179.75:0.5:179.75]; lat=[-89.75:0.5:89.75];
[lat,lon] = meshgrid(lat,lon);
iosize = size(lon);
tileSize = [];

mygrid_latlon.nFaces=1;
mygrid_latlon.dirGrid='none';
mygrid_latlon.fileFormat='straight';
mygrid_latlon.ioSize=iosize;
mygrid_latlon.XC=gcmfaces({lon});
mygrid_latlon.XC_1D=lon(:,1);
mygrid_latlon.YC=gcmfaces({lat});
mygrid_latlon.YC_1D=lat(1,:);
mygrid_latlon.RC=mygrid.RC;
mygrid_latlon.RF=mygrid.RF;
%mygrid_latlon.DRC=mygrid.DRC;
%mygrid_latlon.DRF=mygrid.DRF;
%mygrid_latlon.mskC=1+0*repmat(mygrid_latlon.XC,[1 1  length(mygrid.RC)]);
mygrid_latlon.gcm2facesFast=0;
mygrid_latlon.facesExpand=[];
mygrid_latlon.latlon1D = latlon1D;

mygrid=mygrid_latlon;
for ii=1:length(listDo);
tic; process2nctiles(dirDiags,listDo{ii},listDo{ii},tileSize,iterateOverFiles);
fprintf(['DONE: ' listDo{ii} ' (in ' num2str(toc) 's)\n']);
end;
mygrid=mygrid_orig;

