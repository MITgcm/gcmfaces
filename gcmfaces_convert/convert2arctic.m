function [fld0]=convert2arctic(fld00,varargin);

if fld00.nFaces==1; fld00=convert2cube(fld00); end;

n1=size(fld00{1},1);
n2=size(fld00{1},2);
n3=size(fld00{1},3);
n4=size(fld00{1},4);

f1=flipdim(permute(fld00{1},[2 1 3 4]),2);
f2=fld00{2};                       
f3=fld00{3};
f4=fld00{4};
f5=flipdim(permute(fld00{5},[2 1 3 4]),1);
if isempty(fld00{3}); f3=NaN*zeros(n1,n1,n3,n4); end;

fld0=NaN*zeros(n2*2+n1,n2*2+n1,n3,n4);
fld0(1:n2,n2+1:n2+n1,:,:)=f1;
fld0(n2+1:n2+n1,n2+1:n2+n1,:,:)=f3;
fld0(n2+n1+1:end,n2+1:n2+n1,:,:)=f4;
fld0(n2+1:n2+n1,1:n2,:,:)=f2;
fld0(n2+1:n2+n1,n2+n1+1:end,:,:)=f5;

nn=round(n2/2); 
nn2=n2-nn+1; nn1=n2*2+n1-nn2+1;
fld0=fld0(nn2:nn1,nn2:nn1);

if nargin==2; doFill=varargin{1}; else; doFill=1; end;
if doFill;

if n3>1; fprintf('not implemented yet\n'); return; end;
%fill the corners of fld0:
warning('off','MATLAB:interp1:NaNinY');
for pp=1:4;
%do the interpolation in polar coordinates...
  ii=[0:nn]'*ones(1,nn+1); jj=ones(nn+1,1)*[0:nn];
  aa=angle(ii+i*jj); bb=min(abs(ii+i*jj),nn);
%
  v0=fld0(end-nn:end,end-nn:end);
  k1=find(aa==0); k2=find(aa>0&aa<=pi/4); v0(k2)=interp1(bb(k1),v0(k1),bb(k2));
  k1=find(aa==pi/2); k2=find(aa>pi/4&aa<=pi/2); v0(k2)=interp1(bb(k1),v0(k1),bb(k2));
  fld0(end-nn+1:end,end-nn+1:end)=v0(2:end,2:end);
  fld0=sym_g(fld0,5,0);
%
end;
warning('on','MATLAB:interp1:NaNinY');

end;%if doFill;

