function [] = ncclose(ncid);
% close a netcdf file.

global useNativeMatlabNetcdf; 
if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf_open')); end;


if useNativeMatlabNetcdf;
    netcdf_close(ncid);
else;%try to use old mex stuff
    close(ncid);
end;



