function [nc] = ncputAtt(ncid,varname,attrname,attrvalue);
% add an attribute to a variable in a netcdf file.

global useNativeMatlabNetcdf; 
if isempty(useNativeMatlabNetcdf); useNativeMatlabNetcdf = ~isempty(which('netcdf.open')); end;

if isempty(varname),
    if useNativeMatlabNetcdf;
        netcdf.putAtt(ncid,-1,attrname,attrvalue);
    else;%try to use old mex stuff
        if ischar(attrvalue)
            attrvalue(find(double(attrvalue)==10))=[];
            eval(['ncid.' attrname '=''' attrvalue ''';']);
        else
            eval(['ncid.' attrname '=' num2str(attrvalue) ';']);
        end
    end;
else
    if useNativeMatlabNetcdf;
        varid=netcdf.inqVarID(ncid,varname);
        netcdf.putAtt(ncid,varid,attrname,attrvalue);
    else;%try to use old mex stuff
        if strcmp(attrname,'_FillValue'),
            attrname='FillValue_';
        end
        if ischar(attrvalue)
            attrvalue(find(double(attrvalue)==10))=[];
            eval(['ncid{''' varname '''}.' attrname '=''' attrvalue ''';']);
        else
            eval(['ncid{''' varname '''}.' attrname '=' num2str(attrvalue) ';']);
        end
    end;
end
    


