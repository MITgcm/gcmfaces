function [nc] = nccreate(theNetCDFFile, varargin);
% create a new netcdf file.
%   mode: 'write','nowrite'

global useNativeMatlabNetcdf; 
if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;

mode='NC_NOCLOBBER';
if nargin>1,
    mode=varargin{1};
end

if useNativeMatlabNetcdf;
    nc=netcdf.create(theNetCDFFile,mode);
else;%try to use old mex stuff
    nc=netcdf(theNetCDFFile,mode);
end;



