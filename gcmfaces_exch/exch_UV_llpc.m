function [FLDU,FLDV]=exch_UV_llpc(fldU,fldV);

FLDUtmp=exch_T_N(fldU);
FLDVtmp=exch_T_N(fldV);

FLDU=FLDUtmp;
FLDV=FLDVtmp;

FLDU.f1=FLDUtmp.f1(2:end,2:end-1,:);  
FLDV.f1=FLDVtmp.f1(2:end-1,2:end,:);
FLDV.f1(:,end,:)=FLDUtmp.f1(2:end-1,end,:);

FLDU.f2=FLDUtmp.f2(2:end,2:end-1,:);    
FLDU.f2(end,:,:)=FLDV.f2(end,2:end-1,:);
FLDV.f2=FLDVtmp.f2(2:end-1,2:end,:);
FLDV.f2(:,end,:)=FLDUtmp.f2(2:end-1,end,:);

FLDU.f3=FLDUtmp.f3(2:end,2:end-1,:);
FLDV.f3=FLDVtmp.f3(2:end-1,2:end,:);

FLDU.f4=FLDUtmp.f4(2:end,2:end-1,:);
FLDV.f4=FLDVtmp.f4(2:end-1,2:end,:);
FLDV.f4(:,end,:)=FLDUtmp.f4(2:end-1,end,:);

