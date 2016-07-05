function [] = ncclose(ncid);
% close a netcdf file.

global useNativeMatlabNetcdf; 
if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;


if useNativeMatlabNetcdf;
    netcdf.close(ncid);
else;%try to use old mex stuff
    close(ncid);
end;



