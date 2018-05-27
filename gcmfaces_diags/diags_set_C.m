
if userStep==1;%diags to be computed
    listDiags='fldTzonmean fldSzonmean fldETANzonmean fldSSHzonmean fldSIzonmean fldMLDzonmean';
    listDiags=[listDiags ' IceAreaNorth IceAreaSouth IceVolNorth IceVolSouth SnowVolNorth SnowVolSouth'];
    listDiags=[listDiags ' Ueq Teq SSHglo Tglo Sglo TgloProf SgloProf'];
elseif userStep==2;%input files and variables
    listFlds={    'THETA','SALT','ETAN','SIarea','SIheff','SIhsnow','sIceLoad','MXLDEPTH','UVELMASS','VVELMASS'};
    listFldsNames=deblank(listFlds);
    listFiles={'state_2d_set1','other_2d_set1','state_3d_set1','trsp_3d_set1'};
    listSubdirs={[dirModel 'diags/OTHER/' ],[dirModel 'diags/STATE/' ],[dirModel 'diags/TRSP/' ],...
                 [dirModel 'diags_trsp/'],[dirModel 'diags/']};
elseif userStep==3;%computational part;
    %mask and re-arrange fields:
    fldT=THETA.*mygrid.mskC; fldS=SALT.*mygrid.mskC;
    fldETAN=ETAN.*mygrid.mskC(:,:,1);
    fldSSH=(ETAN+sIceLoad/myparms.rhoconst).*mygrid.mskC(:,:,1);
    fldSI=SIarea.*mygrid.mskC(:,:,1);
    fldMLD=MXLDEPTH.*mygrid.mskC(:,:,1);
    ux=UVELMASS.*mygrid.mskW; vy=VVELMASS.*mygrid.mskS;
    [ue,un]=calc_UEVNfromUXVY(ux,vy);
    
    %compute zonal means:
    [fldTzonmean]=calc_zonmean_T(fldT);
    [fldSzonmean]=calc_zonmean_T(fldS);
    [fldETANzonmean]=calc_zonmean_T(fldETAN);
    [fldSSHzonmean]=calc_zonmean_T(fldSSH);
    [fldSIzonmean]=calc_zonmean_T(fldSI);
    [fldMLDzonmean]=calc_zonmean_T(fldMLD);
   
    %compute hemispheric ice sums:
    fld=SIarea.*mygrid.RAC.*(mygrid.YC>0); IceAreaNorth=nansum(fld);
    fld=SIarea.*mygrid.RAC.*(mygrid.YC<0); IceAreaSouth=nansum(fld);
    fld=SIheff.*mygrid.RAC.*(mygrid.YC>0); IceVolNorth=nansum(fld);
    fld=SIheff.*mygrid.RAC.*(mygrid.YC<0); IceVolSouth=nansum(fld);
    fld=SIhsnow.*mygrid.RAC.*(mygrid.YC>0); SnowVolNorth=nansum(fld);
    fld=SIhsnow.*mygrid.RAC.*(mygrid.YC<0); SnowVolSouth=nansum(fld);
    
    %equatorial sections of T and U:
    [secX,secY,Teq]=gcmfaces_section([],0,fldT,1);
    [secX,secY,Ueq]=gcmfaces_section([],0,ue,1);
    
    %global means and profiles:
    msk=mygrid.RAC.*mygrid.mskC(:,:,1);
    SSHglo=nansum(fldSSH.*msk)./nansum(msk);
    %
    msk=mygrid.mskC.*mygrid.hFacC;
    msk=msk.*mk3D(mygrid.RAC,msk).*mk3D(mygrid.DRF,msk);
    Tglo=nansum(fldT.*msk)./nansum(msk);
    Sglo=nansum(fldS.*msk)./nansum(msk);
    nr=length(mygrid.RC);
    TgloProf=zeros(nr,1); SgloProf=zeros(nr,1);
    for kk=1:nr;
        rac=mygrid.RAC.*mygrid.mskC(:,:,kk);
        TgloProf(kk)=nansum(rac.*fldT(:,:,kk))/nansum(rac);
        SgloProf(kk)=nansum(rac.*fldS(:,:,kk))/nansum(rac);
    end;


%===================== COMPUTATIONAL SEQUENCE ENDS =========================%
%===================== PLOTTING SEQUENCE BEGINS    =========================%

elseif userStep==-1;%plotting

    if isempty(setDiagsParams);
      choicePlot={'all'};
    else;
      choicePlot=setDiagsParams;
    end;

    %ensure backward compatibility
    if ~isfield(alldiag,'fldSSHzonmean'); alldiag.fldSSHzonmean=alldiag.fldETANLEADSzonmean; end;
    if ~isfield(alldiag,'SSHglo'); alldiag.SSHglo=NaN*alldiag.Tglo; end;

    %determine number of years in alldiag.listTimes
    myTimes=alldiag.listTimes; 
    %determine the number of records in one year (lYear)
    tmp1=mean(myTimes(2:end)-myTimes(1:end-1));
    lYear=round(1/tmp1);
    %in case when lYear<2 we use records as years
    if ~(lYear>=2); lYear=1; myTimes=[1:length(myTimes)]; end;
    %determine the number of full years (nYears)
    nYears=floor(length(myTimes)/lYear);

    if nYears>1&(sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'zmtend')));

    if addToTex; write2tex(fileTex,1,'zonal mean tendencies',2); end;

    figureL; set(gcf,'Renderer','zbuffer');
    %cc=[-2:0.25:2];
    cc=1/100*[[-200:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:200]];
    if doAnomalies; cc=scaleAnom/10*cc; end;
    X=mygrid.LATS*ones(1,length(mygrid.RC)); Y=ones(length(mygrid.LATS),1)*(mygrid.RC');
    %T
    subplot(2,1,1);
    fld=annualmean(alldiag.listTimes,alldiag.fldTzonmean,'last')-annualmean(alldiag.listTimes,alldiag.fldTzonmean,'first');
    depthStretchPlot('pcolor',{X,Y,fld}); shading interp;
    cbar=gcmfaces_cmap_cbar(cc); title('zonal mean T anomaly');
    %S
    subplot(2,1,2);
    fld=annualmean(alldiag.listTimes,alldiag.fldSzonmean,'last')-annualmean(alldiag.listTimes,alldiag.fldSzonmean,'first');
    depthStretchPlot('pcolor',{X,Y,fld}); shading interp;
    cbar=gcmfaces_cmap_cbar(cc/4); title('zonal mean S anomaly');
    %
    myCaption={myYmeanTxt,', last year minus first year -- zonal mean temperature (degC; top) and salinity (psu; bottom)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    end;
   
    if sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'eq'));

    if addToTex; write2tex(fileTex,1,'equatorial sections',2); end;

    %time mean equator sections :
    figureL; set(gcf,'Renderer','zbuffer'); cc0=[-2:0.25:2];
    [secX,secY,LONeq]=gcmfaces_section([],0,mygrid.XC,1);
    X=LONeq*ones(1,length(mygrid.RC)); Y=ones(length(LONeq),1)*mygrid.RC';
    X=circshift(X,[-180 0]); X(X<0)=X(X<0)+360;
    %T
    subplot(2,1,1);
    fld=annualmean(alldiag.listTimes,alldiag.Teq,'all'); fld=circshift(fld,[-180 0]);
    depthStretchPlot('pcolor',{X,Y,fld},[0:50:350],[0 350 350]); shading interp;
    if ~doAnomalies; cc=18+6*cc0; else; cc=scaleAnom/10*cc0*2; end;
    cbar=gcmfaces_cmap_cbar(cc); title('equator T (degC)');
    %U
    subplot(2,1,2);
    fld=annualmean(alldiag.listTimes,alldiag.Ueq,'all'); fld=circshift(fld,[-180 0]);
    depthStretchPlot('pcolor',{X,Y,fld},[0:50:350],[0 350 350]); shading interp;
    if ~doAnomalies; cc=cc0/5*2; else; cc=scaleAnom/10*cc0/5; end;
    cbar=gcmfaces_cmap_cbar(cc); title('equator zonal velocity (m/s)');
    %
    myCaption={myYmeanTxt,' mean -- equator temperature (degC;top) and zonal velocity (m/s;bottom)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    end;

    if multiTimes&(sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'gmtime')));

    if addToTex; write2tex(fileTex,1,'global mean properties',2); end;

    %global mean T/S:
    figureL;
    subplot(3,1,1); vec=alldiag.SSHglo;
    plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2);
    aa=axis; axis([min(TT) max(TT) aa(3:4)]); grid on;
    legend('monthly','annual mean'); title('Global Mean Sea level (m, uncorrected free surface)');
    subplot(3,1,2); vec=alldiag.Tglo;
    plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2);
    aa=axis; axis([min(TT) max(TT) aa(3:4)]); grid on;
    legend('monthly','annual mean'); title('Global Mean Temperature (degC)');
    subplot(3,1,3); vec=alldiag.Sglo;
    plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2);
    aa=axis; axis([min(TT) max(TT) aa(3:4)]); grid on;
    legend('monthly','annual mean'); title('Global Mean Salinity (psu)');
    myCaption={'global mean T (degC; top) and S (psu; bottom)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
   
    %global mean T/S profiles:
    figureL; set(gcf,'Renderer','zbuffer'); cc0=[-2:0.25:2];
    X=TT*ones(1,length(mygrid.RC)); Y=ones(length(TT),1)*(mygrid.RC'); X=X'; Y=Y';
    %T
    subplot(2,1,1);
    [tmp1,fld]=annualmean(alldiag.listTimes,squeeze(alldiag.TgloProf),'first');
    depthStretchPlot('pcolor',{X,Y,fld}); shading interp;
    if ~doAnomalies; cc=cc0/5; else; cc=scaleAnom/10*cc0/10; end;
    cbar=gcmfaces_cmap_cbar(cc); title('global mean T minus first year (K)');
    %S
    subplot(2,1,2);
    [tmp1,fld]=annualmean(alldiag.listTimes,squeeze(alldiag.SgloProf),'first');
    depthStretchPlot('pcolor',{X,Y,fld}); shading interp;
    if ~doAnomalies; cc=cc0/50; else; cc=scaleAnom/10*cc0/50; end;
    cbar=gcmfaces_cmap_cbar(cc); title('global mean S minus first year (psu)');
    %
    myCaption={'global mean temperature (K; top) and salinity (psu; bottom) minus first year'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    end;


    if multiTimes&(sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'lzmtime')));

    if addToTex; write2tex(fileTex,1,'zonal mean properties',2); end;

    listLatPlot=[-75 -65 -45 -25 0 25 45 65 75];
    %zonal mean temperature profile at selected latitude:
    for iLatPlot=1:length(listLatPlot);
        tmp1=abs(mygrid.LATS-listLatPlot(iLatPlot));
        iLat=find(tmp1==min(tmp1)); iLat=iLat(1);
        figureL; set(gcf,'Renderer','zbuffer'); cc=[-2:0.25:2];
        if doAnomalies; cc=scaleAnom/10*cc; end;
        %T
        subplot(2,1,1);
        [tmp1,fld]=annualmean(alldiag.listTimes,squeeze(alldiag.fldTzonmean(iLat,:,:)),'first');
        X=TT*ones(1,length(mygrid.RC)); Y=ones(length(TT),1)*(mygrid.RC'); X=X'; Y=Y';
        title0=['mean T minus first year (K) at lat ~ ' num2str(listLatPlot(iLatPlot))];
        depthStretchPlot('pcolor',{X,Y,fld}); shading interp; cbar=gcmfaces_cmap_cbar(cc/5); title(title0);
        %S
        subplot(2,1,2);
        [tmp1,fld]=annualmean(alldiag.listTimes,squeeze(alldiag.fldSzonmean(iLat,:,:)),'first');
        X=TT*ones(1,length(mygrid.RC)); Y=ones(length(TT),1)*(mygrid.RC'); X=X'; Y=Y';
        title0=['mean S minus first year (psu) at lat ~ ' num2str(listLatPlot(iLatPlot))];
        depthStretchPlot('pcolor',{X,Y,fld}); shading interp; cbar=gcmfaces_cmap_cbar(cc/25); title(title0);

        myCaption={'mean temperature (top; K) and salinity (bottom; psu) minus first year ',...
            ['at lat $\\approx$ ' num2str(listLatPlot(iLatPlot))]};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;


    if multiTimes&(sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'szmtime')));

    if addToTex; write2tex(fileTex,1,'zonal mean properties (surface)',2); end;

    %zonal mean SST/SSS:
    figureL; set(gcf,'Renderer','zbuffer'); cc0=[-2:0.25:2]; kk=1;
    x=TT*ones(1,length(mygrid.LATS)); y=ones(nt,1)*mygrid.LATS'; x=x'; y=y';
    %T
    subplot(2,1,1);
    fld=squeeze(alldiag.fldTzonmean(:,kk,:)); [tmp1,fld]=annualmean(alldiag.listTimes,fld,'first');
    if ~doAnomalies; cc=cc0*3; else; cc=scaleAnom/10*cc0; end;
    pcolor(x,y,fld); shading interp; axis([TT(1) TT(end) -90 90]); cbar=gcmfaces_cmap_cbar(cc);
    title('zonal mean SST minus first year (degC)');
    %S
    subplot(2,1,2);
    fld=squeeze(alldiag.fldSzonmean(:,kk,:)); [tmp1,fld]=annualmean(alldiag.listTimes,fld,'first');
    if ~doAnomalies; cc=cc0*2/5; else; cc=scaleAnom/10*cc0/2; end;
    pcolor(x,y,fld); shading interp; axis([TT(1) TT(end) -90 90]); cbar=gcmfaces_cmap_cbar(cc);
    title('zonal mean SSS minus first year (psu)');
    %
    myCaption={'zonal mean temperature (degC; top) and salinity ',...
        '(psu; bottom) minus first year (psu)',[' at ' num2str(-mygrid.RC(kk)) 'm depth']};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    figureL; set(gcf,'Renderer','zbuffer'); cc=[-2:0.25:2]; kk=1;
    if doAnomalies; cc=scaleAnom/10*cc/2; end;
    x=TT*ones(1,length(mygrid.LATS)); y=ones(nt,1)*mygrid.LATS'; x=x'; y=y';
    %SSH
    subplot(2,1,1);
    [tmp1,fld]=annualmean(alldiag.listTimes,alldiag.fldSSHzonmean,'first');
    pcolor(x,y,fld); shading interp; axis([TT(1) TT(end) -90 90]);
    cbar=gcmfaces_cmap_cbar(2*cc/25); title(['zonal mean SSH minus first year (INCLUDING ice, in m)']);
    %ETAN
    subplot(2,1,2);
    [tmp1,fld]=annualmean(alldiag.listTimes,alldiag.fldETANzonmean,'first');
    pcolor(x,y,fld); shading interp; axis([TT(1) TT(end) -90 90]);
    cbar=gcmfaces_cmap_cbar(4*cc/5); title(['zonal mean SSH minus first year (EXCLUDING ice, in m)']);
    %
    myCaption={'zonal mean SSH (m, uncorrected free surface) minus first year, including ice (top) and below ice (bottom) '};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    figureL; set(gcf,'Renderer','zbuffer'); cc=[-2:0.25:2]; kk=1;
    if doAnomalies; cc=scaleAnom/10*cc; end;
    x=TT*ones(1,length(mygrid.LATS)); y=ones(nt,1)*mygrid.LATS'; x=x'; y=y';
    %SSH
    subplot(2,1,1);
    fld=squeeze(alldiag.fldSIzonmean(:,tt));
    pcolor(x,y,fld); shading interp; axis([TT(1) TT(end) -90 90]);
    if doAnomalies; cc2=scaleAnom/50*cc; else; cc2=0.5+cc/4; end;
    cbar=gcmfaces_cmap_cbar(cc2); title(['zonal mean Ice conc. -- in m ']);
    %MLD
    subplot(2,1,2);
    fld=squeeze(alldiag.fldMLDzonmean(:,tt));
    pcolor(x,y,fld); shading interp; axis([TT(1) TT(end) -90 90]);
    if doAnomalies; cc2=scaleAnom*40*cc; else; cc2=200+500*cc/5; end;
    cbar=gcmfaces_cmap_cbar(cc2); title(['zonal mean MLD -- in m ']);
    %
    myCaption={'zonal mean ice concentration (no units) and mixed layer depth (m)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    end;


    if multiTimes&(sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'icetime')));

    if addToTex; write2tex(fileTex,1,'seaice time series',2); end;

    %sea ice area
    figureL;
    subplot(2,1,1); vec=alldiag.IceAreaNorth/1e12;
    plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2); axis([min(TT) max(TT) 0 20]);
    if doAnomalies; aa(3:4)=scaleAnom*[-1 1]; axis(aa); end;
    grid on; if myNmean>0; legend('monthly','annual mean'); end; title('Northern Hemisphere ice cover (in 10^{12}m^2)');
    subplot(2,1,2); vec=alldiag.IceAreaSouth/1e12;
    plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2); axis([min(TT) max(TT) 0 25]);
    grid on; if myNmean>0; legend('monthly','annual mean'); end; title('Southern Hemisphere ice cover (in 10^{12}m^2)');
    if doAnomalies; aa(3:4)=scaleAnom*[-1 1]; axis(aa); end;
    myCaption={'sea ice cover (in $10^{12}m^2$) in northern (top) and southern (bottom) hemisphere'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %sea ice volume
    figureL;
    subplot(2,1,1); vec=alldiag.IceVolNorth/1e12;
    plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2); axis([min(TT) max(TT) 0 50]);
    grid on; if myNmean>0; legend('monthly','annual mean'); end; title('Northern Hemisphere ice volume (in 10^{12m}^3)');
    if doAnomalies; aa(3:4)=scaleAnom*[-1 1]*2; axis(aa); end;
    subplot(2,1,2); vec=alldiag.IceVolSouth/1e12;
    plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2); axis([min(TT) max(TT) 0 15]);
    grid on; if myNmean>0; legend('monthly','annual mean'); end; title('Southern Hemisphere ice volume (in 10^{12}m^3)');
    if doAnomalies; aa(3:4)=scaleAnom*[-1 1]*2; axis(aa); end;
    myCaption={'sea ice volume (in $10^{12}m^3$) in northern (top) and southern (bottom) hemisphere'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %snow volume
    figureL;
    subplot(2,1,1); vec=alldiag.SnowVolNorth/1e12;
    plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2); axis([min(TT) max(TT) 0 5]);
    grid on; if myNmean>0; legend('monthly','annual mean'); end; title('Northern Hemisphere snow volume (in 10^{12}m^3)');
    if doAnomalies; aa(3:4)=scaleAnom*[-1 1]; axis(aa); end;
    subplot(2,1,2); vec=alldiag.SnowVolSouth/1e12;
    plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2); axis([min(TT) max(TT) 0 4]);
    grid on; if myNmean>0; legend('monthly','annual mean'); end; title('Southern Hemisphere snow volume (in 10^{12}m^3)');
    if doAnomalies; aa(3:4)=scaleAnom*[-1 1]; axis(aa); end;
    myCaption={'snow volume (in $10^{12}m^3$) in northern (top) and southern (bottom) hemisphere'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    if ~doAnomalies; %does not work for anomalies -> need to compute ratio in basic_diags_ecco
        %sea ice thickness
        figureL;
        subplot(2,1,1); vec=alldiag.IceVolNorth./alldiag.IceAreaNorth;
        plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2); axis([min(TT) max(TT) 0 5]);
        grid on; if myNmean>0; legend('monthly','annual mean'); end; title('Northern Hemisphere ice thickness (in m)');
        if doAnomalies; aa(3:4)=scaleAnom*[-1 1]; axis(aa); end;
        subplot(2,1,2); vec=alldiag.IceVolSouth./alldiag.IceAreaSouth;
        plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2); axis([min(TT) max(TT) 0 2]);
        grid on; if myNmean>0; legend('monthly','annual mean'); end; title('Southern Hemisphere ice thickness (in m)');
        if doAnomalies; aa(3:4)=scaleAnom*[-1 1]; axis(aa); end;
        myCaption={'sea ice thickness (in m) in northern (top) and southern (bottom) hemisphere'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

        %sea ice thickness
        figureL;
        subplot(2,1,1); vec=alldiag.SnowVolNorth./alldiag.IceAreaNorth;
        plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2); axis([min(TT) max(TT) 0 0.4]);
        grid on; if myNmean>0; legend('monthly','annual mean'); end; title('Northern Hemisphere snow thickness (in m)');
        if doAnomalies; aa(3:4)=scaleAnom*[-1 1]; axis(aa); end;
        subplot(2,1,2); vec=alldiag.SnowVolSouth./alldiag.IceAreaSouth;
        plot(TT,vec,'LineWidth',2); hold on; plot(TT,runmean(vec,myNmean,2),'r','LineWidth',2); axis([min(TT) max(TT) 0 0.25]);
        grid on; if myNmean>0; legend('monthly','annual mean'); end; title('Southern Hemisphere snow thickness (in m)');
        if doAnomalies; aa(3:4)=scaleAnom*[-1 1]; axis(aa); end;
        myCaption={'snow thickness (in m) in northern (top) and southern (bottom) hemisphere'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;

end;
