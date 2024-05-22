function [meta]=rdmds_meta(fileName);

%read meta file
tmp1=dir([fileName '.meta']);
if isempty(tmp1)&~strcmp(fileName(end),'*'); tmp1=dir([fileName '*.meta']); end;
if isempty(tmp1)
    warning(['file not found: ' fileName '*. Trying one level up.'])
    fpath = strsplit(fileName,filesep);
    fileName2 = [strjoin(fpath(1:end-1),filesep) filesep '..' filesep fpath{end}];
    tmp1=dir([fileName2 '*.meta']);
    if isempty(tmp1)
        error(['file not found: ' fileName2 '*'])
    else
        fileName = fileName2;
    end
end; 
tmp1=tmp1(1).name;
tmp2=strfind(fileName,filesep);
if ~isempty(tmp2); tmp2=tmp2(end); else; tmp2=0; end;
tmp1=[fileName(1:tmp2) tmp1]; fid=fopen(tmp1);
while 1;
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    if isempty(whos('tmp3')); tmp3=tline; else; tmp3=[tmp3 ' ' tline]; end;
end
fclose(fid);

%add meta variables to workspace
eval(tmp3);

%reformat to meta structure
meta.dataprec=dataprec;
meta.nDims=nDims;
meta.nFlds=nFlds;
meta.nrecords=nrecords;
meta.fldList=fldList;
meta.dimList=dimList;
if ~isempty(who('timeInterval')); meta.timeInterval=timeInterval; end;
if ~isempty(who('timeStepNumber'));  meta.timeStepNumber=timeStepNumber; end;

