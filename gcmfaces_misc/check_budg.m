function [prec]=check_budg(budgIn,kk);
%function [prec]=check_budg(budgIn,kk);
%
%inputs:  budgIn is a structure containting tend, trU, trV, trWtop, 
%               trWbot (calling sequence reported in check_loop.m)
%         kk is a vertical level (0 for all levels)
%outputs: prec contains 3 measures of residual errors

gcmfaces_global;

tend=budgIn.tend;
trU=budgIn.trU;
trV=budgIn.trV;
trWtop=budgIn.trWtop;
trWbot=budgIn.trWbot;

dt=1;
units='1';
%dt=budgIn.t1-budgIn.t0;
%units = budgIn.specs.units;

%define northern hemisphere as domain of integration
nameMask='Northern Hemisphere';
mask=mygrid.mskC.*mk3D(mygrid.YC>0,mygrid.mskC);
if length(size(tend{1}))<3; mask=mask(:,:,1); end;

%focus on one level
if kk>0;
  mask=mask(:,:,kk);
  tend=tend(:,:,kk);
  trU=trU(:,:,kk);
  trV=trV(:,:,kk);
  trWtop=trWtop(:,:,kk);
  trWbot=trWbot(:,:,kk);
end;

%edit plot title accordingly
descr=nameMask;

%compute northern hemisphere integrals
budg.tend=NaN*dt;
budg.hconv=NaN*dt;
budg.zconv=NaN*dt;

%compute flux convergence
hconv=calc_UV_conv(trU,trV,{});
zconv=(trWbot-trWtop);

%compute local residuals
hconv(tend==0)=NaN;
zconv(tend==0)=NaN;
tend(tend==0)=NaN;

%compute local residuals
norm=sqrt(tend.^2+hconv.^2+zconv.^2);
res=abs(tend-hconv-zconv);

%compute sum over domain
budg.tend=nansum(tend.*mask);
budg.hconv=nansum(hconv.*mask);
budg.zconv=nansum(zconv.*mask);
%
budg.res=abs(budg.tend-budg.hconv-budg.zconv);
budg.norm=sqrt(budg.tend.^2+budg.hconv.^2+budg.zconv.^2);

%output result
prec(1,1)=nanmedian(res)/nanmedian(norm);
prec(1,2)=nanmax(res./norm);
prec(1,3)=budg.res/budg.norm;

