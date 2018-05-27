
doOmit3Dfields=0;
if mygrid.memoryLimit~=0; doOmit3Dfields=1; end;

if userStep==1;%diags to be computed
    %here _s stands for cumulative sum and _2s for cumulative sum of squares
    %the _s should be stated first
    listDiags=['SIatmQnt_s SIatmQnt_2s SIatmFW_s SIatmFW_2s oceQnet_s oceQnet_2s ' ...
               'oceFWflx_s oceFWflx_2s fldTZ_s fldTZ_2s fldTM_s fldTM_2s ' ...
               'curlTau_s curlTau_2s fldETAN_s fldETAN_2s ' ...
               'fldSSH_s fldSSH_2s fldMLD_s fldMLD_2s'];
    if ~doOmit3Dfields;
      listDiags=[listDiags ' THETA_s THETA_2s SALT_s SALT_2s WVELMASS_s WVELMASS_2s'];
    end;

elseif userStep==2;%input files and variables
    listFlds={  'SIatmQnt','SIatmFW ','oceQnet ','oceFWflx','oceTAUX','oceTAUY','ETAN','sIceLoad','MXLDEPTH'};
    if ~doOmit3Dfields;
      listFlds={listFlds{:} ,'THETA','SALT','WVELMASS'};
    end;
    listFldsNames=deblank(listFlds);
    listFiles={'state_3d_set1','trsp_3d_set1','state_2d_set1','other_2d_set1'};
    listSubdirs={[dirModel 'diags/OTHER/' ],[dirModel 'diags/STATE/' ],[dirModel 'diags/TRSP/' ],...
                 [dirModel 'diags_trsp/' ],[dirModel 'diags/']};

elseif userStep==3;%computation
    %mask fields:
    SIatmQnt=SIatmQnt.*mygrid.mskC(:,:,1);
    SIatmFW=SIatmFW.*mygrid.mskC(:,:,1);
    oceQnet=oceQnet.*mygrid.mskC(:,:,1);
    oceFWflx=oceFWflx.*mygrid.mskC(:,:,1);
    fldTX=oceTAUX.*mygrid.mskW(:,:,1);
    fldTY=oceTAUY.*mygrid.mskS(:,:,1);
    %compute Eastward/Northward wind stresses:
    [fldTZ,fldTM]=calc_UEVNfromUXVY(fldTX,fldTY);
    %compute wind stress curl:
    %curlTau=calc_UV_curl(fldTX, fldTY,1 );%the doMask argument should not matter as msk was already applied
    curlTau=NaN*fldTZ;
    %mask and re-arrange fields:
    fldETAN=ETAN.*mygrid.mskC(:,:,1);
    fldSSH=(ETAN+sIceLoad/myparms.rhoconst).*mygrid.mskC(:,:,1);
    fldMLD=MXLDEPTH.*mygrid.mskC(:,:,1);
    %
    if ~doOmit3Dfields;
      THETA=THETA.*mygrid.mskC;
      SALT=SALT.*mygrid.mskC;
      WVELMASS=WVELMASS.*mygrid.mskC;
    end;
    %
    if ii>myparms.recInAve(1);
      fileMatPrev=['diags_set_' tmp1 '_' num2str(listTimes(ii-1)) '.mat'];
      listTimesBak=listTimes;
      load([dirMat fileMatPrev]);
      listTimes=listTimesBak;
      for jj=1:length(listDiags);
        eval(['tmp1=' listDiags{jj} ';']);
        if isa(tmp1,'gcmfaces'); eval([listDiags{jj} '=matLoadFix(tmp1);']); end;
      end;
    end;
    for jj=1:length(listDiags)/2;
        myDiag=listDiags{1+2*(jj-1)}(1:end-2);
        if ii==myparms.recInAve(1);
            eval([myDiag '_s=0*' myDiag ';']);
            eval([myDiag '_2s=0*' myDiag '.^2;']);
        end;
        eval([myDiag '_s=' myDiag '_s+' myDiag ';']);
        eval([myDiag '_2s=' myDiag '_2s+' myDiag '.^2;']);
    end;

%===================== COMPUTATIONAL SEQUENCE ENDS =========================%
%===================== PLOTTING SEQUENCE BEGINS    =========================%

elseif userStep==0;%loading / post-processing of mat files

  nfiles=length(dir(fullfile(dirMat,[fileMat '_*.mat'])));
  if nfiles>=myparms.recInAve(2);  
    ifile1=myparms.recInAve(2);
    ifile0=myparms.recInAve(1)-1;
  else;
    ifile1=nfiles;
    ifile0=0;
  end;

  %load last cumsum
  alldiag=diags_read_from_mat(dirMat,[fileMat '_*.mat'],'',ifile1);
  %load first cumsum if needed
  if ifile0>0;
    tmpdiag=diags_read_from_mat(dirMat,[fileMat '_*.mat'],'',ifile0);
    for ii=1:length(alldiag.listDiags);
         tmp0=alldiag.listDiags{ii};
         if ~strcmp(tmp0,'listTimes')&&~strcmp(tmp0,'listSteps');
           tmp1=getfield(alldiag,alldiag.listDiags{ii});
           tmp2=getfield(tmpdiag,alldiag.listDiags{ii});
           if isa(tmp1,'gcmfaces'); tmp1=matLoadFix(tmp1); end;
           if isa(tmp2,'gcmfaces'); tmp2=matLoadFix(tmp2); end;
           alldiag=setfield(alldiag,tmp0,tmp1-tmp2);
         end;
    end;
  end;
  %ensure backward compatibility
  if ~doOmit3Dfields;
    if ~isfield(alldiag,'WVELMASS_s'); alldiag.WVELMASS_s=NaN*alldiag.THETA_s; end;
    if ~isfield(alldiag,'WVELMASS_2s'); alldiag.WVELMASS_2s=NaN*alldiag.THETA_2s; end;
  end;
  if ~isfield(alldiag,'fldSSH_s'); alldiag.fldSSH_s=alldiag.fldETANLEADS_s; end;
  if ~isfield(alldiag,'fldSSH_2s'); alldiag.fldSSH_2s=alldiag.fldETANLEADS_2s; end;
  jj=find(strcmp(alldiag.listDiags,'fldETANLEADS_s'));
  if ~isempty(jj); alldiag.listDiags{jj}='fldSSH_s'; end;
  jj=find(strcmp(alldiag.listDiags,'fldETANLEADS_2s'));
  if ~isempty(jj); alldiag.listDiags{jj}='fldSSH_2s'; end;
  %
  n=diff(myparms.recInAve)+1;
  for jj=1:length(alldiag.listDiags)/2;
     tmp0=alldiag.listDiags{1+2*(jj-1)};
     if ~strcmp(tmp0,'listTimes')&&~strcmp(tmp0,'listSteps');
       tmp1=getfield(alldiag,tmp0);
       tmp2=getfield(alldiag,[tmp0(1:end-1) '2s']);
       if isa(tmp1,'gcmfaces'); tmp1=matLoadFix(tmp1); end;
       if isa(tmp2,'gcmfaces'); tmp2=matLoadFix(tmp2); end;
       tmp1=1/n*tmp1; tmp2=1/n*tmp2;
       tmp2=(tmp2-tmp1.^2);
       tmp2=n/(n-1)*tmp2;
       %tmp2(tmp2<0)=0;
       tmp2=sqrt(tmp2);
       alldiag=setfield(alldiag,[tmp0(1:end-2) '_mean'],tmp1);
       alldiag=setfield(alldiag,[tmp0(1:end-2) '_std'],tmp2);
     end;
  end;

  diagsWereLoaded=1;

elseif userStep==-1;%plotting

    if isempty(setDiagsParams); 
      choicePlot={'all'};
    else;
      choicePlot=setDiagsParams;
    end;


%===== start with state variables

  if sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'surface'));

    if addToTex; write2tex(fileTex,1,'sea surface height',2); end;

    %ETAN:
    fld=alldiag.fldETAN_mean;
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]/100; title0='sea surface height (EXCLUDING ice)';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*0.05; end;
    figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    myCaption={myYmeanTxt,'mean -- sea surface height (EXCLUDING ice, in m)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %ETANLEADS:
    fld=alldiag.fldSSH_mean;
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]/100; title0='sea surface height (INCLUDING ice)';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*0.05; end;
    figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    myCaption={myYmeanTxt,'mean -- sea surface height (INCLUDING ice, in m)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    if multiTimes;
        %ETAN:
        fld=alldiag.fldETAN_std;
        cc=[0:25:500]/2500; title0='std(ETAN)';
        if doAnomalies; cc=scaleAnom*[0:0.1:1]*0.02; end;
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        myCaption={myYmeanTxt,' standard deviation -- sea surface height (EXCLUDING ice, in m)'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

        %ETANLEADS:
        fld=alldiag.fldSSH_std;
        cc=[0:25:500]/2500; title0='std(ETANLEADS)';
        if doAnomalies; cc=scaleAnom*[0:0.1:1]*0.02; end;
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        myCaption={myYmeanTxt,' standard deviation -- sea surface height (INCLUDING ice, in m)'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;

  if ( sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'subsrfc')) )&&(~doOmit3Dfields);

    if addToTex; write2tex(fileTex,1,'3D state variables',2); end;

    cc_mean=1/100*[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]];
    cc_std=1/250*[0:25:500];
    kkList=[1 11 20 28 37 44];
    vvList={'THETA','SALT','WVELMASS'};

    for vv=1:length(vvList);
      vvtxt=vvList{vv};
      eval(['fld_mean=alldiag.' vvtxt '_mean;']);
      eval(['fld_std=alldiag.' vvtxt '_std;']);
      if strcmp(vvtxt,'WVELMASS');%convert into mm/day
           fld_mean=fld_mean*86400*365/1e3;
           fld_std=fld_std*86400*365/1e3;
      end;
      for kk=kkList;
        if strcmp(vvtxt,'WVELMASS')&&kk==1; kk=2; end;
        if mygrid.RC(kk)>=-50; facD=0.5;
        elseif mygrid.RC(kk)>=-150; facD=1;
        elseif mygrid.RC(kk)>=-500; facD=2.5;
        elseif mygrid.RC(kk)>=-2000; facD=10;
        else; facD=20;
        end;
        %
        if strcmp(vvtxt,'THETA'); nm='temperature (in degC)'; facV=1;
        elseif strcmp(vvtxt,'SALT'); nm='salinity (in psu)'; facV=10;
        elseif strcmp(vvtxt,'WVELMASS'); nm='vertical velocity (in mm/year)'; facV=10;
        else; error('not yet implemented');
        end;
        %

    title0=sprintf('%s at %4dm',nm,round(-mygrid.RC(kk)));

    %time mean map:
    fld=fld_mean(:,:,kk).*mygrid.mskC(:,:,kk);
    if doAnomalies;
      cc=scaleAnom/facV/facD*cc_mean; 
    elseif strcmp(vvtxt,'WVELMASS');
      cc=1/facV*cc_mean; 
    else;
      cc=prctile(facV*fld,[2.5 97.5]);
      cc=[floor(cc(1)):ceil(cc(end))]/facV;
      %ensure at least 10 color levels
      fac0=1;
      while length(cc)<15;
        fac0=fac0*2;
        cc=prctile(fac0*facV*fld,[2.5 97.5]);
        cc=[floor(cc(1)):ceil(cc(end))]/facV/fac0;
      end;
      %ensure at most 10 color levels
      fac0=1;
      while length(cc)>30;
        fac0=fac0/2;
        cc=prctile(fac0*facV*fld,[2.5 97.5]);
        cc=[floor(cc(1)):ceil(cc(end))]/facV/fac0;
      end;
    end;
    %
    figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    myCaption={myYmeanTxt,'mean -- ',title0};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    if multiTimes;
        fld=fld_std(:,:,kk).*mygrid.mskC(:,:,kk);
        cc=1/facV/facD*cc_std; 
        if strcmp(vvtxt,'WVELMASS'); cc=1/facV*cc_std; end;
        if doAnomalies; cc=scaleAnom*cc; end;
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        myCaption={myYmeanTxt,' standard deviation -- ',title0};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;%for kk=...
    end;%for vv=...
    end;%if ( sum(strcmp(...


%now do surface fluxes and forcing fields

    if sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'qnet'));

    if addToTex; write2tex(fileTex,1,'air-sea heat flux',2); end;

    %qnet from ocean+ice:
    fld=-alldiag.SIatmQnt_mean;
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]; title0='QNET to ocean+ice';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*10; end;
    figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    myCaption={myYmeanTxt,'mean -- QNET to ocean+ice (W/m$^2$)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %qnet to ocean:
    fld=alldiag.oceQnet_mean;
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]; title0='QNET to ocean';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*10; end;
    figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    myCaption={myYmeanTxt,'mean -- QNET to ocean (W/m$^2$)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
   
    if multiTimes;
        %qnet from ocean+ice:
        fld=alldiag.SIatmQnt_std;
        cc=[[0:5:25] 35 [50:25:200] [250 300]]; title0='std(QNET to ocean+ice)';
        if doAnomalies; cc=scaleAnom*[0:0.1:1]*5; end;
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        myCaption={myYmeanTxt,'  standard deviation -- QNET to ocean+ice (W/m$^2$)'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

        %qnet from ocean:
        fld=alldiag.oceQnet_std;
        cc=[[0:5:25] 35 [50:25:200] [250 300]]; title0='std(QNET to ocean)';
        if doAnomalies; cc=scaleAnom*[0:0.1:1]*5; end;
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        myCaption={myYmeanTxt,'  standard deviation -- QNET to ocean (W/m$^2$)'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;


    if sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'fwf'));

    if addToTex; write2tex(fileTex,1,'air-sea freshwater flux',2); end;

    %FW flux from ocean+ice:
    fld=-alldiag.SIatmFW_mean/1000;%conversion to m/s
    fld=fld*86400*1000;%conversion to mm/day
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]*0.06; title0='E-P-R to ocean+ice';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*0.5; end;
    figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    myCaption={myYmeanTxt,'mean -- E-P-R from ocean+ice (mm/day)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %FW flux from ocean:
    fld=-alldiag.oceFWflx_mean/1000;%conversion to m/s
    fld=fld*86400*1000;%conversion to mm/day
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]*0.06; title0='E-P-R to ocean';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*0.5; end;
    figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    myCaption={myYmeanTxt,'mean -- E-P-R from ocean (mm/day)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    if multiTimes;
        %empmr from ocean+ice:
        fld=alldiag.SIatmFW_std*86400;%conversion to mm/day
        cc=[[0:5:25] 35 [50:25:200] [250 300]]*0.04; title0='std(E-P-R to ocean+ice)';
        if doAnomalies; cc=scaleAnom*[0:0.1:1]*0.5; end;
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        myCaption={myYmeanTxt,' standard deviation -- E-P-R to ocean+ice (W/m$^2$)'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

        %empmr from ocean:
        fld=alldiag.oceFWflx_std*86400;%conversion to mm/day
        cc=[[0:5:25] 35 [50:25:200] [250 300]]*0.04; title0='std(E-P-R to ocean)';
        if doAnomalies; cc=scaleAnom*[0:0.1:1]*0.5; end;
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        myCaption={myYmeanTxt,' standard deviation -- E-P-R to ocean (W/m$^2$)'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;

    if sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'tau'));

    if addToTex; write2tex(fileTex,1,'surface wind stress',2); end;

    %zonal wind stress:
    fld=alldiag.fldTZ_mean;
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]/500; title0='zonal wind stress';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*0.01; end;
    figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    myCaption={myYmeanTxt,'mean -- zonal wind stress (N/m$^2$)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %meridional wind stress:
    fld=alldiag.fldTM_mean;
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]/500; title0='meridional wind stress';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*0.01; end;
    figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    myCaption={myYmeanTxt,'mean -- meridional wind stress (N/m$^2$)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %fld=alldiag.curlTau_mean;
    %cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]/5e8; title0='wind stress curl';
    %if doAnomalies; cc=scaleAnom*[-1:0.1:1]*0.01; end;
    %figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    %myCaption={myYmeanTxt,'mean -- wind stress curl (N/m$^3$)'};
    %if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    if multiTimes;
        %zonal wind stress:
        fld=alldiag.fldTZ_std;
        cc=[[0:5:25] 35 [50:25:200] [250 300]]/2000; title0='std(tauZ)';
        if doAnomalies; cc=scaleAnom*[0:0.1:1]*0.005; end;
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        myCaption={myYmeanTxt,'  standard deviation -- tauZ (W/m$^2$)'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

        %meridional wind stress:
        fld=alldiag.fldTM_std;
        cc=[[0:5:25] 35 [50:25:200] [250 300]]/2000; title0='std(tauM)';
        if doAnomalies; cc=scaleAnom*[0:0.1:1]*0.005; end;
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        myCaption={myYmeanTxt,' standard deviation -- tauM (W/m$^2$)'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

        %fld=alldiag.curlTau_std;
        %cc=[[0:5:25] 35 [50:25:200] [250 300]]/1e9; title0='wind stress curl';
        %if doAnomalies; cc=scaleAnom*[-1:0.1:1]*0.01; end;
        %figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        %myCaption={myYmeanTxt,'standard deviation -- tauCurl (N/m$^3$)'};
        %if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;

end;


