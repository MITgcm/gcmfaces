function [FLDU,FLDV]=exch_UV_N_ll(fldU,fldV,varargin);

if nargin==2; N=varargin{1}; else; N=1; end;

FLDU=exch_T_N(fldU,N);
FLDV=exch_T_N(fldV,N);

