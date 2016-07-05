function [nc] = ncopen(theNetCDFFile, varargin);
% open a netcdf file.
%   mode: 'write','nowrite'

global useNativeMatlabNetcdf; 
if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;

mode=0;
if nargin>1,
    mode=varargin{1};
end

if useNativeMatlabNetcdf;
    nc=netcdf.open(theNetCDFFile,mode);
else;%try to use old mex stuff
    if mode==0,
        nc=netcdf(theNetCDFFile);
    else
        nc=netcdf(theNetCDFFile,mode);
    end        
end;



