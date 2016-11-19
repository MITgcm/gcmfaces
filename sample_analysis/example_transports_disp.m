function []=example_transports_disp(diags);
%EXAMPLE_TRANSPORTS_DISP display the results (diags) of example_transports
%call: example_transports_disp(diags);

gcmfaces_global;
if myenv.verbose>0;
    gcmfaces_msg('===============================================');
    gcmfaces_msg(['*** entering example_transports_disp: ' ...
        'display the results (diags) of example_transports'],'');
end;

%check that LATS_MASKS has already been defined:
if ~isfield(mygrid,'LATS_MASKS');
    fprintf('one-time initialization of gcmfaces_lines_zonal: begin\n');
    gcmfaces_lines_zonal;
    fprintf('one-time initialization of gcmfaces_lines_zonal: end\n');
end;

%%%%%%%%%%%%%%%
%display diags:
%%%%%%%%%%%%%%%

if isfield(diags,'fldBAR');

%barotropic streamfunction:
[X,Y,FLD]=convert2pcol(mygrid.XC,mygrid.YC,diags.fldBAR);
cc=[[-80:10:30] [40:40:200]];
figureL; set(gca,'FontSize',14);
pcolor(X,Y,FLD); axis([-180 180 -90 90]); 
set(gcf,'Renderer','zbuffer'); shading interp; 
gcmfaces_cmap_cbar(cc); title('Horizontal Stream Function (in Sv)');
xlabel('longitude'); ylabel('latitude');

%meridional streamfunction:
X=mygrid.LATS*ones(1,length(mygrid.RF)); Y=ones(length(mygrid.LATS),1)*mygrid.RF';
FLD=diags.gloOV; FLD(FLD==0)=NaN;
cc=[[-50:10:-30] [-24:3:24] [30:10:50]];
figureL; set(gca,'FontSize',14);
pcolor(X,Y,FLD); axis([-90 90 -6000 0]); 
set(gcf,'Renderer','zbuffer'); shading interp;
gcmfaces_cmap_cbar(cc); title('Meridional Stream Function (in Sv)');
xlabel('latitude'); ylabel('depth');

end;%if isfield(diags,'fldBAR');

if isfield(diags,'fldTRANSPORTS');

if myenv.verbose>0; gcmfaces_msg('* call disp_transport : print and/or plot transports');end;

%Bering Strait and Arctic/Atlantic exchanges:
if length(diags.listTimes)>1; figureL; end;
transpList=[1 8:12];
rangeList=[[-1 3];[-3 1];[-6 2];[-3 9];[-9 3];[-0.5 0.5]];
for iii=1:length(transpList);
    if length(diags.listTimes)>1; subplot(3,2,iii); end;
    ylim=rangeList(iii,:);
    %
    ii=transpList(iii);
    trsp=diags.fldTRANSPORTS(ii,:)';
    txt=[mygrid.LINES_MASKS(ii).name ' (>0 to Arctic)'];
    disp_transport(trsp,diags.listTimes,txt,{'ylim',ylim});
end;

%Drake, ACC etc:
if length(diags.listTimes)>1; figureL; end;
transpList=[13 20 19 18];
rangeList=[[120 200];[120 200];[-40 10];[120 200]];
for iii=1:length(transpList);
    if length(diags.listTimes)>1; subplot(3,2,iii); end;
    ylim=rangeList(iii,:);
    %
    ii=transpList(iii);
    trsp=diags.fldTRANSPORTS(ii,:)';
    txt=[mygrid.LINES_MASKS(ii).name ' (>0 to the West)'];
    disp_transport(trsp,diags.listTimes,txt,{'ylim',ylim});
end;

end;%if isfield(diags,'fldTRANSPORTS');

if isfield(diags,'fldTzonmean');
%zonal mean T and S:

X=mygrid.LATS*ones(1,length(mygrid.RC)); Y=ones(length(mygrid.LATS),1)*mygrid.RC';
FLD=diags.fldTzonmean; FLD(FLD==0)=NaN;
cc=[-3:2:30];
figureL; set(gca,'FontSize',14);
pcolor(X,Y,FLD); axis([-90 90 -6000 0]); 
set(gcf,'Renderer','zbuffer'); shading interp;
gcmfaces_cmap_cbar(cc); title('zonal mean temperature (in degree C)');
xlabel('latitude'); ylabel('depth');

%X=mygrid.LATS*ones(1,length(mygrid.RC)); Y=ones(length(mygrid.LATS),1)*mygrid.RC';
%FLD=diags.fldSzonmean; FLD(FLD==0)=NaN;
%cc=[32:0.2:36];
%figureL; set(gca,'FontSize',14);
%pcolor(X,Y,FLD); axis([-90 90 -6000 0]); 
%set(gcf,'Renderer','zbuffer'); shading interp;
%gcmfaces_cmap_cbar(cc); title('zonal mean salinity (in psu)');
%xlabel('latitude'); ylabel('depth');

end;%if isfield(diags,'fldTzonmean');

if isfield(diags,'gloMT_H');
%meridional transports:

FLD=diags.gloMT_H; FLD(FLD==0)=NaN;
figureL; set(gca,'FontSize',14);
plot(mygrid.LATS,FLD); xlabel('longitude'); ylabel('PW');
grid on; title('Meridional Heat Transport');

%FLD=diags.gloMT_FW; FLD(FLD==0)=NaN;
%figureL; set(gca,'FontSize',14);
%plot(mygrid.LATS,FLD); xlabel('longitude'); ylabel('Sv'); 
%grid on; title('Meridional Sea Water Transport');

%FLD=diags.gloMT_SLT; FLD(FLD==0)=NaN;
%figureL; set(gca,'FontSize',14);
%plot(mygrid.LATS,FLD); xlabel('longitude'); ylabel('psu Sv');
%grid on; title('Meridional Salt Transport');

end;%if isfield(diags,'gloMT_H');

%%%%

if myenv.verbose>0;
    gcmfaces_msg('*** leaving example_transports_disp');
    gcmfaces_msg('===============================================','');
end;
