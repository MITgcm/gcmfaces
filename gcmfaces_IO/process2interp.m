function [listInterp,listNot]=process2interp(dirDiags,fileDiags,varargin);
% [listInterp,listNot]=PROCESS2INTERP(dirDiags,fileDiags);
% []=PROCESS2INTERP(dirDiags,fileDiags,listInterp);
%
%  Either  computes listInterp and listNot (if nargin==2)
%  Or      interpolates and ouput fields in listInterp (if nargin==3)
%
% Usage:
%   dirDiags=[pwd '/diags_ALL_MDS/']; fileDiags='state_2d_set1';
%   [listInterp,listNot]=process2interp(dirDiags,fileDiags);
%   process2interp(dirDiags,fileDiags,listInterp);

gcmfaces_global;
dirOut=[dirDiags filesep 'diags_interp_tmp' filesep];
filAvailDiag=[dirDiags filesep 'available_diagnostics.log'];
%filReadme=[dirDocs filesep 'README'];

%% ======== PART 1 =======
%search for fileDiags in subdirectories
[subDir]=rdmds_search_subdirs(dirDiags,fileDiags);

%read meta file to get list of variables
[meta]=rdmds_meta([dirDiags subDir fileDiags]);

if nargin < 3
    %set listInterp based on available_diagnostics.log
    listInterp={};
    listNot={};
    for ii=1:length(meta.fldList);
        %get units and long name from available_diagnostics.log
        [avail_diag]=read_avail_diag(filAvailDiag,meta.fldList{ii});
        if ~isempty(avail_diag);
            if strcmp(avail_diag.loc_h,'C');
                ndiags=length(listInterp)+1;
                listInterp={listInterp{:},deblank(meta.fldList{ii})};
            else;
                listNot={listNot{:},deblank(meta.fldList{ii})};
            end;
        end;
    end;
    
    if nargin==2; return; end;
end
%% ======== PART 2 =======

if nargin>=3; listInterp=varargin{1}; end;
if ischar(listInterp); listInterp={listInterp}; end;

% Make sure output directory exists and is writable
if ~isdir(dirOut)
    try
        mkdir(dirOut);
    catch
        error(['Cannot write to ' dirDiags  ' please link the contents of ' dirDiags ' to a folder where you have write permissions and try again.'])
    end
end
try
    save(fullfile(dirOut,'test.mat'),'dirOut');
    delete(fullfile(dirOut,'test.mat'));
catch
   error(['Cannot write to ' dirDiags  ' please link the contents of ' dirDiags ' to a folder where you have write permissions and try again.'])
end

if isempty(dir(fullfile(dirOut,'interp_precomputed.mat')));
    lon=[-179.75:0.5:179.75]; lat=[-89.75:0.5:89.75];
    [lat,lon] = meshgrid(lat,lon);
    interp=gcmfaces_interp_coeffs(lon(:),lat(:));
    save(fullfile(dirOut,'interp_precomputed.mat'),'lon','lat','interp');
else;
    fprintf('reloading interp_precomputed.mat...\n');
    load(fullfile(dirOut,'interp_precomputed.mat'));
end;

for ii=1:length(listInterp);
    
    tic;
    
    nameDiag=deblank(listInterp{ii});
    fprintf(['processing ' nameDiag '... \n']);

    if ~isempty(dir([dirOut nameDiag filesep nameDiag '*.data']));
        fprintf(['\n Files were found: ' dirOut nameDiag filesep '*.data']);
        test0=fprintf('\n Do you want to continue despite risk of overwriting them?');
        test0=input('\n >> If yes then please type 1 (otherwise just hit return).\n');
        if isempty(test0)||test0~=1; fprintf(['... skipping ' nameDiag '\n\n']); continue; end;
    end;
    
    if nargin == 5 % passing in pre-loaded fld
        
        fldOut = varargin{2};
        filOut = varargin{3};
        kk=strfind(filOut,'.00');
        if isempty(kk)
            filOut = nameDiag;
        else
            filOut=[nameDiag filOut(kk(1):end)];
        end

        listFiles = {filOut};
        if length(size(fldOut{1})) == length(size(mygrid.mskC{1})) %3D
            fldOut = fldOut.*mygrid.mskC;
        else
            fldOut = fldOut.*mygrid.mskC(:,:,1);
        end
    else
        jj=find(strcmp(deblank(meta.fldList),nameDiag));
        myDiag=rdmds2gcmfaces([dirDiags subDir fileDiags '*'],NaN,'rec',jj);
        listFiles=dir([dirDiags subDir fileDiags '*.data']);
        is3D=length(size(myDiag{1}))==4;
    end
    %loop over months and output result
    for tt=1:length(listFiles);
        if nargin < 5
            filOut=listFiles(tt).name(1:end-5);
            kk=strfind(filOut,'.00');
            filOut=[nameDiag filOut(kk(1):end)];
            if is3D; fldOut=myDiag(:,:,:,tt).*mygrid.mskC;
            else; fldOut=myDiag(:,:,tt).*mygrid.mskC(:,:,1);
            end;
        end
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
        if ~isdir([dirOut nameDiag filesep]); mkdir([dirOut nameDiag filesep]); end;
        %write binary field (masked)
        write2file([dirOut nameDiag filesep filOut '.data'],fldOut,32,0);
        %create meta file
        write2meta([dirOut nameDiag filesep filOut '.data'],sizOut,32,{nameDiag});
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

