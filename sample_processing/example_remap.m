function []=example_remap(doRemap3d);
% EXAMPLE_REMAP maps a lon-lat field to gcmfaces that in the 
%   three-dimensional case (when doRemap3d=1) with or without
%   extrapolation (both cases are illustrated)
%
% Note: activating example_remap requires the following input file
%  mkdir sample_input
%  wget ftp://mit.ecco-group.org/gforget/testcase_remap.mat
%  mv testcase_remap.mat sample_input/.

gcmfaces_global;

fil=fullfile(pwd,filesep,'sample_input',filesep,'testcase_remap.mat');
if isempty(dir(fil));
    help gcmfaces_demo;
    warning('skipping example_remap (missing sample_input/testcase_remap.mat)');
    return;
end;

if isempty(whos('doRemap3d')); doRemap3d=0; end;

%%%%%%%%%%%%%%%%%
%load grid:
%%%%%%%%%%%%%%%%%

if isempty(mygrid);
   grid_load;
end;
nF=mygrid.nFaces;

%%%%%%%%%%%%%%%%%
%load test case:
%%%%%%%%%%%%%%%%%

load(fil);

if myenv.verbose>0;
    gcmfaces_msg('===============================================');
    gcmfaces_msg(['*** entering example_remap: demonstrate ' ...
        'the use of gcmfaces_remap_2d '],'');
end;

warning('off','MATLAB:dsearch:DeprecatedFunction');
warning('off','MATLAB:delaunay:DuplicateDataPoints');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%map lon-lat field to gcmfaces

if myenv.verbose>0;
    gcmfaces_msg('* map lon-lat field to gcmfaces');
end;

kk=20;%choice of output depth level
kkIn=max(find(depth<-mygrid.RC(kk)));% corresponding choice of input level

%without extrapolation (note: shallow regions are blank in FLD)
% ref_remap2d=FLD1(:,:,kkIn);
ref_remap2d=fld1(:,:,kk);
fld_remap2d=gcmfaces_remap_2d(lon,lat,FLD2(:,:,kkIn),3);
fld_remap2d_extrap=gcmfaces_remap_2d(lon,lat,FLD2(:,:,kkIn),3,mygrid.mskC(:,:,kk));

%extrapolate to fill 3D model domain (note: extrapolation is often a bad idea)
if doRemap3d;
    ref_remap3d=fld1(:,:,kk);
    fld_remap3d=gcmfaces_remap_3d(lon,lat,depth(kkIn+[-2:2]),FLD2(:,:,kkIn+[-2:2]));
    fld_repmat3d_kk=fld_remap3d(:,:,kk);
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%quick display
cc=[0.4:0.05:1.1];
%
if myenv.verbose>0;
    gcmfaces_msg('* gcmfaces_remap_2d result (without extrapolation)');
end;
figureL; gcmfaces_sphere(fld_remap2d,cc,[],'N',1); title('gcmfaces_remap_2d result ');
if myenv.verbose>0;
    gcmfaces_msg('* gcmfaces_remap_2d result (with extrapolation)');
end;
figureL; gcmfaces_sphere(fld_remap2d_extrap,cc,[],'N',1); title('gcmfaces_remap_2d result (extrapolated)');
%
if doRemap3d;
    if myenv.verbose>0;
        gcmfaces_msg('* original field');
    end;
    figureL; gcmfaces_sphere(ref_remap2d,cc,[],'N',1); title('original field (slightly different level)');
    if myenv.verbose>0;
        gcmfaces_msg('* gcmfaces_remap_3d result (involves extrapolation)');
    end;
    figureL; gcmfaces_sphere(fld_repmat3d_kk,cc,[],'N',1); title('gcmfaces_remap_3d result');
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if myenv.verbose>0;
    gcmfaces_msg('*** leaving example_remap');
    gcmfaces_msg('===============================================');
end;




