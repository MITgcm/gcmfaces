function r = nansum(p,varargin);
% NANSUM(p,varargin)
% 
%overloaded gcmfaces nansum function :
%  1) if single gcmfaces argument, then returns the global nansum over all faces
%  2) if more than one argument, then simply calls double nansum function for 
%     each face data, passing over the other arguments

if nargin==1;
   tmp1=[]; 
   for iFace=1:p.nFaces; 
      iF=num2str(iFace);
      eval(['tmp1=[tmp1;p.f' iF '(:)];']);
   end;
   r=nansum(tmp1);
   return;
end;

if varargin{1}>0;
  r=p;
  for iFace=1:r.nFaces;
     iF=num2str(iFace); 
     eval(['r.f' iF '=nansum(p.f' iF ',varargin{:});']); 
  end;
else;
  tmp1=convert2gcmfaces(p);
  [n1,n2,n3,n4]=size(tmp1);
  tmp1=reshape(tmp1,n1*n2,n3,n4);
  r=nansum(tmp1,1);
end;

