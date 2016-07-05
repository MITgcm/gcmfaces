function r = repmat(p,varargin)
%overloaded gcmfaces repmat function :
%  simply calls double repmat function for each face data
%  if the first arguments is a gcmfaces object
%  passing over the other arguments

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=repmat(p.f' iF ',varargin{:});']); 
end;


