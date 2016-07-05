function []=example_budget();
%EXAMPLE_TRANSPORTS illustrates ECCO v4 budgets
%
%stand-alone call: addpath gcmfaces/sample_analysis/; example_budget;
%
%needed input files:
%  wget --recursive ftp://mit.ecco-group.org/gforget/nctiles_budget_2d
%  mv mit.ecco-group.org/gforget/nctiles_budget_2d sample_input/.
%  rm -rf mit.ecco-group.org
%
%note: in the nctiles_budget_2d files from 03-Feb-2015 the sign convention 
%   for trWtop and trWbot was positive downward; this sign convention was
%   reversed in later versions for consistency with MITgcm convention.

gcmfaces_global;

if myenv.verbose>0;
    gcmfaces_msg('===============================================');
    gcmfaces_msg(['*** entering example_budget ' ...
        'load budget terms from nctiles files ' ...
        'and compute hemispheric budgets'],'');
end;

%%%%%%%%%%%%%%%%%
%load grid:
%%%%%%%%%%%%%%%%%

%expected location:
myenv.nctilesdir=fullfile('sample_input',filesep,'nctiles_budget_2d',filesep);
%if nctiles_budget_2d is not found then try old location:
if ~isdir(myenv.nctilesdir);
    %if not found then try old location:
    tmpdir=fullfile(myenv.gcmfaces_dir,'/sample_input/nctiles_budget_2d/');
    if isdir(tmpdir); myenv.nctilesdir=tmpdir; end;
end;
%if nctiles_budget_2d is still not found then issue warning and skip example_budget
if ~isdir(myenv.nctilesdir);
    diags=[];
    help example_budget;
    warning(['skipping example_budget (missing ' myenv.nctilesdir ')']);
    return;
end;

dirName=fullfile(myenv.nctilesdir,filesep,'budgMo',filesep);

if ~isdir(dirName);
    help gcmfaces_demo;
    warning(['skipping example_budget (missing ' dirName ')']);
    return;
end;

if isempty(which('ncload'));
    warning(['skipping example_budget (missing ncload that is part of MITprof)']);
    return;
end;

%%%%%%%%%%%%%%%%%%
%main computation:
%%%%%%%%%%%%%%%%%%

%load grid:
if isempty(mygrid);
   grid_load;
end;

%select budget of interest
nameBudg='budgMo';

%load budget terms
fileName=[myenv.nctilesdir nameBudg filesep nameBudg(1:6)];
tend=read_nctiles(fileName,'tend');
trU=read_nctiles(fileName,'trU');
trV=read_nctiles(fileName,'trV');
trWtop=read_nctiles(fileName,'trWtop');
trWbot=read_nctiles(fileName,'trWbot');

%load dt (time increments) vector (not a gcmfaces object)
ncload([fileName '.0001.nc'],'dt');

%get budget descitption and units
ncid = netcdf.open([fileName '.0001.nc'],'NC_NOWRITE');
descr = netcdf.getAtt(ncid,netcdf.getConstant('NC_GLOBAL'),'description');
varid = netcdf.inqVarID(ncid,'tend');
units = netcdf.getAtt(ncid,varid,'units');
netcdf.close(ncid);

if myenv.verbose>0; gcmfaces_msg(['* display Northern Hemisphere budget for ' nameBudg ' (' descr ')']);end;

%define northern hemisphere as domain of integration
nameMask='Northern Hemisphere';
mask=mygrid.mskC(:,:,1).*(mygrid.YC>0); 
areaMask=mygrid.RAC.*mask;

%edit plot title accordingly
tmp1=strfind(descr,'-- ECCO v4');
descr=[descr(1:tmp1-1) 'for: ' nameMask];

%compute northern hemisphere integrals
budg.tend=NaN*dt;
budg.hconv=NaN*dt;
budg.zconv=NaN*dt;
for tt=1:length(dt);
    %compute flux convergence
    hconv=calc_UV_conv(trU(:,:,tt),trV(:,:,tt));
    zconv=trWtop(:,:,tt)-trWbot(:,:,tt);
    %compute sum over domain
    budg.tend(tt)=nansum(tend(:,:,tt).*mask)/nansum(areaMask);
    budg.hconv(tt)=nansum(hconv.*mask)/nansum(areaMask);
    budg.zconv(tt)=nansum(zconv.*mask)/nansum(areaMask);
end;

%display result
figureL;
subplot(3,1,1); set(gca,'FontSize',12);
plot(cumsum(dt.*budg.tend));
grid on; xlabel('month'); ylabel([units ' x s']);
legend('content anomaly');
subplot(3,1,2); set(gca,'FontSize',12);
plot(cumsum(dt.*budg.tend)); hold on;
plot(cumsum(dt.*budg.hconv),'r'); 
plot(cumsum(dt.*budg.zconv),'g');
grid on; xlabel('month'); ylabel([units ' x s']);
legend('content anomaly','horizontal convergence','vertical convergence');
subplot(3,1,3); set(gca,'FontSize',12);
plot(cumsum(dt.*(budg.tend-budg.hconv-budg.zconv))); 
grid on; xlabel('month'); ylabel([units ' x s']);
legend('budget residual');

if myenv.verbose>0;
    gcmfaces_msg('*** leaving example_budget ','');
    gcmfaces_msg('===============================================');
end;

