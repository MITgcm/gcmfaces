function ncdefDim(ncid,dimname,dimlen);
% add a dimension in a netcdf file.

global useNativeMatlabNetcdf; 
if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;

if useNativeMatlabNetcdf;
    netcdf.defDim(ncid,dimname,dimlen);
else;%try to use old mex stuff
    eval(sprintf('ncid(''%s'')=%d;',dimname,dimlen));
end;



