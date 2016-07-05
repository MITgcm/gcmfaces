function [aU,aV]=exch_UV(bU,bV);
%special exchange routine for velocity points

if strcmp(bU.gridType,'llc');
   [aU,aV]=exch_UV_llc(bU,bV); 
elseif strcmp(bU.gridType,'cube');
   [aU,aV]=exch_UV_cube(bU,bV);
elseif strcmp(bU.gridType,'llpc');
   [aU,aV]=exch_UV_llpc(bU,bV);
elseif strcmp(bU.gridType,'ll');
   [aU,aV]=exch_UV_ll(bU,bV);
else;
   error(['exch_UV not implemented for ' bU.gridType '!?']);
end;

