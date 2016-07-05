function [FLD]=exch_T_N_cube(fld,varargin);

if nargin==2; N=varargin{1}; else; N=1; end;

FLD=fld;
s=size(FLD.f1); s(1:2)=s(1:2)+2*N; FLD.f1=NaN*zeros(s);
s=size(FLD.f2); s(1:2)=s(1:2)+2*N; FLD.f2=NaN*zeros(s);
s=size(FLD.f3); s(1:2)=s(1:2)+2*N; FLD.f3=NaN*zeros(s);
s=size(FLD.f4); s(1:2)=s(1:2)+2*N; FLD.f4=NaN*zeros(s);
s=size(FLD.f5); s(1:2)=s(1:2)+2*N; FLD.f5=NaN*zeros(s);
s=size(FLD.f6); s(1:2)=s(1:2)+2*N; FLD.f6=NaN*zeros(s);

n3=max(size(fld.f1,3),1); n4=max(size(fld.f1,4),1);
for k3=1:n3; for k4=1:n4;

%f1245=[fld{1}(:,:,k3,k4);fld{2}(:,:,k3,k4);sym_g(fld{4}(:,:,k3,k4),7,0);sym_g(fld{5}(:,:,k3,k4),7,0)];
%f3=fld{3}(:,:,k3,k4); f3=[sym_g(f3,5,0);f3;sym_g(f3,7,0);sym_g(f3,6,0)];

%initial rotation for SIDE faces:
f1=fld.f1(:,:,k3,k4); 
f2=fld.f2(:,:,k3,k4);
f4=sym_g(fld.f4(:,:,k3,k4),7,0);
f5=sym_g(fld.f5(:,:,k3,k4),7,0);

nan1=NaN*ones(size(FLD.f1,1),N); 
nan2=NaN*ones(N,N);
%face 1:
F1=[f5(end-N+1:end,:);f1;f2(1:N,:)];
f3=sym_g(fld.f3(:,:,k3,k4),5,0);
f6=fld.f6(:,:,k3,k4);
F1=[[nan2;f6(:,end-N+1:end);nan2] F1 [nan2;f3(:,1:N);nan2]];
%face 2:
F2=[f1(end-N+1:end,:);f2;f4(1:N,:)];
f3=fld.f3(:,:,k3,k4);
f6=sym_g(fld.f6(:,:,k3,k4),5,0);
F2=[[nan2;f6(:,end-N+1:end);nan2] F2 [nan2;f3(:,1:N);nan2]];
%face 4:
F4=[f2(end-N+1:end,:);f4;f5(1:N,:)];
f3=sym_g(fld.f3(:,:,k3,k4),7,0);
f6=sym_g(fld.f6(:,:,k3,k4),6,0);
F4=[[nan2;f6(:,end-N+1:end);nan2] F4 [nan2;f3(:,1:N);nan2]];
%face 5:
F5=[f4(end-N+1:end,:);f5;f1(1:N,:)];
f3=sym_g(fld.f3(:,:,k3,k4),6,0);
f6=sym_g(fld.f6(:,:,k3,k4),7,0);
F5=[[nan2;f6(:,end-N+1:end);nan2] F5 [nan2;f3(:,1:N);nan2]];
%face 3:
f3=fld.f3(:,:,k3,k4); F3=FLD.f3(:,:,k3,k4);
F3(1+N:end-N,1+N:end-N)=f3;
F3=sym_g(F3,5,0); F3(1+N:end-N,1:N)=f1(:,end-N+1:end); F3=sym_g(F3,7,0);
F3(1+N:end-N,1:N)=f2(:,end-N+1:end);
F3=sym_g(F3,7,0); F3(1+N:end-N,1:N)=f4(:,end-N+1:end); F3=sym_g(F3,5,0);
F3=sym_g(F3,6,0); F3(1+N:end-N,1:N)=f5(:,end-N+1:end); F3=sym_g(F3,6,0);
%face 6:
f6=fld.f6(:,:,k3,k4); F6=FLD.f6(:,:,k3,k4);
F6(1+N:end-N,1+N:end-N)=f6;
F6(1+N:end-N,end-N+1:end)=f1(:,1:N);
F6=sym_g(F6,5,0); F6(1+N:end-N,end-N+1:end)=f2(:,1:N); F6=sym_g(F6,7,0);
F6=sym_g(F6,6,0); F6(1+N:end-N,end-N+1:end)=f4(:,1:N); F6=sym_g(F6,6,0);
F6=sym_g(F6,7,0); F6(1+N:end-N,end-N+1:end)=f5(:,1:N); F6=sym_g(F6,5,0);

%final rotation for SIDE faces:
F4=sym_g(F4,5,0);
F5=sym_g(F5,5,0);
%store:
FLD.f1(:,:,k3,k4)=F1;
FLD.f2(:,:,k3,k4)=F2;
FLD.f3(:,:,k3,k4)=F3;
FLD.f4(:,:,k3,k4)=F4;
FLD.f5(:,:,k3,k4)=F5;
FLD.f6(:,:,k3,k4)=F6;

end; end;

