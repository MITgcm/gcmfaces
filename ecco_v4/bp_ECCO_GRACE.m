function []=bp_ECCO_GRACE();
% BP_ECCO_GRACE 
%    - reads ECCO and GRACE bottom pressure fields from file
%    - computes monthly area average over Barents Sea
%    - display monthly time series and correlation

fprintf('\n'); help bp_ECCO_GRACE;

%load grid from nctiles_grid/
grid_load; gcmfaces_global;

%option to subtract ECCO time-variable global-mean BP (by default rmGloMean=0
%  and GRACE_jpl_rl05m_SpatialMean.asc is instead added to GRACE BP maps)  
rmGloMean=0;

%input directories
dir_GRACE='input_ecco/input_bp/';
dir_ECCO='nctiles_monthly/PHIBOT/';

%read GRACE global mean
glo_GRACE=NaN*zeros(1,240);
fid=fopen([dir_GRACE 'GRACE_jpl_rl05m_SpatialMean.asc'],'rt');
for ii=1:4; tmp1=fgetl(fid); end;
for ii=1:240; 
  tmp1=fgetl(fid); 
  tmp1=str2num(tmp1);
  glo_GRACE(ii)=tmp1(4);
end;
fclose(fid);
glo_GRACE(glo_GRACE==-999)=NaN;

%read GRACE
fld_GRACE=repmat(NaN*mygrid.XC,[1 1 240]);
for yy=1992:2011;
tmp1=read_bin([dir_GRACE 'GRACE_jpl_rl05m_' num2str(yy)]);
fld_GRACE(:,:,[1:12]+12*(yy-1992))=tmp1;
end;

%read ECCO
fld_ECCO=read_nctiles([dir_ECCO 'PHIBOT']);

%convert ECCO to cm
fld_ECCO=10.1937*fld_ECCO;

%apply common NaN mask to ECCO and GRACE maps
msk=1*(fld_GRACE>-999); msk(msk==0)=NaN;
fld_GRACE=msk.*fld_GRACE;
fld_ECCO=msk.*fld_ECCO;

%NaN mask for GRACE / ECCO time series
msk_tim=1*(nansum(msk,0)>0);
msk_tim(msk_tim==0)=NaN;

%subtract time mean
fld_GRACE=fld_GRACE-repmat(nanmean(fld_GRACE,3),[1 1 240]);
fld_ECCO=fld_ECCO-repmat(nanmean(fld_ECCO,3),[1 1 240]);

%add global mean for GRACE
fld_GRACE=fld_GRACE+mk3D(glo_GRACE,fld_GRACE);

%subtract time variable global mean
if rmGloMean;
  tmp1=nanmedian(fld_GRACE,[],0);
  fld_GRACE=fld_GRACE-mk3D(tmp1,fld_GRACE);
  tmp1=nanmedian(fld_ECCO,[],0);
  fld_ECCO=fld_ECCO-mk3D(tmp1,fld_ECCO);
end;

%Barents Sea (area weighted mean) time series:
msk=v4_basin('barents').*mygrid.mskC(:,:,1);;
mskXrac=repmat(msk.*mygrid.RAC,[1 1 240]);
bp_ECCO=nansum(fld_ECCO.*mskXrac,0)./nansum(mskXrac,0);
bp_GRACE=nansum(fld_GRACE.*mskXrac,0)./nansum(mskXrac,0);

%apply common NaN mask to ECCO and GRACE time series
bp_GRACE=msk_tim.*bp_GRACE;
bp_ECCO=msk_tim.*bp_ECCO;

%display results
figure; set(gca,'FontSize',12); x_tim=[0.5:239.5]/12+1992; 
plot(x_tim,bp_GRACE,'b.-'); hold on; plot(x_tim,bp_ECCO,'r.-');
legend('GRACE','ECCO'); ylabel('Bottom pressure anomaly (in cm)');
title('Barents Sea, area averaged, monthly means');

tmp0=~isnan(msk_tim);
tmp1=corrcoef(bp_ECCO(tmp0),bp_GRACE(tmp0));
fprintf('  Correlation coefficient = %g\n\n',tmp1(2,1));

