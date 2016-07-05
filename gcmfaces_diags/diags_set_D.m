
%select kBudget:
if ~isempty(setDiagsParams);
  kBudget=setDiagsParams{1};
else;
  kBudget=1;
end;

doMoreBudgetOutput=0;
%doMoreBudgetOutput=1;

%override default file name:
%---------------------------
tmp1=setDiags;
if kBudget>1;
    tmp1=sprintf('D%02i',kBudget);
end;
fileMat=['diags_set_' tmp1];

if userStep==1;%diags to be computed
    listDiags=['glo_vol_ocn glo_vol_tot glo_vol_ice glo_bp'];
    listDiags=[listDiags ' north_vol_ocn north_vol_tot north_vol_ice north_bp'];
    listDiags=[listDiags ' south_vol_ocn south_vol_tot south_vol_ice south_bp'];
    listDiags=[listDiags ' glo_heat_ocn glo_heat_tot glo_heat_ice'];
    listDiags=[listDiags ' north_heat_ocn north_heat_tot north_heat_ice'];
    listDiags=[listDiags ' south_heat_ocn south_heat_tot south_heat_ice'];
    listDiags=[listDiags ' glo_salt_ocn glo_salt_tot glo_salt_ice'];
    listDiags=[listDiags ' north_salt_ocn north_salt_tot north_salt_ice'];
    listDiags=[listDiags ' south_salt_ocn south_salt_tot south_salt_ice'];

elseif userStep==2;%input files and variables
    dirSnap=fullfile(dirModel,'diags',filesep,'BUDG',filesep);
    if ~isdir(dirSnap); dirSnap=fullfile(dirModel,'diags',filesep); end;
    tmp1=fullfile(dirSnap,'budg2d_snap_set2*meta');
    test3d=isempty(dir(tmp1));
    %
    listFlds={    'ETAN','SIheff','SIhsnow','THETA   ','SALT    ','PHIBOT','geothFlux'};
    listFlds={listFlds{:},'SIatmFW ','oceFWflx','SItflux','TFLUX','SFLUX','oceSPflx','SRELAX'};
    listFlds={listFlds{:},'oceQnet ','SIatmQnt','SIaaflux','SIsnPrcp','SIacSubl'};
    listFlds={listFlds{:},'TRELAX','WTHMASS','WSLTMASS','oceSflux','oceQsw','oceSPtnd'};
    if kBudget>1|test3d;
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
    if test3d;
        listFiles={listFiles{:},'rate_budg3d_snap_set1','budg3d_hflux_set1','budg3d_zflux_set1'};
    elseif kBudget==1;
        listFiles={listFiles{:},'rate_budg2d_snap_set2','budg2d_hflux_set2','geothermalFlux'};
    else;
        tmp1=sprintf('rate_budg2d_snap_set3_%02i',kBudget);
        tmp2=sprintf('budg2d_zflux_set3_%02i',kBudget);
        tmp3=sprintf('budg2d_hflux_set3_%02i',kBudget);
        tmp4=sprintf('geothermalFlux_%02i',kBudget);
        listFiles={listFiles{:},tmp1,tmp2,tmp3,tmp4};
    end;
    listSubdirs={[dirMat 'BUDG/' ],[dirMat '../BUDG/' ],dirSnap};

elseif userStep==3;%computational part;

    %preliminary tests
    test1=isempty(dir([dirModel 'diags/BUDG/budg2d_snap_set1*']));
    test2=isempty(dir([dirMat 'BUDG/rate_budg2d_snap_set1*']))&...
          isempty(dir([dirMat '../BUDG/rate_budg2d_snap_set1*']));
    if (strcmp(setDiags,'D')&test1&test2);
        fprintf('\n abort : global and regional budgets, due to missing \n');
        fprintf(['\n   ' dirModel 'diags/BUDG/budg2d_snap_set1* \n']);
        return;
    end;

    if (strcmp(setDiags,'D')&test2);
        fprintf('\n abort : global and regional budgets, due to missing \n');
        fprintf(['\n   ' dirModel 'diags/BUDG/rate_budg2d_snap_set1* \n']);
        return;
    end;
    
    %override default file name:
    %---------------------------
    tmp1=setDiags;
    if kBudget>1;
        tmp1=sprintf('D%02i',kBudget);
    end;
    fileMat=['diags_set_' tmp1 '_' num2str(tt) '.mat'];
        
    %fill in optional fields:
    %------------------------
    if isempty(who('TRELAX')); TRELAX=0; end;
    if isempty(who('SRELAX')); SRELAX=0; end;
    if isempty(who('AB_gT')); AB_gT=0; end;
    if isempty(who('AB_gS')); AB_gS=0; end;
    if isempty(who('oceSPtnd')); oceSPtnd=0; end;
    if isempty(who('oceSPflx')); oceSPflx=0; end;
    if isempty(who('PHIBOT')); PHIBOT=0; end;
    if isempty(who('geothFlux')); geothFlux=0; end;

    %aliases from development phase (applies to 2012 core runs)
    %---------------------------------------------------------
    if ~isempty(who('SDIAG1')); SRELAX=SDIAG1; end;
    if ~isempty(who('SDIAG2')); SIatmFW=SDIAG2; end;
    if ~isempty(who('SDIAG3')); SItflux=SDIAG3; end;

    %=======indexing and sign convention======

    %- MITgcm: fluxes are >0 downward, k=1 start at free surface
    %- here, similarly: >0 downward, k=1 free surface k=2 sea floor        
    if ~test3d;
      budgO.specs.top='free surface';
      if kBudget>1; budgO.specs.top=['interface no. ' num2str(kBudget)]; end;
      budgO.specs.bottom='sea floor';
    else;
      budgO.specs.top='interface k';
      budgO.specs.bottom='interface k+1';
    end;
    budgI.specs.top='ocn-ice to atm interface';
    budgI.specs.bottom='free surface';
    
    %here we output tendencies and fluxes in kg/s
    budgMo=budgO; budgMi=budgI;
    budgMo.specs.units='kg/s';%ocean only
    budgMi.specs.units='kg/s';%ice only
    %here we output tendencies and fluxes in Watts
    budgHo=budgO; budgHi=budgI;
    budgHo.specs.units='W';%ocean only
    budgHi.specs.units='W';%ice only
    %here we output tendencies and fluxes in g/s
    budgSo=budgO; budgSi=budgI;
    budgSo.specs.units='g/s';%ocean only
    budgSi.specs.units='g/s';%ice only        

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
    
    %compute northern hemisphere integrals:
    msk=mygrid.mskC(:,:,kBudget).*(mygrid.YC>0);
    tmp1=calc_mskmean_T(budgMoi,msk,'extensive');
    north_vol_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgMo,msk,'extensive');
    north_vol_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgMi,msk,'extensive');
    north_vol_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];

    north_bp=nansum(bp.*msk.*mygrid.RAC)/nansum(msk.*mygrid.RAC);
    
    %and southern hemisphere integrals:
    msk=mygrid.mskC(:,:,kBudget).*(mygrid.YC<=0);
    tmp1=calc_mskmean_T(budgMoi,msk,'extensive');
    south_vol_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgMo,msk,'extensive');
    south_vol_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgMi,msk,'extensive');
    south_vol_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];

    south_bp=nansum(bp.*msk.*mygrid.RAC)/nansum(msk.*mygrid.RAC);
    
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
    
    %compute northern hemisphere integrals:
    msk=mygrid.mskC(:,:,kBudget).*(mygrid.YC>0);
    tmp1=calc_mskmean_T(budgHoi,msk,'extensive');
    north_heat_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgHo,msk,'extensive');
    north_heat_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgHi,msk,'extensive');
    north_heat_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    
    %and southern hemisphere integrals:
    msk=mygrid.mskC(:,:,kBudget).*(mygrid.YC<=0);
    tmp1=calc_mskmean_T(budgHoi,msk,'extensive');
    south_heat_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgHo,msk,'extensive');
    south_heat_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgHi,msk,'extensive');
    south_heat_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];

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

    %compute northern hemisphere integrals:
    msk=mygrid.mskC(:,:,kBudget).*(mygrid.YC>0);
    tmp1=calc_mskmean_T(budgSoi,msk,'extensive');
    north_salt_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgSo,msk,'extensive');
    north_salt_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgSi,msk,'extensive');
    north_salt_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    
    %and southern hemisphere integrals:
    msk=mygrid.mskC(:,:,kBudget).*(mygrid.YC<=0);
    tmp1=calc_mskmean_T(budgSoi,msk,'extensive');
    south_salt_tot=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgSo,msk,'extensive');
    south_salt_ocn=[tmp1.tend;tmp1.hconv;tmp1.zconv];
    tmp1=calc_mskmean_T(budgSi,msk,'extensive');
    south_salt_ice=[tmp1.tend;tmp1.hconv;tmp1.zconv];

    if doMoreBudgetOutput;
        %initial and final state:
        if ii==1; diags_inifin_D(kBudget,test3d,dirSnap,dirMat); end;
        %list of budgets to output
        listbudg={'budgMo','budgHo','budgSo'};
        if kBudget==1; listbudg={listbudg{:},'budgMi','budgHi','budgSi'}; end;
        %the actual output
        for iibudg=1:length(listbudg);
            %set directory name
            dirbudg=dirMat;
            if ~isempty(strfind(dirMat,['diags_set_' setDiags '/']))
                dirbudg=fullfile(dirMat,'..',filesep);
            end;
            sufbudg=''; 
            if kBudget>1; sufbudg=num2str(kBudget); end;
            dirbudg=fullfile(dirbudg,['diags_set_' listbudg{iibudg} sufbudg],filesep);
            %
            if ~isdir(dirbudg); mkdir(dirbudg); end;
            %set file name
            filebudg=[listbudg{iibudg} '_' num2str(tt) '.mat'];
            %output to file
            eval(['tmpbudg=' listbudg{iibudg} '.fluxes;']);
            listterms=fieldnames(tmpbudg);
            for iiterm=1:length(listterms);
              tmp1=getfield(tmpbudg,listterms{iiterm});
              tmp1=convert2gcmfaces(tmp1);
              %tmp2=prod(size(tmp1));
              fid=fopen([dirbudg listterms{iiterm} '.bin'],'a+','b');      
              %status=fseek(fid,(tt-1)*recl2D,'bof');
              fwrite(fid,tmp1,'float64');
              fclose(fid);
            end;
        end;
    end;

%===================== COMPUTATIONAL SEQUENCE ENDS =========================%
%===================== PLOTTING SEQUENCE BEGINS    =========================%

elseif userStep==-1;%plotting

    if isempty(setDiagsParams);
      choicePlot={'all'};
    elseif isnumeric(setDiagsParams{1})&length(setDiagsParams)==1;
      choicePlot={'all'};
    elseif isnumeric(setDiagsParams{1});
      choicePlot={setDiagsParams{2:end}};
    else;
      choicePlot=setDiagsParams;
    end;

    tt=[1:length(alldiag.listTimes)];
    TT=alldiag.listTimes(tt);
    nt=length(TT);

    if (kBudget==1)&(sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'mass')));

        %1.1) ocean+seaice mass budgets
        %------------------------------
        figureL;
        %global volume budget:
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_vol_tot,'kg/m^2','Global Mean Mass (incl. ice)');
        %add bp:
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.glo_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        %northern hemisphere budget:
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.north_vol_tot,'kg/m^2','Northern Mean Mass (incl. ice)');
        %add bp:
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.north_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        %southern hemisphere budget:
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.south_vol_tot,'kg/m^2','Southern Mean Mass (incl. ice)');
        %add bp:
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.south_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) north (mid) and south (lower), '};
        myCaption={myCaption{:},'mass budget (ocean+ice) in kg/m$^2$.'};
        if addToTex&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

        %1.2) ice mass budgets
        %---------------------
        figureL;
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_vol_ice,'kg/m^2','Global Mean Mass (only ice)');
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.glo_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.north_vol_ice,'kg/m^2','Northern Mean Mass (only ice)');
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.north_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.south_vol_ice,'kg/m^2','Southern Mean Mass (only ice)');
        dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.south_bp);
        plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) north (mid) and south (lower), '};
        myCaption={myCaption{:},'mass budget (ice only) in kg/m$^2$.'};
        if addToTex&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;

    if (sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'mass')));

    %1.3) ocean mass budgets
    %-----------------------
    figureL;
    %global volume budget:
    subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_vol_ocn,'kg/m^2','Global Mean Mass (only ocean)');
    dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.glo_bp);
    plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
    subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.north_vol_ocn,'kg/m^2','Northern Mean Mass (only ocean)');
    dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.north_bp);
    plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
    subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.south_vol_ocn,'kg/m^2','Southern Mean Mass (only ocean)');
    dt=median(diff(TT))*86400; bp=dt*cumsum(alldiag.south_bp);
    plot(TT,bp,'k'); aa=legend; bb=get(aa,'String'); bb={bb{:},'bp'}; legend(bb,'Orientation','horizontal');
    %add to tex file
    myCaption={myYmeanTxt,' global (upper) north (mid) and south (lower), '};
    myCaption={myCaption{:},'mass budget (ocean only) in kg/m$^2$.'};
    if addToTex&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;

    if (kBudget==1)&(sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'heat')));

        %2.1) ocean+seaice heat budgets
        %------------------------------
        figureL;
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_heat_tot,'J/m^2','Global Mean Ocean Heat (incl. ice)');
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.north_heat_tot,'J/m^2','Northern Mean Ocean Heat (incl. ice)');
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.south_heat_tot,'J/m^2','Southern Mean Ocean Heat (incl. ice)');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) north (mid) and south (lower), '};
        myCaption={myCaption{:},'heat budget (ocean+ice) in J/m$^2$.'};
        if addToTex&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

        %2.2) ice heat budgets
        %---------------------
        figureL;
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_heat_ice,'J/m^2','Global Mean Ocean Heat (only ice)');
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.north_heat_ice,'J/m^2','Northern Mean Ocean Heat (only ice)');
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.south_heat_ice,'J/m^2','Southern Mean Ocean Heat (only ice)');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) north (mid) and south (lower), '};
        myCaption={myCaption{:},'heat budget (ice only) in J/m$^2$.'};
        if addToTex&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;

    if (sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'heat')));

    %2.3) ocean heat budgets
    %-----------------------
    figureL;
    subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_heat_ocn,'J/m^2','Global Mean Ocean Heat (only ocean)');
    subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.north_heat_ocn,'J/m^2','Northern Mean Ocean Heat (only ocean)');
    subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.south_heat_ocn,'J/m^2','Southern Mean Ocean Heat (only ocean)');
    %add to tex file
    myCaption={myYmeanTxt,' global (upper) north (mid) and south (lower), '};
    myCaption={myCaption{:},'heat budget (ocean only) in J/m$^2$.'};
    if addToTex&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;

    if (kBudget==1)&(sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'salt')));

        %3.1) ocean+seaice salt budgets
        %------------------------------
        figureL;
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_salt_tot,'g/m^2','Global Mean Ocean Salt (incl. ice)');
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.north_salt_tot,'g/m^2','Northern Mean Ocean Salt (incl. ice)');
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.south_salt_tot,'g/m^2','Southern Mean Ocean Salt (incl. ice)');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) north (mid) and south (lower), '};
        myCaption={myCaption{:},'salt budget (ocean+ice) in g/m$^2$.'};
        if addToTex&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

        %2.2) ice salt budgets
        %---------------------
        figureL;
        subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_salt_ice,'g/m^2','Global Mean Ocean Salt (only ice)');
        subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.north_salt_ice,'g/m^2','Northern Mean Ocean Salt (only ice)');
        subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.south_salt_ice,'g/m^2','Southern Mean Ocean Salt (only ice)');
        %add to tex file
        myCaption={myYmeanTxt,' global (upper) north (mid) and south (lower), '};
        myCaption={myCaption{:},'salt budget (ice only) in g/m$^2$.'};
        if addToTex&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;


    if (sum(strcmp(choicePlot,'all'))|sum(strcmp(choicePlot,'salt')));

    %3.3) ocean salt budgets
    %-----------------------
    figureL;
    subplot(3,1,1); disp_budget_mean_mask(TT,alldiag.glo_salt_ocn,'g/m^2','Global Mean Ocean Salt (only ocean)');
    subplot(3,1,2); disp_budget_mean_mask(TT,alldiag.north_salt_ocn,'g/m^2','Northern Mean Ocean Salt (only ocean)');
    subplot(3,1,3); disp_budget_mean_mask(TT,alldiag.south_salt_ocn,'g/m^2','Southern Mean Ocean Salt (only ocean)');
    %add to tex file
    myCaption={myYmeanTxt,' global (upper) north (mid) and south (lower), '};
    myCaption={myCaption{:},'salt budget (ocean only) in g/m$^2$.'};
    if addToTex&multiTimes; write2tex(fileTex,2,myCaption,gcf); elseif ~multiTimes; close; end;

    end;

end;
