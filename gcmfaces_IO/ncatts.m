function [atts]=ncatts(ncid,varid);
%input:     ncid is a netcdf file id
%           varid is a netcdf variable id
%output:    atts is the list of its attributes name (in cell)

[varname,xtype,dimids,natts] = netcdf.inqVar(ncid,varid);

for ii=1:natts;
    aa=netcdf.inqAttName(ncid,varid,ii-1);
    if ii==1; atts={aa}; else; atts=[atts aa]; end;
end;

if natts==0; atts=[]; end;
