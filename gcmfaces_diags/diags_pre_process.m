function [myswitch]=diags_pre_process(dirModel,dirMat,doInteractive);
%object :      pre-processing for grid, model parameters, budgets,
%              profiles, cost and control, etc if required
%input :       dirModel is the directory containing 'diags/' or 'nctiles/'
%              dirMat is the directory where diagnostics results will be saved
%                     if isempty(dirMat) then [dirModel 'mat/'] is used by default
%(optional)    doInteractive=1 allows users to specify parameters interactively
%                     doInteractive = 0 (default) uses ECCO v4 parameters
%                     and omits budgets and model-data misfits analyses
%output :      myswitch is the set of switches (doBudget, doProfiles, doCost, doCtrl)
%                     that are set here depending on the model output available

gcmfaces_global; global myparms;

dirModel=fullfile(dirModel,filesep);
if isempty(dirMat); dirMat=fullfile(dirModel,'mat',filesep); else; dirMat=fullfile(dirMat,filesep); end;
if isempty(who('doInteractive')); doInteractive=0; end;

%detect which types of files are avaiable
test0=isdir([dirModel 'diags'])|~isempty(dir([dirModel 'state_2d_set1*']));
test1=~isempty(dir([dirModel 'nctiles']))|...
  ~isempty(dir([dirModel 'nctiles_climatology']))|...
  ~isempty(dir([dirModel 'nctiles_monthly']));
if test0&test1&doInteractive;
    myenv.nctiles=input('select to use binaries (0) or nctiles (1) files\n');
elseif test1;
    myenv.nctiles=1;
elseif test0;
    myenv.nctiles=0;
else;
    error('no files (diags/ or nctiles/)  were found\n');
end

if ~myenv.nctiles;%only works with binaries
    dirSnap=fullfile(dirModel,'diags',filesep);
    doBudget=~isempty(dir([dirSnap 'budg2d_snap_set1*']));
    if ~doBudget;
      dirSnap=fullfile(dirModel,'diags',filesep,'BUDG',filesep);
      doBudget=~isempty(dir([dirSnap 'budg2d_snap_set1*']));
    end;
    if ~doBudget;
      dirSnap=dirModel;
      doBudget=~isempty(dir([dirSnap 'budg2d_snap_set1*']));
    end;
    doCtrl=~isempty(dir([dirModel 'ADXXfiles' filesep 'xx*.effective.*']));
    doCtrl=doCtrl|~isempty(dir([dirModel 'xx*.effective.*']));
else;
    dirSnap=fullfile(dirModel,'diags',filesep);
    doBudget=0;
    doCost=0;
    doCtrl=0;
end;

doCost=~isempty(dir([dirModel 'barfiles' filesep 'm_eta_day.*.data']));
doCost=doCost|~isempty(dir([dirModel 'm_eta_day.*.data']));
doCost=doCost|~isempty(dir([dirModel 'nctiles_remotesensing']));

doProfiles=~isempty(dir([dirModel 'MITprof' filesep]));
preprocessProfiles=0;
myenv.profiles=fullfile(dirModel,'MITprof',filesep);
if ~doProfiles;
    doProfiles=~isempty(dir([dirModel 'profiles' filesep '*.nc']));
    preprocessProfiles=0;
    myenv.profiles=fullfile(dirModel,'profiles',filesep);
end;
if ~doProfiles;
    doProfiles=~isempty(dir([dirModel 'profiles' filesep]));
    preprocessProfiles=1;
    myenv.profiles=fullfile(dirMat,'profiles',filesep,'output',filesep);
end;

%output switches
myswitch.doBudget=doBudget;
myswitch.doProfiles=doProfiles;
myswitch.doCost=doCost;
myswitch.doCtrl=doCtrl;

disp(myswitch);
if doInteractive;
  test0=input('edit switches (1) or proceed (0)?\n');
  while test0;
    test0=input('type modification (e.g. as ''myswitch.doBudget=1;'') or hit return to stop editing.\n');
    if ~isempty(test0); eval(test0); disp(myswitch); end;
  end;
end;


%set the list of diags directories and files
if myenv.nctiles;
    if isdir(fullfile(dirModel,'nctiles',filesep));
        listSubdirs={fullfile(dirModel,'nctiles',filesep)};
    elseif isdir(fullfile(dirModel,'nctiles_monthly',filesep));
        listSubdirs={fullfile(dirModel,'nctiles_monthly',filesep)};
    elseif isdir(fullfile(dirModel,'nctiles_climatology',filesep));
        listSubdirs={fullfile(dirModel,'nctiles_climatology',filesep)};
    end;
    
    listFiles=dir(listSubdirs{1}); listFiles={listFiles(:).name};
    %remove irrelevant files/dirs
    test1=ones(size(listFiles));
    for kk=1:length(listFiles);
        tmp1=fullfile(listSubdirs{1},listFiles{kk},[listFiles{kk} '*.nc']);
        test1(kk)=~isempty(dir(tmp1));
    end;
    listFiles={listFiles{find(test1)}};
    %store in myparms for later use
    myenv.nctilesdir=listSubdirs{1};
    myenv.nctileslist=listFiles;
    %
    myenv.diagsdir='';
else;
    myenv.diagsdir=fullfile(dirModel,['diags' filesep]);
    if isempty(dir([myenv.diagsdir '*.data']))&...
       isempty(dir([myenv.diagsdir 'STATE' filesep '*.data']));
      myenv.diagsdir=fullfile(dirModel);
    end;
    %
    myenv.nctilesdir='';
    myenv.nctileslist={};
end;
myenv.matdir=fullfile(dirMat);

%0) create dirMat if needed:
if isempty(dir(dirMat)); mkdir(dirMat); end;

%1) pre-processing diags_grid_parms.mat
test0=isempty(dir([dirMat 'diags_grid_parms.mat']));
test1=isempty(dir([dirMat 'lock_mygrid']));

if test0&test1;%this process will do the pre-processing
    fprintf(['pre-processing : started for mygrid, myparms \n']);
    write2file([dirMat 'lock_mygrid'],1);
    %set the list of diags times
    [listTimes]=diags_list_times;
    %set grid and model parameters:
    diags_grid_parms(dirModel,listTimes,doInteractive);
    %save to disk:
    %if doInteractive;
    eval(['save ' dirMat 'diags_grid_parms.mat mygrid myparms;']);
    %end;
    delete([dirMat 'lock_mygrid']);
    test1=1;
    fprintf(['pre-processing : completed for mygrid, myparms \n\n']);
end;

%here I should test that files are indeed found (may have been moved)

while ~test1;%this process will wait for pre-processing to complete
    fprintf(['waiting 30s for removal of ' dirMat 'lock_mygrid \n']);
    fprintf(['- That should happen automatically after pre-processing is complete \n']);
    fprintf(['- But if a previous session was interupted, you may need to stop this one, \n ']);
    fprintf(['  remove ' dirMat 'lock_mygrid manually, and start over. \n\n']);
    test1=isempty(dir([dirMat 'lock_mygrid']));
    pause(30);
end;

%here we always reload the grid from dirMat to make sure the same one is used throughout
eval(['load ' dirMat 'diags_grid_parms.mat;']);

%2) pre-processing profiles
test0=isempty(dir([dirMat 'profiles/']));
test1=isempty(dir([dirMat 'lock_profiles']));

if test0&test1&doProfiles&preprocessProfiles;%this process will do the pre-processing
    fprintf(['pre-processing : started for profiles \n']);
    write2file([dirMat 'lock_profiles'],1);
    mkdir([dirMat 'profiles/']);
    mkdir([dirMat 'profiles/input/']);
    mkdir([dirMat 'profiles/output/']);

    listModel=dir([dirModel '*.nc']);
    listModel={listModel(:).name};
    for ff=1:length(listModel);
       copyfile([dirModel listModel{ff}],[dirMat 'profiles/input/' listModel{ff}]);
    end;

    if dirModel(1)~='/'; dirModelFull=[pwd '/' dirModel]; else; dirModelFull=dirModel; end;
    % NOTE: if on DOS system change ln to mklink
    system(['ln -s ' dirModelFull 'profiles/*equi.data ' dirMat 'profiles/.']);
    listModel=dir([dirMat 'profiles/input/*.nc'])
    listModel={listModel(:).name};
    for ff=1:length(listModel); listModel{ff}=[listModel{ff}(1:end-3) '*']; end;
    if ~isempty(listModel);
      MITprof_gcm2nc([dirMat 'profiles/'],listModel);
    else;
      warning('no MITprof files wer found');
    end;
    delete([dirMat 'lock_profiles']);
    test1=1;
    fprintf(['pre-processing : completed for profiles \n\n']);
end;

while ~test1&doProfiles;%this process will wait for pre-processing to complete
    fprintf(['waiting 30s for removal of ' dirMat 'lock_profiles \n']);
    fprintf(['- That should happen automatically after pre-processing is complete \n']);
    fprintf(['- But if a previous session was interupted, you may need to stop this one, \n ']);
    fprintf(['  remove ' dirMat 'lock_profiles manually, and start over. \n\n']);
    test1=isempty(dir([dirMat 'lock_profiles']));
    pause(30);
end;

%3) budget pre-processing
test0=isempty(dir([dirMat 'BUDG']));
test1=isempty(dir([dirMat 'lock_budg']));%this aims at having only one process do the

if (test0&test1&doBudget);
    fprintf(['pre-processing : started for budget \n']);
    write2file([dirMat 'lock_budg'],1);
    mkdir([dirMat 'BUDG']);
    %compute time derivatives between snapshots that will be
    %compared in budgets with the time mean flux terms
    tmp1=fullfile(dirSnap,'budg3d_snap_set1*meta');
    test3d=~isempty(dir(tmp1));
    tmp1=fullfile(dirSnap,'budg3d_snap_set1*meta');
    test3d=test3d|~isempty(dir(tmp1));
    tmp1=fullfile(dirSnap,'geothermalFlux.bin');
    testGeothermalFlux=~isempty(dir(tmp1));
    diags_diff_snapshots(dirSnap,dirMat,'budg2d_snap_set1');
    if ~test3d;
      diags_diff_snapshots(dirSnap,dirMat,'budg2d_snap_set2');
      if testGeothermalFlux; diags_budg_geothermal(dirSnap,dirMat,'budg2d_snap_set2'); end;
    else;
      diags_diff_snapshots(dirSnap,dirMat,'budg3d_snap_set1');
      if testGeothermalFlux; diags_budg_geothermal(dirSnap,dirMat,'budg3d_snap_set1'); end;
    end;
    budget_list=1;
    for kk=1:length(mygrid.RC);
        tmp1=sprintf('%s/budg2d_snap_set3_%02i*',dirSnap,kk);
        tmp2=~isempty(dir(tmp1));
        if tmp2;
            budget_list=[budget_list kk];
            tmp1=sprintf('budg2d_snap_set3_%02i',kk);
            diags_diff_snapshots(dirSnap,dirMat,tmp1);
           if testGeothermalFlux; diags_budg_geothermal(dirSnap,dirMat,tmp1); end;
        end;
    end;
    eval(['save ' dirMat 'diags_select_budget_list.mat budget_list;']);
    delete([dirMat 'lock_budg']);
    test1=1;
    fprintf(['pre-processing : completed for budget \n\n']);
end;

while ~test1&doBudget;%this process will wait for pre-processing to complete
    fprintf(['waiting 30s more for removal of ' dirMat 'lock_budg \n']);
    fprintf(['- That should happen automatically after pre-processing is complete \n']);
    fprintf(['- But if a previous session was interupted, you may need to stop this one, \n ']);
    fprintf(['  remove ' dirMat 'lock_budg manually, and start over. \n\n']);
    test1=isempty(dir([dirMat 'lock_budg']));
    pause(30);
end;

%set budget list
myparms.budgetList=1;
if ~isempty(dir([dirMat 'diags_select_budget_list.mat']));
    eval(['load ' dirMat 'diags_select_budget_list.mat;']);
    myparms.budgetList=budget_list;
end;
