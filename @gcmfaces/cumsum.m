function r = cumsum(p,varargin)
%overloaded gcmfaces cumsum function :
%  simply calls double cumsum function for each face data
%  if the first arguments is a gcmfaces object
%  passing over the other arguments

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=cumsum(p.f' iF ',varargin{:});']); 
end;


