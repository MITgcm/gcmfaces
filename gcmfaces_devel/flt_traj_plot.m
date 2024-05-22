function []=flt_traj_plot(flts,proj,bgrd);
% flt_traj_plot(flts) plots trajectories generated using pkg/flt
%
%A possible calling sequence:
%
%grid_load;
%dirRun='run/';
%[flts,data,header]=flt_traj_read([dirRun 'float_trajectories'],4);
%flt_traj_plot(flts);

gcmfaces_global;

if isempty(whos('proj')); proj=0; end;

if proj==0;
    figure; orient landscape;
    col='rgbrgb';
    for ii=1:5;
        plot(mygrid.XC{ii}(1:5:end,1:5:end),mygrid.YC{ii}(1:5:end,1:5:end),[col(ii) 'x']); hold on;
    end;
    for ii=1:length(flts);
        x=flts(ii).x; y=flts(ii).y;
        jj=find(abs(diff(x))>90); x(jj)=NaN; y(jj)=NaN;
        x(end)=NaN; y(end)=NaN;
        plot(x,y,'k-'); hold on;
    end;
end;

if proj>0;
    
    figure; orient landscape;
    if isempty(whos('bgrd')); bgrd=mygrid.Depth; end;
    m_map_gcmfaces(bgrd,proj,{'myCmap','gray'},{'doCbar',0});
    for jj=1:3;
        if jj==1; mrk='r.';
        elseif jj==2; mrk='g.';
        else; mrk='b.';
        end;
        mrk='k.'; mrkini='go'; mrkend='co';
        for ii=jj:3:length(flts);
            lon=flts(ii).x; lat=flts(ii).y;
            if proj==1.2; lon(lon<20)=lon(lon<20)+360; end;
            m_map_gcmfaces({'plot',lon,lat,mrk,'MarkerSize',0.5},proj,{'doHold',1});
            m_map_gcmfaces({'plot',lon(1),lat(1),mrkini,'MarkerSize',2},proj,{'doHold',1});
            m_map_gcmfaces({'plot',lon(end-1),lat(end-1),mrkend,'MarkerSize',2},proj,{'doHold',1});
        end;
    end;
end;

