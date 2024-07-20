function [fldOut]=gcmfaces_remap_3d(lon,lat,depIn,fldIn,nDblRes);
%object:    use bin average to remap a lat-lon-depth field to mygrid.mskC
%input:     lon,lat,dep,fld are the gridded product arrays (2D,2D,1D,3D)
%assumption:fld should show NaN for missing values

gcmfaces_global;

%initiate triangulation:
gcmfaces_bindata;

%vertical levels:
nrIn=length(depIn);
depOut=-mygrid.RC; 
nrOut=length(depOut); 

if isempty(whos('nDblRes')); nDblRes=3; end;

%corresponding model mask: chosen to avoid vertical extrapolation later
%  1) from model just above 
mskC=repmat(0*mygrid.XC,[1 1 nrIn]);
KK2=zeros(1,nrIn);
for kk=1:nrIn;
    kk2=max(find(depOut<=depIn(kk)));%model level just above
    if isempty(kk2); kk2=1; end;%pathological case
    KK2(kk)=kk2;
    mskC(:,:,kk)=mygrid.mskC(:,:,kk2);
end;
%  2) shift to above atlas level mask
for kk=nrIn:-1:2;
    mskC(:,:,kk)=mskC(:,:,kk-1);%atlas level just above
end;

%test vertical interpolation to mygrid.RC of the mask:
%     => the printed result should be 0
if 0;
    mskCout=atlas_interp_vert(mskC,depIn,depOut);
    aa=convert2gcmfaces(isnan(mskCout)&~isnan(mygrid.mskC));
    nansum(aa(:))
end;

%horizontal mapping to mygrid.XC, mygrid.YC, mskC:
fld1=mskC;
wb=waitbar(0); waitbar(0,wb,'loop over vertical levels');
for kk=1:nrIn;
    fld1(:,:,kk)=gcmfaces_remap_2d(lon,lat,fldIn(:,:,kk),nDblRes,mskC(:,:,kk));
    waitbar(kk/nrIn,wb,'loop over vertical levels');
end;
close(wb);

%vertical interpolation to mygrid.RC
fld2=atlas_interp_vert(fld1,depIn,depOut);
        

%final mask handling:
%1) remask with mygrid.mskC (mskC was wider by design)
msk1=mygrid.mskC; tmp1=msk1.*fld2;
%2) extrapolate vertically (some deep canions may still miss data)
fldOut=atlas_extrap_vert(tmp1,msk1,depOut);


function [fldOut]=atlas_interp_vert(fldIn,depthIn,depthOut);
%vertical interpolation

gcmfaces_global;

nrIn=length(depthIn);
nrOut=length(depthOut);

%map depthIn to depthOut:
coeff=interp1(depthIn,[1:nrIn],depthOut);
tmp1=find(isnan(coeff)); coeff(tmp1)=nrIn-0.01; %quick fix

%vertical interpolation to mygrid.RC:
fldOut=repmat(0*mygrid.XC,[1 1 nrOut]);
for kk=1:nrOut;
    tmp1=coeff(kk); tmp2=floor(tmp1); tmp1=double(tmp1-tmp2);
    if tmp2==nrIn;
        tmp3=fldIn(:,:,tmp2);
    else;
        tmp3=(1-tmp1)*fldIn(:,:,tmp2)+tmp1*fldIn(:,:,tmp2+1);
    end;
    fldOut(:,:,kk)=tmp3;
end;

function [fldOut]=atlas_extrap_vert(fldIn,mskOut,depthIn);
%vertical extrapolation when needed

fldOut=convert2array(fldIn);
mskOut=convert2array(mskOut);
nrIn=length(depthIn);

for kk=2:nrIn;
    tmp_kk=fldOut(:,:,kk);
    msk_kk=mskOut(:,:,kk);
    [II,JJ]=find(isnan(tmp_kk)&~isnan(msk_kk));
    if ~isempty(II)&kk==2;
        tmp_kkM1=fldOut(:,:,kk-1);
        tmp1=find(isnan(tmp_kk)&~isnan(msk_kk)&~isnan(tmp_kkM1));
        tmp_kk(tmp1)=tmp_kkM1(tmp1);
        fldOut(:,:,kk)=tmp_kk;
    elseif ~isempty(II);
        tmp_kkM1=fldOut(:,:,kk-1);
        tmp_kkM2=fldOut(:,:,kk-2);
        coeff=(depthIn(kk)-depthIn(kk-1))/(depthIn(kk-1)-depthIn(kk-2));
        tmp_kk_x=tmp_kkM1+coeff*(tmp_kkM1-tmp_kkM2);
        tmp1=find(isnan(tmp_kk)&~isnan(msk_kk)&~isnan(tmp_kk_x));
        tmp_kk(tmp1)=tmp_kk_x(tmp1);
        fldOut(:,:,kk)=tmp_kk;
    end;
end;

fldOut=convert2array(fldOut);

