function r = diff(p,varargin)
%overloaded gcmfaces diff function :
%  simply calls double diff function for each face data
%  if the first arguments is a gcmfaces object
%  passing over the other arguments

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=diff(p.f' iF ',varargin{:});']); 
end;


