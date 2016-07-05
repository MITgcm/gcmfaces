
choiceStruct=2;

%===============

if choiceStruct==1;
    structIn=[];
    %
    structIn.vars=mygrid;
    structIn.vars.RF=structIn.vars.RF(1:50);
    %
    structIn.descr={'C-grid parameters (see MITgcm documentation for details).'};
    %
    vars=[]; nv=length(vars)+1;
    vars(nv).fldName='XC'; vars(nv).longName='longitude'; vars(nv).units='degrees_east'; nv=length(vars)+1;
    vars(nv).fldName='YC'; vars(nv).longName='latitude'; vars(nv).units='degrees_north'; nv=length(vars)+1;
    vars(nv).fldName='XG'; vars(nv).longName='longitude'; vars(nv).units='degrees_east'; nv=length(vars)+1;
    vars(nv).fldName='YG'; vars(nv).longName='latitude'; vars(nv).units='degrees_north'; nv=length(vars)+1;
    vars(nv).fldName='RAC'; vars(nv).longName='grid cell area'; vars(nv).units='m^2'; nv=length(vars)+1;
    vars(nv).fldName='RAZ'; vars(nv).longName='grid cell area'; vars(nv).units='m^2'; nv=length(vars)+1;
    vars(nv).fldName='DXC'; vars(nv).longName='grid spacing'; vars(nv).units='m'; nv=length(vars)+1;
    vars(nv).fldName='DYC'; vars(nv).longName='grid spacing'; vars(nv).units='m'; nv=length(vars)+1;
    vars(nv).fldName='DXG'; vars(nv).longName='grid spacing'; vars(nv).units='m'; nv=length(vars)+1;
    vars(nv).fldName='DYG'; vars(nv).longName='grid spacing'; vars(nv).units='m'; nv=length(vars)+1;
    vars(nv).fldName='hFacC'; vars(nv).longName='fractional thickness'; vars(nv).units='1'; nv=length(vars)+1;
    vars(nv).fldName='hFacW'; vars(nv).longName='fractional thickness'; vars(nv).units='1'; nv=length(vars)+1;
    vars(nv).fldName='hFacS'; vars(nv).longName='fractional thickness'; vars(nv).units='1'; nv=length(vars)+1;
    vars(nv).fldName='Depth'; vars(nv).longName='sea floor depth'; vars(nv).units='m'; nv=length(vars)+1;
    vars(nv).fldName='AngleCS'; vars(nv).longName='grid orientation (cosine)'; vars(nv).units='m'; nv=length(vars)+1;
    vars(nv).fldName='AngleSN'; vars(nv).longName='grid orientation (sine)'; vars(nv).units='m'; nv=length(vars)+1;
    vars(nv).fldName='RC'; vars(nv).longName='vertical coordinate'; vars(nv).units='m'; nv=length(vars)+1;
    vars(nv).fldName='RF'; vars(nv).longName='vertical coordinate'; vars(nv).units='m'; nv=length(vars)+1;
    vars(nv).fldName='DRC'; vars(nv).longName='grid spacing'; vars(nv).units='m'; nv=length(vars)+1;
    vars(nv).fldName='DRF'; vars(nv).longName='grid spacing'; vars(nv).units='m'; nv=length(vars)+1;
    %
    structIn.defs=vars;
    %
    struct2nctiles('release1/','GRID',structIn,[90 90]);
end;

%===============

if choiceStruct==2;

  listBudgs={'budgMo','budgHo','budgSo','budgMi','budgHi','budgSi'};

  %directories and snapshot
  dirIn='r4it11.c65i/';
  dirMat='mat_budg3d/';
  fldName='snapshot';
  timName='0000000732'; suff='initial';
% timName='0000174564'; suff='final';
  t0Name=num2str(3600*str2num(timName));

  %load myparms
  eval(['load ' dirIn dirMat 'diags_grid_parms.mat myparms;']);

  %read THETA, SALT
  diagName=['budg3d_snap_set1.' timName];
  diagName=fullfile(dirIn,'diags',filesep,'BUDG',filesep,diagName);
  THETA=rdmds2gcmfaces(diagName,'rec',1);
  SALT=rdmds2gcmfaces(diagName,'rec',2);
  ONE=1*(SALT>0);

  %compute cell thickness
  etanName=['budg2d_snap_set1.' timName];
  etanName=fullfile(dirIn,'diags',filesep,'BUDG',filesep,etanName);
  etan=rdmds2gcmfaces(etanName,'rec',1);
  %compute time variable thickness
  tmp1=mk3D(mygrid.DRF,mygrid.hFacC).*mygrid.hFacC;
  tmp2=tmp1./mk3D(mygrid.Depth,tmp1);
  tmp2=tmp2.*mk3D(etan,tmp1);
  tmp3=mk3D(mygrid.RAC,tmp1);
  vol=tmp3.*(tmp1+tmp2);

  %load ice and snow volume/m2
  SIheff=rdmds2gcmfaces(etanName,'rec',2);
  SIsnow=rdmds2gcmfaces(etanName,'rec',3);

  for ii=1:length(listBudgs);
    budgName=listBudgs{ii};
    [budgName ' -- ' fldName ' -- ' timName]

    %directories and snapshot
    dirOut=fullfile(dirIn,'nctiles_budg',filesep);
    if ~isdir(dirOut); mkdir(dirOut); end;
    dirOut=fullfile(dirOut,budgName,filesep);
    if ~isdir(dirOut); mkdir(dirOut); end;

    switch budgName;
    case 'budgMo'; fld=ONE; fac=myparms.rhoconst;
    case 'budgHo'; fld=THETA; fac=myparms.rcp;
    case 'budgSo'; fld=SALT; fac=myparms.rhoconst;
    case 'budgMi'; FACheff=myparms.rhoi; FACsnow=myparms.rhosn;
    case 'budgHi'; FACheff=-myparms.flami*myparms.rhoi; FACsnow=-myparms.flami*myparms.rhosn;
    case 'budgSi'; FACheff=myparms.SIsal0*myparms.rhoi; FACsnow=0;
    end;

    %compute extensive snapshot
    structIn=[];
    if budgName(end)=='o';
      structIn.vars.snapshot=fac*fld.*vol;
    else;
      structIn.vars.snapshot=mygrid.RAC.*(FACheff*SIheff+FACsnow*SIsnow);
    end;

    %general description
    specs=[];
    if strcmp(budgName(5),'H');
        structIn.descr={'Heat budget in extensive form (in Watt, on C-Grid)'};
        specs.units='J';
        specs.name='heat content';
    elseif strcmp(budgName(5),'M');
        structIn.descr={'Mass budget in extensive form (in kg/s, on C-Grid)'};
        specs.units='kg';
        specs.name='mass content';
    elseif strcmp(budgName(5),'S');
        structIn.descr={'Salt budget in extensive form (in g/s, on C-Grid)'};
        specs.units='g';
        specs.name='salt content';
    end;

    %variables description
    vars=[]; nv=length(vars)+1;
    vars(nv).fldName=fldName; vars(nv).units=specs.units;
    if strcmp(budgName(6),'o'); vars(nv).longName=['ocean ' specs.name ' snapshot'];
    elseif strcmp(budgName(6),'i'); vars(nv).longName=['ice+snow ' specs.name ' snapshot'];
    end;
    vars(nv).longName=[vars(nv).longName ' at ' suff ' time=' t0Name 's'];
    %
    structIn.defs=vars;

    %create file
    tic; struct2nctiles(dirIn,fldName,structIn,[90 90]); toc;
    eval(['!mv ' pwd filesep dirIn filesep 'tmp_nctiles' filesep fldName ' ' pwd filesep dirOut suff]);

  end;%for ii=1:length(listBudgs);

end;

%===============

if choiceStruct==3;

  %budgName='budgHo';

  if budgName(end)=='o'; listFlds={'tend','trU','trV','trWtop'};
  else; listFlds={'tend','trU','trV','trWtop','trWbot'};
  end;

  for ii=1:length(listFlds);
    fldName=listFlds{ii};
    %fldName='trWtop';
    [budgName ' -- ' fldName]

    %directories
    dirIn='r4it11.c65i/';
    dirMat='mat_budg3d/';
    dirOut=fullfile(dirIn,'nctiles_budg',filesep);
    if ~isdir(dirOut); mkdir(dirOut); end;
    dirOut=fullfile(dirOut,budgName,filesep);
    if ~isdir(dirOut); mkdir(dirOut); end;

    %load variable
    eval(['load ' dirIn dirMat 'diags_grid_parms.mat myparms;']);
    dirMat=[dirIn dirMat 'diags_set_' budgName '/'];
    fileMat=[budgName '_*.mat'];
    tic; structIn.vars=diags_read_from_mat(dirMat,fileMat,fldName); toc;

    %time vectors
    [listTimes]=diags_list_times({[dirIn 'diags/BUDG/']},{'budg2d_hflux_set1'});
    structIn.vars.t0=3600*listTimes(1:end-2);
    structIn.vars.t1=3600*listTimes(2:end-1);

    %rename trWtop as trW if adequate
    if strcmp(fldName,'trWtop')&(budgName(end)=='o');
%note: since geothermal heating was added we likely need to add a nr+1 level to trW
%  using trWbot(:,:,nr) or output trWtop and trWbot themselves (as done for seaice)
      structIn.vars=setfield(structIn.vars,'trW',structIn.vars.trWtop);
      structIn.vars=rmfield(structIn.vars,'trWtop');
      structIn.vars.listDiags={'trW'};
      fldName='trW';
    end;

    %switch back to upward convention
    if strcmp(fldName(1:3),'trW');
%note: the following was needed in preparing the 03-Feb-2015 nctiles_budget (3d) files 
%   but is no longer needed since the trW sign convention in gcmfaces_diags was 
%   reversed to positive upward for consistency with MITgcm convention.
      tmp1=getfield(structIn.vars,fldName);
      structIn.vars=setfield(structIn.vars,fldName,-tmp1);
    end;

    %general description
    tmp1=diags_read_from_mat(dirMat,fileMat,'specs',1);
    specs=tmp1.specs;
    if strcmp(specs.units,'W');
        structIn.descr={'Heat budget in extensive form (in Watt, on C-Grid)'};
    elseif strcmp(specs.units,'kg/s');
        structIn.descr={'Mass budget in extensive form (in kg/s, on C-Grid)'};
    elseif strcmp(specs.units,'g/s');
        structIn.descr={'Salt budget in extensive form (in g/s, on C-Grid)'};
    else;
        error('unknown budget');
    end;

    %variables description
    vars=[]; nv=length(vars)+1;
    vars(nv).fldName=fldName; vars(nv).units=specs.units;
    switch fldName;
    case 'tend'; vars(nv).longName='tendency term';
    case 'trU'; vars(nv).longName='horizontal transport (U)';
    case 'trV'; vars(nv).longName='horizontal transport (V)';
    case 'trW'; vars(nv).longName='upward vertical transport (W)';
    case 'trWtop'; vars(nv).longName='upward vertical transport (W)';
    case 'trWbot'; vars(nv).longName='upward vertical transport (W)';
    end;
    nv=length(vars)+1;
    vars(nv).fldName='t0'; vars(nv).longName='initial time'; vars(nv).units='s'; nv=length(vars)+1;
    vars(nv).fldName='t1'; vars(nv).longName='final time'; vars(nv).units='s'; nv=length(vars)+1;
    %
    structIn.defs=vars;

    %create file
    tic; struct2nctiles(dirIn,fldName,structIn,[90 90]); toc;
    eval(['!mv ' pwd filesep dirIn filesep 'tmp_nctiles' filesep fldName ' ' pwd filesep dirOut]);

  end;%for fldName=listFlds;

end;

