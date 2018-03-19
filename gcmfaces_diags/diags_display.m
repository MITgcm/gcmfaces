function [alldiag]=diags_display(dirMat,setDiags,dirTex,nameTex);
% [alldiag]=DIAGS_DISPLAY(dirMat,setDiags,dirTex,nameTex)
%    displays a set of diagnostics (setDiags) from the results
%    stored (in [dirMat 'diags_set_' setDiags]). 
%
%    Further outputs the results to tex ([dirTex nameTex '.tex'])
%    if dirTex and nameTex are specified. This functionality 
%    is normally operated via diags_driver_tex.m. If dirMat is 
%    specified as {dirMat,dirMatRef} then anomalies will be plotted. 
%
%    setDiags is the choice of diagnostics set such as
%                       'A') trasnports
%                       'B') air-sea fluxes
%                       'C') state variables
%                       'D') global and hemispheric budgets
%                       'MLD') mixed layer depths
%
%    In some cases more specific options can be specified, e.g. to 
%    display only subsurface budgets one may set setDiags={{'D',11}}
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%determine input/output params:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%directory names:
if iscell(dirMat); dirMatRef=dirMat{2}; dirMat=dirMat{1}; end;
dirMat=[dirMat '/'];
if isempty(who('dirMatRef')); dirMatRef=''; 
elseif ~isempty(dirMatRef); dirMatRef=[dirMatRef '/']; 
end;
if isempty(who('dirTex')); dirTex=''; else; dirTex=[dirTex '/']; end;
if isempty(who('nameTex')); nameTex='myPlots'; end;

%determine if and where to create tex and figures files
if ~ischar(dirTex); error('mis-specified dirTex'); end;
if isempty(dirTex);
    addToTex=1; fileTex='';
else;
    addToTex=1; fileTex=[dirTex nameTex '.tex'];
end;

%determined where to display anomalies between runs
doAnomalies=~isempty(dirMatRef);

%more params
setDiagsParams=[];
if iscell(setDiags);
    setDiagsParams={setDiags{2:end}};
    setDiags=setDiags{1};
end;

%%%%%%%%%%%%%%%%%%%%%%
%load grid and params:
%%%%%%%%%%%%%%%%%%%%%%

gcmfaces_global; global myparms;
test1=~isempty(dir([dirMat 'basic_diags_ecco_mygrid.mat']));
test2=~isempty(dir([dirMat 'diags_grid_parms.mat']));
if ~test1&&~test2;
  error('missing diags_grid_parms.mat')
elseif test2;
  nameGrid='diags_grid_parms.mat';
  suffDiag='diags_set_';
  budgetList='diags_select_budget_list.mat';
else;
  nameGrid='basic_diags_ecco_mygrid.mat';
  suffDiag='basic_diags_ecco_';
  budgetList='basic_diags_ecco_budget_list.mat';
end;

%reload myparms from dirMat (and mygrid if included the mat file)
eval(['load ' dirMat nameGrid ';']);

%reload mygrid if needed
if isfield(myparms,'dirGrid'); diags_grid(myparms.dirGrid,0); end;

%zonal mean and sections needed for transport computations
if ~isfield(mygrid,'mygrid.LATS_MASKS');
    gcmfaces_lines_zonal;
end;
if ~isfield(mygrid,'LINES_MASKS');
    [lonPairs,latPairs,names]=gcmfaces_lines_pairs;
    gcmfaces_lines_transp(lonPairs,latPairs,names);
end;

%backward compatibility:
if ~isfield(mygrid,'memoryLimit'); mygrid.memoryLimit=0; end;
if ~isfield(mygrid,'ioSize'); mygrid.ioSize=0; end;

%in case mygrid.memoryLimit=1, load the stuff that was not saved to diags_grid_parms.mat
if mygrid.memoryLimit==1;
        list0={'hFacS','hFacW'};
        for iFld=1:length(list0);
          eval(['mygrid.' list0{iFld} '=rdmds2gcmfaces([mygrid.dirGrid ''' list0{iFld} '*'']);']);
        end;
        %
        mygrid.hFacCsurf=mygrid.hFacC;
        for ff=1:mygrid.hFacC.nFaces; mygrid.hFacCsurf{ff}=mygrid.hFacC{ff}(:,:,1); end;
        %
        mskC=mygrid.hFacC; mskC(mskC==0)=NaN; mskC(mskC>0)=1; mygrid.mskC=mskC;
        mskW=mygrid.hFacW; mskW(mskW==0)=NaN; mskW(mskW>0)=1; mygrid.mskW=mskW;
        mskS=mygrid.hFacS; mskS(mskS==0)=NaN; mskS(mskS>0)=1; mygrid.mskS=mskS;
        %
        gcmfaces_lines_zonal;
        mygrid.LATS=[mygrid.LATS_MASKS.lat]';
        [lonPairs,latPairs,names]=gcmfaces_lines_pairs;
        gcmfaces_lines_transp(lonPairs,latPairs,names);
end;

%%%%%%%%%%%%%%
%define diags:
%%%%%%%%%%%%%%

%test for results organization
if isdir([dirMat 'diags_set_' setDiags]); 
    dirMat=[dirMat 'diags_set_' setDiags '/']; 
end;
if isdir([dirMatRef 'diags_set_' setDiags]); 
    dirMatRef=[dirMatRef 'diags_set_' setDiags '/']; 
end;

if strcmp(nameGrid,'diags_grid_parms.mat');
  %load listDiags and get fileMat (if applies)
  userStep=1;
  if ~isempty(which(['diags_set_' setDiags]));
    eval(['diags_set_' setDiags]);
  else;
    diags_set_user;
  end;

  %reformat listDiags to cell array:
  jj=strfind(listDiags,' '); jj=[0 jj length(listDiags)+1];
  for ii=1:length(jj)-1;
    tmp1=listDiags(jj(ii)+1:jj(ii+1)-1);
    if ii==1; listDiags2={tmp1}; else; listDiags2{ii}=tmp1; end;
  end;
  listDiags=listDiags2; clear listDiags2;
end;

%set fileMat to default name if needed
if isempty(who('fileMat')); fileMat=[suffDiag setDiags]; end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%are there results to display?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

test1=isempty(dir([dirMat '/' fileMat '_*.mat']));
tmp1=[dirMat '/' fileMat '_*.mat']; tmp2=strfind(tmp1,'_'); tmp1(tmp2)=' ';
if test1&&addToTex;
    eval(['load ' dirTex nameTex '.mat;']);
    write2tex(fileTex,3,{'[ ',mySection,' ]'},1);
    write2tex(fileTex,3,{'abort : did not find any'},1);
    write2tex(fileTex,3,{tmp1},1);
    write2tex(fileTex,3,{'results files to display'},1);
    return;
elseif test1;
    fprintf(['\n  abort : did not find any \n    ' tmp1 '\n    results files to display\n\n']);
    return;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%
%load pre-computed diags:
%%%%%%%%%%%%%%%%%%%%%%%%%

tic;

diagsWereLoaded=0;

%specific load sequence (if any, diagsWereLoaded will be set to 1)
if strcmp(nameGrid,'diags_grid_parms.mat');
  userStep=0;
  if ~isempty(which(['diags_set_' setDiags]));
    eval(['diags_set_' setDiags]);
  else;
    diags_set_user;
  end;
end;

%generic load (if no specific one, or )
if ~diagsWereLoaded;
  alldiag=diags_read_from_mat(dirMat,[fileMat '_*.mat']);
end;

toc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load ref and compute anomalies:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if doAnomalies;
    %     scaleAnom=10;
    scaleAnom=1;

    %store:
    dirMatBak=dirMat; dirMat=dirMatRef; alldiagBak=alldiag;

    %load reference solution:
    diagsWereLoaded=0;

    %specific load sequence (if any, diagsWereLoaded will be set to 1)
    if strcmp(nameGrid,'diags_grid_parms.mat');
      userStep=0;
      if ~isempty(which(['diags_set_' setDiags]));
        eval(['diags_set_' setDiags]);
      else;
        diags_set_user;
      end;
    end;

    %generic load (if no specific one, or )
    if ~diagsWereLoaded;
      alldiag=diags_read_from_mat(dirMat,[fileMat '_*.mat']);
    end;

    %restore:
    dirMat=dirMatBak; alldiagRef=alldiag; alldiag=alldiagBak;

    %compute anomalies:
    for ii=1:length(alldiag.listDiags);
        tmp0=alldiag.listDiags{ii};
        if ~strcmp(tmp0,'listTimes')&&~strcmp(tmp0,'listSteps')
        if isfield(alldiagRef,tmp0);%compute difference
            tmp1=getfield(alldiag,tmp0)-getfield(alldiagRef,tmp0);
            alldiag=setfield(alldiag,tmp0,tmp1);
        else;%cannot compute diff -> set to NaN
            tmp1=NaN*getfield(alldiag,tmp0);
            alldiag=setfield(alldiag,tmp0,tmp1);
        end;
        end;
    end;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%determine time parameters for plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%number of months for runmean
if myparms.diagsAreMonthly&&myparms.diagsNbRec>12;
  myNmean=6; %half window
  myNmeanTxt=[' -- ' num2str(myNmean*2) ' months low pass filtered'];
else;
  myNmean=0; myNmeanTxt='';
end;

%first and last year of time average
myYmean=myparms.yearInAve;
if myYmean(1)==myYmean(2); myYmeanTxt=[num2str(myYmean(1)) ' '];
else; myYmeanTxt=[num2str(myYmean(1)) '-' num2str(myYmean(2)) ' '];
end;

%to compute time mean/std on the fly
if length(alldiag.listTimes)>diff(myparms.recInAve)+1;
  tt=[myparms.recInAve(1):min(myparms.recInAve(2),length(alldiag.listTimes))];
  TT=alldiag.listTimes(tt);
else;
  tt=[1:length(alldiag.listTimes)]; 
  TT=alldiag.listTimes;
end;
nt=length(TT);

%if only one record, swicth off time series and variance plots
multiTimes=1*(myparms.recInAve(2)>myparms.recInAve(1));

%if llc90 we can plot overturn etc per basin
multiBasins=(sum([90 1170]~=mygrid.ioSize)==0);

%%%%%%%%%%%%%%%
%display diags:
%%%%%%%%%%%%%%%

userStep=-1;
if ~isempty(which(['diags_set_' setDiags]));
  eval(['diags_set_' setDiags]);
else;
  diags_set_user;
end;


