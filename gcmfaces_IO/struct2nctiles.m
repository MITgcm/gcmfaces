function []=struct2nctiles(dirModel,fileOut,structIn,tileSize);
%process2nctiles(dirModel);
%object : convert MITgcm binary output to netcdf files (tiled)
%inputs : dirModel is the MITgcm run directory
%           It is expected to contain binaries in
%           'diags/STATE/', 'diags/TRSP/', etc. as well
%           as the 'available_diagnostics.log' text file.
%         fileModel the file name base e.g. 'state_2d_set1'
%           By default : all variables in e.g. 'state_2d_set1*'
%           files will be processed, and writen individually to
%           nctiles (tiled netcdf) that will be located in 'nctiles/'
%         structIn is a structure containing descr, defs and vars
%            (see prep2nctiles.m for an example)
%         tileSize (optional) is e.g. [90 90] (by default tiles=faces)
%output : (netcdf files)

gcmfaces_global;

%directory names
filReadme=[dirModel 'README'];
dirOut=[dirModel 'tmp_nctiles/'];
if ~isdir(dirOut); mkdir(dirOut); end;

%set list of variables to process
listFlds={structIn(:).defs.fldName};
listDefs=listFlds;

%determine map of tile indices (by default tiles=faces)
if isempty(whos('tileSize'));
    tileNo=mygrid.XC;
    for ff=1:mygrid.nFaces; tileNo{ff}(:)=ff; end;
else;
    tileNo=gcmfaces_loc_tile(tileSize(1),tileSize(2));
end;

%get description of estimate from README
[rdm]=read_readme(filReadme);
disp(rdm');

%add structIn.descr to the beginning of rdm...
disp(structIn.descr');
descr=structIn.descr{1};
for ii=2:length(structIn.descr);
    descr=[descr ' ' structIn.descr{ii}];
end;

%set output directory/file name
myFile=[dirOut fileOut];%first instance is for subdirectory name
if ~isdir(myFile); mkdir(myFile); end;
myFile=[myFile filesep fileOut];%second instance is for file name base

%create netcdf file using write2nctiles
doCreate=1;

%sort by number of dimensions
ndimDiag=NaN*ones(1,length(listFlds));
for ii=1:length(listFlds);
    nameDiag=listFlds{ii};
    myDiag=getfield(structIn.vars,nameDiag);
    if isa(myDiag,'gcmfaces');
        ndimDiag(ii)=length(size(myDiag{1}));
    else;
        ndimDiag(ii)=sum(size(myDiag)~=1);
    end;
end;
[ndimDiag,ii]=sort(ndimDiag,'descend');
listFlds={listFlds{ii}};

%write first field
nameDiag=listFlds{1}; myDiag=getfield(structIn.vars,nameDiag); jj=find(strcmp(listDefs,nameDiag));
dimlist=write2nctiles(myFile,myDiag,doCreate,{'tileNo',tileNo},{'fldName',nameDiag},...
    {'units',structIn.defs(jj).units},{'longName',structIn.defs(jj).longName},...
    {'descr',descr},{'rdm',rdm});

%determine relevant dimensions
for ff=1:length(dimlist);
    dim.threeD{ff}=dimlist{ff};
    dim.twoD{ff}={dimlist{ff}{end-1:end}};
    dim.oneD{ff}={dimlist{ff}{1}};
end;

%prepare to add fields
doCreate=0;

%now add the other fields
for ii=2:length(listFlds);
    nameDiag=listFlds{ii};
    myDiag=getfield(structIn.vars,nameDiag);
    jj=find(strcmp(listDefs,nameDiag));
    if ndimDiag(ii)==1; tmpDim=dim.oneD;
    elseif ndimDiag(ii)==2; tmpDim=dim.twoD;
    elseif ndimDiag(ii)==3; tmpDim=dim.threeD;
    end;
    write2nctiles(myFile,myDiag',doCreate,{'tileNo',tileNo},...
        {'fldName',nameDiag},{'units',structIn.defs(jj).units},...
        {'longName',structIn.defs(jj).longName},{'dimIn',tmpDim});
end;

%%

function [rdm]=read_readme(filReadme);

gcmfaces_global;

rdm=[];

fid=fopen(filReadme,'rt');
while ~feof(fid);
    nn=length(rdm);
    rdm{nn+1} = fgetl(fid);
end;
fclose(fid);

%%
