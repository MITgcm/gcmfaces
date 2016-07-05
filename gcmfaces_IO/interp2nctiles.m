function []=interp2nctiles(indFiles);
% INTERP2CNTILES creates netcdf files from interpolated 
%   fields that were created by process2interp. The 
%   input vector process2interp specifies the file subset
%   to be processed (1:length(listInterp) by default).
%
% note: this routine overrides mygrid with mygrid_latlon 
%   after storing the reference grid in mygrid_orig

gcmfaces_global; global mygrid_orig;

dirModel='./';
if isempty(mygrid_orig);
grid_load; mygrid_orig=mygrid;
cd(dirModel);
end;

lon=[-179.75:0.5:179.75]; lat=[-89.75:0.5:89.75];
[lat,lon] = meshgrid(lat,lon);

mygrid_latlon.nFaces=1;
mygrid_latlon.dirGrid='none';
mygrid_latlon.fileFormat='straight';
mygrid_latlon.ioSize=size(lon);
mygrid_latlon.XC=gcmfaces({lon});
mygrid_latlon.YC=gcmfaces({lat});
mygrid_latlon.RC=mygrid.RC;
mygrid_latlon.RF=mygrid.RF;
mygrid_latlon.DRC=mygrid.DRC;
mygrid_latlon.DRF=mygrid.DRF;
mygrid_latlon.mskC=1+0*repmat(mygrid_latlon.XC,[1 1  length(mygrid.RC)]);
mygrid_latlon.RAC=[];
mygrid_latlon.gcm2facesFast=0;
mygrid_latlon.facesExpand=[];

[listInterp,listNot]=process2interp;
if isempty(who('indFiles')); 
  indFiles=[1:length(listInterp)];
end;

mygrid=mygrid_latlon;
for ii=indFiles;
tic; process2nctiles(dirModel,listInterp{ii},[]);
fprintf(['DONE: ' listInterp{ii} ' (in ' num2str(toc) 's)\n']);
end;
mygrid=mygrid_orig;

