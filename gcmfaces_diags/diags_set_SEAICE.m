
if userStep==1;%diags to be computed
    listDiags='seaIceConc seaIceThick seaSnowThick seaIceStrFun seaIceDiv';
    listDiags=[listDiags ' iceThickNorth iceThickSouth'];
    listDiags=[listDiags ' iceAreaNorth iceAreaSouth'];
    listDiags=[listDiags ' snowThickNorth snowThickSouth'];
    listDiags=[listDiags ' snowAreaNorth snowAreaSouth'];
end;

if userStep==2;%input files and variables
    listFlds={'SIarea  ','SIheff  ','SIhsnow ',...
              'ADVxHEFF','ADVyHEFF','ADVxSNOW','ADVySNOW',...
              'DFxEHEFF','DFyEHEFF','DFxESNOW','DFyESNOW'};
    listFldsNames=deblank(listFlds);
    listFiles={'state_2d_set1'};
    listSubdirs={[dirModel 'diags/STATE/' ],[dirModel 'diags/']};
end;

if userStep==3;%computational part;

%ice masks
mskC=mygrid.mskC(:,:,1); mskC(SIheff==0)=NaN;
mskW=mygrid.mskW(:,:,1); mskW(ADVxHEFF==0)=NaN;
mskS=mygrid.mskS(:,:,1); mskS(ADVyHEFF==0)=NaN;

%ice and snow thickness
seaIceConc=mskC.*SIarea;
seaIceThick=SIheff./seaIceConc;
seaSnowThick=SIhsnow./seaIceConc;

%transports in kg/s
tmpU=(myparms.rhoi*DFxEHEFF+myparms.rhosn*DFxESNOW+...
      myparms.rhoi*ADVxHEFF+myparms.rhosn*ADVxSNOW);
tmpV=(myparms.rhoi*DFyEHEFF+myparms.rhosn*DFyESNOW+...
      myparms.rhoi*ADVyHEFF+myparms.rhosn*ADVySNOW);

%convergence in kiloton/s
seaIceDiv=1e-6*mskC.*calc_UV_conv(tmpU,tmpV); %no dh needed here

%streamfunction in kg/s 
%(factor 1e6 to compensare for calc_barostream internal conversion)
seaIceStrFun=1e6*calc_barostream(tmpU.*mskW,tmpV.*mskS,1,{});
%convert to megaton/s
seaIceStrFun=1e-9*mskC.*seaIceStrFun;

%thickness distributions per hemisphere
xx=convert2vector(seaIceThick);
yy=convert2vector(1+0*seaIceThick);
zz=convert2vector(seaIceConc.*mygrid.RAC);

mm=convert2vector(mygrid.YC>0); jj=find(mm.*zz>0);
[x,y,z,n]=MITprof_stats(xx(jj),[0:0.05:10],yy(jj),[0 1 2],'sum',zz(jj));
iceThickNorth=x(:,2); iceAreaNorth=z(:,2);

mm=convert2vector(mygrid.YC<0); jj=find(mm.*zz>0);
[x,y,z,n]=MITprof_stats(xx(jj),[0:0.05:10],yy(jj),[0 1 2],'sum',zz(jj));
iceThickSouth=x(:,2); iceAreaSouth=z(:,2);

xx=convert2vector(seaSnowThick);

mm=convert2vector(mygrid.YC>0); jj=find(mm.*zz>0);
[x,y,z,n]=MITprof_stats(xx(jj),[0:0.05:10],yy(jj),[0 1 2],'sum',zz(jj));
snowThickNorth=x(:,2); snowAreaNorth=z(:,2);

mm=convert2vector(mygrid.YC<0); jj=find(mm.*zz>0);
[x,y,z,n]=MITprof_stats(xx(jj),[0:0.05:10],yy(jj),[0 1 2],'sum',zz(jj));
snowThickSouth=x(:,2); snowAreaSouth=z(:,2);

end;

if userStep==-1&myparms.diagsAreMonthly==1;%plotting

if ~doAnomalies;

if addToTex; write2tex(fileTex,1,'Monthly Thickness Distribution',2); end;

%compute seasonal cycle in thickness distributions

y=alldiag.iceThickNorth(:,1:12);
x=ones(size(y,1),1)*[1:12];
iceNorth=zeros(size(x)); iceSouth=zeros(size(x));
snowNorth=zeros(size(x)); snowSouth=zeros(size(x));
for mm=1:12;
  tmp1=alldiag.iceAreaNorth(:,mm:12:nt);
  tmp1(isnan(tmp1))=0;
  iceNorth(:,mm)=log10(mean(tmp1,2));
  %
  tmp1=alldiag.iceAreaSouth(:,mm:12:nt);
  tmp1(isnan(tmp1))=0;
  iceSouth(:,mm)=log10(mean(tmp1,2));
  %
  tmp1=alldiag.snowAreaNorth(:,mm:12:nt);
  tmp1(isnan(tmp1))=0;
  snowNorth(:,mm)=log10(mean(tmp1,2));
  %
  tmp1=alldiag.snowAreaSouth(:,mm:12:nt);
  tmp1(isnan(tmp1))=0;
  snowSouth(:,mm)=log10(mean(tmp1,2));
end;
iceNorth(~isfinite(iceNorth))=NaN;
iceSouth(~isfinite(iceSouth))=NaN;
snowNorth(~isfinite(snowNorth))=NaN;
snowSouth(~isfinite(snowSouth))=NaN;

%now display seasonal cycle
x=[x x+12]-0.5; y=[y y]; z=[iceNorth iceNorth];

figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end; 
subplot(2,1,1);
z=[iceNorth iceNorth]; pcolor(x,y,z); shading interp; 
axis([1 13 0 6]); grid on; caxis([9.5 12]); colormap(jet(25));
colorbar; xlabel('month of year'); ylabel('log(thickness)');
title('log(ice area) -- North. Hemi.');
subplot(2,1,2);
z=[snowNorth snowNorth]; pcolor(x,y,z); shading interp;
axis([1 13 0 1.2]); grid on; caxis([9.5 12]+0.5); colormap(jet(25));
colorbar; xlabel('month of year'); ylabel('log(thickness)');
title('log(snow area) -- North. Hemi.');

myCaption={myYmeanTxt,'Northern Hemisphere :',...
           'monthly mean ice (top) and snow (bottom)',...
           ' thickness distribution (in log(m$^2$))'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end;
subplot(2,1,1);
z=[iceSouth iceSouth]; pcolor(x,y,z); shading interp;
axis([1 13 0 4]); grid on; caxis([9.5 12]); colormap(jet(25));
colorbar; xlabel('month of year'); ylabel('log(thickness)');
title('log(ice area) -- South. Hemi.');
subplot(2,1,2);
z=[snowSouth snowSouth]; pcolor(x,y,z); shading interp;
axis([1 13 0 1.2]); grid on; caxis([9.5 12]+0.5); colormap(jet(30)); 
colorbar; xlabel('month of year'); ylabel('log(thickness)');
title('log(snow area) -- South. Hemi.');

myCaption={myYmeanTxt,'Southern Hemisphere :',...
           'monthly mean ice (top) and snow (bottom)',...
           ' thickness distribution (in log(m$^2$))'};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

end;

%maps of mean march and september ice fields

list_var={'seaIceConc',...
	'seaIceThick',...
	'seaSnowThick',...
	'seaIceStrFun',...
	'seaIceDiv'};

list_cc={[0:0.1:1],...
	[0:0.1:0.5 0.75 1:0.5:2.5 3:5],...
	[0:0.1:0.5 0.75 1:0.5:2.5 3:5]/5,...
	1/50*[-5:-3 -2.5:0.5:-1 -0.5:0.2:0.5 1:0.5:2.5 3:5],...
	1/5*[-5:-3 -2.5:0.5:-1 -0.5:0.2:0.5 1:0.5:2.5 3:5]};

list_ccAno={2*[-0.2:0.04:0.2],...
	4*[-0.2:0.04:0.2],...
	[-0.2:0.04:0.2],...
	0.25*[-0.2:0.04:0.2],...
	[-0.2:0.04:0.2]};

list_tit={' ice concentration (unitless)',...
	' ice thickness (m)',...
	' snow thickness (m)',...
	' ice+snow streamfunction (megaton/s)',...
	' ice+snow convergence (kiloton/s)'};

for hemi=1:2;
for seas=1:2;

%select month
if seas==1; mon='March'; else; mon='September'; end;

%select projection
if hemi==1; pp=2; txt='Northern '; else; pp=3; txt='Southern '; end;

if addToTex; write2tex(fileTex,1,[txt 'Hem. in ' mon],2); end;

for vv=1:length(list_var);

eval(['fld=alldiag.' list_var{vv} ';']);

%mask out negligible amounts (e.g. due to monthly averaging)
msk=1+0*alldiag.seaIceConc;
msk(alldiag.seaIceConc<1e-2)=NaN; 
msk(alldiag.seaIceThick<1e-2)=NaN;
fld=fld.*msk;

%compute mean march and september fields
if seas==1; 
  tmp1=fld(:,:,3:12:nt);
  tmp1(isnan(tmp1))=0;
  fld_seas=mean(tmp1,3);
else; 
  tmp1=fld(:,:,9:12:nt);
  tmp1(isnan(tmp1))=0;
  fld_seas=mean(tmp1,3);
end;
fld_seas(fld_seas==0)=NaN;

%ice concentration
figureL; if ~myenv.usingOctave; set(gcf,'Renderer','zbuffer'); end;
cc=list_cc{vv}; if doAnomalies; cc=list_ccAno{vv}; end;
caxi={'myCaxis',cc}; docb={'doCbar',1};
m_map_gcmfaces(fld_seas,pp,caxi,docb);
myCaption={myYmeanTxt,mon,' mean -- ',list_tit{vv}};
if addToTex; write2tex(fileTex,2,myCaption,gcf); end;

end;%for vv=1:length(list_var);
end;%for seas=1:2;
end;%for hemi=1:2;

end;

