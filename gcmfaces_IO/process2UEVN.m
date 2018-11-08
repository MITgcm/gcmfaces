function []=process2UEVN(dirDiags,fileDiags);
% PROCESS2UEVN(dirDiags,fileDiags) computes eastward/northward vector components
%   for vector fields in fileDiags and output result to 'diags_UEVN_tmp/'

gcmfaces_global;

gcmfaces_global;
dirOut=[dirDiags filesep 'diags_UEVN_tmp' filesep];

if strcmp(fileDiags,'trsp_3d_set1');
   pairsIn={{'UVELMASS','VVELMASS'}};
   pairsOut={{'EVELMASS','NVELMASS'}};
elseif strcmp(fileDiags,'trsp_3d_set2');
   pairsIn={{'DFxE_TH ','DFyE_TH '},{'DFxE_SLT','DFyE_SLT'}};
   pairsOut={{'DFeE_TH ','DFnE_TH '},{'DFeE_SLT','DFnE_SLT'}};
   pairsIn={pairsIn{:},{'ADVx_TH ','ADVy_TH '},{'ADVx_SLT','ADVy_SLT'}};
   pairsOut={pairsOut{:},{'ADVe_TH ','ADVn_TH '},{'ADVe_SLT','ADVn_SLT'}};
elseif strcmp(fileDiags,'state_2d_set1');
   pairsIn={{'DFxEHEFF','DFyEHEFF'},{'DFxESNOW','DFyESNOW'}};
   pairsOut={{'DFeEHEFF','DFnEHEFF'},{'DFeESNOW','DFnESNOW'}};
   pairsIn={pairsIn{:},{'ADVxHEFF','ADVyHEFF'},{'ADVxSNOW','ADVySNOW'}};
   pairsOut={pairsOut{:},{'ADVeHEFF','ADVnHEFF'},{'ADVeSNOW','ADVnSNOW'}};
   pairsIn={pairsIn{:},{'oceTAUX ','oceTAUY '},{'SIuice  ','SIvice  '}};
   pairsOut={pairsOut{:},{'oceTAUE ','oceTAUN '},{'EVELice ','NVELice '}};
elseif strcmp(fileDiags,'star_trsp_3d_set1');
   pairsIn={{'UVELSTAR','VVELSTAR'}};
   pairsOut={{'EVELSTAR','NVELSTAR'}};
else;
   error('unknown fileDiags');
end;

%% ======== PART 1 =======

%search for fileDiags in subdirectories
[subDir]=rdmds_search_subdirs(dirDiags,fileDiags);
%read meta file to get list of variables
[meta]=rdmds_meta([dirDiags subDir fileDiags]);

%% ======== PART 2 =======

listIn=dir([dirDiags subDir fileDiags '*meta']);
for tt=1:length(listIn);
  disp([tt length(listIn)]);
  fldsOut=gcmfaces;
  listOut={};
  for pp=1:length(pairsIn);
    pIn=pairsIn{pp}; pOut=pairsOut{pp};
    filIn=listIn(tt).name(1:end-5);
    metaIn=rdmds_meta([dirDiags subDir filIn]);
    i1=find(strcmp(metaIn.fldList,pIn{1}));
    i2=find(strcmp(metaIn.fldList,pIn{2}));
    %[i1 i2]
    %
    UX=rdmds2gcmfaces([dirDiags subDir filIn],'rec',i1);
    VY=rdmds2gcmfaces([dirDiags subDir filIn],'rec',i2);
    [UE,VN]=calc_UV_zonmer(UX,VY);
%   [UE,VN]=calc_UEVNfromUXVY(UX,VY);
    %store binary
    fldsOut=cat(3,fldsOut,UE);
    fldsOut=cat(3,fldsOut,VN);
    listOut={listOut{:},pOut{:}};
  end;
  %output binary file
  filOut=['zonmer_' filIn];
  tmp1=convert2gcmfaces(fldsOut);
  tmp1(isnan(tmp1))=0;
  if ~isdir(dirOut); mkdir(dirOut); end;
  write2file([dirOut filOut '.data'],tmp1,32);
  %create meta file
  tmp2=size(tmp1); tmp2(end)=tmp2(end)/length(pairsIn)/2;
  if tmp2(end)==1; tmp2=tmp2(1:2); end;
  write2meta([dirOut filOut '.data'],tmp2,32,listOut);
end;


