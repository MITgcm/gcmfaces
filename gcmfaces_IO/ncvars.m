function [vars]=ncvars(ncid);
%input:     ncid is a netcdf file id
%output:    vars is the list of its variables name (in cell)

gcmfaces_global; if myenv.usingOctave; import_netcdf; end;

if myenv.useNativeMatlabNetcdf;
    
    [numdims, numvars, numglobalatts, unlimdimID] = netcdf.inq(ncid);
    for ii=1:numvars;
        aa=netcdf.inqVar(ncid,ii-1);
        if ii==1; vars={aa}; else; vars=[vars aa]; end;
    end;
    
else;%try to use old mex stuff
    vars=ncnames(var(ncid));
end;
