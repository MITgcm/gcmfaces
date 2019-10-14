function []=flt_traj_plot(flts);
% flt_traj_plot(flts) plots trajectories generated using pkg/flt
%
%A possible calling sequence:
%
%grid_load;
%dirRun='run/';
%[flts,data,header]=flt_traj_read([dirRun 'float_trajectories'],4);
%flt_traj_plot(flts);

gcmfaces_global;

numPlot=2

if numPlot==1;
    figure; orient landscape;
    col='rgbrgb';
    for ii=1:5;
        plot(mygrid.XC{ii}(1:5:end,1:5:end),mygrid.YC{ii}(1:5:end,1:5:end),[col(ii) 'x']); hold on;
    end;
    for ii=1:length(flts);
        x=flts(ii).x; y=flts(ii).y;
        jj=find(abs(diff(x))>90); x(jj)=NaN; y(jj)=NaN;
        plot(x,y,'k-'); hold on;
    end;
end;

if numPlot==2;
    
    myProj=1.2;
    
    figure; orient landscape;
    m_map_gcmfaces(mygrid.Depth,myProj,{'myCmap','viridis'},{'doCbar',0});
    for jj=1:3;
        if jj==1; mrk='r.';
        elseif jj==2; mrk='g.';
        else; mrk='b.';
        end;
        mrk='r.';
        for ii=jj:3:length(flts);
            lon=flts(ii).x; lat=flts(ii).y;
            if myProj==1.2; lon(lon<20)=lon(lon<20)+360; end;
            m_map_gcmfaces({'plot',lon,lat,mrk,'MarkerSize',1},myProj,{'doHold',1});
        end;
    end;
end;

