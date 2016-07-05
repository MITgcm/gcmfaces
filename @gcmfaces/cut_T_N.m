function r = cut_T_N(p,varargin)
%object :  remove N points at the edge of each face (opposite of exch_T_N).
%input:    b is a gcmfaces object
%optional: N (1 by default) is the halo region width
%output:   a is the reduced gcmfaces object
%

r=p;

if nargin==1; N=1; else; N=varargin{1}; end;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=p.f' iF '(1+N:end-N,1+N:end-N,:,:);']); 
end;


