function [fldBAR]=calc_barostream(fldU,fldV,noDiv,list_factors);
%object:    compute barotropic streamfunction
%inputs:    fldU and fldV are the fields of grid point transport
%optional:  noDiv (default is 1). If 1 then remove the divergent 
%               part of the flow field first. If 0 then dont.
%           list_factors (default is {'dh','dz'})
%output:    FLD is the streamfunction
%notes:     the result is converted to Sv

global mygrid;

if nargin<3; noDiv=1; end;
if nargin<4; list_factors={'dh','dz'}; end;

%0) prepare fldU/fldV (transport fields):
n3=max(size(fldU.f1,3),1); n4=max(size(fldV.f1,4),1);

fldU(isnan(fldU))=0; fldV(isnan(fldV))=0;

dxg=mk3D(mygrid.DXG,fldU); dyg=mk3D(mygrid.DYG,fldU);
if size(fldU.f1,3)==length(mygrid.DRF); drf=mk3D(mygrid.DRF,fldU); else; drf=fldU; drf(:)=1; end;
facW=drf; facW(:)=1; facS=facW;
for ii=1:length(list_factors);
  tmp1=list_factors{ii};
  if strcmp(tmp1,'dh'); facW=facW.*dyg; facS=facS.*dxg;
  elseif strcmp(tmp1,'dz'); facW=facW.*drf; facS=facS.*drf;
  elseif strcmp(tmp1,'hfac'); facW=facW.*mygrid.hFacW; facS=facS.*mygrid.hFacS;
  elseif isempty(tmp1); 1;
  else; fprintf('error in calc_barostream : non supported factor\n'); return;
  end;
end;

for k4=1:n4;
fldU(:,:,:,k4)=fldU(:,:,:,k4).*facW;
fldV(:,:,:,k4)=fldV(:,:,:,k4).*facS;
end;

%apply mask:
fldU=sum(fldU,3).*mygrid.mskW(:,:,1); 
fldV=sum(fldV,3).*mygrid.mskS(:,:,1);

%0.1) compute streamfunction mask:
if noDiv;
 mskU=1*~isnan(fldU);
 mskV=1*~isnan(fldV);
 [mskU,mskV]=exch_UV(mskU,mskV);
 mskU=abs(mskU); mskV=abs(mskV);
 mskBF=0*exch_T_N(mygrid.RAC);
 for iF=1:fldU.nFaces;
  tmp2=mskV{iF};
  tmp3a=[ones(1,size(tmp2,2));tmp2];
  tmp3b=[tmp2;ones(1,size(tmp2,2))];
  mskBF{iF}=tmp3a.*tmp3b;
 end;
end;

%take out the divergent part of the flow:
if noDiv;
  [fldUdiv,fldVdiv,fldDivPot]=diffsmooth2D_div_inv(fldU,fldV);
  fldU=fldU-fldUdiv; fldV=fldV-fldVdiv;
end;

%1) compute streamfunction face by face:
[fldU,fldV]=exch_UV(fldU,fldV); fldU(isnan(fldU))=0; fldV(isnan(fldV))=0;
tmp1=cumsum(fldV,1); for iF=1:fldU.nFaces; tmp2=tmp1{iF}; tmp1{iF}=[zeros(1,size(tmp2,2));tmp2]; end;

%1.1) reset one land value per face to 0:
if noDiv;
 for iF=1:fldU.nFaces;
  tmpA=tmp1{iF};
  tmpB=mskBF{iF};
  [ii,jj]=find(tmpB==0);
  ii=ii(1); jj=jj(1);
  tmpA(:,jj)=tmpA(:,jj)-tmpB(ii,jj);
  for kk=1:jj-1; 
    tmpC=tmpA(:,kk+1)-tmpA(:,kk);
    tmpD=fldU{iF}(:,kk);
    tmpE=nanmedian(tmpC+tmpD);
    tmpA(:,kk)=tmpA(:,kk)-tmpE;
  end;
  for kk=jj+1:size(tmpA,2);
    tmpC=tmpA(:,kk)-tmpA(:,kk-1);
    tmpD=fldU{iF}(:,kk-1);
    tmpE=nanmedian(tmpC+tmpD);
    tmpA(:,kk)=tmpA(:,kk)-tmpE;
  end;
  tmp1{iF}=tmpA;
 end;
end;

%1.2) compute divergent part of the flow on average line by line:
if ~noDiv;
  tmp2=diff(tmp1,1,2)+fldU; tmp3=cumsum(mean(tmp2,1));
  % to check divergence implied errors:  
  % figure; for iF=1:fldU.nFaces; subplot(3,2,iF); plot(std(tmp2{iF},0,1)); end;
  %subtract from streamfunction:
  for iF=1:fldU.nFaces; tmp2=tmp1{iF}; tmp1{iF}=tmp2-ones(size(tmp2,1),1)*[0 tmp3{iF}]; end;
end;

bf_step1=tmp1;

if fldU.nFaces==1;
  bf_step2=bf_step1;
else;
%2) match edges:
%... set face number field
TMP1=tmp1; for iF=1:TMP1.nFaces; TMP1{iF}(:)=iF; end; 
TMP2=exch_T_N(TMP1);%!!! this is a trick, since TMP1 is (n+1 X n+1) and loc. at vorticity points
tmp1=bf_step1;
for iF=1:fldU.nFaces-1;
  tmp2=exch_T_N(tmp1);%!!! same trick 
  tmp3=tmp2{iF+1}; tmp3(3:end-2,3:end-2)=NaN;%mask out interior points
  TMP3=TMP2{iF+1}; tmp3(find(TMP3>iF+1))=NaN;%mask out edges points coming from unadjusted faces
  tmp3(:,1)=tmp3(:,1)-tmp3(:,2); tmp3(:,end)=tmp3(:,end)-tmp3(:,end-1);%compare edge points
  tmp3(1,:)=tmp3(1,:)-tmp3(2,:); tmp3(end,:)=tmp3(end,:)-tmp3(end-1,:);%compare edge points
  tmp3(2:end-1,2:end-1)=NaN;%mask out remaining interior points
  tmp1{iF+1}=tmp1{iF+1}+nanmedian(tmp3(:));%adjust the face data
end;
bf_step2=tmp1;
end;

%3) put streamfunction at cell center
tmp1=bf_step2;
tmp2=tmp1; for iF=1:tmp1.nFaces; tmp3=tmp2{iF}; tmp3=(tmp3(:,1:end-1)+tmp3(:,2:end))/2;
tmp3=(tmp3(1:end-1,:)+tmp3(2:end,:))/2; tmp2{iF}=tmp3; end;
bf_step3=tmp2;
%4) set 0 on fist land point:
tmp1=convert2vector(bf_step3); 
tmp2=convert2vector(mygrid.mskC(:,:,1));
tmp2=find(isnan(tmp2)&~isnan(tmp1)); 
%
%tmp2=median(tmp1(tmp2));%the original method
%tmp2=tmp1(tmp2(1));%a point in Antarctica (in LLC90 at least)
%closest land point closest to Boston:
tmp_lon=convert2vector(mygrid.XC); tmp_lon=tmp_lon(tmp2);
tmp_lat=convert2vector(mygrid.YC); tmp_lat=tmp_lat(tmp2);
tmp_dis=(tmp_lat-42.3601).^2+(tmp_lon-71.0589).^2;
tmp2=tmp1(tmp2(find(tmp_dis==min(tmp_dis))));
%
bf_step4=(bf_step3-tmp2).*mygrid.mskC(:,:,1);

%5) return the result:
fldBAR=bf_step4;

%convert to Sv and change sign:
fldBAR=1e-6*fldBAR;


