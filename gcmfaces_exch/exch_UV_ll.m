function [FLDU,FLDV]=exch_UV_ll(fldU,fldV);

FLDUtmp=exch_T_N(fldU);
FLDVtmp=exch_T_N(fldV);

FLDU=FLDUtmp;
FLDV=FLDVtmp;

FLDU.f1=FLDUtmp.f1(2:end,2:end-1,:);  
FLDV.f1=FLDVtmp.f1(2:end-1,2:end,:);

