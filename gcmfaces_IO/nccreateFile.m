function [nc] = nccreateFile(theNetCDFFile, varargin);
% create a new netcdf file.
%   mode: 'write','nowrite'

gcmfaces_global; if myenv.usingOctave; import_netcdf; end;

mode='NC_NOCLOBBER';
if nargin>1,
    mode=varargin{1};
end

if myenv.useNativeMatlabNetcdf;
    nc=netcdf.create(theNetCDFFile,mode);
else;%try to use old mex stuff
    nc=netcdf(theNetCDFFile,mode);
end;



