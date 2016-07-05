function []=disp_budget_mean_zonal(lat,budg,uni,tit);
%object : plot a budget from budget_integr
%inputs:    lat is the latitude vector
%           budg is the result of budget_integr (in e.g. m^3/s)
%           uni is the unit to be displayed
%           tit is the variable description to be displayed
%display:   cumulative sum of budg*median(dt)

gcmfaces_global; global myparms;

%scaled the budget terms, and integrate in time:
nyears=[myparms.yearInAve(2)-myparms.yearInAve(1)];
dt=365*86400*nyears;
cont=sum(dt*budg(1,:,:),3);
hdiv=sum(dt*budg(2,:,:),3);
zdiv=sum(dt*budg(3,:,:),3);

%do the plotting:
plot(lat,cont,'b','LineWidth',1); hold on;
plot(lat,zdiv,'r','LineWidth',1);
plot(lat,hdiv,'g','LineWidth',1);
plot(lat,cont-zdiv-hdiv,'k','LineWidth',1);
%finish the plot:
tmp1=max(abs(cont)); tmp2=max(abs(zdiv)); tmp3=max(tmp1,tmp2)*1.5;
if tmp3~=0&std(lat)~=0; axis([min(lat) max(lat) -tmp3 tmp3]); end;
grid on; legend('content','vert. div.','hor. div.','residual','Orientation','horizontal');
res=sqrt(mean((cont-zdiv-hdiv).^2));
title(sprintf('Budget %s scaled by %d years; in %s; residual : %0.1e',tit,nyears,uni,res));

%set the axis range : symmetric about 0 and rounded up
aa=axis;
tmp1=max(abs(hdiv));
tmp2=ceil(log10(tmp1));
tmp2=10^tmp2;
tmp3=2*tmp2*round(tmp1/tmp2*10)/10;
if ~isnan(tmp3); aa(3:4)=tmp3*[-1 1]; end;
axis(aa);

%print to screen:
if ~isempty(strfind(tit,'Mass')); tmp0='Mass';
elseif ~isempty(strfind(tit,'Heat')); tmp0='Heat';
elseif ~isempty(strfind(tit,'Salt')); tmp0='Salt';
else; tmp0='????';
end;
tmp1=round(log10(sqrt(mean((cont).^2))));
tmp2=round(log10(sqrt(mean((cont-zdiv-hdiv).^2))));
fprintf('%5s budget    [log10(cont) | log10(res)]   %3i | %3i\n',tmp0,tmp1,tmp2);


