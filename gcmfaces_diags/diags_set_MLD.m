
if userStep==1;%diags to be computed
    listDiags='fldMldBoyer fldMldSuga fldMldKara';
elseif userStep==2;%input files and variables
    listFlds={    'THETA','SALT'};
    listFldsNames=deblank(listFlds);
    listFiles={'monthly_2d_set1','monthly_3d_set1','state_2d_set1','other_2d_set1','state_3d_set1'};
elseif userStep==3;%computational part;
        fldT=THETA.*mygrid.mskC; fldS=SALT.*mygrid.mskC;
        %
        %prepare to compute potential density:
        fldP=0*mygrid.mskC; for kk=1:length(mygrid.RC); fldP(:,:,kk)=-mygrid.RC(kk); end;
        T=convert2vector(fldT);
        S=convert2vector(fldS);
        msk=convert2vector(mygrid.mskC);
        P=convert2vector(fldP);
        %compute potential density:
        RHO=0*msk; alpha=0*msk;
        tmp1=find(~isnan(msk));
        RHO(tmp1) = density(T(tmp1),S(tmp1),P(tmp1));
        fldRhoPot=convert2vector(RHO);
        alpha(tmp1) = density(T(tmp1)+1e-4,S(tmp1),P(tmp1));
        fldAlpha=(convert2vector(alpha)-fldRhoPot)/1e-4;

        clear T S P msk RHO RHOis tmp1;

        %compute mld:
        tmp1=NaN*mygrid.mskC(:,:,1);
        for kk=1:50;
          tmp2=fldRhoPot(:,:,kk)-fldRhoPot(:,:,1);
          %if we pass RHO(1)+0.03 for the first time (or we reach the bottom)
          %then mld is the velocity point above RC(kk), which is RF(kk)
          jj=find((tmp2>0.03|isnan(tmp2))&isnan(tmp1));
         tmp1(jj)=-mygrid.RF(kk);
        end;
        fldMldBoyer=tmp1;

        %compute mld:
        tmp1=NaN*mygrid.mskC(:,:,1);
        for kk=1:50;
          tmp2=fldRhoPot(:,:,kk)-fldRhoPot(:,:,1);
          %if we pass RHO(1)+0.125 for the first time (or we reach the bottom)
          %then mld is the velocity point above RC(kk), which is RF(kk)
          jj=find((tmp2>0.125|isnan(tmp2))&isnan(tmp1));
         tmp1(jj)=-mygrid.RF(kk);
        end;
        fldMldSuga=tmp1;

        %compute mld:
        tmp1=NaN*mygrid.mskC(:,:,1);
        fldRhoPotMax=fldRhoPot(:,:,1)-0.8*fldAlpha(:,:,1);
        for kk=1:50;
          tmp2=fldRhoPot(:,:,kk)-fldRhoPotMax;
          %if we pass RHO(1)+0.8*alpha(1) for the first time (or we reach the bottom)
          %then mld is the velocity point above RC(kk), which is RF(kk)
          jj=find((tmp2>0|isnan(tmp2))&isnan(tmp1));
         tmp1(jj)=-mygrid.RF(kk);
        end;
        fldMldKara=tmp1;

elseif userStep==-1;%plotting;

  list_var={'fldMldKara','fldMldSuga','fldMldBoyer'};

  list_tit={' mixed layer depth per Kara formula (m)',...
            ' mixed layer depth per Suga formula (m)',...
            ' mixed layer depth per Boyer M. formula (m)'};

  if myparms.diagsAreMonthly==1;
  for seas=1:2;
  for vv=1:length(list_var);

    eval(['fld=alldiag.' list_var{vv} ';']);

    %compute mean march and september fields
    if seas==1; fld_seas=nanmedian(fld(:,:,3:12:nt),3); mon='March';
    else; fld_seas=nanmedian(fld(:,:,9:12:nt),3); mon='September';
    end;
    fld_seas(fld_seas==0)=NaN;
  
    %plot
    cc=[[0:20:100] [150:50:300] 400 [500:200:1100] [1500:500:2000]];
    if doAnomalies; cc=scaleAnom*[-5:0.5:5]; end;
    figureL; set(gcf,'Renderer','zbuffer');
    m_map_gcmfaces(fld_seas,0,{'myCaxis',cc});
    myCaption={myYmeanTxt,mon,' mean -- ',list_tit{vv}};
    if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

  end;%for vv=1:length(list_var);
  end;%for seas=1:2;
  end;%if myparms.diagsAreMonthly==1

end;


