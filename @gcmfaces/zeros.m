function r = zeros(p,varargin)
%overloaded gcmfaces zeros function :
%  if the first arguments is a gcmfaces object
%  we call the double zeros function for each face data
%  using face dimensions for the first two arguments and
%  passing over the other arguments

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace); 
   eval(['[n1,n2]=size(p.f' iF '(:,:,1));']);
   eval(['r.f' iF '=zeros(n1,n2,varargin{:});']); 
end;


