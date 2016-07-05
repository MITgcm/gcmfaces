function [fld]=example_bin_average();
% EXAMPLE_BIN_AVERAGE generates a sample of random
%    numbers distributed over the globe and 
%    bin averages to the default grid.
 
%%%%%%%%%%%%%%%%%
%load grid:
%%%%%%%%%%%%%%%%%

gcmfaces_global;

if isempty(mygrid);
  grid_load;
end;

if myenv.verbose>0;
    gcmfaces_msg('===============================================');
    gcmfaces_msg(['*** entering example_bin_average: generate ' ... 
        'randomly distributed data samples (position and value), ' ... 
        'and bin average this data set to a gcmfaces grid'],'');
end;

warning('off','MATLAB:dsearch:DeprecatedFunction');
warning('off','MATLAB:delaunay:DuplicateDataPoints');

%%%%%%%%%%%%%%%%%%%%%%%
%generate random data

if myenv.verbose>0;
    gcmfaces_msg('* generate random data');
end;
nn=1e6;
lat=(rand(nn,1)-0.5)*2*90;
lon=(rand(nn,1)-0.5)*2*180; 
%needed for 0-360 longitude convention
if mygrid.nFaces==1;
    xx=find(lon<0);lon(xx)=lon(xx)+360;
end;
sample=(rand(nn,1)-0.5)*2;

%%%%%%%%%%%%%%%%%%%%%%%
%generate delaunay triangulation

if myenv.verbose>0;
    gcmfaces_msg('* call gcmfaces_bindata : generate delaunay triangulation');
end;
gcmfaces_bindata;

%%%%%%%%%%%%%%%%%%%%%%%%
%bin average random data

if myenv.verbose>0;
    gcmfaces_msg('* call gcmfaces_bindata : bin average data');
end;
fld=gcmfaces_bindata(lon,lat,sample);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%quick display
if myenv.verbose>0;
    gcmfaces_msg('* display results on sphere');
end;
figureL; set(gca,'FontSize',16);
gcmfaces_sphere(fld); axis xy; caxis([-1 1]*0.4); colorbar;
title('bin averaged random data');

if myenv.verbose>0;
    gcmfaces_msg('*** leaving example_bin_average');
    gcmfaces_msg('===============================================');
end;




