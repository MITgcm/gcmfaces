function [fldUe,fldVn]=calc_UV_zonmer(fldU,fldV);
%object:    compute Eastward/Northward vectors form X/Y vectors
%inputs:    fldU/fldV are the X/Y vector fields at velocity points
%outputs:   fldUe/fldVn are the Eastward/Northward vectors at tracer points
%
%note: this routine does no apply any mask -- unlike the old calc_UEVNfromUXVY.m

gcmfaces_global;

[FLDU,FLDV]=exch_UV(fldU,fldV);

fldUe=fldU; fldVn=fldV;
for iF=1:fldU.nFaces; 
tmp1=FLDU{iF}(1:end-1,:,:); tmp2=FLDU{iF}(2:end,:,:);
fldUe{iF}=reshape(nanmean([tmp1(:) tmp2(:)],2),size(tmp1));
tmp1=FLDV{iF}(:,1:end-1,:); tmp2=FLDV{iF}(:,2:end,:);
fldVn{iF}=reshape(nanmean([tmp1(:) tmp2(:)],2),size(tmp1));
end;

FLDU=fldUe; FLDV=fldVn;
cs=mk3D(mygrid.AngleCS,FLDU); sn=mk3D(mygrid.AngleSN,FLDU);

fldUe=+FLDU.*cs-FLDV.*sn;
fldVn=FLDU.*sn+FLDV.*cs;


