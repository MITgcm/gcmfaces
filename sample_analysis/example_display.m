function []=example_display(method);
% EXAMPLE_DISPLAY(method) illustrate various options to display 2D fields.
%
%  method (optional) selects the plotting method
%     1: plot a gcmfaces object face by face (as in Fig. C1) of doi:10.5194/gmd-8-3071-2015).
%     2: use convert2array via qwckplot (a quick but crude display option).
%     3: use convert2pcol then pcolor (for a display in lat-lon coordinates).
%     4: use the m_map_gcmfaces front end to m_map (https://www.eoas.ubc.ca/~rich/map.html).
%     5: use gcmfaces_sphere to display fields on a sphere.
%     6: use stretched vertical coordinate.
%  If method is not specified then it is set to [3:5] by default.
%
% Example: addpath gcmfaces/sample_analysis/; example_display;

gcmfaces_global;

input_list_check('example_display',nargin);

if isempty(whos('method')); method=[1:5]; end;

if myenv.verbose>0;
    gcmfaces_msg('===============================================');
    gcmfaces_msg(['*** entering example_display: displays a gridded ' ...
        'field of ocean depth (gcmfaces object) in geographic coordinates ' ...
        'using pcolor, in various projections (if m_map is in Matlab path), ' ...
        'and on a sphere.'],'');
end;

%%%%%%%%%%%%%%%%%
%load grid:
%%%%%%%%%%%%%%%%%

if isempty(mygrid);
   grid_load; 
end;
nF=mygrid.nFaces;

%%%%%%%%%%%
%get field:
%%%%%%%%%%%

fld=mygrid.Depth; fld(fld==0)=NaN;
cc=[[0:0.05:0.5] [0.6 0.75 1 1.25]]*1e4; myCmap='gray';

%%%%%%%%%%%%
%plot field:
%%%%%%%%%%%%

if sum(ismember(method,1));
    if myenv.verbose>0; gcmfaces_msg('* gcmfaces format display -- face by face.'); end;
    if nF==1;
        figureL; imagescnan(fld{1}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
    elseif nF==5;
        figureL;
        subplot(3,3,7); imagescnan(fld{1}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'1','FontSize',32,'Color','r','Rotation',0);
        subplot(3,3,8); imagescnan(fld{2}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'2','FontSize',32,'Color','r','Rotation',0);
        subplot(3,3,5); imagescnan(fld{3}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'3','FontSize',32,'Color','r','Rotation',0);
        subplot(3,3,6); imagescnan(fld{4}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'4','FontSize',32,'Color','r','Rotation',0);
        subplot(3,3,3); imagescnan(fld{5}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'5','FontSize',32,'Color','r','Rotation',0);
    elseif nF==6;
        figureL;
        subplot(3,4,9); imagescnan(fld{1}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'1','FontSize',32,'Color','r','Rotation',0); 
        subplot(3,4,10); imagescnan(fld{2}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'2','FontSize',32,'Color','r','Rotation',0);
        subplot(3,4,6); imagescnan(fld{3}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'3','FontSize',32,'Color','r','Rotation',0);
        subplot(3,4,7); imagescnan(fld{4}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'4','FontSize',32,'Color','r','Rotation',0);
        subplot(3,4,3); imagescnan(fld{5}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'5','FontSize',32,'Color','r','Rotation',0);
        subplot(3,4,4); imagescnan(fld{6}','nancolor',[1 1 1]*0.8); axis xy; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb);
        tmp1=axis; tmp2=text(tmp1(2)/2,tmp1(4)/2,'6','FontSize',32,'Color','r','Rotation',0);
    else;
        error('face by face plot not yet implemented for this grid');
    end;
    title('display face by face');
end;

if sum(ismember(method,2));
    if myenv.verbose>0; gcmfaces_msg('* array format display -- all faces concatenated.'); end;
    figureL; qwckplot(fld); cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); %delete(cb);
    title('display using qwckplot');
    for ff=1:mygrid.nFaces;
        tmp0=0*mygrid.XC;
        tmp1=round(size(tmp0{ff})/2);
        tmp0{ff}(tmp1(1),tmp1(2))=1;
        tmp0=convert2array(tmp0); [ii,jj]=find(tmp0==1);
        if ff==3; ang=90; elseif ff>3; ang=-90; else; ang=0; end;
        hold on; text(ii,jj,num2str(ff),'FontSize',32,'Color','r','Rotation',ang);
    end;
end;

if sum(ismember(method,3));
    if myenv.verbose>0; gcmfaces_msg('* geographical display -- using pcolor directly.'); end;
    figureL;
    [X,Y,FLD]=convert2pcol(mygrid.XC,mygrid.YC,fld); pcolor(X,Y,FLD);
    if ~isempty(find(X>359)); axis([0 360 -90 90]); else; axis([-180 180 -90 90]); end;
    shading flat; cb=gcmfaces_cmap_cbar(cc,{'myCmap',myCmap}); delete(cb); 
    xlabel('longitude'); ylabel('latitude'); 
    title('display using convert2pcol');
end;

if sum(ismember(method,4));
    if myenv.verbose>0; gcmfaces_msg('* geographical display -- using m_map_gcmfaces.'); end;
    if ~isempty(which('m_proj'));
        figureL; m_map_gcmfaces(fld,0,{'myCaxis',cc},{'myCmap',myCmap});
        aa=get(gcf,'Children'); axes(aa(4));
        title('display using m_map_gcmfaces','Interpreter','none');
    elseif myenv.verbose;
        fprintf('  > To use m_map_gcmfaces, please add m_map to your Matlab path\n');
    end;
end;

if sum(ismember(method,5));
    if myenv.verbose>0; gcmfaces_msg('* geographical display -- on a sphere.'); end;
    figureL; gcmfaces_sphere(fld,cc,[],'N',3);
    title('display using gcmfaces_sphere','Interpreter','none');
end;

%test case for depthStretchPlot:
if sum(ismember(method,6));
    if myenv.verbose>0; gcmfaces_msg('* section display -- using strecthed vertical coord.'); end;
    x=ones(length(mygrid.RC),1)*[1:200]; z=mygrid.RC*ones(1,200); c=sin(z/2000*pi).*cos(x/50*pi);
    figureL;
    subplot(1,2,1); set(gca,'FontSize',16);
    pcolor(x,z,c); shading flat; title('standard depth display');
    subplot(1,2,2); set(gca,'FontSize',16);
    depthStretchPlot('pcolor',{x,z,c}); shading flat; 
    title('stretched depth display');
end;

if myenv.verbose>0;
    gcmfaces_msg('*** leaving example_display');
    gcmfaces_msg('===============================================');
end;

