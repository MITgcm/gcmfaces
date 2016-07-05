function [FLDU,FLDV]=exch_UV_N_cube(fldU,fldV,varargin);

if nargin==3; N=varargin{1}; else; N=1; end;

%fill interior of extended arrays
FLDUtmp=exch_T_N(fldU,N); FLDVtmp=exch_T_N(fldV,N);
for iFace=1:fldU.nFaces; 
    FLDUtmp{iFace}(1:N,:,:)=NaN;
    FLDUtmp{iFace}(end-N+1:end,:,:)=NaN;
    FLDUtmp{iFace}(:,1:N,:)=NaN;
    FLDUtmp{iFace}(:,end-N+1:end,:)=NaN;
    FLDVtmp{iFace}(1:N,:,:)=NaN;
    FLDVtmp{iFace}(end-N+1:end,:,:)=NaN;
    FLDVtmp{iFace}(:,1:N,:)=NaN;
    FLDVtmp{iFace}(:,end-N+1:end,:)=NaN;
end;

FLDU=FLDUtmp;
FLDV=FLDVtmp;

%now add the one extra point we need for U and V
[FLDUtmp,FLDVtmp]=exch_UV(fldU,fldV);
%then add the remaining rows and columns...

%U face 1
tmp1=permute(FLDVtmp.f5(:,end-N:end-1,:),[2 1 3]);
FLDU.f1(1:N,N+1:end-N,:)=flipdim(tmp1,2);
tmp1=FLDUtmp.f2(1:N,:,:);
FLDU.f1(end-N+1:end,N+1:end-N,:)=tmp1;
%
tmp1=permute(-FLDVtmp.f3(1:N,:,:),[2 1 3]);
FLDU.f1(N+1:end-N+1,end-N+1:end,:)=flipdim(tmp1,1);

%V face 1
tmp1=permute(-FLDUtmp.f5(:,end-N+1:end,:),[2 1 3]);
FLDV.f1(1:N,N+1:end-N+1,:)=flipdim(tmp1,2);
tmp1=FLDVtmp.f2(1:N,:,:);
FLDV.f1(end-N+1:end,N+1:end-N+1,:)=tmp1;
%
tmp1=permute(FLDUtmp.f3(1:N,:,:),[2 1 3]);
FLDV.f1(N+1:end-N,end-N+1:end,:)=flipdim(tmp1,1);


%U face 2
tmp1=FLDUtmp.f1(end-N:end-1,:,:);
FLDU.f2(1:N,N+1:end-N,:)=tmp1;
tmp1=permute(FLDVtmp.f4(:,1:N,:),[2 1 3]);
FLDU.f2(end-N+1:end,N+1:end-N,:)=flipdim(tmp1,2);
%
tmp1=FLDUtmp.f3(:,1:N,:);
FLDU.f2(N+1:end-N+1,end-N+1:end,:)=tmp1;

%V face 2
tmp1=FLDVtmp.f1(end-N+1:end,:,:);
FLDV.f2(1:N,N+1:end-N+1,:)=tmp1;
tmp1=permute(-FLDUtmp.f4(:,1:N,:),[2 1 3]);
FLDV.f2(end-N+1:end,N+1:end-N+1,:)=flipdim(tmp1,2);
%
tmp1=FLDVtmp.f3(:,1:N,:);
FLDV.f2(N+1:end-N,end-N+1:end,:)=tmp1;


%U face 3
tmp1=permute(FLDVtmp.f1(:,end-N:end-1,:),[2 1 3]);
FLDU.f3(1:N,N+1:end-N,:)=flipdim(tmp1,2);
tmp1=FLDUtmp.f4(1:N,:,:);
FLDU.f3(end-N+1:end,N+1:end-N,:)=tmp1;
%
tmp1=FLDUtmp.f2(:,end-N+1:end,:);
FLDU.f3(N+1:end-N+1,1:N,:)=tmp1;
tmp1=permute(-FLDVtmp.f5(1:N,:,:),[2 1 3]);
FLDU.f3(N+1:end-N+1,end-N+1:end,:)=flipdim(tmp1,1);

%V face 3
tmp1=permute(-FLDUtmp.f1(:,end-N+1:end,:),[2 1 3]);
FLDV.f3(1:N,N+1:end-N+1,:)=flipdim(tmp1,2);
tmp1=FLDVtmp.f4(1:N,:,:);
FLDV.f3(end-N+1:end,N+1:end-N+1,:)=tmp1;
%
tmp1=FLDVtmp.f2(:,end-N:end-1,:);
FLDV.f3(N+1:end-N,1:N,:)=tmp1;
tmp1=permute(FLDUtmp.f5(1:N,:,:),[2 1 3]);
FLDV.f3(N+1:end-N,end-N+1:end,:)=flipdim(tmp1,1);


%U face 4
tmp1=FLDUtmp.f3(end-N:end-1,:,:);
FLDU.f4(1:N,N+1:end-N,:)=tmp1;
%
tmp1=permute(-FLDVtmp.f2(end-N+1:end,:,:),[2 1 3]);
FLDU.f4(N+1:end-N+1,1:N,:)=flipdim(tmp1,1);
tmp1=FLDUtmp.f5(:,1:N,:);
FLDU.f4(N+1:end-N+1,end-N+1:end,:)=tmp1;

%V face 4
tmp1=FLDVtmp.f3(end-N+1:end,:,:);
FLDV.f4(1:N,N+1:end-N+1,:)=tmp1;
%
tmp1=permute(FLDUtmp.f2(end-N:end-1,:,:),[2 1 3]);
FLDV.f4(N+1:end-N,1:N,:)=flipdim(tmp1,1);
tmp1=FLDVtmp.f5(:,1:N,:);
FLDV.f4(N+1:end-N,end-N+1:end,:)=tmp1;


%U face 5
tmp1=permute(FLDVtmp.f3(:,end-N:end-1,:),[2 1 3]);
FLDU.f5(1:N,N+1:end-N,:)=flipdim(tmp1,2);
%
tmp1=FLDUtmp.f4(:,end-N+1:end,:);
FLDU.f5(N+1:end-N+1,1:N,:)=tmp1;
tmp1=permute(-FLDVtmp.f1(1:N,:,:),[2 1 3]);
FLDU.f5(N+1:end-N+1,end-N+1:end,:)=flipdim(tmp1,1);

%V face 5
tmp1=permute(-FLDUtmp.f3(:,end-N+1:end,:),[2 1 3]);
FLDV.f5(1:N,N+1:end-N+1,:)=flipdim(tmp1,2);
%
tmp1=FLDVtmp.f4(:,end-N:end-1,:);
FLDV.f5(N+1:end-N,1:N,:)=tmp1;
tmp1=permute(FLDUtmp.f1(1:N,:,:),[2 1 3]);
FLDV.f5(N+1:end-N,end-N+1:end,:)=flipdim(tmp1,1);


