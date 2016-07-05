function r = convn(p,varargin)
% CONVN gcmfaces convn function :
%  simply calls double convn function for each face data
%  if the first arguments is a gcmfaces object
%  passing over the other arguments

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['r.f' iF '=convn(p.f' iF ',varargin{:});']); 
end;


