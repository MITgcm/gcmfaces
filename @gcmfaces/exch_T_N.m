function [a]=exch_T_N(b,varargin);
%object :  add halo region data; exchange data between faces.
%input:    b is a gcmfaces object
%optional: N (1 by default) is the halo region width  
%output:   a is the augmented gcmfaces object
%
%notes:
% - This routine adds N points at the edge of each face, which
% are obtained from the neighboring faces edge points; those are necessary to
% operations such as neighbor averaging, or computing gradients over a face. 
% - Applying this routine recursively will likely lead to errors.
% - The connectivity between faces depends on the grid topology and needs 
% to be implemented by hand for any new grid topology (see gcmfaces_exch).

if strcmp(b.gridType,'llc');
   a=exch_T_N_llc(b,varargin{:}); 
elseif strcmp(b.gridType,'cube');
   a=exch_T_N_cube(b,varargin{:});
elseif strcmp(b.gridType,'llpc');
   a=exch_T_N_llpc(b,varargin{:});
elseif strcmp(b.gridType,'ll');
   a=exch_T_N_ll(b,varargin{:});
else;
   error(['exch_T_N not implemented for ' b.gridType '!?']);
end;

