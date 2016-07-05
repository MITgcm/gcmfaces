function [FLDU,FLDV]=exch_UV_N_llpc(fldU,fldV,varargin);

error('!!!exch_UV_N_llpc has not been fully tested and is probably wrong!!!\n')

if nargin==3; N=varargin{1}; else; N=1; end;

FLDUtmp=exch_T_N(fldU,N);
FLDVtmp=exch_T_N(fldV,N);

FLDU=FLDUtmp;
FLDV=FLDVtmp;

FLDU.f1(1:N,:,:)=FLDVtmp.f1(1:N,:,:);
FLDV.f1(1:N,:,:)=-FLDUtmp.f1(1:N,:,:);
FLDU.f1(:,end-N+1:end,:)=-FLDVtmp.f1(:,end-N+1:end,:);
FLDV.f1(:,end-N+1:end,:)=FLDUtmp.f1(:,end-N+1:end,:);

FLDU.f2(end-N+1:end,:,:)=FLDVtmp.f2(end-N+1:end,:,:);
FLDV.f2(end-N+1:end,:,:)=-FLDUtmp.f2(end-N+1:end,:,:);
FLDU.f2(:,end-N+1:end,:)=-FLDVtmp.f2(:,end-N+1:end,:);
FLDV.f2(:,end-N+1:end,:)=FLDUtmp.f2(:,end-N+1:end,:);

FLDU.f3(1:N,:,:)=FLDVtmp.f3(1:N,:,:);
FLDV.f3(1:N,:,:)=-FLDUtmp.f3(1:N,:,:);
FLDU.f3(:,1:N,:)=-FLDVtmp.f3(:,1:N,:);
FLDV.f3(:,1:N,:)=FLDUtmp.f3(:,1:N,:);

FLDU.f4(1:N,:,:)=FLDVtmp.f4(1:N,:,:);
FLDV.f4(1:N,:,:)=-FLDUtmp.f4(1:N,:,:);
FLDU.f4(:,end-N+1:end,:)=-FLDVtmp.f4(:,end-N+1:end,:);
FLDV.f4(:,end-N+1:end,:)=FLDUtmp.f4(:,end-N+1:end,:);

