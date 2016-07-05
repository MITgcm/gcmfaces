function [v0]=convert2widefaces(v0);
%object:    when mygrid.facesSize is non standard (i.e.
%           some faces were troncated in the files) this
%           routine expands them back to dimensions that
%           allow e.g. the exchanges to work

gcmfaces_global;

if ~isempty(mygrid.facesExpand);
    
    nn=mygrid.facesExpand(1); mm=mygrid.facesExpand(2);
    widefacesSize=[[nn mm];[nn mm];[nn nn];[mm nn];[mm nn]];
    
    v0facesSize=[size(v0{1});size(v0{2});size(v0{3});size(v0{4});size(v0{5})];
    v0facesSize=v0facesSize(:,1:2);
    
    test0=0<sum(abs(prod(mygrid.facesSize,2)-prod(v0facesSize,2)));
    test1=0<sum(abs(prod(widefacesSize,2)-prod(v0facesSize,2)));
    if (test0&test1)|(~test0&~test1);
        error('inconsitent size');
    end;
    
    if test1;%the expand faces
        for iFace=1:mygrid.nFaces;
            ii=size(v0{iFace}); ii(1:2)=widefacesSize(iFace,:);
            tmp1=mygrid.missVal*zeros(ii);
            if iFace==1|iFace==2;%fill the Northern part of faces 1 and 2
                jj=[widefacesSize(iFace,2)-v0facesSize(iFace,2)+1:widefacesSize(iFace,2)];
            else;
                jj=[1:v0facesSize(iFace,2)];
            end;
            ii=[1:v0facesSize(iFace,1)];
            tmp1(ii,jj,:,:)=v0{iFace};
            v0{iFace}=tmp1;
        end;
    else;%then truncate faces
        for iFace=1:mygrid.nFaces;
            if iFace==1|iFace==2;%truncate the Southern part of faces 1 and 2
                jj=[widefacesSize(iFace,2)-mygrid.facesSize(iFace,2)+1:widefacesSize(iFace,2)];
            else;
                jj=[1:mygrid.facesSize(iFace,2)];
            end;
            ii=[1:mygrid.facesSize(iFace,1)];
            v0{iFace}=v0{iFace}(ii,jj,:,:);
        end;
    end;
    
end;
