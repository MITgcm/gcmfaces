function [] = ncsave(theNetCDFFile, varargin);

global useNativeMatlabNetcdf; if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;

if useNativeMatlabNetcdf;
    nc=netcdf.open(theNetCDFFile,'write');
else;%try to use old mex stuff
    nc=netcdf(theNetCDFFile,'write');
end;

for ii=1:nargin-1;
    nameCur=inputname(ii+1);
    if useNativeMatlabNetcdf;
        vv = netcdf.inqVarID(nc,nameCur); netcdf.putVar(nc,vv,varargin{ii}');
    else;%try to use old mex stuff
        nc{nameCur}(:)=varargin{ii};
    end;
end;


if useNativeMatlabNetcdf;
    netcdf.close(nc);
else;%try to use old mex stuff
    close(nc);
end;



