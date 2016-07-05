function [FLD]=diffsmooth2D_extrap_inv(fld,mskOut,varargin);
%object:        extrapolate an incomplete field to create a full field, by 
%                       solving for a diffusion equation equilibrium state.
%inputs:        fld     incomplete field of interest (masked with NaN)
%               mskOut  land mask (1s and NaNs) for the full field (output)
%output:        FLD     full field
%optional:      doFormMatrix (1 by default)
%                       if set to 1 then compute the dFLDdt_op matrix
%                       if set to 0 then use precomputed one (global dFLDdt_op)
%               doMSKOUT (1 by default)
%                       if set to 1 then first detect closed regions lacking
%                         data points to extrapolate from (e.g. abyssal canions)
%                         and restrict mskOut to MSKOUT accordingly
%                       if set to 0 then omit this step
%principle : 
%in points where mskFreeze is 1 solve diffusion equation
%in points where mskFreeze is 0 solve the trivial FLD=fld

gcmfaces_global;

if nargin==3; doFormMatrix=varargin{1}; else; doFormMatrix=1; end;
if nargin==4; doMSKOUT=varargin{2}; else; doMSKOUT=1; end;

if doMSKOUT;
  %problematic regions will show MSKOUT==0;
  tmp1=1+0*fld; [MSKOUT]=diffsmooth2D_extrap_inv(tmp1,mskOut,doFormMatrix,0);
  %if no problematic region then no need to recompute dFLDdt_op 
  if sum(MSKOUT==0)==0; doFormMatrix=0; end;
  %finalize MSKOUT
  MSKOUT(MSKOUT==0)=NaN; 
  MSKOUT(~isnan(MSKOUT))=1;
end;

dxC=mygrid.DXC; dyC=mygrid.DYC; 
rA=mygrid.RAC;

dxCsm=dxC; dyCsm=dyC;
mskFreeze=fld; mskFreeze(find(~isnan(mskFreeze)))=0; mskFreeze(find(isnan(mskFreeze)))=1;

%check for domain edge points where no exchange is possible:
tmp1=mskOut; tmp1(:)=1; tmp2=exch_T_N(tmp1);
for iF=1:mskOut.nFaces;
tmp3=mskOut{iF}; tmp4=tmp2{iF}; 
tmp4=tmp4(2:end-1,1:end-2)+tmp4(2:end-1,3:end)+tmp4(1:end-2,2:end-1)+tmp4(3:end,2:end-1);
if ~isempty(find(isnan(tmp4)&~isnan(tmp3))); fprintf('warning: mask was modified\n'); end;
tmp3(isnan(tmp4))=NaN; mskOut{iF}=tmp3; 
end;

%put 0 first guess if needed and switch land mask:
fld(find(isnan(fld)))=0; fld=fld.*mskOut;

%scale the diffusive operator:
tmp0=dxCsm./dxC; tmp0(isnan(mskOut))=NaN; tmp00=nanmax(tmp0);
tmp0=dyCsm./dyC; tmp0(isnan(mskOut))=NaN; tmp00=max([tmp00 nanmax(tmp0)]);
smooth2D_nbt=tmp00;
smooth2D_nbt=ceil(1.1*2*smooth2D_nbt^2);

smooth2D_dt=1;
smooth2D_T=smooth2D_nbt*smooth2D_dt;
smooth2D_Kux=dxCsm.*dxCsm/smooth2D_T/2;
smooth2D_Kvy=dyCsm.*dyCsm/smooth2D_T/2;

%form matrix problem:
tmp1=convert2array(mskOut);
kk=find(~isnan(tmp1));
KK=tmp1; KK(kk)=kk; KK=convert2array(KK);
nn=length(kk);
NN=tmp1; NN(kk)=[1:nn]; %NN=convert2array(NN); 

global dFLDdt_op; 
if doFormMatrix==1;

dFLDdt_op=sparse([],[],[],nn,nn,nn*5);

for iF=1:fld.nFaces; for ii=1:3; for jj=1:3;
    FLDones=fld; FLDones(find(~isnan(fld)))=0; 
    FLDones{iF}(ii:3:end,jj:3:end)=1;
    FLDones(find(isnan(fld)))=NaN;

    FLDkkFROMtmp=fld; FLDkkFROMtmp(find(~isnan(fld)))=0;
    FLDkkFROMtmp{iF}(ii:3:end,jj:3:end)=KK{iF}(ii:3:end,jj:3:end);
    FLDkkFROMtmp(find(isnan(fld)))=0;

    FLDkkFROM=exch_T_N(FLDkkFROMtmp); 
    FLDkkFROM(find(isnan(FLDkkFROM)))=0;
    for iF2=1:fld.nFaces; 
       tmp1=FLDkkFROM{iF2}; tmp2=zeros(size(tmp1)-2);
       for ii2=1:3; for jj2=1:3; tmp2=tmp2+tmp1(ii2:end-3+ii2,jj2:end-3+jj2); end; end;
       FLDkkFROM{iF2}=tmp2; 
    end;
    %clear FLDkkFROMtmp;

    [dTdxAtU,dTdyAtV]=calc_T_grad(FLDones,0);
    tmpU=dTdxAtU.*smooth2D_Kux;
    tmpV=dTdyAtV.*smooth2D_Kvy;
    [fldDIV]=calc_UV_conv(tmpU,tmpV);
    dFLDdt=smooth2D_dt*fldDIV./rA;
    dFLDdt=dFLDdt.*mskFreeze;

    dFLDdt=convert2array(dFLDdt); FLDkkFROM=convert2array(FLDkkFROM); FLDkkTO=convert2array(KK);
    tmp1=find(dFLDdt~=0&~isnan(dFLDdt)); 
    dFLDdt=dFLDdt(tmp1); FLDkkFROM=FLDkkFROM(tmp1); FLDkkTO=FLDkkTO(tmp1);
    dFLDdt_op=dFLDdt_op+sparse(NN(FLDkkTO),NN(FLDkkFROM),dFLDdt,nn,nn);

end; end; end;

end;%if doFormMatrix==1;

%figure; spy(dFLDdt_op);

FLD_vec=convert2array(fld);%right hand side of FLD=fld 
mskFreeze_vec=convert2array(mskFreeze);
FLD_vec(find(mskFreeze_vec==1))=0;%right hand side of diffusion equation
FLD_vec=FLD_vec(kk);

INV_op=1-mskFreeze_vec(kk);
INV_op=sparse([1:nn],[1:nn],INV_op,nn,nn);%identity where mskFreeze is 0 
INV_op=INV_op+dFLDdt_op;%add diffusion operator where mskFreeze is 1

warning('off','MATLAB:nearlySingularMatrix');
warning('off','MATLAB:singularMatrix');
INV_vec=INV_op\FLD_vec;%solve
warning('on','MATLAB:nearlySingularMatrix');
warning('on','MATLAB:singularMatrix');

INV_fld=convert2array(mskOut);
INV_fld(find(~isnan(INV_fld)))=INV_vec;
FLD=convert2array(INV_fld);%reformat

if doMSKOUT; FLD=FLD.*MSKOUT; end;%mask problematic regions


