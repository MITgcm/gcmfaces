function []=example_interp();
% EXAMPLE_INTERP illustrates interpolation capabilities
%   by going back and forth between gcmfaces grid and
%   longitude-latitude arrays

gcmfaces_global;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if myenv.verbose>0;
    gcmfaces_msg('===============================================');
    gcmfaces_msg(['*** entering example_interp: illustrate ' ...
        'interpolation capabilities to get in and out of gcmfaces'],'');
end;

%%%%%%%%%%%%%%%%%
%load grid and setup test case:
%%%%%%%%%%%%%%%%%

if isempty(mygrid);
   grid_load;
end;

%target locations:
lon=[-179.75:0.5:179.75]; lat=[-89.75:0.5:89.75];
[lat,lon] = meshgrid(lat,lon);

%original field:
m=mygrid.mskC(:,:,1);
fld=m.*mygrid.Depth;

%%%%%%%%%%%%%%%%%%%%%%%
%interpolate mygrid.Depth to lon-lat grid:

if myenv.verbose>0;
    gcmfaces_msg('* interpolate mygrid.Depth to lon-lat grid');
end;

fld_interp=gcmfaces_interp_2d(fld,lon,lat);

if 0;
%use sparse matrix method:
interp=gcmfaces_interp_coeffs(lon(:),lat(:));
%
tmp1=convert2vector(fld);
tmp0=1*~isnan(tmp1);
tmp1(isnan(tmp1))=0;
%
tmp0=interp.SPM*tmp0;
tmp1=interp.SPM*tmp1;
%
fld_SPM=reshape(tmp1./tmp0,size(lon));
end;

%%%%%%%%%%%%%%%%%%%%%%%
%interpolate back to mygrid.XC, mygrid.YC:

if myenv.verbose>0;
    gcmfaces_msg('* interpolate back to gcmfaces grid');
end;

fld_reinterp=gcmfaces_interp_2d(fld_interp,lon,lat,'linear');

%%%%%%%%%%%%%%%%%%%%%%%
%remap to gcmfaces grid using extrapolation:

if myenv.verbose>0;
    gcmfaces_msg('* remap to gcmfaces grid using extrapolation');
end;

fld_remap=gcmfaces_remap_2d(lon,lat,fld_interp,0,m);

%%%%%%%%%%%%%%%%%%%%%%%
%illustrate results:

figureL;
subplot(2,1,1); set(gca,'FontSize',14);
[X,Y,FLD]=convert2pcol(mygrid.XC,mygrid.YC,fld);
pcolor(X,Y,FLD); axis([-180 180 -90 90]); shading flat;
title('original field');
subplot(2,1,2); set(gca,'FontSize',14);
pcolor(lon,lat,fld_interp); axis([-180 180 -90 90]); shading flat;
title('interpolated field');

figureL;
subplot(2,1,1); set(gca,'FontSize',14);
[X,Y,FLD]=convert2pcol(mygrid.XC,mygrid.YC,fld_reinterp);
pcolor(X,Y,FLD); axis([-180 180 -90 90]); shading flat;
title('reinterpolated field');
subplot(2,1,2); set(gca,'FontSize',14);
[X,Y,FLD]=convert2pcol(mygrid.XC,mygrid.YC,fld_remap);
pcolor(X,Y,FLD); axis([-180 180 -90 90]); shading flat;
title('remapped field');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if myenv.verbose>0;
    gcmfaces_msg('*** leaving example_interp');
    gcmfaces_msg('===============================================');
end;


