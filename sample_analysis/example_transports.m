function [diags]=example_transports();
%EXAMPLE_TRANSPORTS computes transports (and zonal averages)
%
% Note: this demonstration routine includes its own call to grid_load
%
% Example:
%          addpath gcmfaces/; gcmfaces_global; myenv.verbose=1;
%          [diags]=example_transports();
%          example_transports_disp(diags);

gcmfaces_global;
if myenv.verbose>0;
    gcmfaces_msg('===============================================');
    gcmfaces_msg(['*** entering example_transports: ' ...
        'load flow field form nctiles file and compute transports'],'');
end;

%%%%%%%%%%%%%%%%%
%load grid:
%%%%%%%%%%%%%%%%%

if isempty(mygrid);
   grid_load;
end;

myenv.nctilesdir=fullfile('release1',filesep,'nctiles_climatology',filesep);

if ~isdir(myenv.nctilesdir);
    diags=[];
    help gcmfaces_demo;
    warning(['skipping example_transports (missing ' myenv.nctilesdir ')']);
    return;
end;

if myenv.verbose>0;
    gcmfaces_msg('* call gcmfaces_lines_zonal : determine grid lines that closely follow');
    gcmfaces_msg('parallel lines and will be used in zonal mean and overturning computations','  ');
end;
gcmfaces_lines_zonal;

if myenv.verbose>0;
    gcmfaces_msg('* call gcmfaces_lines_transp : determine grid lines that closely follow');
    gcmfaces_msg('great circles and will be used to compute transsects transports','  ');
end;
% warning('skipping gcmfaces_lines_transp\n');
[lonPairs,latPairs,names]=gcmfaces_lines_pairs;
gcmfaces_lines_transp(lonPairs,latPairs,names);

%%%%%%%%%%%%%%%%%
%do computations:
%%%%%%%%%%%%%%%%%

listDiags={};

% [listTimes]=diags_list_times;
diags.listTimes=1;

%part 1:

listVars={'UVELMASS','VVELMASS'};
missingVars={};
for vv=1:length(listVars);
  tmp1=[myenv.nctilesdir listVars{vv} filesep listVars{vv} '*nc'];
  if isempty(dir(tmp1)); missingVars={missingVars{:},tmp1}; end;
end;

if ~isempty(missingVars);
    fprintf('\n example_transports could not find the following files ---> skipping related computation!\n');
    disp(missingVars');
else;

if myenv.verbose>0; gcmfaces_msg('* call read_nctiles : load velocity fields');end;

for vvv=1:length(listVars);
    vv=listVars{vvv};
    tmp1=read_nctiles([myenv.nctilesdir vv '/' vv],vv);
    tmp1=mean(tmp1,4);
    tmp1(mygrid.mskC==0)=NaN;
    eval([vv '=tmp1;']);
end;

UVELMASS=UVELMASS.*mygrid.mskW;
VVELMASS=VVELMASS.*mygrid.mskS;

listDiags={listDiags{:},'fldBAR','gloOV','fldTRANSPORTS','gloMT_FW'};
if myenv.verbose>0; gcmfaces_msg('* call calc_barostream : comp. barotropic stream function');end;
[fldBAR]=calc_barostream(UVELMASS,VVELMASS);
if myenv.verbose>0; gcmfaces_msg('* call calc_overturn : comp. overturning stream function');end;
[gloOV]=calc_overturn(UVELMASS,VVELMASS);
if myenv.verbose>0; gcmfaces_msg('* call calc_transports : comp. transects transports');end;
[fldTRANSPORTS]=1e-6*calc_transports(UVELMASS,VVELMASS,mygrid.LINES_MASKS,{'dh','dz'});
if myenv.verbose>0; gcmfaces_msg('* call calc_MeridionalTransport : comp. meridional seawater transport');end;
[gloMT_FW]=1e-6*calc_MeridionalTransport(UVELMASS,VVELMASS,1);

end;%if ~isempty(missingVars);

%part 2:

listVars={'THETA','SALT','ADVx_TH','ADVy_TH','ADVx_SLT','ADVy_SLT'};
listVars={listVars{:},'DFxE_TH','DFyE_TH','DFxE_SLT','DFyE_SLT'};

missingVars={};
for vv=1:length(listVars);
  tmp1=[myenv.nctilesdir listVars{vv} filesep listVars{vv} '*nc'];
  if isempty(dir(tmp1)); missingVars={missingVars{:},tmp1}; end;
end;

if ~isempty(missingVars);
    fprintf('\n example_transports could not find the following files ---> skipping related computation!\n');
    disp(missingVars');
else;

if myenv.verbose>0; gcmfaces_msg('* load tracer and transports fields');end;
listDiags={listDiags{:},'fldTzonmean','fldSzonmean','gloMT_H','gloMT_SLT'};
for vvv=1:length(listVars);
    vv=listVars{vvv};
    tmp1=read_nctiles([myenv.nctilesdir vv '/' vv],vv);
    tmp1=mean(tmp1,4);
    tmp1(mygrid.mskC==0)=NaN;
    eval([vv '=tmp1;']);
end;

if myenv.verbose>0; gcmfaces_msg('* call calc_zonmean_T : comp. zonal mean temperature');end;
[fldTzonmean]=calc_zonmean_T(THETA);
if myenv.verbose>0; gcmfaces_msg('* call calc_zonmean_T : comp. zonal mean salinity');end;
[fldSzonmean]=calc_zonmean_T(SALT);

if myenv.verbose>0; gcmfaces_msg('* call calc_MeridionalTransport : comp. meridional heat transport');end;
tmpU=(ADVx_TH+DFxE_TH); tmpV=(ADVy_TH+DFyE_TH);
[gloMT_H]=1e-15*4e6*calc_MeridionalTransport(tmpU,tmpV,0);
if myenv.verbose>0; gcmfaces_msg('* call calc_MeridionalTransport : comp. meridional salt transport');end;
tmpU=(ADVx_SLT+DFxE_SLT); tmpV=(ADVy_SLT+DFyE_SLT);
[gloMT_SLT]=1e-6*calc_MeridionalTransport(tmpU,tmpV,0);

end;%if ~isempty(missingVars);

%part 3: format output

for ddd=1:length(listDiags);
    dd=listDiags{ddd};
    eval(['diags.' dd '=' dd ';']);
end;

if myenv.verbose>0;
    gcmfaces_msg('*** leaving example_transports');
    gcmfaces_msg('===============================================','');
end;

