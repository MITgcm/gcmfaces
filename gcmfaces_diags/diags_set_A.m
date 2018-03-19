
if userStep==1;%diags to be computed
    listDiags='fldBAR fldTRANSPORTS gloOV gloOVbolus gloOVres gloMT_H gloMT_FW gloMT_SLT';
    listBasins=1;
    if sum([90 1170]~=mygrid.ioSize)==0;
        listBasins=[1:3];
        mskC=v4_basin({'atlExt'});
        if isempty(mskC); listBasins=1; end;
    end;
    if length(listBasins)==3;
      listDiags=[listDiags ' atlOV atlOVbolus atlOVres atlMT_H atlMT_FW atlMT_SLT'];
      listDiags=[listDiags ' pacindOV pacindOVbolus pacindOVres pacindMT_H pacindMT_FW pacindMT_SLT'];
    end;
elseif userStep==2;%input files and variables
    listFlds={'UVELMASS','VVELMASS','GM_PsiX','GM_PsiY'};
    listFlds={listFlds{:},'ADVx_TH ','ADVy_TH ','DFxE_TH ','DFyE_TH '};
    listFlds={listFlds{:},'ADVx_SLT','ADVy_SLT','DFxE_SLT','DFyE_SLT'};
    listFldsNames=deblank(listFlds);
    listFiles={'trsp_3d_set1','trsp_2d_set1','trsp_3d_set2'};
    listSubdirs={[dirModel 'diags/TRSP/'],[dirModel 'diags/']};
elseif userStep==3;%computational part;
        %mask fields:
        fldU=UVELMASS.*mygrid.mskW; fldV=VVELMASS.*mygrid.mskS;
        if ~isempty(whos('ADVx_TH'));%for backward compatibility
            if size(ADVx_TH{1},3)>1; %assume full 3D fields
                mskW=mygrid.mskW; mskS=mygrid.mskS;
            else; %assume vertically integrated (2D fields)
                mskW=mygrid.mskW(:,:,1); mskS=mygrid.mskS(:,:,1);
            end;
            ADVx_TH=ADVx_TH.*mskW; ADVy_TH=ADVy_TH.*mskS;
            ADVx_SLT=ADVx_SLT.*mskW; ADVy_SLT=ADVy_SLT.*mskS;
            DFxE_TH=DFxE_TH.*mskW; DFyE_TH=DFyE_TH.*mskS;
            DFxE_SLT=DFxE_SLT.*mskW; DFyE_SLT=DFyE_SLT.*mskS;
        end;
        if ~isempty(whos('GM_PsiX'));%for backward compatibility
            [fldUbolus,fldVbolus,fldWbolus]=calc_bolus(GM_PsiX,GM_PsiY);
            fldUbolus=fldUbolus.*mygrid.mskW; fldVbolus=fldVbolus.*mygrid.mskS;
            fldUres=fldU+fldUbolus; fldVres=fldV+fldVbolus;
        end;
        
        %compute barotropic stream function:
        [fldBAR]=calc_barostream(fldU,fldV);
        %compute transports along transects:
        [fldTRANSPORTS]=1e-6*calc_transports(fldU,fldV,mygrid.LINES_MASKS,{'dh','dz'});

        %compute overturning stream functions:
        for bb=listBasins;
            %mask : global, atlantic or Pac+Ind
            if bb==1;       mskC=mygrid.mskC; mskC(:)=1;
            elseif bb==2;   mskC=v4_basin({'atlExt'}); mskC=mk3D(mskC,fldU);
            elseif bb==3;   mskC=v4_basin({'pacExt','indExt'}); mskC=mk3D(mskC,fldU);
            end;
            %note: while mskC is a basin mask for tracer points, it can be applied to U/V below
            %compute overturning: eulerian contribution
            [fldOV]=calc_overturn(fldU.*mskC,fldV.*mskC);
            if ~isempty(whos('GM_PsiX'));%for backward compatibility
                %compute overturning: eddy contribution
                [fldOVbolus]=calc_overturn(fldUbolus.*mskC,fldVbolus.*mskC);
                %compute overturning: residual overturn
                [fldOVres]=calc_overturn(fldUres.*mskC,fldVres.*mskC);
            else;
                fldOVbolus=NaN*fldOV; fldOVres=NaN*fldOV;
            end;
            
            if ~isempty(whos('ADVx_TH'));%for backward compatibility
                %compute meridional heat transports:
                tmpU=(ADVx_TH+DFxE_TH).*mskC(:,:,1:size(ADVx_TH{1},3));
                tmpV=(ADVy_TH+DFyE_TH).*mskC(:,:,1:size(ADVx_TH{1},3));
                [fldMT_H]=1e-15*4e6*calc_MeridionalTransport(tmpU,tmpV,0);
                %compute meridional fresh water transports:
                %... using the virtual salt flux formula:
                %[fldMT_FW]=1e-6/35*calc_MeridionalTransport(ADVx_SLT+DFxE_SLT,ADVy_SLT+DFyE_SLT,0);
                %[fldMT_FW]=1e-6/35*calc_MeridionalTransport(ADVx_SLT,ADVy_SLT,0);
                %... using the real freshwater flux formula:
                [fldMT_FW]=1e-6*calc_MeridionalTransport(fldU.*mskC,fldV.*mskC,1);
                %compute meridional salt transports:
                tmpU=(ADVx_SLT+DFxE_SLT).*mskC(:,:,1:size(ADVx_TH{1},3));
                tmpV=(ADVy_SLT+DFyE_SLT).*mskC(:,:,1:size(ADVx_TH{1},3));
                [fldMT_SLT]=1e-6*calc_MeridionalTransport(tmpU,tmpV,0);
            else;
                fldMT_H=NaN*mygrid.LATS; fldMT_FW=NaN*mygrid.LATS; fldMT_SLT=NaN*mygrid.LATS;
            end;
            
            %store to global, atlantic or Pac+Ind arrays:
            if bb==1;
                gloMT_H=fldMT_H; gloMT_FW=fldMT_FW; gloMT_SLT=fldMT_SLT;
                gloOV=fldOV; gloOVbolus=fldOVbolus; gloOVres=fldOVres;
            elseif bb==2;
                kk=find(mygrid.LATS<-35|mygrid.LATS>70);
                fldMT_H(kk,:)=NaN; fldMT_FW(kk,:)=NaN; fldMT_SLT(kk,:)=NaN;
                fldOV(kk,:)=NaN; fldOVbolus(kk,:)=NaN; fldOVres(kk,:)=NaN;
                atlMT_H=fldMT_H; atlMT_FW=fldMT_FW; atlMT_SLT=fldMT_SLT;
                atlOV=fldOV; atlOVbolus=fldOVbolus; atlOVres=fldOVres;
            elseif bb==3;
                kk=find(mygrid.LATS<-35|mygrid.LATS>65);
                fldMT_H(kk,:)=NaN; fldMT_FW(kk,:)=NaN; fldMT_SLT(kk,:)=NaN;
                fldOV(kk,:)=NaN; fldOVbolus(kk,:)=NaN; fldOVres(kk,:)=NaN;
                pacindMT_H=fldMT_H; pacindMT_FW=fldMT_FW; pacindMT_SLT=fldMT_SLT;
                pacindOV=fldOV; pacindOVbolus=fldOVbolus; pacindOVres=fldOVres;
            end;
        end;    

%===================== COMPUTATIONAL SEQUENCE ENDS =========================%
%===================== PLOTTING SEQUENCE BEGINS    =========================%

elseif userStep==-1;%plotting

    if isempty(setDiagsParams);
      choicePlot={'all'};
    else;
      choicePlot=setDiagsParams;
    end;

    if ~sum(strcmp(listDiags,'atlOV')); multiBasins=0; end;

    if sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'bf'));

    if addToTex; write2tex(fileTex,1,'barotropic streamfunction',2); end;

    %barotropic streamfunction:
    fld=mean(alldiag.fldBAR(:,:,tt),3);
    cc=[[-80:20:-40] [-25 -15:5:15 25] [40:40:200]]; title0='Horizontal Stream Function';
    if doAnomalies; cc=scaleAnom*[-5:0.5:5]; end;
    figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
    myCaption={myYmeanTxt,'mean -- barotropic streamfunction (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    %and the corresponding standard deviation:
    if multiTimes;
        fld=std(alldiag.fldBAR(:,:,tt),[],3);
        cc=[0:0.5:3 4 5 7 10 15:5:25 35 50]; title0='Horizontal Stream Function';
        if doAnomalies; cc=scaleAnom*[0:0.25:2]; end;
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'do_m_coast',1},{'myTitle',title0});
        myCaption={myYmeanTxt,' standard deviation -- barotropic streamfunction (Sv)'};
        if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;

    if sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'ov'));

    if addToTex; write2tex(fileTex,1,'meridional streamfunction',2); end;

    %meridional streamfunction (Eulerian) :
    fld=mean(alldiag.gloOV(:,:,tt),3); fld(fld==0)=NaN;
    X=mygrid.LATS*ones(1,length(mygrid.RF)); Y=ones(length(mygrid.LATS),1)*(mygrid.RF');
    cc=[[-50:10:-30] [-24:3:24] [30:10:50]]; title0='Meridional Stream Function';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]; end;
    figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end; %set(gcf,'Units','Normalized','Position',[0.05 0.1 0.4 0.8]);
    depthStretchPlot('pcolor',{X,Y,fld}); shading interp; cbar=gcmfaces_cmap_cbar(cc); title(title0);
    myCaption={myYmeanTxt,'mean -- overturning streamfunction (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %meridional streamfunction (residual) :
    fld=mean(alldiag.gloOVres(:,:,tt),3); fld(fld==0)=NaN;
    X=mygrid.LATS*ones(1,length(mygrid.RF)); Y=ones(length(mygrid.LATS),1)*(mygrid.RF');
    cc=[[-50:10:-30] [-24:3:24] [30:10:50]]; title0='Meridional Stream Function (incl. GM)';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]; end;
    figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end; %set(gcf,'Units','Normalized','Position',[0.05 0.1 0.4 0.8]);
    depthStretchPlot('pcolor',{X,Y,fld}); shading interp; cbar=gcmfaces_cmap_cbar(cc); title(title0);
    myCaption={myYmeanTxt,'mean -- overturning streamfunction incl. GM (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    if multiBasins;
    %meridional streamfunction (Eulerian):
    fld=mean(alldiag.atlOV(:,:,tt),3); fld(fld==0)=NaN;
    X=mygrid.LATS*ones(1,length(mygrid.RF)); Y=ones(length(mygrid.LATS),1)*(mygrid.RF');
    cc=[[-50:10:-30] [-24:3:24] [30:10:50]]; title0='Atlantic Meridional Stream Function';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]; end;
    figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end; %set(gcf,'Units','Normalized','Position',[0.05 0.1 0.4 0.8]);
    depthStretchPlot('pcolor',{X,Y,fld}); shading interp; cbar=gcmfaces_cmap_cbar(cc); title(title0);
    myCaption={myYmeanTxt,'mean -- Atlantic overturning streamfunction (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    %meridional streamfunction (residual):
    fld=mean(alldiag.pacindOV(:,:,tt),3); fld(fld==0)=NaN;
    X=mygrid.LATS*ones(1,length(mygrid.RF)); Y=ones(length(mygrid.LATS),1)*(mygrid.RF');
    cc=[[-50:10:-30] [-24:3:24] [30:10:50]]; title0='Pac+Ind Meridional Stream Function';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]; end;
    figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end; %set(gcf,'Units','Normalized','Position',[0.05 0.1 0.4 0.8]);
    depthStretchPlot('pcolor',{X,Y,fld}); shading interp; cbar=gcmfaces_cmap_cbar(cc); title(title0);
    myCaption={myYmeanTxt,'mean -- Pac+Ind overturning streamfunction (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    if multiTimes;
    %and the corresponding standard deviation:
    fld=std(alldiag.gloOV(:,:,tt),[],3); fld(fld==0)=NaN;
    X=mygrid.LATS*ones(1,length(mygrid.RF)); Y=ones(length(mygrid.LATS),1)*(mygrid.RF');
    cc=[0:0.5:3 4 5 7 10 15:5:25 35 50]; title0='Meridional Stream Function';
    if doAnomalies; cc=scaleAnom*[0:0.1:1]; end;
    figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end; %set(gcf,'Units','Normalized','Position',[0.05 0.1 0.4 0.8]);
    depthStretchPlot('pcolor',{X,Y,fld}); shading interp; cbar=gcmfaces_cmap_cbar(cc); title(title0);
    myCaption={myYmeanTxt,' standard deviation -- overturning streamfunction (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    if multiTimes&&multiBasins;
    %and the corresponding standard deviation:
    fld=std(alldiag.atlOV(:,:,tt),[],3); fld(fld==0)=NaN;
    X=mygrid.LATS*ones(1,length(mygrid.RF)); Y=ones(length(mygrid.LATS),1)*(mygrid.RF');
    cc=[0:0.5:3 4 5 7 10 15:5:25 35 50]; title0='Atlantic Meridional Stream Function';
    if doAnomalies; cc=scaleAnom*[0:0.1:1]; end;
    figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end; %set(gcf,'Units','Normalized','Position',[0.05 0.1 0.4 0.8]);
    depthStretchPlot('pcolor',{X,Y,fld}); shading interp; cbar=gcmfaces_cmap_cbar(cc); title(title0);
    myCaption={myYmeanTxt,' standard deviation -- Atlantic overturning streamfunction (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;

    if sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'ovtime'));

    if addToTex; write2tex(fileTex,1,'meridional streamfunction (time series)',2); end;

    %time series
    if multiTimes;
    figureL;
    tmp1=abs(-mygrid.RC-1000); kk=find(tmp1==min(tmp1)); kk=kk(1);
    gloOV1000=squeeze(alldiag.gloOV(:,kk,:)); gloOV1000=runmean(gloOV1000,myNmean,2);
    plot(TT,gloOV1000(90+25,:),'LineWidth',2); hold on; plot(TT,gloOV1000(90+35,:),'k','LineWidth',2);
    plot(TT,gloOV1000(90+45,:),'r','LineWidth',2); plot(TT,gloOV1000(90+55,:),'g','LineWidth',2);
    title0='annual global overturning at \approx 1000m depth (Sv)'; aa=axis; aa()
    legend('25N','35N','45N','55N'); title(title0);
    aa(3:4)=[0 20]; axis(aa); grid on;
    if doAnomalies; aa(3:4)=scaleAnom*[-1 1]; axis(aa); end;
    myCaption={'annual global overturning at select latitudes at $\\approx$ 1000m depth'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    if multiTimes&&multiBasins;
    figureL;
    tmp1=abs(-mygrid.RC-1000); kk=find(tmp1==min(tmp1)); kk=kk(1);
    atlOV1000=squeeze(alldiag.atlOV(:,kk,:)); atlOV1000=runmean(atlOV1000,myNmean,2);
    plot(TT,atlOV1000(90+25,:),'LineWidth',2); hold on; plot(TT,atlOV1000(90+35,:),'k','LineWidth',2);
    plot(TT,atlOV1000(90+45,:),'r','LineWidth',2); plot(TT,atlOV1000(90+55,:),'g','LineWidth',2);
    title0='annual atlantic overturning at \approx 1000m depth';
    legend('25N','35N','45N','55N'); title(title0);
    aa(3:4)=[0 20]; axis(aa); grid on;
    if doAnomalies; aa(3:4)=scaleAnom*[-1 1]*2; axis(aa); end;
    myCaption={'annual Atlantic overturning at select latitudes at $\\approx$ 1000m depth (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;

    if sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'mht'));

    if addToTex; write2tex(fileTex,1,'meridional heat transport',2); end;

    %meridional heat transport
    figureL; 
    fld=mean(alldiag.gloMT_H(:,tt),2);
    plot(mygrid.LATS,fld,'LineWidth',2);
    if multiBasins;
      atl=mean(alldiag.atlMT_H(:,tt),2); pacind=mean(alldiag.pacindMT_H(:,tt),2);
      hold on; plot(mygrid.LATS,atl,'r','LineWidth',2);
      plot(mygrid.LATS,pacind,'g','LineWidth',2);
      legend('global','Atlantic','Pacific+Indian','Location','SouthEast');
    end;
    set(gca,'FontSize',14); grid on; axis([-90 90 -2 2]);
    if doAnomalies; aa=axis; aa(3:4)=scaleAnom*[-1 1]*0.05; axis(aa); end;
    title('Meridional Heat Transport (in PW)');
    myCaption={myYmeanTxt,'mean -- meridional heat transport (PW)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %and the corresponding standard deviation:
    if multiTimes;
    figureL;
    fld=std(alldiag.gloMT_H(:,tt),[],2);
    plot(mygrid.LATS,fld,'LineWidth',2);
    if multiBasins;
       atl=std(alldiag.atlMT_H(:,tt),[],2);
       pacind=std(alldiag.pacindMT_H(:,tt),[],2);
       hold on; plot(mygrid.LATS,atl,'r','LineWidth',2);
       plot(mygrid.LATS,pacind,'g','LineWidth',2);
       legend('global','Atlantic','Pacific+Indian');
    end;
    set(gca,'FontSize',14); grid on; axis([-90 90 0 4]);
    if doAnomalies; aa=axis; aa(3:4)=scaleAnom*[0 1]*0.1; axis(aa); end;
    title('Meridional Heat Transport (in PW)');
    myCaption={myYmeanTxt,' standard deviation -- meridional heat transport (PW)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;

    if sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'mfwt'));

    if addToTex; write2tex(fileTex,1,'meridional freshwater transport',2); end;

    %meridional freshwater transport
    figureL;
    fld=mean(alldiag.gloMT_FW(:,tt),2);
    plot(mygrid.LATS,fld,'LineWidth',2);
    if multiBasins;
       atl=mean(alldiag.atlMT_FW(:,tt),2); pacind=mean(alldiag.pacindMT_FW(:,tt),2);
       hold on; plot(mygrid.LATS,atl,'r','LineWidth',2);
       plot(mygrid.LATS,pacind,'g','LineWidth',2);
       legend('global','Atlantic','Pacific+Indian');
    end;
    set(gca,'FontSize',14); grid on; axis([-90 90 -1.5 2.0]);
    if doAnomalies; aa=axis; aa(3:4)=scaleAnom*[-1 1]*0.1; axis(aa); end;
    title('Meridional Freshwater Transport (in Sv)');
    myCaption={myYmeanTxt,'mean -- meridional freshwater transport (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %and the corresponding standard deviation:
    if multiTimes;
    figureL;
    fld=std(alldiag.gloMT_FW(:,tt),[],2);
    plot(mygrid.LATS,fld,'LineWidth',2);
    if multiBasins;
       atl=std(alldiag.atlMT_FW(:,tt),[],2); pacind=std(alldiag.pacindMT_FW(:,tt),[],2);
       hold on; plot(mygrid.LATS,atl,'r','LineWidth',2);
       plot(mygrid.LATS,pacind,'g','LineWidth',2);
       legend('global','Atlantic','Pacific+Indian');
    end;
    set(gca,'FontSize',14); grid on; axis([-90 90 0 2]);
    if doAnomalies; aa=axis; aa(3:4)=scaleAnom*[0 1]*0.2; axis(aa); end;
    title('Meridional Freshwater Transport (in Sv)');
    myCaption={myYmeanTxt,' standard deviation -- meridional freshwater transport (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;

    if sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'mslt'));

    if addToTex; write2tex(fileTex,1,'meridional salt transport',2); end;

    %meridional salt transport
    figureL;
    fld=mean(alldiag.gloMT_SLT(:,tt),2);
    plot(mygrid.LATS,fld,'LineWidth',2);
    if multiBasins;
       atl=mean(alldiag.atlMT_SLT(:,tt),2); pacind=mean(alldiag.pacindMT_SLT(:,tt),2);
       hold on; plot(mygrid.LATS,atl,'r','LineWidth',2);
       plot(mygrid.LATS,pacind,'g','LineWidth',2);
       legend('global','Atlantic','Pacific+Indian');
    end;
    set(gca,'FontSize',14); grid on; axis([-90 90 -50 50]);
    if doAnomalies; aa=axis; aa(3:4)=scaleAnom*[-1 1]*2; axis(aa); end;
    title('Meridional Salt Transport (in psu.Sv)');
    myCaption={myYmeanTxt,'mean -- meridional salt transport (psu.Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    %and the corresponding standard deviation:

    if multiTimes;
    figureL;
    fld=std(alldiag.gloMT_SLT(:,tt),[],2);
    plot(mygrid.LATS,fld,'LineWidth',2);
    if multiBasins;
      atl=std(alldiag.atlMT_SLT(:,tt),[],2); pacind=std(alldiag.pacindMT_SLT(:,tt),[],2);
      hold on; plot(mygrid.LATS,atl,'r','LineWidth',2);
      plot(mygrid.LATS,pacind,'g','LineWidth',2);
      legend('global','Atlantic','Pacific+Indian');
    end;
    set(gca,'FontSize',14); grid on; axis([-90 90 0 60]);
    if doAnomalies; aa=axis; aa(3:4)=scaleAnom*[0 1]*2; axis(aa); end;
    title('Meridional Salt Transport (in psu.Sv)');
    myCaption={myYmeanTxt,' standard deviation -- meridional salt transport (psu.Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;
    end;

    end;

    if multiTimes&&(sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'mttime')));

    if addToTex; write2tex(fileTex,1,'meridional transports (time series)',2); end;

    %meridional heat transport
    fld=squeeze(alldiag.gloMT_H(:,tt))';
    x=TT*ones(1,length(mygrid.LATS)); y=ones(nt,1)*mygrid.LATS';
    fld=runmean(fld,myNmean,1);
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]/50;
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*0.05; end;
    figureL; pcolor(x,y,fld); shading flat; axis([TT(1) TT(end) -90 90]);
    gcmfaces_cmap_cbar(cc); title('Meridional Heat Transport (in PW)');
    myCaption={'meridional heat transport (PW, annual mean)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %meridional freshwater transport
    fld=squeeze(alldiag.gloMT_FW(:,tt))';
    x=TT*ones(1,length(mygrid.LATS)); y=ones(nt,1)*mygrid.LATS';
    fld=runmean(fld,myNmean,1);
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]/100;
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*0.05; end;
    figureL; pcolor(x,y,fld); shading flat; axis([TT(1) TT(end) -90 90]);
    gcmfaces_cmap_cbar(cc); title('Meridional Freshwater Transport (in Sv)');
    myCaption={'meridional freshwater transport (Sv, annual mean)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %meridional salt transport
    fld=squeeze(alldiag.gloMT_SLT(:,tt))';
    x=TT*ones(1,length(mygrid.LATS)); y=ones(nt,1)*mygrid.LATS';
    fld=runmean(fld,myNmean,1);
    cc=[[-250:50:-100] [-75 -50] [-35:10:35] [50 75] [100:50:250]]/10;
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]*1; end;
    figureL; pcolor(x,y,fld); shading flat; axis([TT(1) TT(end) -90 90]);
    gcmfaces_cmap_cbar(cc); title('Meridional Salt Transport (in psu.Sv)');
    myCaption={'meridional salt transport (psu.Sv, annual mean)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    end;


    if (sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'sectime')));

    if addToTex; write2tex(fileTex,1,'transects transport',2); end;

    %Bering Strait and Arctic/Atlantic exchanges:
    if multiTimes; figureL; end;
    iiList=[1 8:12]; rrList=[[-1 3];[-3 1];[-7 -2];[0 9];[-4 4];[-0.5 0.5]];
    for iii=1:length(iiList);
        ii=iiList(iii);
        if multiTimes; subplot(3,2,iii); end;
        trsp=squeeze(alldiag.fldTRANSPORTS(ii,:,:));
        txt=[mygrid.LINES_MASKS(ii).name ' (>0 to Arctic)'];
        ylim=rrList(iii,:);
        if doAnomalies; ylim=scaleAnom*[-1 1]*0.4; end;
        disp_transport(trsp,TT,txt,{'ylim',ylim},{'nmean',myNmean});
    end;
    myCaption={'volume transports entering the Arctic (Sv, annual mean)'};
    if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); end;
   
    %Florida Strait:
    if multiTimes; figureL; end;
    iiList=[3 4 6 7]; rrList=[[20 40];[20 40];[-1 3];[-6 2]];
    for iii=1:length(iiList);
        ii=iiList(iii);
        if multiTimes; subplot(2,2,iii); end;
        trsp=squeeze(alldiag.fldTRANSPORTS(ii,:,:));
        txt=[mygrid.LINES_MASKS(ii).name ' (>0 to Atlantic)'];
        ylim=rrList(iii,:);
        if doAnomalies; ylim=scaleAnom*[-1 1]*2; end;
        disp_transport(trsp,TT,txt,{'ylim',ylim},{'nmean',myNmean});
    end;
    myCaption={'volume transports entering the Atlantic (Sv, annual mean)'};
    if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); end;

    %Gibraltar special case:
    if multiTimes; figureL; end;
    trsp=squeeze(alldiag.fldTRANSPORTS(2,:,:));
    txt='Gibraltar Overturn (upper ocean transport towards Med.)';
    ylim=[0.4 1.2];
    if doAnomalies; ylim=scaleAnom*[-1 1]*0.05; end;
    disp_transport(trsp,TT,txt,{'ylim',ylim},{'nmean',myNmean},{'choicePlot',2});
    myCaption={'Gibraltar Overturn (Sv, annual mean)'};
    if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); end;

    %Drake, ACC etc:
    if multiTimes; figureL; end;
    iiList=[13 20 19 18]; rrList=[[120 180];[140 200];[-40 -10];[140 200]];
    for iii=1:length(iiList);
        ii=iiList(iii);
        if multiTimes; subplot(2,2,iii); end;
        trsp=squeeze(alldiag.fldTRANSPORTS(ii,:,:));
        txt=[mygrid.LINES_MASKS(ii).name ' (>0 westward)'];
        ylim=rrList(iii,:);
        if doAnomalies; ylim=scaleAnom*[-1 1]*5; end;
        disp_transport(trsp,TT,txt,{'ylim',ylim},{'nmean',myNmean});
    end;
    myCaption={'ACC volume transports (Sv, annual mean)'};
    if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); end;

    %Indonesian Throughflow special case:
    if multiTimes; figureL; end;
    %trsp=-squeeze(nansum(alldiag.fldTRANSPORTS([15:17],:,:),1));
    trsp=-squeeze(nansum(alldiag.fldTRANSPORTS([14:17],:,:),1));%needed to fix sign for the (small) No.14 transport
    txt='Indonesian Throughflow (>0 toward Indian Ocean)';
    ylim=[5 25];
    if doAnomalies; ylim=scaleAnom*[-1 1]*0.5; end;
    disp_transport(trsp,TT,txt,{'ylim',ylim},{'nmean',myNmean});
    myCaption={'Indonesian Throughflow (Sv, annual mean)'};
    if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); end;

    end;


end;
