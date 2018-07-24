function []=process2UVSTAR(dirDiags,fileDiags);
% PROCESS2UVstar computes bolus velocity vector components (U,V,WVELSTAR) from
%   GM_PsiX,Y in fileDiags (trsp_3d_set1) and output result to 'diags_post_tmp/'

gcmfaces_global;

dirOut=[dirDiags filesep 'diags_UVstar_tmp' filesep];
if ~isdir(dirOut); mkdir(dirOut); end;

pairsIn={{'GM_PsiX ' 'GM_PsiY '}};
pairsOut={{'UVELSTAR','VVELSTAR','WVELSTAR'}};

%% ======== PART 1 =======

%search for fileDiags in subdirectories
[subDir]=rdmds_search_subdirs(dirDiags,fileDiags);
%read meta file to get list of variables
[meta]=rdmds_meta([dirDiags subDir fileDiags]);

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
    GM_PsiX=rdmds2gcmfaces([dirDiags subDir filIn],'rec',i1);
    GM_PsiY=rdmds2gcmfaces([dirDiags subDir filIn],'rec',i2);
    [fldUbolus,fldVbolus,fldWbolus]=calc_bolus(GM_PsiX,GM_PsiY);
    %store binary
    fldsOut=cat(3,fldsOut,fldUbolus);
    fldsOut=cat(3,fldsOut,fldVbolus);
    fldsOut=cat(3,fldsOut,fldWbolus);
    listOut={listOut{:},pOut{:}};
  end;
  %output binary file
  filOut=['star_' filIn];
  tmp1=convert2gcmfaces(fldsOut);
  tmp1(isnan(tmp1))=0;
  if ~isdir(dirOut); mkdir(dirOut); end;
  write2file([dirOut filOut '.data'],tmp1,32);
  %create meta file
  tmp2=size(tmp1); tmp2(end)=tmp2(end)/3;
  write2meta([dirOut filOut '.data'],tmp2,32,listOut);
end;


