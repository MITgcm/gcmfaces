function [FLD]=exch_T_N_llc(fld,varargin);

if nargin==2; N=varargin{1}; else; N=1; end;

FLD=fld;
s=size(FLD.f1); s(1:2)=s(1:2)+2*N; FLD.f1=NaN*zeros(s);
s=size(FLD.f2); s(1:2)=s(1:2)+2*N; FLD.f2=NaN*zeros(s);
s=size(FLD.f3); s(1:2)=s(1:2)+2*N; FLD.f3=NaN*zeros(s);
s=size(FLD.f4); s(1:2)=s(1:2)+2*N; FLD.f4=NaN*zeros(s);
s=size(FLD.f5); s(1:2)=s(1:2)+2*N; FLD.f5=NaN*zeros(s);

n3=max(size(fld.f1,3),1); n4=max(size(fld.f1,4),1);

%initial rotation for "LATLON" faces:
f1=fld.f1; 
f2=fld.f2;
f4=sym_g(fld.f4,7,0);
f5=sym_g(fld.f5,7,0);

nan1=NaN*ones(size(FLD.f1,1),N,n3,n4); 
nan2=NaN*ones(N,N,n3,n4);
%face 1:
F1=cat(1,f5(end-N+1:end,:,:,:),f1,f2(1:N,:,:,:));
f3=sym_g(fld.f3,5,0);
F1=cat(2,nan1,F1,cat(1,nan2,f3(:,1:N,:,:),nan2));
%face 2:
F2=cat(1,f1(end-N+1:end,:,:,:),f2,f4(1:N,:,:,:));
f3=fld.f3;
F2=cat(2,nan1,F2,cat(1,nan2,f3(:,1:N,:,:),nan2));
%face 4:
F4=cat(1,f2(end-N+1:end,:,:,:),f4,f5(1:N,:,:,:));
f3=sym_g(fld.f3,7,0);
F4=cat(2,nan1,F4,cat(1,nan2,f3(:,1:N,:,:),nan2));
%face 5:
F5=cat(1,f4(end-N+1:end,:,:,:),f5,f1(1:N,:,:,:));
f3=sym_g(fld.f3,6,0);
F5=cat(2,nan1,F5,cat(1,nan2,f3(:,1:N,:,:),nan2));
%face 3:
f3=fld.f3; F3=FLD.f3;
F3(1+N:end-N,1+N:end-N,:,:)=f3;
F3=sym_g(F3,5,0); F3(1+N:end-N,1:N,:,:)=f1(:,end-N+1:end,:,:); F3=sym_g(F3,7,0);
F3(1+N:end-N,1:N,:,:)=f2(:,end-N+1:end,:,:);
F3=sym_g(F3,7,0); F3(1+N:end-N,1:N,:,:)=f4(:,end-N+1:end,:,:); F3=sym_g(F3,5,0);
F3=sym_g(F3,6,0); F3(1+N:end-N,1:N,:,:)=f5(:,end-N+1:end,:,:); F3=sym_g(F3,6,0);

%final rotation for "LATLON" faces:
F4=sym_g(F4,5,0);
F5=sym_g(F5,5,0);
%store:
FLD.f1=F1;
FLD.f2=F2;
FLD.f3=F3;
FLD.f4=F4;
FLD.f5=F5;


