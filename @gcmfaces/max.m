function r = max(p,varargin)
% MAX(p,varargin)
%
%overloaded gcmfaces max function :
%  1) if single gcmfaces argument, then returns the global max over all faces
%  2) if two gcmfaces arguments, then returns the max of the two at each point
%  3) otherwise calls double max function for each face, passing over the other arguments

if nargin==1;
   tmp1=[];
   for iFace=1:p.nFaces;
      iF=num2str(iFace);
      eval(['tmp1=[tmp1;p.f' iF '(:)];']);
   end;
   r=max(tmp1);
   return;
end;

if isa(varargin{1},'gcmfaces');
   r=p;
   for iFace=1:r.nFaces;
      iF=num2str(iFace);
      eval(['r.f' iF '=max(p.f' iF ',varargin{1}.f' iF ');']);
   end;
   return;
end;

if varargin{2}>0;
  r=p;
  for iFace=1:r.nFaces;
     iF=num2str(iFace); 
     eval(['r.f' iF '=max(p.f' iF ',varargin{:});']); 
  end;
else;
  tmp1=convert2gcmfaces(p);
  [n1,n2,n3,n4]=size(tmp1);
  tmp1=reshape(tmp1,n1*n2,n3,n4);
  r=max(tmp1,[],1);
end;


