function [FLD]=exch_Z(fld);
%[FLD]=exch_Z(fld);
%adds vorticity points (to north and east of center points)

if strcmp(fld.gridType,'llc');
   FLD=exch_Z_llc(fld); 
elseif strcmp(fld.gridType,'cube');
   FLD=exch_Z_cube(fld);
elseif strcmp(fld.gridType,'ll');
   FLD=exch_Z_ll(fld); 
else;
   error(['exch_Z not implemented for ' fld.gridType '!?']);
end;

