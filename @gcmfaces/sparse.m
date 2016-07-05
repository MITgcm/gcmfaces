function r = sparse(p,varargin)
%overloaded gcmfaces sparse function :
%  simply calls double sparse function for each face data
%  if the first arguments is a gcmfaces object
%  passing over the other arguments

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=sparse(p.f' iF ',varargin{:});']); 
end;


