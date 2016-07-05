function [FLD]=exch_Z_cub(fld);
%[FLD]=exch_Z_cub(fld, [flag]);
%adds vorticity points (to north and east of center points) for
%cubed-sphere grid

gcmfaces_global;

%missing corners : assume symmetry of the grid (that may be completly wrong!)
global exch_Z_assume_sym;
if isempty(exch_Z_assume_sym);
    exch_Z_assume_sym=0;
end;

%determine vertical and/or time dimensions
n3=max(size(fld.f1,3),1); n4=max(size(fld.f1,4),1);

%initialize FLD
FLD=gcmfaces;
for iF=1:mygrid.nFaces
    [n1,n2]=size(mygrid.XC{iF});
    FLD{iF}=NaN*zeros([n1+1 n2+1 n3 n4]);
end;

for k3=1:n3; for k4=1:n4;
        
        for iF=1:mygrid.nFaces
            FLD{iF}(1:end-1,1:end-1,k3,k4)=fld{iF}(:,:,k3,k4);
        end
        
        %overlap in i+1
        FLD.f1(end,1:end-1,k3,k4)=fld.f2(1,:,k3,k4);
        FLD.f2(end,2:end,k3,k4)=flipud(fld.f4(:,1,k3,k4));
        FLD.f3(end,1:end-1,k3,k4)=fld.f4(1,:,k3,k4);
        FLD.f4(end,2:end,k3,k4)=flipud(fld.f6(:,1,k3,k4));
        FLD.f5(end,1:end-1,k3,k4)=fld.f6(1,:,k3,k4);
        FLD.f6(end,2:end,k3,k4)=flipud(fld.f2(:,1,k3,k4));
        
        %overlap in j+1
        FLD.f1(2:end,end,k3,k4)=fliplr(fld.f3(1,:,k3,k4));
        FLD.f2(1:end-1,end,k3,k4)=fld.f3(:,1,k3,k4);
        FLD.f3(2:end,end,k3,k4)=fliplr(fld.f5(1,:,k3,k4));
        FLD.f4(1:end-1,end,k3,k4)=fld.f5(:,1,k3,k4);
        FLD.f5(2:end,end,k3,k4)=fliplr(fld.f1(1,:,k3,k4));
        FLD.f6(1:end-1,end,k3,k4)=fld.f1(:,1,k3,k4);
        
        %missing corners : use the average value (from the 3 or 2 neighbours)
        zzC(1)=fld.f1(1,end,k3,k4)+fld.f3(1,end,k3,k4)+fld.f5(1,end,k3,k4);
        zzC(2)=fld.f2(end,1,k3,k4)+fld.f4(end,1,k3,k4)+fld.f6(end,1,k3,k4);
        zzC=zzC/3;
        
        %missing corners : assume symmetry of the grid (that may be completly wrong!)
        if exch_Z_assume_sym;
            zzC(1)=fld.f4(1,1,k3,k4);
            zzC(2)=fld.f1(1,1,k3,k4);
        end
        
        %- 1rst = N.W corner of face 1
        FLD.f1(1,end,k3,k4)=zzC(1);
        FLD.f3(1,end,k3,k4)=zzC(1);
        FLD.f5(1,end,k3,k4)=zzC(1);
        %- 2nd  = S.E corner of face 2
        FLD.f2(end,1,k3,k4)=zzC(2);
        FLD.f4(end,1,k3,k4)=zzC(2);
        FLD.f6(end,1,k3,k4)=zzC(2);
        
    end; 
end;

