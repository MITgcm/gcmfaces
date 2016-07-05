
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%starting point:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

gcmfaces_global;
% mygrid_refgrid=mygrid;
mygrid=mygrid_refgrid;

fld=rdmds2gcmfaces([dir1 'ptrac_3d_set2.0000175296'],'rec',2);
fld=fld.*mygrid.mskC;
fld1=fld;
m=repmat(mygrid.mskC(:,:,28),[1 1 50]);%mask coastal region for demo of extrapolation
fld=fld.*m;
fld2=fld;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%create lat-lon grid:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ncload woa13_all_p00_01.nc lon lat depth;
lon=double(lon); lat=double(lat); depth=double(depth);
[lat,lon] = meshgrid(lat,lon);

%prepare mygrid for lat-lon with no mask
mygrid_latlon.nFaces=1;
mygrid_latlon.XC=gcmfaces({lon}); mygrid_latlon.YC=gcmfaces({lat});
mygrid_latlon.dirGrid='none';
mygrid_latlon.fileFormat='straight';
mygrid_latlon.ioSize=size(lon);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%interpolate to lat-lon grid:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for ii=1:2;
    if ii==1; fld=fld1;
    else; fld=fld2;
    end;
    
    mygrid=mygrid_latlon; gcmfaces_bindata; global mytri;
    veclon=convert2array(mygrid.XC); veclon=veclon(mytri.kk);
    veclat=convert2array(mygrid.YC); veclat=veclat(mytri.kk);
    
    mygrid=mygrid_refgrid; mytri=[]; gcmfaces_bindata;
    vecfld=NaN*veclon*ones(1,50);
    for kk=1:50;
        %go from gcmfaces grid to lat-lon grid
        vecfld(:,kk)=gcmfaces_interp_2d(fld(:,:,kk),veclon,veclat);
    end;
    
    %reformat into a 360*180*50 array
    mygrid=mygrid_latlon; mytri=[]; gcmfaces_bindata;
    fld_latlon=NaN*ones(360*180,50);
    fld_latlon(mytri.kk,:)=vecfld;
    fld_latlon=reshape(fld_latlon,[360 180 50]);
    
    %interpolate vertically
    coeff=interp1(-mygrid_refgrid.RC,[1:50],depth); coeff(1)=1;
    tmp1=find(isnan(coeff)); coeff(tmp1)=50-0.01; %quick fix
    
    %vertical interpolation to mygrid.RC:
    nrOut=length(depth);
    FLD=NaN*zeros(360,180,nrOut);
    for kk=1:nrOut;
        tmp1=coeff(kk); tmp2=floor(tmp1); tmp1=tmp1-tmp2;
        if tmp2==50;
            tmp3=fld_latlon(:,:,tmp2);
        else;
            tmp3=(1-tmp1)*fld_latlon(:,:,tmp2)+tmp1*fld_latlon(:,:,tmp2+1);
        end;
        FLD(:,:,kk)=tmp3;
    end;
    
    if ii==1; FLD1=FLD;
    else; FLD2=FLD;
    end;
end;%for ii=1:2;

% save testcase_remap.mat lon lat depth FLD1 FLD2 fld1 fld2;

mygrid=mygrid_refgrid; mytri=[];

