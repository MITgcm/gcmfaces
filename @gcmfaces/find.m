function r = find(p,varargin)
%overloaded gcmfaces find function :
%  simply calls double find function for each face data
%  if the first arguments is a gcmfaces object
%  passing over the other arguments

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=find(p.f' iF ',varargin{:});']); 
end;


