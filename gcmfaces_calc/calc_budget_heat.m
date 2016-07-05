function [budgO,budgI,budgOI]=calc_budget_heat(kBudget);
% CALC_BUDGET_HEAT(kBudget)

gcmfaces_global;

%get variables from caller routine:
%----------------------------------

global myparms;

list_variables={'THETA','AB_gT','TRELAX','SIheff','SIhsnow',...
                'TFLUX','geothFlux','SItflux','SIaaflux','oceQnet',...
                'SIatmQnt','SIsnPrcp','SIacSubl','WTHMASS',...
                'ADVx_TH','DFxE_TH','ADVy_TH','DFyE_TH',...
                'ADVxHEFF','ADVxSNOW','DFxEHEFF','DFxESNOW',...
                'ADVyHEFF','ADVySNOW','DFyEHEFF','DFyESNOW'};

for vv=1:length(list_variables);
  v = evalin('caller',list_variables{vv});
  eval([list_variables{vv} '=v;']);
end;
clear v;

test3d=length(size(ADVx_TH{1}))>2;

if test3d|kBudget>1;
  list_variables={'oceQsw','ADVr_TH','DFrE_TH',...
                  'DFrI_TH','ADVr_TH','DFrE_TH','DFrI_TH'};
  for vv=1:length(list_variables);
    v = evalin('caller',list_variables{vv});
    eval([list_variables{vv} '=v;']);
  end;
  clear v;
end;

%compute mapped budget:
%----------------------

budgO.tend=myparms.rcp*THETA-myparms.rcp*AB_gT;
budgI.tend=-myparms.flami*(SIheff*myparms.rhoi+SIhsnow*myparms.rhosn);
%
tmptend=mk3D(mygrid.RAC,budgO.tend).*budgO.tend;%Watt
budgO.fluxes.tend=tmptend;
budgO.tend=nansum(tmptend,3);
budgI.tend=mygrid.RAC.*budgI.tend;%Watt
%
budgOI.tend=budgO.tend+budgI.tend;

%vertical divergence (air-sea fluxes or vertical adv/dif)
budgO.zconv=TFLUX+geothFlux;
budgI.zconv=-(SItflux+TFLUX-TRELAX);
%in linear surface we omit :
if ~myparms.useNLFS; budgO.zconv=budgO.zconv-myparms.rcp*WTHMASS; end;
%in virtual salt flux we omit :
if ~myparms.useRFWF|~myparms.useNLFS; budgI.zconv=budgI.zconv+SIaaflux; end;
%working approach for real fresh water (?) and virtual salt flux
if 0; budgI.zconv=-oceQnet-SIatmQnt-myparms.flami*(SIsnPrcp-SIacSubl); end;
%
budgO.zdia=budgO.zconv;
%for deep ocean layer :
if kBudget>1;
  budgO.zconv=-(ADVr_TH+DFrE_TH+DFrI_TH)./mygrid.RAC*myparms.rcp;
  budgO.zdia=-(DFrE_TH+DFrI_TH)./mygrid.RAC*myparms.rcp;
  dd=mygrid.RF(kBudget); msk=mygrid.mskC(:,:,kBudget);
  swfrac=0.62*exp(dd/0.6)+(1-0.62)*exp(dd/20);
  if dd<-200; swfrac=0; end;
  budgO.zconv=budgO.zconv+swfrac*oceQsw+geothFlux;%.*msk;
  budgO.zdia=budgO.zdia+swfrac*oceQsw+geothFlux;%.*msk;
end;
%
%notes: - geothFlux remains to be accounted for in 3D case
%       - diaWtop, diaWbot remain to be implemented in 3D case
if test3d;
  trWtop=-(ADVr_TH+DFrE_TH+DFrI_TH)*myparms.rcp;
  %
  dd=mygrid.RF(1:end-1);
  swfrac=0.62*exp(dd/0.6)+(1-0.62)*exp(dd/20);
  swfrac(dd<-200)=0;
  swtop=mk3D(swfrac,trWtop).*mk3D(mygrid.RAC.*oceQsw,trWtop);
  swtop(isnan(mygrid.mskC))=0;
  trWtop=trWtop+swtop;
  %
  trWtop(:,:,1)=budgO.zconv.*mygrid.RAC;
  trWbot=trWtop(:,:,2:length(mygrid.RC));
  trWbot(:,:,length(mygrid.RC))=0;
  %
  budgO.fluxes.trWtop=trWtop;%Watt
  budgO.fluxes.trWbot=trWbot;%Watt
else;
  budgO.fluxes.trWtop=-mygrid.RAC.*(budgO.zconv-geothFlux);
  budgO.fluxes.trWbot=mygrid.RAC.*geothFlux;%Watt
  budgO.fluxes.diaWtop=-mygrid.RAC.*(budgO.zdia-geothFlux);
  budgO.fluxes.diaWbot=mygrid.RAC.*geothFlux;%Watt
end;
budgI.fluxes.trWtop=-mygrid.RAC.*(budgI.zconv+budgO.zconv);
budgI.fluxes.trWbot=-mygrid.RAC.*budgO.zconv;%Watt
%
budgO.zconv=mk3D(mygrid.RAC,budgO.zconv).*budgO.zconv;%Watt
budgI.zconv=mygrid.RAC.*budgI.zconv;%Watt
budgOI.zconv=budgO.zconv+budgI.zconv;

%horizontal divergence (advection and diffusion)
tmpUo=myparms.rcp*(ADVx_TH+DFxE_TH); tmpVo=myparms.rcp*(ADVy_TH+DFyE_TH);
budgO.hconv=calc_UV_conv(nansum(tmpUo,3),nansum(tmpVo,3));
%
tmpUoD=myparms.rcp*DFxE_TH; tmpVoD=myparms.rcp*DFyE_TH;
budgO.hdia=calc_UV_conv(nansum(tmpUoD,3),nansum(tmpVoD,3));
%
tmpUi=-myparms.flami*(myparms.rhoi*DFxEHEFF+myparms.rhosn*DFxESNOW+myparms.rhoi*ADVxHEFF+myparms.rhosn*ADVxSNOW);
tmpVi=-myparms.flami*(myparms.rhoi*DFyEHEFF+myparms.rhosn*DFyESNOW+myparms.rhoi*ADVyHEFF+myparms.rhosn*ADVySNOW);
budgI.hconv=calc_UV_conv(tmpUi,tmpVi); %no dh needed here
budgOI.hconv=budgO.hconv+budgI.hconv;
%
budgO.fluxes.trU=tmpUo; budgO.fluxes.trV=tmpVo;%Watt
budgO.fluxes.diaU=tmpUoD; budgO.fluxes.diaV=tmpVoD;%Watt
budgI.fluxes.trU=tmpUi; budgI.fluxes.trV=tmpVi;%Watt

