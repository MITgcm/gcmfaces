function [v1]=convert2gcmfaces(v0,varargin);
%object:    converts model output to gcmfaces object
%           or vice versa
%input:     v0 model output array (resp. gcmfaces object)
%output:    v1 gcmfaces object (model output array)
%
%note:      global mygrid parameters (nFaces, fileFormat) are used

input_list_check('convert2gcmfaces',nargin);

aa=whos('v0'); 
if strcmp(aa.class,'single'); v0=double(v0); end;
aa=whos('v0');
doGcm2Faces=strcmp(aa.class,'double');

global mygrid;

if doGcm2Faces&&mygrid.gcm2facesFast;
    
    [n1,n2,n3,n4,n5]=size(v0);
    
    v0=reshape(v0,[n1*n2 n3*n4*n5]);
    for iFace=1:mygrid.nFaces;
        v1{iFace}=reshape(mygrid.gcm2faces{iFace}*v0,[size(mygrid.XC{iFace}) n3 n4 n5]);
    end;
    
    v1=gcmfaces(v1);
    
elseif ~doGcm2Faces&&mygrid.gcm2facesFast;
    
    [n1,n2,n3,n4,n5]=size(v0{1});
    
    v1=zeros(mygrid.faces2gcmSize(1)*mygrid.faces2gcmSize(2),n3*n4*n5);
    for iFace=1:mygrid.nFaces;
        nn=size(mygrid.XC{iFace});
        v1(mygrid.faces2gcm{iFace},:)=reshape(v0{iFace},[nn(1)*nn(2) n3*n4*n5]);
    end;
    v1=reshape(v1,[mygrid.faces2gcmSize n3 n4 n5]);
    
elseif doGcm2Faces;
    
    [n1,n2,n3,n4,n5]=size(v0);
    
    if strcmp(mygrid.fileFormat,'straight');
        v1={v0};
    elseif strcmp(mygrid.fileFormat,'cube');
        for ii=1:6; v1{ii}=v0(n2*(ii-1)+[1:n2],:,:,:,:); end;
    elseif strcmp(mygrid.fileFormat,'compact')||strcmp(mygrid.fileFormat,'nctiles');
        v00=reshape(v0,[n1*n2 n3*n4*n5]);
        i0=0; i1=0;
        for iFace=1:mygrid.nFaces;
            i0=i1+1;
            nn=mygrid.facesSize(iFace,1); mm=mygrid.facesSize(iFace,2);
            i1=i1+nn*mm;
            v1{iFace}=reshape(v00(i0:i1,:),[nn mm n3 n4 n5]);
        end;
    elseif strcmp(mygrid.fileFormat,'native');
        v1=convert2array(v0);
    end;
    
    if ~strcmp(mygrid.fileFormat,'native'); v1=gcmfaces(v1); end;
    
    if ~isempty(mygrid.facesExpand); v1=convert2widefaces(v1); end;
    
else;
    
    [n1,n2,n3,n4,n5]=size(v0{1});
    
    if strcmp(mygrid.fileFormat,'straight');
        v1=v0{1};
    elseif strcmp(mygrid.fileFormat,'cube');
        v1=zeros(n2*6,n2,n3,n4,n5);
        for ii=1:6; v1([1:n2]+(ii-1)*n2,:,:,:,:)=v0{ii}; end;
    elseif strcmp(mygrid.fileFormat,'compact')||strcmp(mygrid.fileFormat,'nctiles');
        
        %   is there a reason for this?
        %         v0_faces=v0; clear v0;
        %         for iFace=1:mygrid.nFaces; eval(['v0{iFace}=get(v0_faces,''f' num2str(iFace) ''');']); end;
        
        if ~isempty(mygrid.facesExpand); v0=convert2widefaces(v0); end;

        aa=0;bb=0;
        for iFace=1:mygrid.nFaces;
            aa=aa+prod(mygrid.facesSize(iFace,:));
            bb=bb+prod(size(v0{iFace}));
        end;
        bb=bb/aa;
        v11=NaN*zeros(aa,bb);
        
        i0=0; i1=0;
        for iFace=1:mygrid.nFaces;
            i0=i1+1;
            nn=mygrid.facesSize(iFace,1); mm=mygrid.facesSize(iFace,2);
            i1=i1+nn*mm;
            v11(i0:i1,:)=reshape(v0{iFace},[nn*mm bb]);
        end;
        nn=mygrid.ioSize(1); mm=mygrid.ioSize(2);        
        v1=reshape(v11,[nn mm n3 n4 n5]);

    elseif strcmp(mygrid.fileFormat,'native');
        v1=convert2array(v0);        
    end;
    
end;


