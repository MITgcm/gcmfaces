function [nc] = ncopen(theNetCDFFile, varargin);
% open a netcdf file.
%   mode: 'write','nowrite'

gcmfaces_global; if myenv.usingOctave; import_netcdf; end;

mode=0;
if nargin>1,
    mode=varargin{1};
end

if myenv.useNativeMatlabNetcdf;
    nc=netcdf.open(theNetCDFFile,mode);
else;%try to use old mex stuff
    if mode==0,
        nc=netcdf(theNetCDFFile);
    else
        nc=netcdf(theNetCDFFile,mode);
    end        
end;



