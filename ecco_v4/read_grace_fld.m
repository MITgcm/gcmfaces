function [fld,fldsm]=read_grace_fld(fname);

%[fld]=read_grace_fld('GRACE_CSR_Error.asc');

fid=fopen(fname,'rt');
fgetl(fid);
fgetl(fid);

fld4columns=zeros(1e5,4);
ii=1;
while ~feof(fid);
fld4columns(ii,:)=str2num(fgetl(fid));
ii=ii+1;
end;
fclose(fid);

ii=find(fld4columns(:,2)>0&fld4columns(:,2)<360); 
jj=(fld4columns(ii,1)+89.5)*360+fld4columns(ii,2)+0.5;
fld=NaN*zeros(360,180); 
fld(jj)=fld4columns(ii,3);
fldsm=NaN*zeros(360,180);
fldsm(jj)=fld4columns(ii,4);


