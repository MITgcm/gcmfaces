function [budgO,budgI,budgOI]=calc_budget_mass(kBudget);
% CALC_BUDGET_MASS(kBudget,doMoreBudgetOutput)

gcmfaces_global;

%get variables from caller routine:
%----------------------------------

global myparms;

list_variables={'ETAN','SIheff','SIhsnow','oceFWflx','SIatmFW','oceFWflx',...
                'UVELMASS','VVELMASS',...
                'ADVxHEFF','ADVxSNOW','DFxEHEFF','DFxESNOW',...
                'ADVyHEFF','ADVySNOW','DFyEHEFF','DFyESNOW'};

for vv=1:length(list_variables);
  v = evalin('caller',list_variables{vv});
  eval([list_variables{vv} '=v;']);
end;
clear v;

test3d=length(size(UVELMASS{1}))>2;

if test3d|kBudget>1;
  list_variables={'WVELMASS'};
  for vv=1:length(list_variables);
    v = evalin('caller',list_variables{vv});
    eval([list_variables{vv} '=v;']);
  end;
  clear v;
end;

%compute mapped budget:
%----------------------

%mass = myparms.rhoconst * sea level
budgO.tend=ETAN*myparms.rhoconst;
budgI.tend=(SIheff*myparms.rhoi+SIhsnow*myparms.rhosn);
%for deep ocean layer :
if kBudget>1&myparms.useNLFS<2;
  budgO.tend=0;
elseif kBudget>1;%rstar case
  tmp1=mk3D(mygrid.DRF,mygrid.hFacC).*mygrid.hFacC;
  tmp2=sum(tmp1(:,:,kBudget:length(mygrid.RC)),3)./mygrid.Depth;
  budgO.tend=tmp2.*ETAN*myparms.rhoconst;
end;
%
if test3d;
  tmp1=mk3D(mygrid.DRF,mygrid.hFacC).*mygrid.hFacC;
  tmp2=tmp1./mk3D(mygrid.Depth,tmp1);
  budgO.tend=tmp2.*mk3D(ETAN,tmp2)*myparms.rhoconst;
end;
%
tmptend=mk3D(mygrid.RAC,budgO.tend).*budgO.tend;%kg/s
budgO.fluxes.tend=tmptend;
budgO.tend=nansum(tmptend,3);
budgI.tend=mygrid.RAC.*budgI.tend;%kg/s
budgOI.tend=budgO.tend+budgI.tend;

%vertical divergence (air-sea fluxes or vertical advection)
budgO.zconv=oceFWflx;
budgI.zconv=SIatmFW-oceFWflx;
%in virtual salt flux we omit :
if ~myparms.useRFWF; budgO.zconv=0*budgO.zconv; end;
%for deep ocean layer :
if kBudget>1; budgO.zconv=-WVELMASS*myparms.rhoconst; end;
%
if test3d;
  trWtop=-WVELMASS*myparms.rhoconst;
  %trWtop(:,:,1)=budgO.zconv;
  trWbot=trWtop(:,:,2:length(mygrid.RC));
  trWbot(:,:,length(mygrid.RC))=0;
  %
  budgO.fluxes.trWtop=mk3D(mygrid.RAC,trWtop).*trWtop;
  budgO.fluxes.trWbot=mk3D(mygrid.RAC,trWbot).*trWbot;%kg/s
else;
  budgO.fluxes.trWtop=-mygrid.RAC.*budgO.zconv; 
  budgO.fluxes.trWbot=mygrid.RAC*0;%kg/s
end;
budgI.fluxes.trWtop=-mygrid.RAC.*(budgI.zconv+budgO.zconv); 
budgI.fluxes.trWbot=-mygrid.RAC.*budgO.zconv;%kg/s
%
budgO.zconv=mk3D(mygrid.RAC,budgO.zconv).*budgO.zconv;%kg/s
budgI.zconv=mygrid.RAC.*budgI.zconv;%kg/s
budgOI.zconv=budgO.zconv+budgI.zconv;

%horizontal divergence (advection and ice diffusion)
if test3d; 
  %3D UVELMASS,VVELMASS are multiplied by DRF
  %(2D diagnostics are expectedly vertically integrated by MITgcm)
  tmp1=mk3D(mygrid.DRF,UVELMASS);
  UVELMASS=tmp1.*UVELMASS;
  VVELMASS=tmp1.*VVELMASS;
end;
dxg=mk3D(mygrid.DXG,VVELMASS); dyg=mk3D(mygrid.DYG,UVELMASS);
tmpUo=myparms.rhoconst*dyg.*UVELMASS;
tmpVo=myparms.rhoconst*dxg.*VVELMASS;
budgO.hconv=calc_UV_conv(nansum(tmpUo,3),nansum(tmpVo,3));
tmpUi=(myparms.rhoi*DFxEHEFF+myparms.rhosn*DFxESNOW+...
       myparms.rhoi*ADVxHEFF+myparms.rhosn*ADVxSNOW);
tmpVi=(myparms.rhoi*DFyEHEFF+myparms.rhosn*DFyESNOW+...
       myparms.rhoi*ADVyHEFF+myparms.rhosn*ADVySNOW);
budgI.hconv=calc_UV_conv(tmpUi,tmpVi); %dh needed is alerady in DFxEHEFF etc
%
budgOI.hconv=budgO.hconv;
budgOI.hconv(:,:,1)=budgOI.hconv(:,:,1)+budgI.hconv;
%
budgO.fluxes.trU=tmpUo; budgO.fluxes.trV=tmpVo;%kg/s
budgI.fluxes.trU=tmpUi; budgI.fluxes.trV=tmpVi;%kg/s

