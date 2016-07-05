function [uvcurl]=calc_UV_curl(u,v,putCurlOnTpoints, doMask);
%[uvcurl]=calc_UV_curl(u,v,putCurlOnTpoints, [doMask]);
%object:    compute curl of a vector field
%inputs:    u,v is the vector field of interest
%           putCurlOnTpoints states wherther to return the curl
%               at curl points (0) or on tracer points (1)
%           doMask: 0 to computer curl at all points (default) or 1 to
%           mask so that curl is only computed at points that do not
%           touch land (set to zero where touches land)
%output:    [uvcurl] is the curl

gcmfaces_global;

if ~isfield(mygrid,'RAZfull');
    %get full RAZ (incl. 'extra line and column')
    fprintf('\n calc_UV_curl requires loading (once) RAZfull \n');
    fprintf('into mygrid, so we now call grid_load_native_RAZ \n\n');
    grid_load_native_RAZ;
end;

if nargin < 4
    doMask=0;
end

if doMask
    u(find(u==0))=NaN; v(find(v==0))=NaN;
end

%do the exchange: with sign changes for u and v, ...
nn=1;
[U,V]=exch_UV_N(u,v,nn);
%... without sign changes for DXC and DYC
[DXC,DYC]=exch_UV_N(mygrid.DXC,mygrid.DYC,nn);
U=U.*abs(DXC); V=V.*abs(DYC);

%compute the curl field
uvcurl=NaN*mygrid.RAZfull;

for iF=1:uvcurl.nFaces;
    %define ucur, vcur as u,v on current face, with points that dont
    %contribute to curl on that face removed.
    ucur=U{iF}(2:end,:);
    vcur=V{iF}(:,2:end);
    
    tmpcurl=ucur(:,1:end-1)-ucur(:,2:end);
    tmpcurl=tmpcurl-(vcur(1:end-1,:)-vcur(2:end,:));
    
    %deal with corners where only 3 point contribute to curl
    if mod(iF,2)==1 %odd faces
        
        vc=-vcur(1,1); %- S-W corner
        tmpcurl(1,1) = (vcur(2,1)-ucur(1,2))+vc;
        
        vc=vcur(end,1); %- S-E corner
        tmpcurl(end,1) = (vc-ucur(end,2))-vcur(end-1,1);
        
        vc=vcur(end,end); %- N-E corner
        tmpcurl(end,end)=(vc-vcur(end-1,end))+ucur(end,end-1);
        
        vc=-vcur(1,end); %- N-W corner
        vc3=[vc vcur(2,end) ucur(1,end-1) vc vcur(2,end)];
        n=(iF+1)/2;
        tmpcurl(1,end) = (vc3(n+2)+vc3(n+1))+vc3(n);
        
    else %even faces
        vc=-vcur(1,1); %- S-W corner
        tmpcurl(1,1)   = (vcur(2,1)-ucur(1,2))+vc;
        
        vc=vcur(end,1); %- S-E corner
        n=iF/2;
        vc3=[-ucur(end,2) -vcur(end-1,1) vc -ucur(end,2) -vcur(end-1,1)];
        tmpcurl(end,1) = (vc3(n)+vc3(n+1))+vc3(n+2);
        
        vc=vcur(end,end); %- N-E corner
        tmpcurl(end,end)=(ucur(end,end-1)+vc)-vcur(end-1,end);
        
        vc=-vcur(1,end); %- N-W corner
        tmpcurl(1,end) = (vcur(2,end)+vc)+ucur(1,end-1);
    end
    
    tmpcurl=tmpcurl./mygrid.RAZfull{iF};
    
    %set points where NaN back to zero
    tmpcurl(isnan(tmpcurl))=0;
    
    %put to tracer points
    if putCurlOnTpoints;
        tmpcurl=1/4*(tmpcurl(1:end-1,2:end)+tmpcurl(1:end-1,1:end-1)+...
            tmpcurl(2:end,2:end)+tmpcurl(2:end,1:end-1));
    end;
    uvcurl{iF}=tmpcurl;
    
end;

