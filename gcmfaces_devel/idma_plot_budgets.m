
%'budgMo' ocean mass budget (volume*rhoconst)
%'budgHo' ocean heat budget
%'budgSo' ocean salt budget
%'budgMi' seaice+snow mass budget
%'budgHi' seaice+snow heat budget
%'budgSi' seaice+snow salt budget

budgName='budgHo'
nt=238
nk=10;
doRes=0;

dirIn=[dir0 '/release1/nctiles_budg/' budgName '/'];

%constant parameters:
parms.rhoconst =1029; %sea water density
parms.rcp      =3994*parms.rhoconst; % sea water rho X heat capacity
parms.rhoi     = 910; %sea ice density
parms.rhosn    = 330; %snow density
parms.flami    = 3.34e05; % latent heat of fusion of ice/snow (J/kg)
parms.flamb    = 2.50e06; % latent heat of evaporation (J/kg)

%reference grid cell volumes:
tmp1=mk3D(mygrid.DRF,mygrid.hFacC).*mygrid.hFacC;
tmp3=mk3D(mygrid.RAC,tmp1);
vol0=tmp3.*(tmp1);

switch budgName;
case 'budgMo'; fac=parms.rhoconst;
case 'budgHo'; fac=parms.rcp;
case 'budgSo'; fac=parms.rhoconst;
case 'budgMi'; FACheff=myparms.rhoi; FACsnow=myparms.rhosn;
case 'budgHi'; FACheff=-myparms.flami*myparms.rhoi; FACsnow=-myparms.flami*myparms.rhosn;
case 'budgSi'; FACheff=myparms.SIsal0*myparms.rhoi; FACsnow=0;
end;

budgIn=[];

budgIn.ini=read_nctiles([dirIn 'initial/snapshot'],'snapshot');
budgIn.fin=read_nctiles([dirIn 'final/snapshot'],'snapshot');
eval(['ncload ' dirIn 'tend/tend.0001.nc t0']);
eval(['ncload ' dirIn 'tend/tend.0001.nc t1']);
budgIn.dt=t1-t0;

increments=repmat(NaN*mygrid.RAC,[1 1 nt]);

switch budgName;
case 'budgMo'; 
  ini=nansum(budgIn.ini-fac*vol0,3)./mygrid.RAC/fac;
  fin=nansum(budgIn.fin-fac*vol0,3)./mygrid.RAC/fac;
case 'budgHo';
  ini=nansum(budgIn.ini(:,:,1:nk),3)./nansum(vol0(:,:,1:nk),3)/fac;
  fin=nansum(budgIn.fin(:,:,1:nk),3)./nansum(vol0(:,:,1:nk),3)/fac;
otherwise; error('not implemented yet');
end;

for tt=1:nt;
  disp(tt)
  %load the various fields:
  budgIn.tend=read_nctiles([dirIn 'tend/tend'],'tend',tt);
  budgIn.trU=read_nctiles([dirIn 'trU/trU'],'trU',tt);
  budgIn.trV=read_nctiles([dirIn 'trV/trV'],'trV',tt);
  if dirIn(end-1)=='o';
    budgIn.trW=read_nctiles([dirIn 'trW/trW'],'trW',tt);
    budgIn.trWtop=budgIn.trW;
    budgIn.trWbot=budgIn.trW(:,:,2:50);
    budgIn.trWbot(:,:,50)=0;
  else;
    budgIn.trWtop=read_nctiles([dirIn 'trWtop/trWtop'],'trWtop',tt);
    budgIn.trWbot=read_nctiles([dirIn 'trWbot/trWbot'],'trWbot',tt);
  end;
  %compute budget residuals:
  if doRes;
    nr=size(budgIn.tend{1},3);
    for kk=1:nr; prec(kk,:)=check_budg(budgIn,kk); end;
    if tt==1;
      store_prec=prec;
    else;
      store_prec(:,:,tt)=prec;
    end;
  end;
  %reconstruct time series from budget
  switch budgName;
  case 'budgMo'; 
    increments(:,:,tt)=budgIn.dt(tt)*nansum(budgIn.tend,3)./mygrid.RAC/fac;
  case 'budgHo';
    increments(:,:,tt)=budgIn.dt(tt)*nansum(budgIn.tend(:,:,1:nk),3)...
                       ./nansum(vol0(:,:,1:nk),3)/fac;
  otherwise; error('not implemented yet');
  end;

end;%for tt=[1 119 238];

