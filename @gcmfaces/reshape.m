function r = reshape(p,varargin)
% RESHAPE Reshape gcmfaces object
%  Calls usual reshape for each face in a loop.
%  The first two dimensions sizes (that differ amongst faces)
%  are left unchanged; the others are set according to the
%  input parameter specification (see help reshape).

r=p;

for iFace=1:r.nFaces;
   iF=num2str(iFace);
   eval(['tmpsiz=size(p.f' iF ');']);
   if nargin>2;
     tmpsiz=[tmpsiz(1:2) varargin{3:end}]; 
   else;
     tmpsiz=[tmpsiz(1:2) varargin{1}(3:end)];
   end;
   eval(['r.f' iF '=reshape(p.f' iF ',tmpsiz);']); 
end;


