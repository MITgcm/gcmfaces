function []=diags_inifin_D(kBudget,test3d,dirSnap,dirMat);
% DIAGS_INIFIN_D(kBudget,test3d,dirSnap,dirMat);

gcmfaces_global; global myparms;

[listTimes]=diags_list_times({dirSnap},{'budg2d_snap_set1'});

if kBudget==1&&~test3d; 
nmSnap='budg2d_snap_set2';
listBudgs={'budgMo','budgHo','budgSo','budgMi','budgHi','budgSi'};
elseif kBudget==1&&test3d;
nmSnap='budg3d_snap_set1';
listBudgs={'budgMo','budgHo','budgSo','budgMi','budgHi','budgSi'};
else;
nmSnap=['budg2d_snap_set3_' num2str(kBudget)];
listBudgs={'budgMo','budgHo','budgSo'};
end;

%load fields:
ini=sprintf('.%010d',listTimes(1));
fin=sprintf('.%010d',listTimes(end));

H{1}=rdmds2gcmfaces([dirSnap 'budg2d_snap_set1' ini],'rec',1);
H{2}=rdmds2gcmfaces([dirSnap 'budg2d_snap_set1' fin],'rec',1);
if ~test3d;
  tmp1=mk3D(mygrid.DRF,mygrid.hFacC).*mygrid.hFacC;
  tmp2=sum(tmp1(:,:,kBudget:length(mygrid.RC)),3)./mygrid.Depth;
  H{1}=tmp2.*H{1}+tmp2.*mygrid.Depth;
  H{2}=tmp2.*H{2}+tmp2.*mygrid.Depth;
else;
  tmp1=mk3D(mygrid.DRF,mygrid.hFacC).*mygrid.hFacC;
  tmp2=tmp1.*mk3D(H{1}./mygrid.Depth,tmp1);
  H{1}=(tmp1+tmp2);
  tmp2=tmp1.*mk3D(H{2}./mygrid.Depth,tmp1);
  H{2}=(tmp1+tmp2);
end;

SIheff{1}=rdmds2gcmfaces([dirSnap 'budg2d_snap_set1' ini],'rec',2);
SIheff{2}=rdmds2gcmfaces([dirSnap 'budg2d_snap_set1' fin],'rec',2);

SIsnow{1}=rdmds2gcmfaces([dirSnap 'budg2d_snap_set1' ini],'rec',3);
SIsnow{2}=rdmds2gcmfaces([dirSnap 'budg2d_snap_set1' fin],'rec',3);

if test3d;
  tmpfac{1}=H{1};
  tmpfac{2}=H{2};
else;
  tmpfac{1}=1;
  tmpfac{2}=1;
end;

THETA{1}=tmpfac{1}.*rdmds2gcmfaces([dirSnap nmSnap ini],'rec',1);
THETA{2}=tmpfac{2}.*rdmds2gcmfaces([dirSnap nmSnap fin],'rec',1);

SALT{1}=tmpfac{1}.*rdmds2gcmfaces([dirSnap nmSnap ini],'rec',2);
SALT{2}=tmpfac{2}.*rdmds2gcmfaces([dirSnap nmSnap fin],'rec',2);

for ii=1:length(listBudgs);
  budgName=listBudgs{ii};

  %set directory name
  dirOut=fullfile(dirMat,'..',filesep);
  sufbudg=''; if kBudget>1; sufbudg=num2str(kBudget); end;
  dirOut=fullfile(dirOut,['diags_set_' budgName sufbudg],filesep);
  if ~isdir(dirOut); mkdir(dirOut); end;

  for tt=1:2;
  switch budgName;
    case 'budgMo'; fld=myparms.rhoconst*H{tt};
    case 'budgHo'; fld=myparms.rcp*THETA{tt};
    case 'budgSo'; fld=myparms.rhoconst*SALT{tt};
    case 'budgMi'; fld=myparms.rhoi*SIheff{tt}+myparms.rhosn*SIsnow{tt};
    case 'budgHi'; fld=-myparms.flami*myparms.rhoi*SIheff{tt}-myparms.flami*myparms.rhosn*SIsnow{tt};
    case 'budgSi'; fld=myparms.SIsal0*myparms.rhoi*SIheff{tt};
  end;
  fld=fld.*repmat(mygrid.RAC,[1 1 size(fld{1},3)]);
  if tt==1; nmOut='ini.bin'; else; nmOut='fin.bin'; end;
  fprintf(['writing: ' dirOut nmOut '\n']);
  write2file([dirOut nmOut],convert2gcmfaces(fld),64);
  end;
end;


