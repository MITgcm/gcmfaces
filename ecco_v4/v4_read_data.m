function [fld]=v4_read_data(fileName,irec);
%usage: fld=v4_read_data(fileName,irec);  'fast' read of 2D fields no irec in all [fileName '*.data'] 

gcmfaces_global;

dir0=strfind(fileName,filesep); if isempty(dir0); dir0='./'; else; dir0=fileName(1:dir0(end)); end;
fileList=dir([fileName '.data']);

nn=length(fileList);
fld=zeros(90,1170,nn);
for ii=1:nn; 
fid_cur=fopen([dir0 fileList(ii).name],'r','b');
recl=90*1170*4; position0=recl*(irec-1);
status=fseek(fid_cur,position0,'bof');
fld(:,:,ii)=fread(fid_cur,[90 1170],'float32');
fclose(fid_cur);
end;

fld=convert2gcmfaces(fld);

