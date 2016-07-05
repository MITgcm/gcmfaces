function [prof_interp,tile_corners]=gcmfaces_interp_coeffs(prof_lon,prof_lat,varargin);
%[prof_interp]=gcmfaces_interp_coeffs(prof_lon,prof_lat);
%object:    compute bilinear interpolation weights for prof_lon, prof_lat
%inputs:    prof_lon, prof_lat are column vectors
%(optional) ni,nj is the MITgcm tile size (2 numbers total)
%outputs:   prof_interp contains face and tile numbers,
%           indices within tiles (within 0:ni+1,0:nj+1)
%           and interpolation weights (between 0 and 1)
%           of the four neighboring grid points.
%(optional) tile_corners contains XC11,XCNINJ,YC11,YCNINJ (for MITprof)
%
%note: pathological cases (e.g. at edges) remain to be treated.
%example:
%prof=MITprof_load('ctd_feb2013.nc');
%[prof_interp]=gcmfaces_interp_coeffs(prof.prof_lon,prof.prof_lat);

gcmfaces_global;

doDisplay=0;
doVerbose=0; %if myenv.verbose>=1; doVerbose=myenv.verbose; end;
%set doVerbose to display points that could not be triangulated (if any)

%set-up tile information (domain decomposition to ni,nj blocs)
if nargin<=2;
    ni=30; nj=30;
else;
    ni=varargin{1};
    nj=varargin{2};
end;

map_tile=gcmfaces_loc_tile(ni,nj);
loc_tile=gcmfaces_loc_tile(ni,nj,prof_lon,prof_lat);
prof_tile=loc_tile.tileNo;
list_tile=unique(prof_tile);

%point indices in vector format
map_vpi=convert2vector(mygrid.XC);
map_vpi=convert2vector([1:length(map_vpi)]'); 

%initialize output:
prof_interp.point=loc_tile.point;  
prof_interp.face=NaN*prof_lon;
prof_interp.tile=NaN*prof_lon;
prof_interp.i=NaN*repmat(prof_lon,[1 4]);
prof_interp.j=NaN*repmat(prof_lon,[1 4]);
prof_interp.w=NaN*repmat(prof_lon,[1 4]);
prof_interp.XC=NaN*repmat(prof_lon,[1 4]);
prof_interp.YC=NaN*repmat(prof_lon,[1 4]);
prof_interp.vpi=NaN*repmat(prof_lon,[1 4]);
%
tile_corners.XC11=NaN*prof_lon;
tile_corners.YC11=NaN*prof_lon;
tile_corners.XCNINJ=NaN*prof_lon;
tile_corners.YCNINJ=NaN*prof_lon;

%loop over tiles
for ii=1:length(list_tile);
    %1) determine face of current tile ...
    tmp1=1*(map_tile==list_tile(ii));
    tmp11=sum(sum(tmp1,1),2); tmp12=[];
    for ff=1:tmp11.nFaces; tmp12=[tmp12,tmp11{ff}]; end;
    iiFace=find(tmp12);
    %... and its index range within face ...
    tmp1=tmp1{iiFace};
    tmp11=sum(tmp1,2);
    iiMin=min(find(tmp11)); iiMax=max(find(tmp11));
    tmp11=sum(tmp1,1);
    jjMin=min(find(tmp11)); jjMax=max(find(tmp11));
    %... as well as the list of profiles in tile
    ii_prof=find(prof_tile==list_tile(ii));
    %tile corners
    XC11=mygrid.XC{iiFace}(iiMin,jjMin);
    YC11=mygrid.YC{iiFace}(iiMin,jjMin);
    XCNINJ=mygrid.XC{iiFace}(iiMax,jjMax);
    YCNINJ=mygrid.YC{iiFace}(iiMax,jjMax);

    clear tmp*;
    
    %2) stereographic projection to current tile center:
    ii0=floor((iiMin+iiMax)/2);
    jj0=floor((jjMin+jjMax)/2);
    XC0=mygrid.XC{iiFace}(ii0,jj0);
    YC0=mygrid.YC{iiFace}(ii0,jj0);
    %for grid locations:
    [xx,yy]=gcmfaces_stereoproj(XC0,YC0);
    %for profile locations
    [prof_x,prof_y]=gcmfaces_stereoproj(XC0,YC0,prof_lon,prof_lat);
    
    % nrm=sqrt(prof_x.^2+prof_y.^2);
    %ii_prof=find(nrm<tan(pi/4/2));%points inside of pi/4 cone
    
    %3) form array of grid cell quadrilaterals
    xxx=exch_T_N(xx); yyy=exch_T_N(yy);
    xc=exch_T_N(mygrid.XC); yc=exch_T_N(mygrid.YC); vpi=exch_T_N(map_vpi);
    x_quad=[]; y_quad=[]; xc_quad=[]; yc_quad=[]; vpi_quad=[]; i_quad=[]; j_quad=[];
    for pp=1:4;
        switch pp;
            case 1; di=0; dj=0;
            case 2; di=1; dj=0;
            case 3; di=1; dj=1;
            case 4; di=0; dj=1;
        end;
        %note the shift in indices due to exchange above
        tmpx=xxx{iiFace}(iiMin+di:iiMax+1+di,jjMin+dj:jjMax+1+dj);
        tmpx=tmpx(:); x_quad=[x_quad tmpx];
        tmpy=yyy{iiFace}(iiMin+di:iiMax+1+di,jjMin+dj:jjMax+1+dj);
        tmpy=tmpy(:); y_quad=[y_quad tmpy];
        %
        tmpx=xc{iiFace}(iiMin+di:iiMax+1+di,jjMin+dj:jjMax+1+dj);
        tmpx=tmpx(:); xc_quad=[xc_quad tmpx];
        tmpy=yc{iiFace}(iiMin+di:iiMax+1+di,jjMin+dj:jjMax+1+dj);
        tmpy=tmpy(:); yc_quad=[yc_quad tmpy];
        tmpvpi=vpi{iiFace}(iiMin+di:iiMax+1+di,jjMin+dj:jjMax+1+dj);
        tmpvpi=tmpvpi(:); vpi_quad=[vpi_quad tmpvpi];
        %
        tmpi=[0+di:iiMax-iiMin+1+di]'*ones(1,jjMax-jjMin+2);
        tmpi=tmpi(:); i_quad=[i_quad tmpi];
        tmpj=ones(jjMax-jjMin+2,1)*[0+dj:jjMax-jjMin+1+dj];
        tmpj=tmpj(:); j_quad=[j_quad tmpj];
    end;
    
    %4) associate profile locations with quadrilaterals
    [angsum]=gcmfaces_polygonangle(x_quad,y_quad,prof_x(ii_prof),prof_y(ii_prof));
    [II,JJ]=find(abs(angsum)>179);%+-360 for an interior point (+-180 for an edge point)
    if length(unique(JJ))~=length(JJ)&doVerbose;
        n0=num2str(length(JJ)-length(unique(JJ)));
        warning(['multiple polygons (' n0 ')']);
        %store indices of such instances for display
        [a,b]=hist(JJ,unique(JJ));
        KK=find(a>1);
        kk_prof=ii_prof(KK);
        kk_quad={};
        for kk=1:length(KK);
          kk_quad{kk}=II(find(JJ==KK(kk)));
        end
    else;
        kk_prof=[];
    end;
    if length(unique(JJ))<length(ii_prof)&doVerbose;
        n0=num2str(length(ii_prof)-length(unique(JJ)));
        n1=num2str(length(ii_prof));
        warning(['no polygon for ' n0 ' / ' n1]);
        %the following will then remove the corresponding profiles form ii_prof
    end;
    [C,IA,IC] = unique(JJ);
    %
    ii_prof0=ii_prof;
    ii_prof=ii_prof(C);%treated profiles
    jj_prof=setdiff(ii_prof0,ii_prof);%un-treated profiles
    %
    ii_quad=II(IA);

    if length(kk_prof)>0&doVerbose>=3;
      for kk=1:length(kk_prof);
        figureL;
        tmpx=x_quad(kk_quad{kk},[1:4 1])';
        tmpy=y_quad(kk_quad{kk},[1:4 1])';
        plot(tmpx,tmpy,'k.-','MarkerSize',36); hold on;
        plot(prof_x(kk_prof(kk)),prof_y(kk_prof(kk)),'r.','MarkerSize',36)
        aa=axis;
        aa(1:2)=aa(1:2)+abs(diff(aa(1:2)))*[-0.1 0.1];
        aa(3:4)=aa(3:4)+abs(diff(aa(3:4)))*[-0.1 0.1];
        axis(aa);
        keyboard;
      end;
    end;

    if length(jj_prof)>0&doVerbose>=2;
        figureL;
        %
        subplot(2,1,1);
        plot(prof_x(ii_prof),prof_y(ii_prof),'.');
        hold on; plot(x_quad(:),y_quad(:),'r.');
        plot(prof_x(jj_prof),prof_y(jj_prof),'k.','MarkerSize',36);
        %
        subplot(2,1,2);
        tmpx=convert2vector(mygrid.XC);
        tmpy=convert2vector(mygrid.YC);
        tmpi=convert2vector(map_tile);
        tmpi=find(tmpi==ii);
        plot(tmpx(:),tmpy(:),'r.'); hold on; 
        plot(tmpx(tmpi),tmpy(tmpi),'c.');
        plot(prof_lon(ii_prof),prof_lat(ii_prof),'.');
        plot(prof_lon(jj_prof),prof_lat(jj_prof),'k.','MarkerSize',36);
        %
        tmp1=prof_lon([ii_prof;jj_prof]);
        tmp2=prof_lat([ii_prof;jj_prof]);
        axis([min(tmp1) max(tmp1) min(tmp2) max(tmp2)]);
        %
        keyboard;
    end;
    
    if doDisplay;
        figureL;
        xx_tile=xxx{iiFace}(iiMin:iiMax+2,jjMin:jjMax+2);
        yy_tile=yyy{iiFace}(iiMin:iiMax+2,jjMin:jjMax+2);
        pcolor(xx_tile,yy_tile,sqrt(xx_tile.^2+yy_tile.^2)); hold on;
        cc=caxis; cc(2)=cc(2)*2; caxis(cc);
        plot(prof_x(ii_prof),prof_y(ii_prof),'r.','MarkerSize',20);
        plot(prof_x(jj_prof),prof_y(jj_prof),'k.','MarkerSize',60);
        axis([-0.6 0.6 -0.6 0.6]/6);
    end;
    
    if ~isempty(ii_prof);
        %5) determine bi-linear interpolation weights:
        px=x_quad(ii_quad,:);
        py=y_quad(ii_quad,:);
        ox=prof_x(ii_prof);
        oy=prof_y(ii_prof);
        [ow]=gcmfaces_quadmap(px,py,ox,oy);
        
        %to double check interpolation
        % pw=squeeze(ow);
        % oxInterp=sum(pw.*px,2);
        % oyInterp=sum(pw.*py,2);

        %round up coefficient to 4th digit (also to avoid slight negatives)
        test1=~isempty(find(ow(:)<-1e-5));
        if test1; error('interp weight < 0 -- something went wrong'); end;
        test1=~isempty(find(ow(:)>1+1e-5));
        if test1; error('interp weight >1 -- something went wrong'); end;
        %
        ow=1e-4*round(ow*1e4);
        sumw=repmat(sum(ow,3),[1 1 4]);
        ow=ow./sumw;
        
        %6) output interpolation specs:
        prof_interp.face(ii_prof,1)=iiFace*(1+0*ii_quad);
        prof_interp.tile(ii_prof,1)=list_tile(ii)*(1+0*ii_quad);
        prof_interp.i(ii_prof,:)=i_quad(ii_quad,:);
        prof_interp.j(ii_prof,:)=j_quad(ii_quad,:);
        prof_interp.w(ii_prof,:)=squeeze(ow);
        prof_interp.XC(ii_prof,:)=xc_quad(ii_quad,:);
        prof_interp.YC(ii_prof,:)=yc_quad(ii_quad,:);
        prof_interp.vpi(ii_prof,:)=vpi_quad(ii_quad,:);
        %
        tile_corners.XC11(ii_prof)=XC11;
        tile_corners.YC11(ii_prof)=YC11;
        tile_corners.XCNINJ(ii_prof)=XCNINJ;
        tile_corners.YCNINJ(ii_prof)=YCNINJ;
    end;

end;%for ii=1:length(list_tile);

%now format interpolation as sparse matrix and delete vpi:
sizin=convert2vector(mygrid.XC); sizin=length(sizin);
sizout=size(prof_interp.vpi);
tmpi=[1:sizout(1)]'*ones(1,sizout(2));
tmpi=tmpi(:); tmpj=prof_interp.vpi(:); tmpw=prof_interp.w(:);
kk=find(~isnan(tmpj));
tmpi=tmpi(kk); tmpj=tmpj(kk); tmpw=tmpw(kk);
prof_interp.SPM=sparse(tmpi,tmpj,tmpw,sizout(1),sizin,prod(sizout));
prof_interp=rmfield(prof_interp,'vpi');

if doVerbose;
  n1=sum(~isnan(prof_interp.face));
  n2=sum(isnan(prof_interp.face));
  fprintf(['interpolated points: ' num2str(n1) '\n']);
  fprintf(['un-treated points:   ' num2str(n2) '\n']);
end;

