function [listTimes]=diags_list_times(listSubdirs,listFiles);
%object : get the list of diags times by scanning pkg/diagnostics files
%inputs : listSubdirs is the cell array of directories to scan, in order
%         listFiles is the list of files to scan for, in order
%example: listSubdirs={[dirMat 'BUDG/' ],[dirModel 'diags/BUDG/' ],[dirModel 'diags/OTHER/' ],...
%                      [dirModel 'diags/STATE/' ],[dirModel 'diags/TRSP/'],[dirModel 'diags/' ]};
%         listFiles={'state_2d_set1.','diags_2d_set1.','monthly_2d_set1.'};

gcmfaces_global; global myparms; if myenv.usingOctave; import_netcdf; end;

if isfield(myenv,'nctiles');
    use_nctiles=myenv.nctiles;
else;
    use_nctiles=0;
end;

%get time list from binary directory scan
if ~use_nctiles;
    if isempty(who('listSubdirs'));
        listSubdirs={[myenv.matdir 'BUDG/' ],[myenv.diagsdir '/BUDG/' ],[myenv.diagsdir '/OTHER/' ],...
            [myenv.diagsdir '/STATE/' ],[myenv.diagsdir '/TRSP/'],[myenv.diagsdir '/' ]};
        listFiles={'state_2d_set1','trsp_3d_set1','budg2d_zflux_set1','gud_3d_set1'};
    end;
    %
    listTimes=[];
    for kk=1:length(listFiles);
        if isempty(listTimes);
            for jj=1:length(listSubdirs);
                tmp1=dir([listSubdirs{jj} '/' listFiles{kk} '.*meta']);
                if ~isempty(tmp1)&&isempty(listTimes);
                    for tt=1:length(tmp1); listTimes=[listTimes;str2num(tmp1(tt).name(end-14:end-5))]; end;
                end;
            end;
        end;
    end;
end;

%get time list from one netcdf file
if use_nctiles;
    timeStep=[];
    di=myenv.nctilesdir;
    %nm=myenv.nctileslist{1};
    nm='ETAN';
    fileIn=sprintf('%s/%s/%s.%04d.nc',di,nm,nm,1);
    nc=netcdf.open(fileIn,0);
    tmp1=ncinfo(fileIn);
    tmp1={tmp1.Variables(:).Name};
    if ~isempty(find(strcmp(tmp1,'step')));
      vv = netcdf.inqVarID(nc,'step');
    elseif ~isempty(find(strcmp(tmp1,'timstep')));
      vv = netcdf.inqVarID(nc,'timstep');
    else;
      error('could not find either ''step'' or ''timstep'' in \n %s \n',fileIn);
    end;
    listTimes=netcdf.getVar(nc,vv);
    netcdf.close(nc);
end;

%if no files were found then stop
if isempty(listTimes); error('no files were found'); end;
