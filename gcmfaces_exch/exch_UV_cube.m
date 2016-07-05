function [FLDU,FLDV]=exch_UV_cube(fldU,fldV);

FLDUtmp=exch_T_N(fldU);
FLDVtmp=exch_T_N(fldV);

FLDU=FLDUtmp;
FLDV=FLDVtmp;

FLDU.f1=FLDUtmp.f1(2:end,2:end-1,:);  
FLDV.f1=FLDVtmp.f1(2:end-1,2:end,:);
FLDV.f1(:,end,:)=FLDUtmp.f1(2:end-1,end,:);

FLDU.f2=FLDUtmp.f2(2:end,2:end-1,:);    
FLDU.f2(end,:,:)=FLDVtmp.f2(end,2:end-1,:);
FLDV.f2=FLDVtmp.f2(2:end-1,2:end,:);

FLDU.f3=FLDUtmp.f3(2:end,2:end-1,:);
FLDV.f3=FLDVtmp.f3(2:end-1,2:end,:);
FLDV.f3(:,end,:)=FLDUtmp.f3(2:end-1,end,:);

FLDU.f4=FLDUtmp.f4(2:end,2:end-1,:);
FLDU.f4(end,:,:)=FLDVtmp.f4(end,2:end-1,:);
FLDV.f4=FLDVtmp.f4(2:end-1,2:end,:);
%?? u 

FLDU.f5=FLDUtmp.f5(2:end,2:end-1,:);
FLDV.f5=FLDVtmp.f5(2:end-1,2:end,:);
FLDV.f5(:,end,:)=FLDUtmp.f5(2:end-1,end,:);

FLDU.f6=FLDUtmp.f6(2:end,2:end-1,:);
FLDU.f6(end,:,:)=FLDVtmp.f6(end,2:end-1,:);
FLDV.f6=FLDVtmp.f6(2:end-1,2:end,:);
%??u 

