function [listInterp,listNot]=process2interp(listDo);
% [listInterp,listNot]=PROCESS2INTERP(listDo);
% 1) computes listInterp and listNot (if listDo is not provided)
% 2) interpolates and ouput fields in listDo (= precomputed listInterp)
%
% Usage: [listInterp,listNot]=process2interp;
%        process2interp({listInterp{1:3}});
%        process2interp({listInterp{4:25}});
%        process2interp({listInterp{26:47}});


dirIn=[pwd filesep 'nctiles/'];
dirTim=[pwd '/diags/STATE/']; filTim='state_2d_set1';
dirOut=[pwd filesep 'diags_interp_tmp/'];
filAvailDiag=[pwd filesep 'available_diagnostics.log'];
filReadme=[pwd filesep 'README'];

%% ======== PART 1 =======

if isempty(who('listDo'));
  listDirs=dir(dirIn);
  listInterp={};
  listNot={};
  for ii=1:length(listDirs);
    %get units and long name from available_diagnostics.log
    [avail_diag]=read_avail_diag(filAvailDiag,listDirs(ii).name);
    if ~isempty(avail_diag);
    if strcmp(avail_diag.loc_h,'C');
      ndiags=length(listInterp)+1;
      listInterp={listInterp{:},listDirs(ii).name};
    else;
      listNot={listNot{:},listDirs(ii).name};
    end;
    end;
  end;
  return;
end;

%% ======== PART 2 =======

lon=[-179.75:0.5:179.75]; lat=[-89.75:0.5:89.75];
[lat,lon] = meshgrid(lat,lon);
interp=gcmfaces_interp_coeffs(lon(:),lat(:));

if ~isdir(dirOut); mkdir(dirOut); end;

for ii=1:length(listDo);

tic;

nameDiag=listDo{ii};
myDiag=read_nctiles([dirIn nameDiag '/' nameDiag]);
[listTimes]=diags_list_times({dirTim},{filTim});

is3D=length(size(myDiag{1}))==4;

%loop over months and output result
for tt=1:240;
  filOut=sprintf('%s.%010i',nameDiag,listTimes(tt)); 
  if is3D; fldOut=myDiag(:,:,:,tt);
  else; fldOut=myDiag(:,:,tt);
  end;
  %interpolate one field
  tmp1=convert2vector(fldOut);
  tmp0=1*~isnan(tmp1);
  tmp1(isnan(tmp1))=0;
  siz=[size(lon) size(tmp1,2)];
  tmp0=interp.SPM*tmp0;
  tmp1=interp.SPM*tmp1;
  fldOut=reshape(tmp1./tmp0,siz);
  sizOut=size(fldOut);
  %create subdirectory
  if ~isdir([dirOut nameDiag '/']); mkdir([dirOut nameDiag '/']); end;
  %write binary field (masked)
  write2file([dirOut nameDiag '/' filOut '.data'],fldOut,32,0);
  %create meta file
  write2meta([dirOut nameDiag '/' filOut '.data'],sizOut,32,{nameDiag});
end;

fprintf(['DONE: ' nameDiag ' (in ' num2str(toc) 's)\n']);
end;

%% ======== FUNCTIONS =======

function [avail_diag]=read_avail_diag(filAvailDiag,nameDiag);

gcmfaces_global;

avail_diag=[];

fid=fopen(filAvailDiag,'rt');
while ~feof(fid);
    tline = fgetl(fid);
    tmp1=8-length(nameDiag); tmp1=repmat(' ',[1 tmp1]);
    tname = ['|' sprintf('%s',nameDiag) tmp1 '|'];
    if ~isempty(strfind(tline,tname));
        %e.g. tline='   235 |SIatmQnt|  1 |       |SM      U1|W/m^2           |Net atmospheric heat flux, >0 decreases theta';
        %
        tmp1=strfind(tline,'|'); tmp1=tmp1(end-1:end);
        avail_diag.units=strtrim(tline(tmp1(1)+1:tmp1(2)-1));
        avail_diag.longNameDiag=tline(tmp1(2)+1:end);
        %
        tmp1=strfind(tline,'|'); tmp1=tmp1(4:5);
        pars=tline(tmp1(1)+1:tmp1(2)-1);
        %
        if strcmp(pars(2),'M'); avail_diag.loc_h='C';
        elseif strcmp(pars(2),'U'); avail_diag.loc_h='W';
        elseif strcmp(pars(2),'V'); avail_diag.loc_h='S';
        end;
        %
        avail_diag.loc_z=pars(9);
        %
        if strcmp(pars(10),'1'); avail_diag.nr=1;
        else; avail_diag.nr=length(mygrid.RC);
        end;
    end;
end;
fclose(fid);

