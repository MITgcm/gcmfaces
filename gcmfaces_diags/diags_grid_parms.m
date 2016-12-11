function []=diags_grid_parms(dirModel,listTimes,doInteractive);
%object :      load grid, set params, and save myparms to dirMat
%input :       listTimes is the time list obtained from diags_list_times
%(optional)    doInteractive=1 allows users to specify parameters interactively
%                     doInteractive = 0 (default) uses ECCO v4 parameters
%                     and omits budgets and model-data misfits analyses

%global variables
gcmfaces_global;
global myparms;

%load grid
diags_grid(dirModel,doInteractive);

%set default for model run parameters
if doInteractive;
    choiceParams=input(['choice of default parameters? (1=ecco v4, ' ...
                 '2=core, 3=ecco2 adjoint, 4=ecco v3, 5=core-Jeff)\n']);
else;
    choiceParams=1;
end;
myparms=default_parms(myparms,choiceParams);

%allow user to change model params if necessary
myparms=review_parms(myparms,listTimes,doInteractive);

function [parms]=default_parms(parms,choiceParams);
%set model parameters to default (ecco_v4)

if choiceParams==1|choiceParams==2|choiceParams==4|choiceParams==5;
parms.yearFirst=1992; %first year covered by model integration
parms.yearLast =2011; %last year covered by model integration
parms.yearInAve=[parms.yearFirst parms.yearLast]; %period for time averages and variance computations
parms.timeStep =3600; %model time step for tracers
parms.iceModel =1;%0=use freezing point   1=use pkg/seaice   2=use pkg/thsice
parms.useRFWF  =1;%1=real fresh water flux 0=virtual salt flux
parms.useNLFS  =2;%2=rstar 1=nlfs 0=linear free surface
parms.rhoconst =1029; %sea water density
parms.rcp      =3994*parms.rhoconst; % sea water rho X heat capacity
parms.rhoi     = 910; %sea ice density
parms.rhosn    = 330; %snow density
parms.flami    = 3.34e05; % latent heat of fusion of ice/snow (J/kg)
parms.flamb    = 2.50e06; % latent heat of evaporation (J/kg)
parms.SIsal0   =4;
if choiceParams==2;
  parms.yearFirst=1948; %first year covered by model integration
  parms.yearLast =2007; %last year covered by model integration
  parms.yearInAve = [1948 2007];
end;
if choiceParams==4;
  parms.useRFWF  =0;%1=real fresh water flux 0=virtual salt flux
  parms.useNLFS  =0;%2=rstar 1=nlfs 0=linear free surface
end;
if choiceParams==5;
 parms.yearFirst=2006; %first year covered by model integration
 parms.yearLast =2305; %last year covered by model integration
 parms.yearInAve = [2006 2305];
end;
end;

if choiceParams==3;
        parms.yearFirst=2004; %first year covered by model integration
        parms.yearLast =2005; %last year covered by model integration
        parms.yearInAve=[parms.yearFirst parms.yearLast]; %period for time averages and variance computations
        parms.timeStep =1200; %model time step for tracers
        parms.iceModel =1;%0=use freezing point   1=use pkg/seaice   2=use pkg/thsice
        parms.useRFWF  =0;%1=real fresh water flux 0=virtual salt flux
        parms.useNLFS  =0;%2=rstar 1=nlfs 0=linear free surface
        parms.rhoconst =1027.5; %sea water density
        parms.rcp      =3994*parms.rhoconst; % sea water rho X heat capacity
        parms.rhoi     = 910; %sea ice density
        parms.rhosn    = 330; %snow density
        parms.flami    = 3.34e05; % latent heat of fusion of ice/snow (J/kg)
        parms.flamb    = 2.50e06; % latent heat of evaporation (J/kg)
        parms.SIsal0   = 0;
end;

function [parms]=review_parms(parms,listTimes,doInteractive);
%review model parameters, correct them if needed, and check a couple more things

test1=1;%so that we print params at least once
while test1;
    fprintf('\n\n');
    gcmfaces_msg('model parameters summary','==== ');
    
    tmp1=sprintf('parms.yearFirst  = %i (first year covered by model integration)',parms.yearFirst); gcmfaces_msg(tmp1,'== ');
    tmp1=sprintf('parms.yearLast   = %i (first year covered by model integration)',parms.yearLast);  gcmfaces_msg(tmp1,'== ');
    tmp1=sprintf('parms.yearInAve  = [%i %i] (time mean and variance years)',parms.yearInAve);  gcmfaces_msg(tmp1,'== ');
    tmp1=sprintf('parms.timeStep   = %i (model time step for tracers)',parms.timeStep);  gcmfaces_msg(tmp1,'== ');
    tmp1=sprintf('parms.iceModel   = %i (0=freezing point  1=pkg/seaice  2=pkg/thsice)',parms.iceModel);  gcmfaces_msg(tmp1,'== ');
    tmp1=sprintf('parms.useRFWF    = %i (1=real fresh water flux 0=virtual salt flux)',parms.useRFWF);  gcmfaces_msg(tmp1,'== ');
    tmp1=sprintf('parms.useNLFS    = %i; (2=rstar 1=nlfs 0=linear free surface)',parms.useNLFS);  gcmfaces_msg(tmp1,'== ');
    tmp1=sprintf('parms.rhoconst   = %0.6g (sea water density)',parms.rhoconst);  gcmfaces_msg(tmp1,'== ');
    tmp1=sprintf('parms.rcp        = %0.6g (sea water density X heat capacity)',parms.rcp);  gcmfaces_msg(tmp1,'== ');
    if parms.iceModel==1;
        tmp1=sprintf('parms.rhoi       = %0.6g (sea ice density)',parms.rhoi);  gcmfaces_msg(tmp1,'== ');
        tmp1=sprintf('parms.rhosn      = %0.6g (snow density)',parms.rhosn);  gcmfaces_msg(tmp1,'== ');
        tmp1=sprintf('parms.flami      = %0.6g (latent heat of fusion of ice/snow in J/kg)',parms.flami);  gcmfaces_msg(tmp1,'== ');
        tmp1=sprintf('parms.flamb      = %0.6g (latent heat of evaporation in J/kg)',parms.flamb);  gcmfaces_msg(tmp1,'== ');
        tmp1=sprintf('parms.SIsal0     = %0.6g (sea ice constant salinity)',parms.SIsal0);  gcmfaces_msg(tmp1,'== ');
        %tmp1=sprintf('',);  gcmfaces_msg(tmp1,'== ');
    else;
        error('only parms.iceModel=1 is currently treated\n');
    end;
    
    if doInteractive;
      gcmfaces_msg('to change a param type e.g. ''parms.yearFirst=1;'' or hit return if all params are ok. Change a param?','==== ');
      tmp1=input('');
      test1=~isempty(tmp1); %so that we change param and iterate process
      if test1; eval(tmp1); end;
    else;
      test1=[];
    end;    
end;

%determine a few more things about the diagnostic time axis
fprintf('\n\n');
parms.diagsNbRec=length(listTimes);
test1=median(diff(listTimes)*parms.timeStep/86400);
if abs(test1-30.5)<1; parms.diagsAreMonthly=1; else; parms.diagsAreMonthly=0; end;
if abs(test1-365.25)<1; parms.diagsAreAnnual=1; else; parms.diagsAreAnnual=0; end;
if doInteractive;
   tmp1=sprintf('parms.diagsNbRec       = %i (number of records, based on model output files)',parms.diagsNbRec); gcmfaces_msg(tmp1,'== ');
   tmp1=sprintf('parms.diagsAreMonthly  = %i (0/1 = false/true; based on output frequency)',parms.diagsAreMonthly); gcmfaces_msg(tmp1,'== ');
   tmp1=sprintf('parms.diagsAreAnnual   = %i (0/1 = false/true; based on output frequency)',parms.diagsAreAnnual); gcmfaces_msg(tmp1,'== ');
   gcmfaces_msg('hit return if this seems correct otherwise stop here','== '); test0=input(''); if ~isempty(test0); error('likely dir problem'); end;
end;

listTimes2=parms.yearFirst+listTimes*parms.timeStep/86400/365.25;%this approximation of course makes things simpler
tmp1=-0.5*diff(listTimes,1,1)*parms.timeStep/86400/365.25; tmp1=[median(tmp1);tmp1];
listTimes2=listTimes2+tmp1;%this converts the enddate to the middate of pkg/diags
ii=find(listTimes2>=parms.yearInAve(1)&listTimes2<=parms.yearInAve(2)+1);
if parms.diagsAreMonthly;%then restrict to full years
    ni=floor(length(ii)/12)*12; 
    if ni>0; 
      parms.recInAve=[ii(1) ii(floor(ni))];
    else;
      parms.recInAve=[ii(1) ii(end)];
    end;
elseif ~isempty(ii);
    parms.recInAve=[ii(1) ii(end)];
else;
    parms.recInAve=[1 1];
end;
if doInteractive; 
  tmp1=sprintf('parms.recInAve  = [%i %i] (time mean and variance records)',parms.recInAve);  gcmfaces_msg(tmp1,'== ');
end;

fprintf('\n\n');

