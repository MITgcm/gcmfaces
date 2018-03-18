function [] = ncclose(ncid);
% close a netcdf file.

gcmfaces_global; if myenv.usingOctave; import_netcdf; end;

if myenv.useNativeMatlabNetcdf;
    netcdf.close(ncid);
else;%try to use old mex stuff
    close(ncid);
end;



