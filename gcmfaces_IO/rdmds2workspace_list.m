function []=rdmds2workspace_list(fileName,timeListToRead,fldListToRead);
%object:    read with rmds2gcmfaces then pass variables to workspace
%input:     fileName is the file name root (e.g. 'diags_3d_set2*')
%           timeListToRead is time steps Nos list (e.g. [98088 98089], or
%               NaN to load all files)
%           fldListToRead is the list of fields to be read (e.g.
%               'THETA' or {'THETA','SALT'} or '*' to load all fields)
%output:    no output needs to be specified
%

global mygrid;

%read meta file
tmp1=dir([fileName '*.meta']); tmp1=tmp1(1).name;
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

%fldListToRead special cases (1 field,
if ischar(fldListToRead);
    if strcmp(fldListToRead,'*');
        fldListToRead=meta.fldList;
    else;
        fldListToRead={fldListToRead};
    end;
end;

%list fields that will actually be loaded
recListToRead=zeros(meta.nFlds,1);
for ii=1:meta.nFlds;
    test0=sum(strcmp(fldListToRead,strtrim(meta.fldList(ii))));
    if test0; recListToRead(ii)=1; end;
end;
recListToRead=find(recListToRead);

%update fldListToRead accordingly
fldListToRead={meta.fldList{recListToRead}};

%timeListToRead special case
if isnan(timeListToRead(1));
    tmp1=dir([fileName '*.data']);
    timeListToRead=[];
    for tt=1:length(tmp1);
        i0=strfind(tmp1(tt).name,'.00')+1;
        i1=strfind(tmp1(tt).name,'.data')-1;
        timeListToRead=[timeListToRead ; str2num(tmp1(tt).name(i0:i1))];
    end;
end;

if 1;%use rdmds2gcmfaces
    if size(timeListToRead,1)>1; timeListToRead=timeListToRead'; end;
    for ii=1:length(recListToRead);
        data=rdmds2gcmfaces(fileName,timeListToRead,'rec',recListToRead(ii));
        eval([deblank(fldListToRead{ii}) '=data;']);
    end;    
else;%use fread instead
    %initialize arrays
    nt=length(timeListToRead);
    siz=size(convert2gcmfaces(mygrid.XC)); txt='(:,:';
    if meta.nDims==3; siz=[siz length(mygrid.RC)]; txt=[txt ',:']; end;
    for ii=1:length(recListToRead); eval([fldListToRead{ii} '=zeros([siz nt]);']); end;
    recl=prod(siz);
    
    %load the data
    for tt=1:nt;
        tmp1=dir([fileName sprintf('*.%010i',timeListToRead(tt)) '.data']); fname=tmp1.name;
        tmp2=strfind(fileName,filesep); if isempty(tmp2); dname='./'; else; dname=fileName(1:tmp2(end)); end;
        fid=fopen([dname fname],'r','b');
        for ii=1:length(recListToRead);
            tmp1=recl*4*(recListToRead(ii)-1);
            status=fseek(fid,tmp1,'bof');
            tmp1=reshape(fread(fid,recl,'float32'),siz);
            eval([fldListToRead{ii} txt ',tt)=tmp1' txt ');']);
        end;
    end;
    
    %convert2gcmfaces
    for ii=1:length(recListToRead);
        eval([fldListToRead{ii} '=convert2gcmfaces(' fldListToRead{ii} ');']);
    end;
end;

%export the various fields to caller workspace:
assignin('caller','meta',meta);

%export the various fields to caller workspace:
for ii=1:length(fldListToRead);
    eval(['data=' deblank(fldListToRead{ii}) ';']);
    if meta.nDims==3;
        assignin('caller',deblank(fldListToRead{ii}),data);
    else;
        assignin('caller',deblank(fldListToRead{ii}),data);
    end;
%    fprintf([deblank(fldListToRead{ii}) ' loaded into workspace \n']);
end;

