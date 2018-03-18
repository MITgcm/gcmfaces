function ncdefDim(ncid,dimname,dimlen);
% add a dimension in a netcdf file.

gcmfaces_global; if myenv.usingOctave; import_netcdf; end;

if myenv.useNativeMatlabNetcdf;
    netcdf.defDim(ncid,dimname,dimlen);
else;%try to use old mex stuff
    eval(sprintf('ncid(''%s'')=%d;',dimname,dimlen));
end;



