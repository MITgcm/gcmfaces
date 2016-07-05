function [vars]=ncvars(ncid);
%input:     ncid is a netcdf file id
%output:    vars is the list of its variables name (in cell)

global useNativeMatlabNetcdf; if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;

if useNativeMatlabNetcdf;
    
    [numdims, numvars, numglobalatts, unlimdimID] = netcdf.inq(ncid);
    for ii=1:numvars;
        aa=netcdf.inqVar(ncid,ii-1);
        if ii==1; vars={aa}; else; vars=[vars aa]; end;
    end;
    
else;%try to use old mex stuff
    vars=ncnames(var(ncid));
end;
