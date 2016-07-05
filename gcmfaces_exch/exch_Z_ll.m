function [FLD]=exch_Z_ll(fld);
%[FLD]=exch_Z_llc(fld);
%adds vorticity points (to north and east of center points) for
%lat-lon grid

gcmfaces_global;

FLD=exch_T_N(fld,1);

FLD{1}=FLD{1}(2:end,2:end,:,:);

if mygrid.domainPeriodicity(1);
    FLD{1}(end,end,:,:)=FLD{1}(1,end,:,:);
elseif mygrid.domainPeriodicity(2);
    FLD{1}(end,end,:,:)=FLD{1}(end,1,:,:);
end;
