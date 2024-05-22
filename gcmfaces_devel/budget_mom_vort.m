function [out]=budget_mom_vort(nmRun,tim);
% BUDGET_MOM_VORT performs a simple check of momentum budget closure for output
%    in nmRun ('diags.20160531' by default) and time tim (62772 by default)
%
%    example 1: budget_mom_vort('diags.20160531',62772);
%
%    example 2: execute commands below to compute time mean BPV budget
%
%list0=dir('diags.20160531/budg_tendU.*.meta'); nt=240;
%list1=zeros(nt,1); for tt=1:nt; list1(tt)=str2num(list0(tt).name(12:end-5)); end;
%
%tic;
%for tt=1:nt; 
%  disp(tt);
%  [out]=budget_mom_vort('diags.20160531',list1(tt));
%  if tt==1;
%    list2=fieldnames(out);
%    for nn=1:length(list2);
%       ave.(list2{nn})=out.(list2{nn})/nt;
%    end;
%  else;
%    for nn=1:length(list2);
%       ave.(list2{nn})=ave.(list2{nn})+out.(list2{nn})/nt;
%    end;
%  end;
%end;
%toc;
%
%%save budget_mom_vort_ave.mat ave;
%
%rot.TOTUTEND=calc_UV_curl(ave.TOTUTEND,ave.TOTVTEND,1);
%rot.AB_gU=calc_UV_curl(ave.AB_gU,ave.AB_gV,1);
%rot.Um_Diss=calc_UV_curl(ave.Um_Diss,ave.Vm_Diss,1);
%rot.Um_Advec=calc_UV_curl(ave.Um_Advec,ave.Vm_Advec,1);
%rot.Um_dPHdx=calc_UV_curl(ave.Um_dPHdx,ave.Vm_dPHdx,1);
%rot.Um_Ext=calc_UV_curl(ave.Um_Ext,ave.Vm_Ext,1);
%rot.VISrI_Um=calc_UV_curl(ave.VISrI_Um,ave.VISrI_Vm,1);
%rot.Um_dETANdx=calc_UV_curl(ave.Um_dETANdx,ave.Vm_dETANdy,1);
%
%%msk=mygrid.mskC(:,:,1);
%msk=exch_T_N(mygrid.mskC(:,:,1));
%for ff=1:msk.nFaces;
%  tmp1=msk{ff}(2:end-1,2:end-1);
%  for ii=-1:1; for jj=-1:1; tmp1=tmp1.*msk{ff}(2+ii:end-1+ii,2+jj:end-1+jj); end; end;
%  msk{ff}=tmp1;
%end;
%
%list2=fieldnames(rot);
%distXC=3*mygrid.DXC; distYC=3*mygrid.DYC;
%for nn=1:length(list2); 
%  tmp1=msk.*rot.(list2{nn});
%  tmp1=diffsmooth2D(tmp1,distXC,distYC);
%  eval([list2{nn} '=tmp1;']); 
%end;
%
%figureL; fac2=2;
%subplot(3,2,1); qwckplot(TOTUTEND); caxis(fac2*[-1 1]*2e-10); colorbar; title('TEND');
%subplot(3,2,2); qwckplot(Um_dETANdx+Um_dPHdx); caxis(fac2*[-1 1]*2e-10); colorbar; title('PRESS');
%subplot(3,2,3); qwckplot(AB_gU+Um_Diss+VISrI_Um); caxis(fac2*[-1 1]*2e-10); colorbar; title('VARIOUS');
%subplot(3,2,4); qwckplot(Um_Advec); caxis(fac2*[-1 1]*2e-10); colorbar; title('ADVEC');
%subplot(3,2,5); qwckplot(Um_Ext); caxis(fac2*[-1 1]*2e-10); colorbar; title('EXT');
%subplot(3,2,6); qwckplot(TOTUTEND-Um_dETANdx-Um_dPHdx-AB_gU...
%       -Um_Diss-VISrI_Um-Um_Advec-Um_Ext); caxis(fac2*[-1 1]*2e-10); colorbar; title('RESIDUAL');

gcmfaces_global;

doPlot=0;
if nargin<1; nmRun='diags.20160531'; end;
if nargin<2; tim=62772; end;

dir00='eccov4_release2_mom/';
dir0=[dir00 nmRun '/'];
dirGrid=[dir00 'GRID/'];

if isempty(mygrid); grid_load(dirGrid,5,'compact'); end;

RAW=rdmds2gcmfaces([dirGrid 'RAW']);
RAS=rdmds2gcmfaces([dirGrid 'RAS']);
nr=length(mygrid.RC); kk=1; fac0=1e3; fac1=1e3;
doIce=0;

listVars={'TOTUTEND','AB_gU   ','Um_Diss ','Um_Advec','Um_dPHdx','Um_Ext  ','VISrI_Um'};
listVars=deblank(listVars);
for vv=1:7;
    fld=rdmds2gcmfaces([dir0 'budg_tendU'],tim,'rec',vv);
    %fld=fld(:,:,:,end);
    if vv==1; fld=fld/86400;
    elseif vv==7;
        fld=fld./repmat(RAW,[1 1 nr]);
        tmp1=mygrid.hFacW.*mk3D(mygrid.DRF,fld);
        tmp2=fld; tmp2(:,:,nr)=fld(:,:,nr);
        tmp2(:,:,1:nr-1)=fld(:,:,1:nr-1)-fld(:,:,2:nr);
        fld=tmp2./tmp1;
    end;
    tmp1=mygrid.hFacW.*mk3D(mygrid.DRF,fld);
    fld=nansum(tmp1.*fld,3);
    eval([listVars{vv} '=fld;']);
    eval(['out.' listVars{vv} '=fld;']);
end;

listVars_V={'TOTVTEND','AB_gV   ','Vm_Diss ','Vm_Advec','Vm_dPHdx','Vm_Ext  ','VISrI_Vm'};
listVars_V=deblank(listVars_V);
for vv=1:7;
    fld=rdmds2gcmfaces([dir0 'budg_tendV'],tim,'rec',vv);
    %fld=fld(:,:,:,end);
    if vv==1; fld=fld/86400;
    elseif vv==7;
        fld=fld./repmat(RAS,[1 1 nr]);
        tmp1=mygrid.hFacS.*mk3D(mygrid.DRF,fld);
        tmp2=fld; tmp2(:,:,nr)=fld(:,:,nr);
        tmp2(:,:,1:nr-1)=fld(:,:,1:nr-1)-fld(:,:,2:nr);
        fld=tmp2./tmp1;
    end;
    tmp1=mygrid.hFacS.*mk3D(mygrid.DRF,fld);
    fld=nansum(tmp1.*fld,3);
    eval([listVars_V{vv} '=fld;']);
    eval(['out.' listVars_V{vv} '=fld;']);
end;

ETAN=1/9.81*rdmds2gcmfaces([dir0 'budg_aveSURF'],tim,'rec',6);
[Um_dETANdx,Vm_dETANdy]=calc_T_grad(-9.81*mygrid.mskC(:,:,1).*ETAN,0);

tmp1=nansum(mygrid.hFacW.*mk3D(mygrid.DRF,mygrid.hFacW),3);
Um_dETANdx=Um_dETANdx.*tmp1;
tmp1=nansum(mygrid.hFacS.*mk3D(mygrid.DRF,mygrid.hFacS),3);
Vm_dETANdy=Vm_dETANdy.*tmp1;

out.Um_dETANdx=Um_dETANdx;
out.Vm_dETANdy=Vm_dETANdy;

%%

if nargout==0;

m=mygrid.mskC(:,:,kk);

figureL;
subplot(3,2,1); qwckplot(m.*VISrI_Um(:,:,kk));
title('VISrI_Um (d/dr/rac of VISC)'); caxis(fac0*[-1 1]*1e-8); colorbar;
subplot(3,2,2); qwckplot(m.*Um_dETANdx);
title('Um_dETANdx (d/dx of PHI_SURF/g)'); caxis(fac0*[-1 1]*1e-5); colorbar;
for jj=1:6;
    vv=listVars{jj+1};
    subplot(3,3,jj+3);
    eval(['fld=' vv ';']);
    qwckplot(m.*fld(:,:,kk));
    if strcmp(vv,'Um_Advec')|strcmp(vv,'Um_dPHdx')|strcmp(vv,'Um_Ext');
        caxis(fac0*[-1 1]*1e-5); colorbar;
    else;
        caxis(fac0*[-1 1]*1e-8); colorbar;
    end;
    title(listVars{jj+1});
end;

%compute R.H.S.
fld=Um_dPHdx(:,:,kk)+Um_dETANdx+Um_Advec(:,:,kk);
fld=fld+Um_Diss(:,:,kk)+Um_Ext(:,:,kk)+AB_gU(:,:,kk);
fld=fld-VISrI_Um(:,:,kk);

figureL;
subplot(3,1,1); qwckplot(m.*TOTUTEND(:,:,kk));
title('TOTUTEND'); caxis(fac1*[-1 1]*1e-8); colorbar;
subplot(3,1,2); qwckplot(m.*fld);
title('R.H.S.'); caxis(fac1*[-1 1]*1e-8); colorbar;
subplot(3,1,3); qwckplot(m.*TOTUTEND(:,:,kk)-fld);
title('residual'); caxis(fac1*[-1 1]*1e-11); colorbar;

%compute R.H.S.
fld=Vm_dPHdx(:,:,kk)+Vm_dETANdy+Vm_Advec(:,:,kk);
fld=fld+Vm_Diss(:,:,kk)+Vm_Ext(:,:,kk)+AB_gV(:,:,kk);
fld=fld-VISrI_Vm(:,:,kk);

figureL;
subplot(3,1,1); qwckplot(m.*TOTVTEND(:,:,kk));
title('TOTVTEND'); caxis(fac1*[-1 1]*1e-8); colorbar;
subplot(3,1,2); qwckplot(m.*fld);
title('R.H.S.'); caxis(fac1*[-1 1]*1e-8); colorbar;
subplot(3,1,3); qwckplot(m.*TOTVTEND(:,:,kk)-fld);
title('residual'); caxis(fac1*[-1 1]*1e-11); colorbar;

if 0;
figureL;
subplot(2,1,1); qwckplot(m.*TOTUTEND(:,:,kk)-fld);
title('residual'); caxis(fac1*[-1 1]*1e-8); colorbar;
subplot(2,1,2); qwckplot(m.*VISrI_Um(:,:,kk));
title('residual'); caxis(fac1*[-1 1]*1e-8); colorbar;
end;

end;%if nargout==0; 

