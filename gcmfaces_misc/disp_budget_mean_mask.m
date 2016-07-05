function []=disp_budget_mean_mask(tim,budg,uni,tit);
%object : plot a budget from budget_integr
%inputs:    tim is the time vector (in days)
%           budg is the result of budget_integr (in e.g. m^3/s)
%           uni is the unit to be displayed
%           tit is the variable description to be displayed
%display:   cumulative sum of budg*median(dt)

%scale the budget terms, and integrate in time:
dt=365.25*median(diff(tim));%in days
if isnan(dt); dt=1; end;%assume annual mean
dt=dt*86400;%in seconds
cont=dt*cumsum(budg(1,:));
hdiv=dt*cumsum(budg(2,:));
zdiv=dt*cumsum(budg(3,:));

%do the plotting:
plot(tim,cont,'b','LineWidth',1); hold on;
plot(tim,zdiv,'r','LineWidth',1);
plot(tim,hdiv,'g','LineWidth',1);
plot(tim,cont-zdiv-hdiv,'k','LineWidth',1);
%finish the plot:
tmp1=max(abs(cont)); tmp2=max(abs(zdiv)); tmp3=max(tmp1,tmp2)*1.5;
if tmp3~=0&std(tim)~=0; axis([min(tim) max(tim) -tmp3 tmp3]); end;
grid on; legend('content','vert. div.','hor. div.','residual','Orientation','horizontal');
res=sqrt(mean((cont-zdiv-hdiv).^2));
title(sprintf('Budget %s; in %s; residual : %0.1e',tit,uni,res));

%set the axis range : symmetric about 0 and rounded up
aa=axis;
tmp1=max(abs(cont));
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


