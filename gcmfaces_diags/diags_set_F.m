
%select kBudget:
if ~isempty(setDiagsParams);
  kBudget=setDiagsParams{1};
else;
  kBudget=1;
end;

%override default file name:
%---------------------------
tmp1=setDiags;
if kBudget>1;
    tmp1=sprintf('F%02i',kBudget);
end;
fileMat=['diags_set_' tmp1];

if userStep==1;%diags to be computed
    listDiags=['glo_vol_ocn glo_vol_tot glo_vol_ice glo_bp'];
    listDiags=[listDiags ' glo_heat_ocn glo_heat_tot glo_heat_ice'];
    listDiags=[listDiags ' glo_salt_ocn glo_salt_tot glo_salt_ice'];
    if sum([90 1170]~=mygrid.ioSize)==0;
    listDiags=[listDiags ' gsbox_vol_ocn gsbox_vol_tot gsbox_vol_ice gsbox_bp'];
    listDiags=[listDiags ' arctic_vol_ocn arctic_vol_tot arctic_vol_ice arctic_bp'];
    listDiags=[listDiags ' gsbox_heat_ocn gsbox_heat_tot gsbox_heat_ice'];
    listDiags=[listDiags ' arctic_heat_ocn arctic_heat_tot arctic_heat_ice'];
    listDiags=[listDiags ' gsbox_salt_ocn gsbox_salt_tot gsbox_salt_ice'];
    listDiags=[listDiags ' arctic_salt_ocn arctic_salt_tot arctic_salt_ice'];
    end;

elseif userStep==2;%input files and variables
    listFlds={    'ETAN','SIheff','SIhsnow','THETA   ','SALT    ','PHIBOT','geothFlux'};
    listFlds={listFlds{:},'SIatmFW ','oceFWflx','SItflux','TFLUX','SFLUX','oceSPflx','SRELAX'};
    listFlds={listFlds{:},'oceQnet ','SIatmQnt','SIaaflux','SIsnPrcp','SIacSubl'};
    listFlds={listFlds{:},'TRELAX','WTHMASS','WSLTMASS','oceSflux','oceQsw','oceSPtnd'};
    if kBudget>1;
        listFlds={listFlds{:},'ADVr_TH','DFrE_TH','DFrI_TH','ADVr_SLT','DFrE_SLT','DFrI_SLT','WVELMASS'};
    end;
    listFlds={listFlds{:},'SDIAG1','SDIAG2','SDIAG3'};
    listFlds={listFlds{:},'UVELMASS','VVELMASS','AB_gT','AB_gS'};
    listFlds={listFlds{:},'ADVx_TH ','ADVy_TH ','DFxE_TH ','DFyE_TH '};
    listFlds={listFlds{:},'ADVx_SLT','ADVy_SLT','DFxE_SLT','DFyE_SLT'};
    listFlds={listFlds{:},'ADVxHEFF','ADVyHEFF','DFxEHEFF','DFyEHEFF'};
    listFlds={listFlds{:},'ADVxSNOW','ADVySNOW','DFxESNOW','DFyESNOW'};
    listFldsNames=deblank(listFlds);
    %
    listFiles={'rate_budg2d_snap_set1','budg2d_hflux_set1','budg2d_zflux_set1','budg2d_zflux_set2'};
    if kBudget==1;
        listFiles={listFiles{:},'rate_budg2d_snap_set2','budg2d_hflux_set2','geothermalFlux'};
    else;
        tmp1=sprintf('rate_budg2d_snap_set3_%02i',kBudget);
        tmp2=sprintf('budg2d_zflux_set3_%02i',kBudget);
        tmp3=sprintf('budg2d_hflux_set3_%02i',kBudget);
        tmp4=sprintf('geothermalFlux_%02i',kBudget);
        listFiles={listFiles{:},tmp1,tmp2,tmp3,tmp4};
    end;
    listSubdirs={[dirMat 'BUDG/' ],[dirMat '../BUDG/' ],[dirModel 'diags/BUDG/'],[dirModel 'diags/']};

elseif userStep==3;%computational part;

    %preliminary tests
    test1=isempty(dir([dirModel 'diags/BUDG/budg2d_snap_set1*']));
    test2=isempty(dir([dirMat 'BUDG/rate_budg2d_snap_set1*']))&&...
          isempty(dir([dirMat '../BUDG/rate_budg2d_snap_set1*']));

    if (strcmp(setDiags,'F')&&test1&&test2);
        fprintf('\n abort : global and regional budgets, due to missing \n');
        fprintf(['\n   ' dirModel 'diags/BUDG/budg2d_snap_set1* \n']);
        return;
    end;

    if (strcmp(setDiags,'F')&&test2);
        fprintf('\n abort : global and regional budgets, due to missing \n');
        fprintf(['\n   ' dirModel 'diags/BUDG/rate_budg2d_snap_set1* \n']);
        return;
    end;
    
    %override default file name:
    %---------------------------
    tmp1=setDiags;
    if kBudget>1;
        tmp1=sprintf('F%02i',kBudget);
    end;
    fileMat=['diags_set_' tmp1 '_' num2str(tt) '.mat'];
        
    %fill in optional fields:
    %------------------------
    if isempty(who('TRELAX')); TRELAX=0*mygrid.XC; end;
    if isempty(who('SRELAX')); SRELAX=0*mygrid.XC; end;
    if isempty(who('AB_gT')); AB_gT=0*mygrid.XC; end;
    if isempty(who('AB_gS')); AB_gS=0*mygrid.XC; end;
    if isempty(who('oceSPtnd')); oceSPtnd=0*mygrid.XC; end;
    if isempty(who('oceSPflx')); oceSPflx=0*mygrid.XC; end;
    if isempty(who('PHIBOT')); PHIBOT=0*mygrid.XC; end;
    if isempty(who('geothFlux')); geothFlux=0; end;

    %aliases from development phase (applies to 2012 core runs)
    %---------------------------------------------------------
    if ~isempty(who('SDIAG1')); SRELAX=SDIAG1; end;
    if ~isempty(who('SDIAG2')); SIatmFW=SDIAG2; end;
    if ~isempty(who('SDIAG3')); SItflux=SDIAG3; end;

    
    %=======MASS=========
    
    [budgMo,budgMi,budgMoi]=calc_budget_mass(kBudget);

    %bottom pressure for comparison:
    bp=myparms.rhoconst/9.81*PHIBOT;
    
    %compute global integrals:
    %-------------------------
    msk=mygrid.mskC(:,:,kBudget);
    tmp1=calc_mskmean_T(budgMoi,msk,'extensive');
    glo_vol_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgMo,msk,'extensive');
    glo_vol_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgMi,msk,'extensive');
    glo_vol_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    glo_bp=nansum(bp.*msk.*mygrid.RAC)/nansum(msk.*mygrid.RAC);

    if sum([90 1170]~=mygrid.ioSize)==0;    
    %compute gsbox integrals:
    msk=mygrid.mskC(:,:,kBudget).*v4_basin('atl').*(mygrid.YC>=26&mygrid.YC<=45);
    tmp1=calc_mskmean_T(budgMoi,msk,'extensive');
    gsbox_vol_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgMo,msk,'extensive');
    gsbox_vol_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgMi,msk,'extensive');
    gsbox_vol_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    gsbox_bp=nansum(bp.*msk.*mygrid.RAC)/nansum(msk.*mygrid.RAC);
    
    %and arctic integrals:
    msk=mygrid.mskC(:,:,kBudget).*v4_basin('arct');
    tmp1=calc_mskmean_T(budgMoi,msk,'extensive');
    arctic_vol_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgMo,msk,'extensive');
    arctic_vol_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgMi,msk,'extensive');
    arctic_vol_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    arctic_bp=nansum(bp.*msk.*mygrid.RAC)/nansum(msk.*mygrid.RAC);
    end;

    %=======HEAT=======
    
    [budgHo,budgHi,budgHoi]=calc_budget_heat(kBudget);

    %compute global integrals:
    %-------------------------
    msk=mygrid.mskC(:,:,kBudget);
    tmp1=calc_mskmean_T(budgHoi,msk,'extensive');
    glo_heat_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgHo,msk,'extensive');
    glo_heat_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgHi,msk,'extensive');
    glo_heat_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    
    if sum([90 1170]~=mygrid.ioSize)==0;
    %compute gsbox integrals:
    msk=mygrid.mskC(:,:,kBudget).*v4_basin('atl').*(mygrid.YC>=26&mygrid.YC<=45);
    tmp1=calc_mskmean_T(budgHoi,msk,'extensive');
    gsbox_heat_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgHo,msk,'extensive');
    gsbox_heat_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgHi,msk,'extensive');
    gsbox_heat_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    
    %and arctic integrals:
    msk=mygrid.mskC(:,:,kBudget).*v4_basin('arct');
    tmp1=calc_mskmean_T(budgHoi,msk,'extensive');
    arctic_heat_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgHo,msk,'extensive');
    arctic_heat_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgHi,msk,'extensive');
    arctic_heat_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    end;

    %=======SALT=======
    
    [budgSo,budgSi,budgSoi]=calc_budget_salt(kBudget);

    %compute global integrals:
    %-------------------------
    msk=mygrid.mskC(:,:,kBudget);
    tmp1=calc_mskmean_T(budgSoi,msk,'extensive');
    glo_salt_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgSo,msk,'extensive');
    glo_salt_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgSi,msk,'extensive');
    glo_salt_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];

    if sum([90 1170]~=mygrid.ioSize)==0;    
    %compute gsbox integrals:
    msk=mygrid.mskC(:,:,kBudget).*v4_basin('atl').*(mygrid.YC>=26&mygrid.YC<=45);
    tmp1=calc_mskmean_T(budgSoi,msk,'extensive');
    gsbox_salt_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgSo,msk,'extensive');
    gsbox_salt_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgSi,msk,'extensive');
    gsbox_salt_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    
    %and arctic integrals:
    msk=mygrid.mskC(:,:,kBudget).*v4_basin('arct');
    tmp1=calc_mskmean_T(budgSoi,msk,'extensive');
    arctic_salt_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgSo,msk,'extensive');
    arctic_salt_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgSi,msk,'extensive');
    arctic_salt_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    end;

%===================== COMPUTATIONAL SEQUENCE ENDS =========================%
%===================== PLOTTING SEQUENCE BEGINS    =========================%

elseif userStep==-1&&multiBasins==1;%plotting

    if isempty(setDiagsParams);
      choicePlot={'all'};
    elseif isnumeric(setDiagsParams{1})&&length(setDiagsParams)==1;
      choicePlot={'all'};
    elseif isnumeric(setDiagsParams{1});
      choicePlot={setDiagsParams{2:end}};
    else;
      choicePlot=setDiagsParams;
    end;

    tt=[1:length(alldiag.listTimes)];
    TT=alldiag.listTimes(tt);
    nt=length(TT);

    if (kBudget==1)&&(sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'mass')));

        %1.1) ocean+seaice mass budgets
        %------------------------------
        figureL;
        %global volume budget:
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_vol_tot,'kg/m2','Global Mean Mass (incl. ice)');
        %add bp:
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.glo_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        %gsboxern hemisphere budget:
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.gsbox_vol_tot,'kg/m2','Gulf Stream Box Mass (incl. ice)');
        %add bp:
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.gsbox_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        %arcticern hemisphere budget:
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.arctic_vol_tot,'kg/m2','Arctic Mass (incl. ice)');
        %add bp:
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.arctic_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) gsbox (mid) and arctic (lower), '};
        myCaption={myCaption{:},'mass budget (ocean+ice) in kg/m2.'};
        if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

        %1.2) ice mass budgets
        %---------------------
        figureL;
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_vol_ice,'kg/m2','Global Mean Mass (only ice)');
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.glo_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.gsbox_vol_ice,'kg/m2','Gulf Stream Box Mass (only ice)');
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.gsbox_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.arctic_vol_ice,'kg/m2','Arctic Mass (only ice)');
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.arctic_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) gsbox (mid) and arctic (lower), '};
        myCaption={myCaption{:},'mass budget (ice only) in kg/m2.'};
        if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;

    if (sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'mass')));

    %1.3) ocean mass budgets
    %-----------------------
    figureL;
    %global volume budget:
    subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_vol_ocn,'kg/m2','Global Mean Mass (only ocean)');
    dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.glo_bp);
    plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
    subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.gsbox_vol_ocn,'kg/m2','Gulf Stream Box Mass (only ocean)');
    dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.gsbox_bp);
    plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
    subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.arctic_vol_ocn,'kg/m2','Arctic Mass (only ocean)');
    dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.arctic_bp);
    plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
    %add to tex file
    myCaption={myYmeanTxt,' global (upper) gsbox (mid) and arctic (lower), '};
    myCaption={myCaption{:},'mass budget (ocean only) in kg/m2.'};
    if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;

    if (kBudget==1)&&(sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'heat')));

        %2.1) ocean+seaice heat budgets
        %------------------------------
        figureL;
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_heat_tot,'J/m2','Global Mean Ocean Heat (incl. ice)');
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.gsbox_heat_tot,'J/m2','Gulf Stream Box Ocean Heat (incl. ice)');
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.arctic_heat_tot,'J/m2','Arctic Ocean Heat (incl. ice)');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) gsbox (mid) and arctic (lower), '};
        myCaption={myCaption{:},'heat budget (ocean+ice) in J/m2.'};
        if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

        %2.2) ice heat budgets
        %---------------------
        figureL;
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_heat_ice,'J/m2','Global Mean Ocean Heat (only ice)');
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.gsbox_heat_ice,'J/m2','Gulf Stream Box Ocean Heat (only ice)');
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.arctic_heat_ice,'J/m2','Arctic Ocean Heat (only ice)');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) gsbox (mid) and arctic (lower), '};
        myCaption={myCaption{:},'heat budget (ice only) in J/m2.'};
        if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;

    if (sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'heat')));

    %2.3) ocean heat budgets
    %-----------------------
    figureL;
    subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_heat_ocn,'J/m2','Global Mean Ocean Heat (only ocean)');
    subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.gsbox_heat_ocn,'J/m2','Gulf Stream Box Ocean Heat (only ocean)');
    subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.arctic_heat_ocn,'J/m2','Arctic Ocean Heat (only ocean)');
    %add to tex file
    myCaption={myYmeanTxt,' global (upper) gsbox (mid) and arctic (lower), '};
    myCaption={myCaption{:},'heat budget (ocean only) in J/m2.'};
    if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;

    if (kBudget==1)&&(sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'salt')));

        %3.1) ocean+seaice salt budgets
        %------------------------------
        figureL;
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_salt_tot,'g/m2','Global Mean Ocean Salt (incl. ice)');
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.gsbox_salt_tot,'g/m2','Gulf Stream Box Ocean Salt (incl. ice)');
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.arctic_salt_tot,'g/m2','Arctic Ocean Salt (incl. ice)');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) gsbox (mid) and arctic (lower), '};
        myCaption={myCaption{:},'salt budget (ocean+ice) in g/m2.'};
        if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

        %2.2) ice salt budgets
        %---------------------
        figureL;
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_salt_ice,'g/m2','Global Mean Ocean Salt (only ice)');
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.gsbox_salt_ice,'g/m2','Gulf Stream Box Ocean Salt (only ice)');
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.arctic_salt_ice,'g/m2','Arctic Ocean Salt (only ice)');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) gsbox (mid) and arctic (lower), '};
        myCaption={myCaption{:},'salt budget (ice only) in g/m2.'};
        if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;


    if (sum(strcmp(choicePlot,'all'))||sum(strcmp(choicePlot,'salt')));

    %3.3) ocean salt budgets
    %-----------------------
    figureL;
    subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_salt_ocn,'g/m2','Global Mean Ocean Salt (only ocean)');
    subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.gsbox_salt_ocn,'g/m2','Gulf Stream Box Ocean Salt (only ocean)');
    subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.arctic_salt_ocn,'g/m2','Arctic Ocean Salt (only ocean)');
    %add to tex file
    myCaption={myYmeanTxt,' global (upper) gsbox (mid) and arctic (lower), '};
    myCaption={myCaption{:},'salt budget (ocean only) in g/m2.'};
    if addToTex&&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;

end;
