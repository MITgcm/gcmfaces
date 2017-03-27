function []=example_MITprof();
% EXAMPLE_MITPROF illustrates the use of MITprof datasets by computing
%    Argo stats over a regional domain that includes the ACC core

gcmfaces_global;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if myenv.verbose>0;
    gcmfaces_msg('===============================================');
    gcmfaces_msg(['*** entering example_MITprof: illustrate ' ...
        'the use of MITprof datasets by computing Argo ACC stats'],'');
end;

%%%%%%%%%%%%%%%%%
%load grid and setup test case:
%%%%%%%%%%%%%%%%%

if isempty(mygrid);
   grid_load;
end;

myenv.nctilesdir=fullfile('release2_climatology',filesep,'nctiles_climatology',filesep);
myenv.mitprofdir=fullfile('release2_climatology',filesep,'profiles',filesep);

if ~isdir(myenv.nctilesdir);
    diags=[];
    help gcmfaces_demo;
    warning(['skipping example_MITprof (missing ' myenv.nctilesdir ')']);
    return;
end;

if ~isdir(myenv.mitprofdir);
    diags=[];
    help gcmfaces_demo;
    warning(['skipping example_MITprof (missing ' myenv.mitprofdir ')']);
    return;
end;

%%%%%%%%%%%%%%%%%%%%%%%
%define regional mask

if myenv.verbose>0;
    gcmfaces_msg('* call calc_barostream and define regional mask accordingly');
end;

%compute mean streamfunction to define mask:
fldU=mygrid.mskW.*mean(read_nctiles([myenv.nctilesdir 'UVELMASS/UVELMASS']),4);
fldV=mygrid.mskS.*mean(read_nctiles([myenv.nctilesdir 'VVELMASS/VVELMASS']),4);
[fldBAR]=calc_barostream(fldU,fldV);

%define 2D mask:
msk2D=fldBAR;
msk2D(fldBAR>100)=0; msk2D(fldBAR<30)=0; msk2D(mygrid.YC>0)=0;
msk2D(msk2D>0)=1; msk2D=msk2D.*mygrid.mskC(:,:,1);

%max climatological MLD could aternatively be used to define mask:
% maxMLD=mygrid.mskC(:,:,1).*max(read_nctiles('release2_climatology/nctiles_climatology/MXLDEPTH/MXLDEPTH'),[],3);

%define 3D mask:
msk3D=repmat(msk2D,[1 1 50]).*mygrid.mskC;
msk3D(:,:,26:50)=0.*msk3D(:,:,26:50);


%%%%%%%%%%%%%%%%%%%%%%%
%read in MITprof data sets and matching climatology profiles

if myenv.verbose>0;
    gcmfaces_msg('* read-in and select Argo profiles');
end;

listData={'MITprof_mar2016_argo9506*','MITprof_mar2016_argo0708*','MITprof_mar2016_argo0910*',...
    'MITprof_mar2016_argo1112*','MITprof_mar2016_argo1314*','MITprof_mar2016_argo1515*'};
listVar={'prof_T'}; listV={'T'};

for vv=1:length(listVar);
    tmpprof=MITprof_stats_load(myenv.mitprofdir,listData,listV{vv},listVar{vv});
    %
    loc_tile=gcmfaces_loc_tile(90,90,tmpprof.prof_lon,tmpprof.prof_lat);
    tmpprof.prof_msk=convert2array(msk2D); 
    tmpprof.prof_msk=tmpprof.prof_msk(loc_tile.point);
    tmpprof=MITprof_subset(tmpprof,'msk',1);
    %
    if vv==1; myprof=tmpprof; end;
    myprof.(listVar{vv})=tmpprof.prof;
    %
    clear tmpprof;
end;
myprof=rmfield(myprof,{'prof','prof_msk'});

if myenv.verbose>0;
    gcmfaces_msg('* subsample monthly climatology to profile locations');
end;

fldIn.fil=fullfile(myenv.nctilesdir,filesep,'THETA');
fldIn.tim='monclim'; fldIn.name='prof_Tclim';
myprof=MITprof_resample(myprof,fldIn);


%%%%%%%%%%%%%%%%%%%%%%%
%compute monthly averages

if myenv.verbose>0;
    gcmfaces_msg('* call MITprof_wrapper to compute monthly climatology');
end;

%specify operation to compute via MITprof_wrapper
myop=[];
%myop.op_name='mean';
myop.op_name='cycle'; myop.op_tim=[0:7:365];
myop.op_vars={'prof_T','prof_Tclim'};

%compute cycle via MITprof_wrapper
[cy_T,cy_Tclim]=MITprof_wrapper(myprof,myop);

if myenv.verbose>0;
    gcmfaces_msg('* call MITprof_wrapper via bootstrp to compute std');
end;

%store myprof and myop into global variable
global myprofmyop; myprofmyop=myprof;
for ii=fieldnames(myop)'; myprofmyop.(ii{1})=myop.(ii{1}); end;

%store mask since it could be useful for plotting or other purposes
myprofmyop.msk2D=msk2D;
myprofmyop.msk3D=msk3D;

%compute boostrap samples using MITprof_wrapper
K=[1:myprofmyop.np]; N=100;
myout = bootstrp(N, @MITprof_wrapper,K);

%compute standard deviation
bo_cy_T=reshape(cell2mat(myout(:,1)'),[size(cy_T) N]);
bo_cy_Tclim=reshape(cell2mat(myout(:,2)'),[size(cy_T) N]);
std_cy_T=std(bo_cy_T,[],3);
std_cy_Tclim=std(bo_cy_Tclim,[],3);

%%%%%%%%%%%%%%%%%%%%%%%
%display results

figure;
subplot(2,2,1); imagescnan(cy_T'); colorbar; title('mean using Argo');
subplot(2,2,2); imagescnan(cy_Tclim'); colorbar;  title('mean using climatology');
subplot(2,2,3); imagescnan(std_cy_T'); colorbar; title('std using Argo');
subplot(2,2,4); imagescnan(std_cy_Tclim'); colorbar;  title('std using climatology');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if myenv.verbose>0;
    gcmfaces_msg('*** leaving example_MITprof');
    gcmfaces_msg('===============================================');
end;

