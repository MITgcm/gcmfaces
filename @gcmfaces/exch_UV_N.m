function [aU,aV]=exch_UV_N(bU,bV,varargin);
%special exchange routine for velocity points

if strcmp(bU.gridType,'llc');
   [aU,aV]=exch_UV_N_llc(bU,bV,varargin{:}); 
elseif strcmp(bU.gridType,'cube');
   [aU,aV]=exch_UV_N_cube(bU,bV,varargin{:});
elseif strcmp(bU.gridType,'llpc');
   [aU,aV]=exch_UV_N_llpc(bU,bV,varargin{:});
elseif strcmp(bU.gridType,'ll');
   [aU,aV]=exch_UV_N_ll(bU,bV,varargin{:});
else;
   error(['exch_UV_N not implemented for ' bU.gridType '!?']);
end;

