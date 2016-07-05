function r = std(p,varargin)
% STD(p,varargin)
%
%overloaded gcmfaces std function :
%  1) if single gcmfaces argument, then returns the global std over all faces
%  2) if more than one argument, then simply calls double std function for 
%     each face data, passing over the other arguments

if nargin==1;
   tmp1=[];
   for iFace=1:p.nFaces;
      iF=num2str(iFace);
      eval(['tmp1=[tmp1;p.f' iF '(:)];']);
   end;
   r=std(tmp1);
   return;
end;

if varargin{2}>0;
  r=p;
  for iFace=1:r.nFaces;
     iF=num2str(iFace); 
     eval(['r.f' iF '=std(p.f' iF ',varargin{:});']); 
  end;
else;
  tmp1=convert2gcmfaces(p);
  [n1,n2,n3,n4]=size(tmp1);
  tmp1=reshape(tmp1,n1*n2,n3,n4);
  r=std(tmp1,varargin{1},1);
end;


