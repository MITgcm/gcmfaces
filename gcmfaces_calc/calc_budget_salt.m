function [budgO,budgI,budgOI]=calc_budget_salt(kBudget);
% CALC_BUDGET_SALT(kBudget)
%
% note: within this routine `SALT', `SIheff', and `SIhsnow' denote
%  the corresponding tendencies as computed by diags_diff_snapshots.m
%  rather than the state variables themselves.

gcmfaces_global;

%get variables from caller routine:
%----------------------------------

global myparms;

list_variables={'SALT','AB_gS','SRELAX','SIheff',...
'SFLUX','oceSPflx','oceSflux','WSLTMASS',...
'ADVx_SLT','DFxE_SLT','ADVy_SLT','DFyE_SLT',...
'ADVxHEFF','ADVxSNOW','DFxEHEFF','DFxESNOW',...
'ADVyHEFF','ADVySNOW','DFyEHEFF','DFyESNOW'};

for vv=1:length(list_variables);
  v = evalin('caller',list_variables{vv});
  eval([list_variables{vv} '=v;']);
end;
clear v;

test3d=length(size(ADVx_SLT{1}))>2;

if test3d|kBudget>1;
  list_variables={'oceSPtnd','ADVr_SLT','DFrE_SLT',...
  'DFrI_SLT','ADVr_SLT','DFrE_SLT','DFrI_SLT'};
  for vv=1:length(list_variables);
    v = evalin('caller',list_variables{vv});
    eval([list_variables{vv} '=v;']);
  end;
  clear v;
end;

%compute mapped budget:
%----------------------

budgO.tend=myparms.rhoconst*SALT-myparms.rhoconst*AB_gS;
budgI.tend=myparms.SIsal0*myparms.rhoi*SIheff;
%
tmptend=mk3D(mygrid.RAC,budgO.tend).*budgO.tend;%g/s
budgO.fluxes.tend=tmptend;
budgO.tend=nansum(tmptend,3);
budgI.tend=mygrid.RAC.*budgI.tend;%g/s
%
budgOI.tend=budgO.tend+budgI.tend;

%vertical divergence (air-sea fluxes or vertical adv/dif)
budgO.zconv=SFLUX+oceSPflx;
budgI.zconv=-budgO.zconv+SRELAX;
%in linear surface we omit :
if ~myparms.useNLFS; budgO.zconv=budgO.zconv-myparms.rhoconst*WSLTMASS; end;
%working approach for real fresh water (?) and virtual salt flux
if ~myparms.useRFWF|~myparms.useNLFS; budgI.zconv=-oceSflux; end;
%
budgO.zdia=budgO.zconv;
%for deep ocean layer :
if kBudget>1;
  budgO.zconv=-(ADVr_SLT+DFrE_SLT+DFrI_SLT)./mygrid.RAC*myparms.rhoconst;
  budgO.zconv=budgO.zconv+oceSPtnd;%.*msk;
  budgO.zdia=-(DFrE_SLT+DFrI_SLT)./mygrid.RAC*myparms.rhoconst;
  budgO.zdia=budgO.zdia+oceSPtnd;%.*msk;
end;
%
if test3d;
  nr=length(mygrid.RC);
  trWtop=-(ADVr_SLT+DFrE_SLT+DFrI_SLT)*myparms.rhoconst;
  tmp1=mk3D(oceSPflx,oceSPtnd)-cumsum(oceSPtnd,3);
  tmp1=tmp1.*mk3D(mygrid.RAC,tmp1);
  trWtop(:,:,2:nr)=trWtop(:,:,2:nr)+tmp1(:,:,1:nr-1);
  %
  trWtop(:,:,1)=budgO.zconv.*mygrid.RAC;
  trWbot=trWtop(:,:,2:length(mygrid.RC));
  trWbot(:,:,length(mygrid.RC))=0;
  %
  budgO.fluxes.trWtop=trWtop;%kg/s
  budgO.fluxes.trWbot=trWbot;%kg/s
else;
  budgO.fluxes.trWtop=-mygrid.RAC.*budgO.zconv;
  budgO.fluxes.trWbot=mygrid.RAC*0;%kg/s
  budgO.fluxes.diaWtop=-mygrid.RAC.*budgO.zdia;
  budgO.fluxes.diaWbot=mygrid.RAC*0;%kg/s
end;
budgI.fluxes.trWtop=0*mygrid.RAC;
budgI.fluxes.trWbot=budgO.fluxes.trWtop(:,:,1);%kg/s
%
budgO.zconv=mk3D(mygrid.RAC,budgO.zconv).*budgO.zconv;%Watt
budgI.zconv=mygrid.RAC.*budgI.zconv;%Watt
%
budgOI.zconv=budgO.zconv+budgI.zconv;

%horizontal divergence (advection and diffusion)
tmpUo=myparms.rhoconst*(ADVx_SLT+DFxE_SLT); 
tmpVo=myparms.rhoconst*(ADVy_SLT+DFyE_SLT);
budgO.hconv=calc_UV_conv(nansum(tmpUo,3),nansum(tmpVo,3));
%
tmpUoD=myparms.rhoconst*(DFxE_SLT);
tmpVoD=myparms.rhoconst*(DFyE_SLT);
budgO.hdia=calc_UV_conv(nansum(tmpUoD,3),nansum(tmpVoD,3));
%
tmpUi=myparms.SIsal0*(myparms.rhoi*DFxEHEFF+myparms.rhoi*ADVxHEFF);
tmpVi=myparms.SIsal0*(myparms.rhoi*DFyEHEFF+myparms.rhoi*ADVyHEFF);
budgI.hconv=calc_UV_conv(tmpUi,tmpVi); %no dh needed here
budgOI.hconv=budgO.hconv+budgI.hconv;
%
budgO.fluxes.trU=tmpUo; budgO.fluxes.trV=tmpVo;%g/s
budgO.fluxes.diaU=tmpUoD; budgO.fluxes.diaV=tmpVoD;%g/s
budgI.fluxes.trU=tmpUi; budgI.fluxes.trV=tmpVi;%g/s

