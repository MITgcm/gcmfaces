
layersOffline=1;
layersEulerian=0;
integrateFromBottom=1;
if isempty(whos('setDiagsParams')); setDiagsParams={}; end;

if length(setDiagsParams)==2;
    layersName=setDiagsParams{1};
    layersLims=setDiagsParams{2};
    layersOffline=1;
    layersEulerian=1;%hacked : should be 0
elseif length(setDiagsParams)==1;
    layersName=setDiagsParams{1};
else;
    layersName='sigma';
    pref0=0;
    layersLims0=[18:0.5:22.5 22.8:0.2:27.4 27.5:0.02:28 28.2:0.2:29.2 29.5:0.5:31]';
    %pref0=2000;
    %layersLims0=[30:0.1:38]';
end;

layersFileSuff=['LAYERS_' layersName];
if layersOffline; layersFileSuff=['LAYERS_offline_' layersName]; end;

%override default file name:
%---------------------------
fileMat=['diags_set_' layersFileSuff];

if userStep==1;%diags to be computed
    listDiags=['layersParams gloOV gloThick gloDelThick gloBAR gloMT gloD'];
    listBasins=1;
    if sum([90 1170]~=mygrid.ioSize)==0;
        listBasins=[1:3];
        mskC=v4_basin({'atlExt'});
        if isempty(mskC); listBasins=1; end;
    end;
    if length(listBasins)==3;
      listDiags=[listDiags ' atlOV atlThick atlDelThick atlBAR atlMT atlD'];
      listDiags=[listDiags ' pacindOV pacindThick pacindDelThick pacindBAR pacindMT pacindD'];
    end;
elseif userStep==2&~layersOffline;%input files and variables
    listFlds={    ['LaUH' layersName],['LaVH' layersName],...
        ['LaHw' layersName],['LaHs' layersName]};
    listFldsNames=deblank(listFlds);
    listFiles={'layersDiags'};
    listSubdirs={[dirModel 'diags/LAYERS/' ],[dirModel 'diags/']};
    %load layersLims consistent with online MITgcmpkg/layers
    layersLims=squeeze(rdmds([dirModel 'diags/LAYERS/layers' layersName]));
elseif userStep==2&layersOffline;%input files and variables
    listFlds={'THETA','SALT','UVELMASS','VVELMASS','GM_PsiX','GM_PsiY'};
    listFldsNames=deblank(listFlds);
    listFiles={'state_3d_set1','trsp_3d_set1','trsp_3d_set2'};
elseif userStep==3;

    %override default file name:
    %---------------------------
    fileMat=['diags_set_' layersFileSuff '_' num2str(tt) '.mat'];
    
    if ~layersOffline;
        
        eval(['fldU=LaUH' layersName '; fldV=LaVH' layersName ';']);
        if ~isempty(whos(['LaHw' layersName]));
            eval(['fldHw=LaHw' layersName '; fldHs=LaHs' layersName ';']);
        else;
            fldHw=[]; fldHs=[];
        end;
        fldD=[];
        layersGrid=(layersLims(1:end-1)+layersLims(2:end))'/2;
        
    else;
        
        if ~layersEulerian;
            [fldUbolus,fldVbolus,fldWbolus]=calc_bolus(GM_PsiX,GM_PsiY);
            fldUbolus=fldUbolus.*mygrid.mskW; fldVbolus=fldVbolus.*mygrid.mskS;
            UVELMASS=UVELMASS+fldUbolus; VVELMASS=VVELMASS+fldVbolus;
        end;
        
        U=UVELMASS.*mk3D(mygrid.DRF,UVELMASS);
        V=VVELMASS.*mk3D(mygrid.DRF,VVELMASS);

        if strcmp(layersName,'theta');
            tracer=THETA;
            if isempty(whos('layersLims')); layersLims=[-2:35]; end;
        elseif strcmp(layersName,'salt');
            tracer=SALT;
            if isempty(whos('layersLims')); layersLims=[33:0.1:38]; end;
        elseif strcmp(layersName,'sigma');
            P=mk3D(-mygrid.RC,THETA);
            t=convert2vector(THETA);
            s=convert2vector(SALT);
            p=convert2vector(P);
            pref=pref0+0*p;
            [rhop,rhpis,rhor] = density(t(:),s(:),p(:),pref(:));
            rhor=reshape(rhor,size(t));
            tracer=convert2vector(rhor)-1000;
            if isempty(whos('layersLims')); layersLims=layersLims0; end;
        end
        
        layersGrid=(layersLims(1:end-1)+layersLims(2:end))'/2;
        [fldU,fldV]=layers_remap({U,V},'extensive',tracer,layersGrid,2);
        fldHw=[]; fldHs=[];
        [fldD]=layers_remap(P,'intensive',tracer,layersGrid,2);

    end;%if ~layersOffline;

    for bb=listBasins;

    %mask : global, atlantic or Pac+Ind
    if bb==1;       mskC=mygrid.mskC(:,:,1); mskW=mygrid.mskW(:,:,1); mskS=mygrid.mskS(:,:,1);
    elseif bb==2;   [mskC,mskW,mskS]=v4_basin({'atlExt'});
    elseif bb==3;   [mskC,mskW,mskS]=v4_basin({'pacExt','indExt'});
    end;
    mskC3d=1*(mskC>0); mskW3d=1*(mskW>0); mskS3d=1*(mskS>0);
    mskC3d=mk3D(mskC3d,fldU); mskW3d=mk3D(mskW3d,fldU); mskS3d=mk3D(mskS3d,fldU);

    %the overturning streamfunction computation itself
    layersOV=calc_overturn(fldU.*mskW3d,fldV.*mskS3d,1,{'dh'});

    %the associated barotropic streamfunction (for checking)
    layersBAR=calc_barostream(fldU.*mskW3d,fldV.*mskS3d,1,{'dh'});

    %meridional transport per layer:
    layersMT=diff(layersOV,1,2); 

    if ~isempty(fldD);
      %compute zonal mean depth from fldD
      layersD=calc_zonmean_T(fldD.*mskC3d);
    else;
      layersD=[];
    end;

    %the associated thickness
    if isempty(fldHw);
        layersThick=[];
        layersDelThick=[];
    else;
        %interpolate to tracer points
        fldH=0*fldHw;
        [fldHwp,fldHsp]=exch_UV(LaHw1SLT.*mskW3d,LaHs1SLT.*mskS3d);
        for iF=1:fldH.nFaces;
            tmpA=fldHwp{iF}(2:end,:,:);
            tmpB=fldHwp{iF}(1:end-1,:,:);
            tmpC=fldHsp{iF}(:,2:end,:);
            tmpD=fldHsp{iF}(:,1:end-1,:);
            tmpTot=tmpA+tmpB+tmpC+tmpD;
            tmpNb=1*(tmpA~=0)+1*(tmpB~=0)+1*(tmpC~=0)+1*(tmpD~=0);
            jj=find(tmpNb>0); tmpTot(jj)=tmpTot(jj)./tmpNb(jj);
            jj=find(isnan(tmpTot)); tmpTot(jj)=0;
            fldH{iF}=tmpTot;
        end;
        %compute zonal mean
        fldH=calc_zonmean_T(fldH.*mskC3d);
        %integrate to overturning points
        if integrateFromBottom;
            layersThick=[flipdim(cumsum(flipdim(fldH,2),2),2) zeros(size(fldH,1),1)];
        else;
            layersThick=[zeros(size(fldH,1),1) cumsum(fldH,2)];
        end;
        %compute dH/dLayer
        layersDelThick=[zeros(size(fldH,1),1) fldH./( ones(size(fldH,1),1)*diff(layersLims') )];
    end;

    %store to global, atlantic or Pac+Ind arrays:
    if bb==1;
        gloOV=layersOV; gloThick=layersThick; gloDelThick=layersDelThick; 
        gloBAR=layersBAR; gloMT=layersMT; gloD=layersD;
    elseif bb==2;
        kk=find(mygrid.LATS<-35|mygrid.LATS>70);
        layersOV(kk,:)=NaN; layersMT(kk,:)=NaN;
        if ~isempty(layersThick); layersThick(kk,:)=NaN; layersDelThick(kk,:)=NaN; end;
        atlOV=layersOV; atlThick=layersThick; atlDelThick=layersDelThick;
        atlBAR=layersBAR; atlMT=layersMT; atlD=layersD;
    elseif bb==3;
        kk=find(mygrid.LATS<-35|mygrid.LATS>65);
        layersOV(kk,:)=NaN; layersMT(kk,:)=NaN;
        if ~isempty(layersThick); layersThick(kk,:)=NaN; layersDelThick(kk,:)=NaN; end;
        pacindOV=layersOV; pacindThick=layersThick; pacindDelThick=layersDelThick;
        pacindBAR=layersBAR; pacindMT=layersMT; pacindD=layersD;
    end;
    end;
    
    layersParams.name=layersName;
    layersParams.LC=layersGrid;
    layersParams.LF=layersLims;
    layersParams.isOffline=layersOffline;
    layersParams.suffix=layersFileSuff;
    layersParams.isEulerian=layersEulerian;

%===================== COMPUTATIONAL SEQUENCE ENDS =========================%
%===================== PLOTTING SEQUENCE BEGINS    =========================%

elseif userStep==-1;%plotting
   
    if ~sum(strcmp(listDiags,'atlOV')); multiBasins=0; end;
 
    X=mygrid.LATS*ones(1,length(alldiag.layersParams(1).LF));
    Y=ones(length(mygrid.LATS),1)*(alldiag.layersParams(1).LF');
    cc=[[-50:10:-30] [-24:3:24] [30:10:50]];

    %meridional streamfunction (Eulerian) :
    fld=mean(alldiag.gloOV(:,:,tt),3); fld(fld==0)=NaN; title0='Meridional Stream Function';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]; end;
    figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end; %set(gcf,'Units','Normalized','Position',[0.05 0.1 0.4 0.8]);
    pcolor(X,Y,fld); shading interp; cbar=gcmfaces_cmap_cbar(cc); title(title0); set(gca,'YDir','reverse');
    myCaption={myYmeanTxt,'mean -- overturning streamfunction (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    if multiBasins;

    %meridional streamfunction in Atlantic:
    fld=mean(alldiag.atlOV(:,:,tt),3); fld(fld==0)=NaN; title0='Atlantic Meridional Stream Function';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]; end;
    figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end; %set(gcf,'Units','Normalized','Position',[0.05 0.1 0.4 0.8]);
    pcolor(X,Y,fld); shading interp; cbar=gcmfaces_cmap_cbar(cc); title(title0); set(gca,'YDir','reverse');
    myCaption={myYmeanTxt,'mean -- Atlantic overturning streamfunction (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    %meridional streamfunction Pacific+Indian:
    fld=mean(alldiag.pacindOV(:,:,tt),3); fld(fld==0)=NaN; title0='Pac+Ind Meridional Stream Function';
    if doAnomalies; cc=scaleAnom*[-1:0.1:1]; end;
    figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end; %set(gcf,'Units','Normalized','Position',[0.05 0.1 0.4 0.8]);
    pcolor(X,Y,fld); shading interp; cbar=gcmfaces_cmap_cbar(cc); title(title0); set(gca,'YDir','reverse');
    myCaption={myYmeanTxt,'mean -- Pac+Ind overturning streamfunction (Sv)'};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

    end;

end;
