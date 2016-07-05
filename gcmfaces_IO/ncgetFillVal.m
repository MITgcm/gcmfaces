function [FillVal]=ncgetFillVal(ncid,varname);
% [FillVal]=ncgetFillVal(ncid,varname)
%           return the missing_value or _FillValue of varname
%  return an error if varname does not exist

global useNativeMatlabNetcdf; 
if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;

FillVal=[];
if useNativeMatlabNetcdf;
    varid = netcdf.inqVarID(ncid,varname);
    [varname,xtype,dimids,natts] = netcdf.inqVar(ncid,varid);
    [atts]=ncatts(ncid,varid);
    if any(ismember(atts,'missing_value'))
        FillVal = netcdf.getAtt(ncid,varid,'missing_value');
    elseif any(ismember(atts,'_FillValue'))
        FillVal = netcdf.getAtt(ncid,varid,'_FillValue');
    end
    if strcmp(xtype,'single') | strcmp(xtype,'double')
        FillVal=double(FillVal);
    end
else
    eval(['FillVal = ncid{''' varname '''}.missing_value(:);']);
    if isempty(FillVal);
        eval(['FillVal = ncid{''' varname '''}.FillValue_(:);']);
    end
end

