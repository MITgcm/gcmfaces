
xC1=[0.5:359.5]'*ones(1,180);
yC1=ones(360,1)*[-89.5:89.5];
v4_reclen=convert2gcmfaces(mygrid.RAC); v4_reclen=size(v4_reclen); v4_reclen=v4_reclen(1)*v4_reclen(2);

dir_out='./'; %output directory
dir_in='./'; %input directory
file_pref='GRACE_CSR_withland_';

%load error field
[fieldErr_nosmooth,fieldErr]=read_grace_fld([dir_in 'GRACE_CSR_Error.asc']);

%process grace fields
for yy=1992:2012;
for mm=1:12;
tt=sprintf('%4i%02i',yy,mm);

file0=dir([dir_in file_pref tt '.asc']);
if ~isempty(file0);

%read
file0=file0.name;
field0=read_grace_fld([dir_in file0]);

%map
x=[xC1-360;xC1]; y=[yC1;yC1]; z=[field0;field0];
x=[x x x]; y=[y-180 y y+180]; z=[flipdim(z,2) z flipdim(z,2)];

field1=0*mygrid.XC;
for ii=1:5;
xi=mygrid.XC{ii}; yi=mygrid.YC{ii};
zi = interp2(x',y',z',xi,yi);
%zi = griddata(x,y,z,xi,yi);
field1{ii}=zi;
end;

%mask the model poles
tmp1=find(mygrid.RAC<8e8&mygrid.YC>0); field1(tmp1)=NaN;
tmp1=find(mygrid.RAC<2e8&mygrid.YC<0); field1(tmp1)=NaN;

else;
fprintf(['did not find : ' file_pref tt '.asc \n']);
field1=NaN*mygrid.RAC;
end;

%use -999 for mask
field1(isnan(field1))=-999;

%write to file
if mm==1; fid=fopen([dir_out file_pref num2str(yy)],'w','b'); end;
fwrite(fid,convert2gcmfaces(field1),'float32');
if mm==12; fclose(fid); end;

end;
end;

%process error estimate
z=[fieldErr;fieldErr]; z=[flipdim(z,2) z flipdim(z,2)];

field1=0*mygrid.XC;
for ii=1:5;
xi=mygrid.XC{ii}; yi=mygrid.YC{ii};
zi = interp2(x',y',z',xi,yi);
%zi = griddata(x,y,z,xi,yi);
field1{ii}=zi;
end;

%mask the model poles
tmp1=find(mygrid.RAC<8e8&mygrid.YC>0); field1(tmp1)=NaN;
tmp1=find(mygrid.RAC<2e8&mygrid.YC<0); field1(tmp1)=NaN;

%use 0 for mask
field1(isnan(field1))=0;

%write to file
write2file([dir_out file_pref 'err'],convert2gcmfaces(field1));

