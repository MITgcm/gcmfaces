function []=example_IO();
%
% EXAMPLE_IO computes and displays a standard deviation field
%
% stand-alone call:
%   addpath gcmfaces/sample_analysis/; example_IO;
%
% needed input files:
%   mkdir release2
%   wget --recursive ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/nctiles_climatology/ETAN
%   mv mit.ecco-group.org/ecco_for_las/version_4/release2/nctiles_climatology release2_climatology/.

gcmfaces_global;

input_list_check('example_IO',nargin);

%expected location:
myenv.nctilesdir=fullfile(pwd,'/release2_climatology/nctiles_climatology/ETAN/');
%if ETAN is not found then try old locations:
if ~isdir(myenv.nctilesdir);
    %if not found then try old location:
    tmpdir=fullfile(pwd,'/release2_climatology/nctiles_climatology/ETAN/');
    if isdir(tmpdir); myenv.nctilesdir=tmpdir; end;
end;
%if ETAN is still not found then issue warning and skip example_IO
if ~isdir(myenv.nctilesdir);
    help example_IO;
    warning('example_IO requires release2_climatology/nctiles_climatology/ETAN that was not found ---> abort!');
    return;
end;

%%%%%%%%%%%%%%%%%
%load grid:
%%%%%%%%%%%%%%%%%

if isempty(mygrid);
   grid_load;
end;

%%%%%%%%%%%
%get field:
%%%%%%%%%%%
fld=read_nctiles([myenv.nctilesdir 'ETAN'],'ETAN');
fld=std(fld,[],3); fld(find(fld==0))=NaN;
cc=[0:0.1:1]*0.10;

%%%%%%%%%%%%
%plot field:
%%%%%%%%%%%%
if ~myenv.lessplot;
    figureL; gcmfaces_sphere(fld,cc,[],[],1);
end;


