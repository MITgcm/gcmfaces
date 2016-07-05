function [bolusU,bolusV,bolusW]=calc_bolus(GM_PsiX,GM_PsiY);
%object:    compute bolus velocty field (bolusU,bolusV,bolusW)
%           from gm streamfunction (GM_PsiX,GM_PsiY).
%input:     GM_PsiX,GM_PsiY
%output:    bolusU,bolusV,bolusW

gcmfaces_global;
nr=length(mygrid.RC);

%replace NaNs with 0s:
GM_PsiX(isnan(GM_PsiX))=0;
GM_PsiY(isnan(GM_PsiY))=0;

%compute bolus velocity:
GM_PsiX(:,:,nr+1)=0*GM_PsiX(:,:,end);
GM_PsiY(:,:,nr+1)=0*GM_PsiY(:,:,end);
bolusU=0*mygrid.hFacW;
bolusV=0*mygrid.hFacS;
for k=1:nr;
    bolusU(:,:,k)=(GM_PsiX(:,:,k+1)-GM_PsiX(:,:,k))/mygrid.DRF(k);
    bolusV(:,:,k)=(GM_PsiY(:,:,k+1)-GM_PsiY(:,:,k))/mygrid.DRF(k);
end;
bolusU=bolusU.*(~isnan(mygrid.mskW));
bolusV=bolusV.*(~isnan(mygrid.mskS));

%and its vertical part
%   (seems correct, leading to 0 divergence)
tmp_x=GM_PsiX(:,:,1:nr).*repmat(mygrid.DYG,[1 1 nr]);
tmp_y=GM_PsiY(:,:,1:nr).*repmat(mygrid.DXG,[1 1 nr]);
[tmp_x,tmp_y]=exch_UV(tmp_x,tmp_y);
tmp_a=repmat(mygrid.RAC,[1 1 nr]);
tmp_w=0*tmp_x;
for iFace=1:mygrid.nFaces;
    tmp_w{iFace}=( tmp_x{iFace}(2:end,:,:)-tmp_x{iFace}(1:end-1,:,:) )+...
        ( tmp_y{iFace}(:,2:end,:)-tmp_y{iFace}(:,1:end-1,:) );
    tmp_w{iFace}=tmp_w{iFace}./tmp_a{iFace};
end;
bolusW=tmp_w.*(~isnan(mygrid.mskC));
