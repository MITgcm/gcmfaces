function [jj]=flt_traj_sel(flts,lons,lats,days);
%lons, lats, days are all pairs

test0=zeros(size(flts));
for ii=1:length(flts)
    lon=flts(ii).x(1:end-1);
    lat=flts(ii).y(1:end-1);
    %day=mod(flts(ii).time(1:end-1)/86400,365);
    day=flts(ii).time(1:end-1)/86400;
    kk=find(lon>lons(1)&lon<lons(2)&lat>lats(1)&lat<lats(2)&day>days(1)&day<days(2));
    if ~isempty(kk); test0(ii)=1; end;
end;
    
jj=find(test0);
    