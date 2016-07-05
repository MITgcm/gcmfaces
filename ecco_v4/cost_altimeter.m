function []=cost_altimeter(dirModel,dirMat);
%object:       compute or plot the various sea level statistics
%              (std model-obs, model, obs, leading to cost function terms)
%inputs:       dirModel is the model run directory
%              dirMat is the directory where diagnozed .mat files will be saved
%                     -> set it to '' to use the default [dirModel 'mat/']
%              doComp is the switch from computation to plot

doComp=1;
if doComp==1;
    doSave=1;
    doPlot=0;
else;
    doSave=0;
    doPlot=1;
end;
doPrint=0;

%%%%%%%%%%%
%load grid:
%%%%%%%%%%%
    
gcmfaces_global;
if ~isfield(mygrid,'XC'); grid_load('./GRID/',5,'compact'); end;
if ~isfield(mygrid,'LATS_MASKS'); gcmfaces_lines_zonal; end;
    
%%%%%%%%%%%%%%%
%define pathes:
%%%%%%%%%%%%%%%

%search for nctiles files
useNctiles=0;
dirNctiles=[dirModel 'nctiles_remotesensing/sealevel/'];
if ~isempty(dir(dirNctiles)); useNctiles=1; end;

nameSigma={'sigma_MDT_glob_eccollc.bin','slaerr_largescale_r5.err','slaerr_gridscale_r5.err'}; maxLatObs=90

dirSigma=dirModel;
if ~isempty(dir([dirModel 'inputfiles/' nameSigma{1}]));
  dirSigma=[dirModel 'inputfiles/'];
end;

dirEcco=dirModel;
if ~isempty(dir([dirModel 'barfiles']));
  dirEcco=[dirModel 'barfiles' filesep];
end;

if isempty(dirMat); dirMat=[dirModel 'mat/']; else; dirMat=[dirMat '/']; end;
if isempty(dir(dirMat));     mkdir([dirMat]); end;
if ~isdir([dirMat 'cost/']); mkdir([dirMat 'cost/']); end;
runName=pwd; tmp1=strfind(runName,filesep); runName=runName(tmp1(end)+1:end);

%%%%%%%%%%%%%%%%%
%global means:
%%%%%%%%%%%%%%%%%

tmpName=dir([dirEcco 'm_eta_day*data']);
avisoName=which('MSL_aviso.bin');
if length(tmpName)==1&~isempty(avisoName);
  m_eta_day=rdmds2gcmfaces([dirEcco tmpName.name(1:end-5)]);
  avisoName=which('MSL_aviso.bin');
  etaglo_aviso=read2memory(avisoName)';
  %global mean
  nt=size(m_eta_day{1},3); etaglo=NaN*zeros(1,nt);
  area=mygrid.mskC(:,:,1).*mygrid.RAC; areatot=nansum(area);
  for tt=1:nt;
    etaglo(tt)=nansum(area.*m_eta_day(:,:,tt))/areatot;
  end;
  %monthly mean
  etaglo_mon=NaN*zeros(1,240);
  etaglo_aviso_mon=NaN*zeros(1,240);
  etadate=datenum([1992 1 1 12 0 0])+[1:nt]-1;
  for mm=1:240;
    t0=datenum([1992 1+(mm-1) 1 0 0 0]);
    t1=datenum([1992 1+mm 1 0 0 0]);
    tt=find(etadate>t0&etadate<t1);
    etaglo_mon(mm)=mean(etaglo(tt));
    etaglo_aviso_mon(mm)=mean(etaglo_aviso(tt));
  end;
  %
  if doSave; eval(['save ' dirMat 'cost/cost_altimeter_etaglo.mat etaglo*;']); end;
end;

%%%%%%%%%%%%%%%%%
%uncertainties:
%%%%%%%%%%%%%%%%%

sig_mdt=NaN*mygrid.RAC;
file0=[dirSigma nameSigma{1}];
if ~isempty(dir(file0)); sig_mdt=read_bin(file0,1,0); end;
%missing field:
%if useNctiles; sig_mdt=read_nctiles([dirNctiles 'sealevel'],'mdt_sigma'); end;

sig_sladiff_smooth=NaN*mygrid.RAC;
file0=[dirSigma nameSigma{2}];
if ~isempty(dir(file0)); sig_sladiff_smooth=read_bin(file0,1,0); end;
if useNctiles; sig_sladiff_smooth=read_nctiles([dirNctiles 'sealevel'],'lsc_sigma_r5'); end;

sig_sladiff_point=NaN*mygrid.RAC;
file0=[dirSigma nameSigma{2}];
if ~isempty(dir(file0)); sig_sladiff_point=read_bin(file0,1,0); end;
if useNctiles; sig_sladiff_point=read_nctiles([dirNctiles 'sealevel'],'point_sigma_r5'); end;

sig_mdt(find(sig_mdt==0))=NaN;
sig_sladiff_point(find(sig_sladiff_point==0))=NaN;
sig_sladiff_smooth(find(sig_sladiff_smooth==0))=NaN;

myflds.sig_mdt=sig_mdt;
myflds.sig_sladiff_point=sig_sladiff_point;
myflds.sig_sladiff_smooth=sig_sladiff_smooth;

fprintf('done with init\n');

%%%%%%%%%%%%%%%%%
%do computations:
%%%%%%%%%%%%%%%%%

for doDifObsOrMod=1:3;

    if doDifObsOrMod==1; suf='modMobs'; elseif doDifObsOrMod==2; suf='obs'; else; suf='mod'; end;
    
    if doComp==0;
        eval(['load ' dirMat 'cost/cost_altimeter_' suf '.mat myflds;']);
    else;
        
        %mdt cost function term (misfit plot)
        dif_mdt=NaN*mygrid.RAC;
        file0=[dirEcco 'mdtdiff_smooth.data'];
        if ~isempty(dir(file0)); dif_mdt=read_bin(file0,1,0); end;
        if useNctiles; dif_mdt=read_nctiles([dirNctiles 'sealevel'],'mdt_misfit'); end;
        %
        myflds.dif_mdt=dif_mdt;

        fprintf('done with mdt\n');

     if ~useNctiles;        
        %skip blanks:
        tmp1=dir([dirEcco 'sladiff_smooth*data']);
        nrec=tmp1.bytes/90/1170/4;
        ttShift=17;
        %skip 1992
        listRecs=[1+365-ttShift:17+365*18-ttShift];
        nRecs=length(listRecs); TT=1993+[0:nRecs-1]/365.25;

        tic;
        %pre-load lsc cost function term to add it back to pointwise/1day terms:
        if doDifObsOrMod==1;
            sladiff_smooth=cost_altimeter_read([dirEcco 'sladiff_smooth'],listRecs);
        elseif doDifObsOrMod==2;
            sladiff_smooth=cost_altimeter_read([dirEcco 'slaobs_smooth'],listRecs);
        else;
            sladiff_smooth=cost_altimeter_read([dirEcco 'sladiff_smooth'],listRecs);
            sladiff_smooth=sladiff_smooth+cost_altimeter_read([dirEcco 'slaobs_smooth'],listRecs);
        end;
        toc;
     end;%if ~useNctiles;

     if useNctiles;
        if doDifObsOrMod==1; 
            sladiff_smooth=read_nctiles([dirNctiles 'sealevel'],'lsc_misfit');
        elseif doDifObsOrMod==2;
            sladiff_smooth=read_nctiles([dirNctiles 'sealevel'],'lsc_sla');
        else;
            sladiff_smooth=read_nctiles([dirNctiles 'sealevel'],'lsc_misfit');
            sladiff_smooth=sladiff_smooth+read_nctiles([dirNctiles 'sealevel'],'lsc_sla');
        end;
        nRecs=size(sladiff_smooth{1},3);
        TT=1992+[0:nRecs-1]/365.25;
     end;

        fprintf('done with lsc\n');

        %pointwise/1day terms:
        sladiff_point=repmat(0*mygrid.RAC,[1 1 nRecs]); count_point=sladiff_point;
        for ii=1:3;
            if ii==1; myset='tp'; elseif ii==2; myset='gfo'; else; myset='ers'; end;
            %topex pointwise misfits:
     if ~useNctiles;
            if doDifObsOrMod==1;
                sladiff_tmp=cost_altimeter_read([dirEcco 'sladiff_' myset '_raw'],ttShift+listRecs);
            elseif doDifObsOrMod==2;
                sladiff_tmp=cost_altimeter_read([dirEcco 'slaobs_' myset '_raw'],ttShift+listRecs);
            else;
                sladiff_tmp=cost_altimeter_read([dirEcco 'sladiff_' myset '_raw'],ttShift+listRecs);
                sladiff_tmp=sladiff_tmp+cost_altimeter_read([dirEcco 'slaobs_' myset '_raw'],ttShift+listRecs);
            end;
            %add back the smoothed values that has been subtracted in cost_gencost_sshv4
            sladiff_smooth_tmp=sladiff_smooth;
            sladiff_smooth_tmp(sladiff_tmp==0)=0;
            sladiff_tmp=sladiff_tmp+sladiff_smooth_tmp;
     end;%if ~useNctiles;

     if useNctiles;
            if doDifObsOrMod==1;
                sladiff_tmp=read_nctiles([dirNctiles 'sealevel'],[myset '_misfit']);
            elseif doDifObsOrMod==2;
                sladiff_tmp=read_nctiles([dirNctiles 'sealevel'],[myset '_sla']);
            else;
                sladiff_tmp=read_nctiles([dirNctiles 'sealevel'],[myset '_misfit']);
                sladiff_tmp=sladiff_tmp+read_nctiles([dirNctiles 'sealevel'],[myset '_sla']);
            end;
            sladiff_tmp(isnan(sladiff_tmp))=0;
     end;

            %add to overall data set:
            sladiff_point=sladiff_point+sladiff_tmp; count_point=count_point+(sladiff_tmp~=0);
            %finalize data set:
            sladiff_tmp(sladiff_tmp==0)=NaN;
            %compute rms:
            count_tmp=sum(~isnan(sladiff_tmp),3); count_tmp(find(count_tmp<10))=NaN; msk_tmp=1+0*count_tmp;
            eval(['myflds.rms_' myset '=sqrt(nansum(sladiff_tmp.^2,3)./count_tmp);']);
            eval(['myflds.std_' myset '=nanstd(sladiff_tmp,0,3).*msk_tmp;']);
        end;

        fprintf('done with point\n');

        %finalize overall data set:
        count_point(count_point==0)=NaN;
        sladiff_point=sladiff_point./count_point;
        %compute overall rms,std:
        count_tmp=sum(~isnan(sladiff_point),3); count_tmp(find(count_tmp<10))=NaN; msk_tmp=1+0*count_tmp;
        myflds.rms_sladiff_point=sqrt(nansum(sladiff_point.^2,3)./count_tmp);
        myflds.std_sladiff_point=nanstd(sladiff_point,0,3).*msk_tmp;
        %
        msk_point=1*(count_point>0);
        %fill blanks:
        warning('off','MATLAB:divideByZero');
        msk=mygrid.mskC(:,:,1); msk(find(abs(mygrid.YC)>maxLatObs))=NaN;
        myflds.xtrp_rms_sladiff_point=diffsmooth2D_extrap_inv(myflds.rms_sladiff_point,msk);
        myflds.xtrp_std_sladiff_point=diffsmooth2D_extrap_inv(myflds.std_sladiff_point,msk);
        warning('on','MATLAB:divideByZero');

     if ~useNctiles;        
        %computational mask : only points that were actually observed, and in 35d average
        msk_point35d=cost_altimeter_read([dirEcco 'sladiff_raw'],listRecs);
        msk_point35d=1*(msk_point35d~=0);
        tmp1=sum(msk_point35d==0&msk_point~=0);
        tmp2=sum(msk_point35d~=0&msk_point~=0);
        fprintf('after masking : %d omitted, %d retained \n',tmp1,tmp2);
        msk_point=msk_point.*msk_point35d;
     end;%if ~useNctiles;

        %plotting mask : regions of less than 100 observations are omitted
        msk_point(msk_point==0)=NaN;
        msk_100pts=1*(nansum(msk_point,3)>=100);
        msk_100pts(msk_100pts==0)=NaN;
        %store
        myflds.msk_100pts=msk_100pts;

        fprintf('done with msk100\n');
        
     if ~useNctiles;
        tic;
        %lsc cost function term:
        if doDifObsOrMod==1;
            sladiff_smooth=cost_altimeter_read([dirEcco 'sladiff_smooth'],listRecs);
        elseif doDifObsOrMod==2;
            sladiff_smooth=cost_altimeter_read([dirEcco 'slaobs_smooth'],listRecs);
        else;
            sladiff_smooth=cost_altimeter_read([dirEcco 'sladiff_smooth'],listRecs);
            sladiff_smooth=sladiff_smooth+cost_altimeter_read([dirEcco 'slaobs_smooth'],listRecs);
        end;
        %mask missing points:
        sladiff_smooth(sladiff_smooth==0)=NaN;
        sladiff_smooth=sladiff_smooth.*msk_point;
        count_tmp=sum(~isnan(sladiff_smooth),3); count_tmp(find(count_tmp<10))=NaN; msk_tmp=1+0*count_tmp;
        %compute rms:
        rms_sladiff_smooth=msk_tmp.*sqrt(nanmean(sladiff_smooth.^2,3));
        std_sladiff_smooth=msk_tmp.*nanstd(sladiff_smooth,0,3);
        toc;
     end;%if ~useNctiles;

     if useNctiles;
        rms_sladiff_smooth=sqrt(nanmean(sladiff_smooth.^2,3));
        std_sladiff_smooth=nanstd(sladiff_smooth,0,3);
     end;

        %store:
        myflds.rms_sladiff_smooth=rms_sladiff_smooth;
        myflds.std_sladiff_smooth=std_sladiff_smooth;

        fprintf('done with rms\n');
        
     if ~useNctiles;
        tic;
        %pointwise/point35days cost function term:
        if doDifObsOrMod==1;
            sladiff_point35d=cost_altimeter_read([dirEcco 'sladiff_raw'],listRecs);
        elseif doDifObsOrMod==2;
            sladiff_point35d=cost_altimeter_read([dirEcco 'slaobs_raw'],listRecs);
        else;
            sladiff_point35d=cost_altimeter_read([dirEcco 'sladiff_raw'],listRecs);
            sladiff_point35d=sladiff_point35d+cost_altimeter_read([dirEcco 'slaobs_raw'],listRecs);
        end;
        %mask missing points:
        sladiff_point35d(sladiff_point35d==0)=NaN;
        sladiff_point35d=sladiff_point35d.*msk_point;
        count_tmp=sum(~isnan(sladiff_point35d),3); count_tmp(find(count_tmp<10))=NaN; msk_tmp=1+0*count_tmp;
        %compute rms:
        rms_sladiff_point35d=msk_tmp.*sqrt(nanmean(sladiff_point35d.^2,3));
        std_sladiff_point35d=msk_tmp.*nanstd(sladiff_point35d,0,3);
        %store:
        myflds.rms_sladiff_point35d=rms_sladiff_point35d;
        myflds.std_sladiff_point35d=std_sladiff_point35d;
        
        if 0;
            %difference between scales
            rms_sladiff_35dMsmooth=msk_tmp.*sqrt(nanmean((sladiff_point35d-sladiff_smooth).^2,3));
            std_sladiff_35dMsmooth=msk_tmp.*nanstd((sladiff_point35d-sladiff_smooth),0,3);
            %store:
            myflds.rms_sladiff_35dMsmooth=rms_sladiff_35dMsmooth;
            myflds.std_sladiff_35dMsmooth=std_sladiff_35dMsmooth;

            %difference between scales
            rms_sladiff_pointMpoint35d=msk_tmp.*sqrt(nanmean((sladiff_point-sladiff_point35d).^2,3));
            std_sladiff_pointMpoint35d=msk_tmp.*nanstd((sladiff_point-sladiff_point35d),0,3);
            %store:
            myflds.rms_sladiff_pointMpoint35d=rms_sladiff_pointMpoint35d;
            myflds.std_sladiff_pointMpoint35d=std_sladiff_pointMpoint35d;
        end;
        toc;
     end;%if ~useNctiles;

     if useNctiles;
            %store:
            myflds.rms_sladiff_point35d=NaN*rms_sladiff_smooth;
            myflds.std_sladiff_point35d=NaN*std_sladiff_smooth;
     end;
        
        %compute zonal mean/median:
        for ii=1:4;
            switch ii;
                case 1; tmp1='mdt'; cost_fld=(mygrid.mskC(:,:,1).*myflds.dif_mdt./myflds.sig_mdt).^2;
                case 2; tmp1='lsc'; cost_fld=(mygrid.mskC(:,:,1).*myflds.rms_sladiff_smooth./myflds.sig_sladiff_smooth).^2;
                case 3; tmp1='point35d'; cost_fld=(mygrid.mskC(:,:,1).*myflds.rms_sladiff_point35d./myflds.sig_sladiff_point).^2;
                case 4; tmp1='point'; cost_fld=(mygrid.mskC(:,:,1).*myflds.rms_sladiff_point./myflds.sig_sladiff_point).^2;
            end;
            cost_zmean=calc_zonmean_T(cost_fld); eval(['mycosts_mean.' tmp1 '=cost_zmean;']);
            cost_zmedian=calc_zonmedian_T(cost_fld); eval(['mycosts_median.' tmp1 '=cost_zmedian;']);
        end;

        fprintf(['done with ' suf '\n']);
        
        %write to disk:
        if doSave; eval(['save ' dirMat 'cost/cost_altimeter_' suf '.mat myflds mycosts_mean mycosts_median;']); end;
        
    end;%if doComp
    
    if doPlot;
        cc=[-0.4:0.05:-0.25 -0.2:0.03:-0.05 -0.03:0.01:0.03 0.05:0.03:0.2 0.25:0.05:0.4];
        figure; m_map_gcmfaces(myflds.dif_mdt,0,{'myCaxis',cc}); drawnow;
        cc=[0:0.005:0.02 0.03:0.01:0.05 0.06:0.02:0.1 0.14:0.03:0.2 0.25:0.05:0.4];
        figure; m_map_gcmfaces(myflds.rms_sladiff_smooth,0,{'myCaxis',cc}); drawnow;
        figure; m_map_gcmfaces(myflds.rms_sladiff_point35d,0,{'myCaxis',cc}); drawnow;
        figure; m_map_gcmfaces(myflds.rms_sladiff_point,0,{'myCaxis',cc}); drawnow;
    end;
    
    if doPlot&doPrint;
        dirFig='../figs/altimeter/'; ff0=gcf-4;
        for ff=1:4;
            figure(ff+ff0); saveas(gcf,[dirFig runName '_' suf num2str(ff)],'fig');
            eval(['print -depsc ' dirFig runName '_' suf num2str(ff) '.eps;']);
            eval(['print -djpeg90 ' dirFig runName '_' suf num2str(ff) '.jpg;']);
        end;
    end;
    
end;%for doDifObsOrMod=1:3;



function [fldOut]=cost_altimeter_read(fileIn,recIn);

nrec=length(recIn);
global mygrid; siz=[size(convert2gcmfaces(mygrid.XC)) nrec];
lrec=siz(1)*siz(2)*4;
myprec='float32';

fldOut=zeros(siz);
fid=fopen([fileIn '.data'],'r','b');
for irec=1:nrec;
    status=fseek(fid,(recIn(irec)-1)*lrec,'bof');
    fldOut(:,:,irec)=fread(fid,siz(1:2),myprec);
end;

fldOut=convert2gcmfaces(fldOut);



