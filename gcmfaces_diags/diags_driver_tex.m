function []=diags_driver_tex(dirMat,setDiags,dirTex,nameTex);
% DIAGS_DRIVER_TEX(dirMat,setDiags,dirTex,nameTex)
%
%    displays multiple sets of diagnostics (setDiags={'profiles',
%    'cost','A','B','C','MLD','D'} by default) from the results
%    stored in dirMat and outputs the plots to tex 
%    ([dirTex nameTex '.tex'] and [dirTex nameTex '*.eps'])
%
%    setDiags is the choice of diagnostics (cell) that may include
%                       'profiles') model to insitu data comparison
%                       'cost') ssh etc. cost functions
%                       'A') trasnports
%                       'B') air-sea fluxes
%                       'C') state variables
%                       'D') global and hemispheric budgets
%                       'MLD') mixed layer depths
%                       'SEAICE') seaice fields
%                       'controls') control vector adjustments

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

%set default setDiags and myTitle
if isempty(setDiags);
  setDiags={'profiles','cost','A','B','C','MLD','D'};
  if strcmp(nameTex,'myPlots'); nameTex='standardAnalysis'; end;
  %
  tmp1=dirMat; tmp2=strfind(tmp1,'_'); tmp1(tmp2)=' ';
  myTitle={'gcmfaces','standard analysis of the solution in',tmp1};
else;
  tmp1=dirMat; tmp2=strfind(tmp1,'_'); tmp1(tmp2)=' ';
  myTitle={'gcmfaces analysis of the solution in',tmp1};
end;

%set fileTex and create dirTex if needed
if isempty(dirTex); error('dirTex must be specified'); end;
fileTex=[dirTex nameTex '.tex'];
if isempty(dir(dirTex)); mkdir(dirTex); end;

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%finalize listDiags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%determined where to display anomalies between runs
doAnomalies=~isempty(dirMatRef);

%check if result is here to plot
doBudget=~isempty(dir([dirMat suffDiag 'D_*']));
doBudget=~isempty(dir([dirMat suffDiag 'D_*']))|...
    ~isempty(dir([dirMat 'diags_set_D/' suffDiag 'D_*']));
doProfiles=~isempty(dir([dirMat 'insitu_cost_all.mat']))|...
    ~isempty(dir([dirMat 'cost/insitu_cost_all.mat']));
doCost=~isempty(dir([dirMat 'cost_altimeter_obs.mat']))|...
    ~isempty(dir([dirMat 'cost/cost_altimeter_obs.mat']));
doCtrl=~isempty(dir([dirMat 'cost_xx_aqh.mat']))|...
    ~isempty(dir([dirMat 'cost/cost_xx_aqh.mat']));

%the following have no code for diff between runs
if doAnomalies;
    doProfiles=0;
    doCost=0;
    doCtrl=0;
end;

%reduce setDiags if needed:
doDiags=ones(1,length(setDiags));
%
for ii=1:length(setDiags);
  if iscell(setDiags{ii});
    if ~doBudget&&strcmp(setDiags{ii}{1},'D'); doDiags(ii)=0; end;
  elseif ~doBudget&&strcmp(setDiags{ii},'D'); doDiags(ii)=0; 
  elseif ~doProfiles&&strcmp(setDiags{ii},'profiles'); doDiags(ii)=0;   
  elseif ~doCost&&strcmp(setDiags{ii},'cost'); doDiags(ii)=0;   
  elseif ~doCtrl&&strcmp(setDiags{ii},'controls'); doDiags(ii)=0;   
  end;
end;
%
setDiags={setDiags{find(doDiags)}};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%initialize tex file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(dirMatRef);
    tmp1=dirMat; tmp2=strfind(tmp1,'_'); tmp1(tmp2)=' ';
    myTitle={'gcmfaces analysis of the solution in',tmp1};
    tmp1=dirMatRef; tmp2=strfind(tmp1,'_'); tmp1(tmp2)=' ';
    myTitle={myTitle{:},' minus ',tmp1};
end;

if isempty(dirMatRef)&&~isempty(dir([dirMat '../README']));
  [rdm]=read_readme([dirMat '../README']);
else;
  rdm=[];
end;

write2tex(fileTex,0,myTitle,rdm);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%augment tex file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for ii=1:length(setDiags);

  if iscell(setDiags{ii});
    ttl=input('specify tex file section title:\n');
    write2tex(fileTex,1,ttl,1);
    diags_display({dirMat,dirMatRef},setDiags{ii},dirTex,nameTex);

  elseif strcmp(setDiags{ii},'profiles');
        %in situ profiles fit
        write2tex(fileTex,1,'Fit To Data',1);
        write2tex(fileTex,1,'Fit To In Situ Data',2);
        insitu_diags(dirMat,0,dirTex,nameTex);
    
  elseif strcmp(setDiags{ii},'cost');
        if isempty(find(strcmp(setDiags,'profiles')));
          write2tex(fileTex,1,'Fit To Data',1);
        end;
        %altimeter fit
        if ~isempty(dir([dirMat 'cost/cost_altimeter_mod.mat']))
        write2tex(fileTex,1,'Fit To Altimeter Data (RADS)',2);
        cost_altimeter_disp(dirMat,0,'etaglo',dirTex,nameTex);
        cost_altimeter_disp(dirMat,2,'modMobs',dirTex,nameTex);
        cost_altimeter_disp(dirMat,1,'modMobs',dirTex,nameTex);
        cost_altimeter_disp(dirMat,3,'modMobs',dirTex,nameTex);
        cost_altimeter_disp(dirMat,1,'obs',dirTex,nameTex);
        cost_altimeter_disp(dirMat,1,'mod',dirTex,nameTex);
        end;
        %other cost terms
        write2tex(fileTex,1,'Fit To SST Data',2);
        cost_sst('',dirMat,0,dirTex,nameTex);
        write2tex(fileTex,1,'Fit To Seaice Data',2);
        cost_seaicearea('',dirMat,0,dirTex,nameTex);
    
  elseif strcmp(setDiags{ii},'A');
      write2tex(fileTex,1,'Volume, Heat, And Salt Transports',1);
      diags_display({dirMat,dirMatRef},'A',dirTex,nameTex);

  elseif strcmp(setDiags{ii},'B');
    write2tex(fileTex,1,'Mean And Variance Maps',1);
    diags_display({dirMat,dirMatRef},'B',dirTex,nameTex);

  elseif strcmp(setDiags{ii},'C');
    write2tex(fileTex,1,'Global, Zonal, Regional Averages',1);
    diags_display({dirMat,dirMatRef},'C',dirTex,nameTex);

  elseif strcmp(setDiags{ii},'D');
        budget_list=1;
        if ~isempty(dir([dirMat budgetList]));
            eval(['load ' dirMat budgetList ';']);
        end;
        for kk=budget_list;
            if kk==1;
                tmp1='(Top To Bottom)';
            else;
                tmp1=sprintf('(%im To Bottom)',round(-mygrid.RF(kk)));
            end;
            write2tex(fileTex,1,['Budgets : Volume, Heat, And Salt ' tmp1],1);
            diags_display({dirMat,dirMatRef},{'D',kk},dirTex,nameTex);
        end;

  elseif strcmp(setDiags{ii},'MLD');
      write2tex(fileTex,1,'Mixed Layer Depth Fields',1);
      diags_display({dirMat,dirMatRef},'MLD',dirTex,nameTex);
  elseif strcmp(setDiags{ii},'SEAICE');
      write2tex(fileTex,1,'Seaice And Snow Fields',1);
      diags_display({dirMat,dirMatRef},'SEAICE',dirTex,nameTex);
  elseif strcmp(setDiags{ii},'gudA');
      write2tex(fileTex,1,'Primary Production And Related Fields',1);
      diags_display({dirMat,dirMatRef},'gudA',dirTex,nameTex);
  elseif strcmp(setDiags{ii},'drwn3');
      write2tex(fileTex,1,'Plankton Biomass And Related Fields',1);
      diags_display({dirMat,dirMatRef},'drwn3',dirTex,nameTex);
  elseif strcmp(setDiags{ii},'controls');
        %controls
        write2tex(fileTex,1,'Control Parameters',1);
        cost_xx('',dirMat,0,dirTex,nameTex);

  else;
    ttl=input('specify tex file section title:\n');
    write2tex(fileTex,1,ttl,1);
    diags_display({dirMat,dirMatRef},setDiags{ii},dirTex,nameTex);

  end;%if iscell(setDiags{ii});
end;%for ii=1:length(setDiags);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%finalize tex file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

write2tex(fileTex,4);
%if isunix;
%write2tex(fileTex,5);
%else;
%fprintf(['\nUsers of pc or mac computers are left to compile the tex file :\n' fileTex '\noutside of matlab \n \n']);
%end;
fprintf(['\n Tex file is ready to be compiled :\n ' fileTex '\n']);

%%%%% get README text information

function [rdm]=read_readme(filReadme);

gcmfaces_global;

rdm=[];

fid=fopen(filReadme,'rt');
while ~feof(fid);
    nn=length(rdm);
    rdm{nn+1} = fgetl(fid);
end;
fclose(fid);


