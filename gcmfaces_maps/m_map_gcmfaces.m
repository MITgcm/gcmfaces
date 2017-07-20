function []=m_map_gcmfaces(fld,varargin);
%object:    gcmfaces front end to m_map
%inputs:    fld is the 2D field to be mapped, or a cell (see below).
%optional:  proj is either the index (integer; 0 by default) of pre-defined
%               projection(s) or parameters to pass to m_proj (cell)
%more so:   other optional paramaters can be provided ONLY AFTER proj,
%           and must take the following form {'name',param1,param2,...}
%           those that are currently active are
%               {'myCaxis',myCaxis} is the color axis ('auto' by default)
%               {'do_m_coast',do_m_coast} adds call to m_coast (1; default) or not (0).
%               {'myCmap',myCmap} is the colormap name ('jet' by default)
%               {'doHold',1} indicates to 'hold on' and superimpose e.g. a contour
%               {'doCbar',1} indicates to include the colorbar (1 by default)
%               {'doLabl',1} indicates to include the axes labels (1 by default)
%               {'doFit',1} indicates to exclude white space (0 by default)
%               {'myShading','flat'} indicates to use flat shading instead of interp
%               {'myFontSize',12} indicates font size for axis labels (10 by default)
%
%notes:     - for proj==0 (i.e. the default) three panels will be plotted :
%           a mercator projection over mid-latitude, and two polar
%           stereographic projections. The other predefined proj are
%               -1  mollweide or cylindrical projection
%               1   mercator projection only
%               2   arctic stereographic projection only
%               3   antarctic stereographic projection only
%               1.1 and 1.2 are atlantic mercator projections
%           - myTitle is currently not used; it will take the form
%              {'myTitle',myTitle} is the title (none by default)
%           - myCaxis can be specified with more than 2 values, in which
%             case gcmfaces_cb will be used.
%           - if fld is a 2D field we use pcolor to display it
%           - if fld is a cell one can specify the plotting tool.
%             The cell  must then have the form {plotType,FLD,varargin}
%             where plotType is e.g. 'pcolor' or 'contour', FLD is
%             the 2D field to be plotted, and varargin are options
%             to pass over to the contour command.
%           - Hence .e.g. fld={'contour',mygrid.Depth,'r'} will draw
%             red contours, while fld=mygrid.Depth will color shade.

%check that m_map is in the path
aa=which('m_proj'); if isempty(aa); error('this function requires m_map that is missing'); end;

global mygrid;

%get optional parameters
if nargin>1; proj=varargin{1}; else; proj=0; end;
if iscell(proj);
    error('not yet implemented');
else;
    choicePlot=proj;
end;
%determine the type of plot
if iscell(fld); myPlot=fld{1}; else; myPlot='pcolor'; fld={'pcolor',fld}; end;
%set more optional paramaters to default values
myCaxis=[]; myTitle=''; myShading='interp'; myCmap='jet'; myFontSize=10;
do_m_coast=1; doHold=0; doCbar=1; doLabl=1; doFit=0;
%set more optional paramaters to user defined values
for ii=2:nargin-1;
    if ~iscell(varargin{ii});
        warning('inputCheck:m_map_gcmfaces_1',...
            ['As of june 2011, m_map_gcmfaces expects \n'...
            '         its optional parameters as cell arrays. \n'...
            '         Argument no. ' num2str(ii+1) ' was ignored \n'...
            '         Type ''help m_map_gcmfaces'' for details.']);
    elseif ~ischar(varargin{ii}{1});
        warning('inputCheck:m_map_gcmfaces_2',...
            ['As of june 2011, m_map_gcmfaces expects \n'...
            '         its optional parameters cell arrays \n'...
            '         to start with character string. \n'...
            '         Argument no. ' num2str(ii+1) ' was ignored \n'...
            '         Type ''help m_map_gcmfaces'' for details.']);
    else;
        if strcmp(varargin{ii}{1},'myCaxis')|...
                strcmp(varargin{ii}{1},'myCmap')|...
                strcmp(varargin{ii}{1},'myShading')|...
                strcmp(varargin{ii}{1},'myFontSize')|...
                strcmp(varargin{ii}{1},'myTitle')|...
                strcmp(varargin{ii}{1},'doHold')|...
                strcmp(varargin{ii}{1},'doCbar')|...
                strcmp(varargin{ii}{1},'doLabl')|...
                strcmp(varargin{ii}{1},'doFit')|...
                strcmp(varargin{ii}{1},'do_m_coast');
            eval([varargin{ii}{1} '=varargin{ii}{2};']);
        else;
            warning('inputCheck:m_map_gcmfaces_3',...
                ['unknown option ''' varargin{ii}{1} ''' was ignored']);
        end;
    end;
end;

%make parameter inferences
if length(myCaxis)==0;
    plotCBAR=0;
elseif length(myCaxis)==2;
    plotCBAR=1;
else;
    plotCBAR=2;
end;
%
if choicePlot==0&~doHold;
    clf;
elseif ~doHold;
    cla;
else;
    hold on;
end;

%re-group param:
param.plotCBAR=plotCBAR;
param.myCmap=myCmap;
param.myCaxis=myCaxis;
param.myFontSize=myFontSize;
param.do_m_coast=do_m_coast;
param.doHold=doHold;
param.doCbar=doCbar;
param.doLabl=doLabl;
param.doFit=doFit;
param.myPlot=myPlot;

%do the plotting:
if (choicePlot~=0&choicePlot~=1&choicePlot~=2&choicePlot~=3);
    do_my_plot(fld,param,choicePlot,myShading);
end;%if choicePlot==0|choicePlot==1;

if choicePlot==0; subplot(2,1,1); end;
if choicePlot==0|choicePlot==1;
    if mygrid.nFaces~=5&mygrid.nFaces~=6;
       do_my_plot(fld,param,1,myShading);
    else;
       do_my_plot(fld,param,1.1,myShading);
    end;
end;%if choicePlot==0|choicePlot==1;

if choicePlot==0; subplot(2,2,3); end;
if choicePlot==0|choicePlot==2;
    do_my_plot(fld,param,2,myShading);
end;%if choicePlot==0|choicePlot==1;

if choicePlot==0; subplot(2,2,4); end;
if choicePlot==0|choicePlot==3;
    do_my_plot(fld,param,3,myShading);
end;%if choicePlot==0|choicePlot==1;

if plotCBAR==2&strcmp(myPlot,'pcolor')&doCbar;
    cbar=gcmfaces_cmap_cbar(myCaxis,{'myCmap',myCmap});
    if choicePlot==0;
        set(cbar,'Position',[0.88 0.15 0.02 0.75]);
    elseif choicePlot==-1;
        set(cbar,'Position',[0.88 0.35 0.02 0.3]);
    elseif choicePlot==1;
        set(cbar,'Position',[0.88 0.34 0.02 0.35]);
    elseif choicePlot==1.2;
        set(cbar,'Position',[0.88 0.34 0.02 0.35]);
    elseif choicePlot==1.3;
        set(cbar,'Position',[0.88 0.34 0.02 0.35]);
    else;
        set(cbar,'Position',[0.88 0.3 0.02 0.4]);
    end;
end;

if doFit;
    if doLabl&~doCbar; 
        set(gca,'LooseInset',[0.05 0.02 0.03 0.03]);
    else; 
        set(gca,'LooseInset',[0.01 0 0.03 0.03]);
    end;
    tmp1=get(gca,'PlotBoxAspectRatio');
    set(gcf,'PaperPosition',[0 4 8 8/tmp1(1)]);
end;

function []=do_my_plot(fld,param,proj,shad);

gcmfaces_global;

%default m_grid params:
xloc='bottom'; xtic=[-180:60:180]; xticlab=1;
yloc='left';   ytic=[-60:30:60];   yticlab=1;

%choice of projection:
if proj==-1;
    %%m_proj('Miller Cylindrical','lat',[-90 90]);
    %m_proj('Equidistant cylindrical','lat',[-90 90]);
    %m_proj('mollweide','lon',[-180 180],'lat',[-80 80]);
    m_proj('mollweide','lon',[-180 180],'lat',[-88 88]);
    myConv='pcol'; xticlab=0; yticlab=0;
elseif proj==1;
    m_proj('Mercator','lat',[-70 70]);
    myConv='pcol';
elseif proj==1.1;
    m_proj('Mercator','lat',[-70 70],'lon',[0 360]+20);
    myConv='pcol';
    xtic=[-360:60:360]; ytic=[-60:30:60];
elseif proj==1.2;
    m_proj('Equidistant cylindrical','lat',[-90 90],'lon',[0 360]+20);
    myConv='pcol';
    xtic=[-360:60:360]; ytic=[-90:30:90];
elseif proj==1.3;
    m_proj('Equidistant cylindrical','lat',[-90 -12],'lon',[0 360]+20);
    myConv='pcol';
    xtic=[-360:60:360]; ytic=[-90:30:90];
elseif proj==2;
    m_proj('Stereographic','lon',0,'lat',90,'rad',40);
    myConv='convert2arctic';
    yloc='bottom'; ytic=[50:10:90];
elseif proj==2.1;
    m_proj('Stereographic','lon',0,'lat',90,'rad',60);
    myConv='convert2arctic';
    yloc='bottom'; ytic=[30:10:90];
elseif proj==3;
    m_proj('Stereographic','lon',0,'lat',-90,'rad',40);
    myConv='convert2southern';
    xloc='top'; ytic=[-90:10:-50];
elseif proj==3.1;
    m_proj('Stereographic','lon',0,'lat',-90,'rad',60);
    myConv='convert2southern';
    xloc='top'; ytic=[-90:10:-30];
elseif proj==4.1;
    m_proj('mollweide','lat',[25 75],'lon',[-100 30]);
    myConv='pcol';
    xtic=[-100:20:30]; ytic=[30:10:70];
elseif proj==4.2;
    m_proj('mollweide','lat',[-30 30],'lon',[-65 20]);
    myConv='pcol';
    xtic=[-60:10:20]; ytic=[-30:10:30];
elseif proj==4.3;
    m_proj('mollweide','lat',[-75 -25],'lon',[-75 25]);
    myConv='pcol';
    xtic=[-70:20:20]; ytic=[-70:10:-30]; xloc='top';
elseif proj==4.4;
    m_proj('mollweide','lat',[25 75],'lon',[-240 -110]);
    myConv='pcol';
    xtic=[-240:20:-120]; ytic=[30:10:60]; 
elseif proj==4.5;
    m_proj('mollweide','lat',[-30 30],'lon',[-240 -70]);
    myConv='pcol';
    xtic=[-240:20:-70]; ytic=[-30:10:30];
elseif proj==4.6;
    m_proj('mollweide','lat',[-75 -25],'lon',[-215 -60]);
    myConv='pcol';
    xtic=[-210:20:-70]; ytic=[-70:10:-30]; xloc='top'; 
elseif proj==4.7;
    m_proj('mollweide','lat',[-30 30],'lon',[15 155]);
    myConv='pcol';
    xtic=[10:20:160]; ytic=[-30:10:30]; xloc='top'; 
elseif proj==4.8;
    m_proj('mollweide','lat',[-75 -25],'lon',[15 155]);
    myConv='pcol';
    xtic=[10:20:160]; ytic=[-70:10:-30]; xloc='top';
else;
    error('undefined projection');
end;

if ~param.doLabl; xticlab=0; yticlab=0;end; %omit labels

m_grid_opt=['''XaxisLocation'',xloc,''YaxisLocation'',yloc'];
m_grid_opt=[m_grid_opt ',''xtick'',xtic,''ytick'',ytic'];
if xticlab==0; m_grid_opt=[m_grid_opt ',''xticklabel'',[]']; end;
if yticlab==0; m_grid_opt=[m_grid_opt ',''yticklabel'',[]']; end;
m_grid_opt=[m_grid_opt ',''fontsize'',param.myFontSize'];

if strcmp(param.myPlot,'pcolor')|strcmp(param.myPlot,'contour')||strcmp(param.myPlot,'contourf');
    x=mygrid.XC;
    %mask out the XC padded zeros
    if isfield(mygrid,'xtrct');
      pt1=mygrid.xtrct.pt1face; pt2=mygrid.xtrct.pt2face;
      if pt1~=pt2;
        for iF=1:6; if iF~=pt1&iF~=pt2; x{iF}(:)=NaN; end; end; 
      end;
      x(x<0)=x(x<0)+360;
    end;
    if strcmp(myConv,'pcol');
        [xx,yy,z]=convert2pcol(x,mygrid.YC,fld{2});
    else;
        eval(['xx=' myConv '(x);']);
        eval(['yy=' myConv '(mygrid.YC);']);
        eval(['z=' myConv '(fld{2});']);
    end;
    [x,y]=m_ll2xy(xx,yy);
    if strcmp(param.myPlot,'pcolor');
        if sum(~isnan(x(:)))>0; pcolor(x,y,z); eval(['shading ' shad ';']); end;
        if param.plotCBAR==0;
            colormap(param.myCmap); if param.doCbar; colorbar; end;
        elseif param.plotCBAR==1;
            caxis(param.myCaxis); colormap(param.myCmap); if param.doCbar; colorbar; end;
        else;
            cbar=gcmfaces_cmap_cbar(param.myCaxis,{'myCmap',param.myCmap}); delete(cbar);
        end;
        if param.do_m_coast; m_coast('patch',[1 1 1]*.7,'edgecolor','none'); end;
        eval(['m_grid(' m_grid_opt ');']);
    elseif strcmp(param.myPlot,'contour');
        if ~param.doHold;
            if param.do_m_coast; m_coast('patch',[1 1 1]*.7,'edgecolor','none'); end;
            eval(['m_grid(' m_grid_opt ');']);
        end;
        if length(fld)==2; fld{3}='k'; end;
        hold on; contour(x,y,z,fld{3:end});
    elseif strcmp(param.myPlot,'contourf');
        if ~param.doHold;
            if param.do_m_coast; m_coast('patch',[1 1 1]*.7,'edgecolor','none'); end;
            eval(['m_grid(' m_grid_opt ');']);
        end;
        if length(fld)==2; fld{3}='k'; end;
        hold on; contourf(x,y,z,fld{3:end});
    end;
elseif strcmp(param.myPlot,'plot');
    if ~param.doHold;
        if param.do_m_coast; m_coast('patch',[1 1 1]*.7,'edgecolor','none'); end;
        eval(['m_grid(' m_grid_opt ');']);
    end;
    [x,y]=m_map_fix_range(fld{2},fld{3});
    [x,y]=m_ll2xy(x,y);
    hold on; plot(x,y,fld{4:end});
elseif strcmp(param.myPlot,'scatter');
    if ~param.doHold;
        if param.do_m_coast; m_coast('patch',[1 1 1]*.7,'edgecolor','none'); end;
        eval(['m_grid(' m_grid_opt ');']);
    end;
    [x,y]=m_map_fix_range(fld{2},fld{3});
    [x,y]=m_ll2xy(x,y);
    hold on; scatter(x,y,fld{4:end});
elseif strcmp(param.myPlot,'text');
    if ~param.doHold;
        if param.do_m_coast; m_coast('patch',[1 1 1]*.7,'edgecolor','none'); end;
        eval(['m_grid(' m_grid_opt ');']);
    end;
    [x,y]=m_ll2xy(fld{2},fld{3});
    if length(fld)>4; cc=fld{5}; else; cc='k'; end;
    hold on; hold on; text(x,y,fld{4},'Color',cc,'FontSize',16,'FontWeight','bold');
end;

%add tag spec. to map & proj generated with this routine
set(gca,'Tag',['gfMap' num2str(proj)]);

  