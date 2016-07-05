function [myplot]=disp_transport(myTransports,myTimes,myTitle,varargin);
%object:	display transport time series and/or time mean
%inputs:	myTransports contains the transports as a function of depth and time
%		myTitle is the transport name to be displayed
%		myTimes is the time vector
%optional:	must take the following form {'name',param1,param2,...} where name may be
%		nmean is a running mean window length (0 by default) 
%               ylim is the y axis range for plotting
%		choicePlot is the type of plot (1 by default)
%			1) time series of vertical integral
%			2) time series of overturning magnitude (>0)
%			3) time mean profile of transport per grid point
%			4) time mean profile of bottom-to-top cumulated transport 

global mygrid;


%set more optional paramaters to default values
ylim=[]; nmean=0; choicePlot=1; myUnit=[];
%set more optional paramaters to user defined values
for ii=1:nargin-3;
    if ~iscell(varargin{ii});
        warning(inputCheck:disp_transport_1',...
            ['disp_transport optional parameters must be spc. as cell arrays. \n'...
            '         Argument no. ' num2str(ii+1) ' was ignored \n'...
            '         Type ''help disp_transport'' for details.']);
    elseif ~ischar(varargin{ii}{1});
        warning('inputCheck:disp_transport_2',...
            ['disp_transport opt. param. cells must start with a char. string. \n'...
            '         Argument no. ' num2str(ii+1) ' was ignored \n'...
            '         Type ''help disp_transport'' for details.']);
    else;
        if strcmp(varargin{ii}{1},'nmean')|...
                strcmp(varargin{ii}{1},'ylim')|...
                strcmp(varargin{ii}{1},'choicePlot')|...
                strcmp(varargin{ii}{1},'myUnit');
            eval([varargin{ii}{1} '=varargin{ii}{2};']);
        else;
            warning('inputCheck:disp_transport_3',...
                ['unknown option ''' varargin{ii}{1} ''' was ignored']);
        end;
    end;
end;

nt=length(myTimes);
if nt==1&size(myTransports,1)==1; myTransports=myTransports'; end;

if choicePlot==2|choicePlot==4;%compute cumulative sum from bottom
    if size(myTransports,1)>1;
        fld=[flipdim(cumsum(flipdim(myTransports,1)),1);zeros(1,nt)];
    else;
        fld=[flipdim(cumsum(flipdim(myTransports',1)),1);zeros(1,nt)];
    end;
else;
 fld=myTransports;
end;

if choicePlot==1;  fld=nansum(fld,1); end;
if choicePlot==2;  fld=nanmax(abs(fld),[],1); end;
if choicePlot==3;  fld=nanmean(fld,2); z=squeeze(mygrid.RC); end;
if choicePlot==4;  fld=[nanmean(fld,2);0]; z=squeeze(mygrid.RF); end;

if choicePlot==1|choicePlot==2;%time series
 fldmean=1e-2*round(mean(fld)*1e2);
 if ~isempty(myUnit); unit=[' ' myUnit]; else; unit=' Sv'; end;
 if nt>1;
   %myTitle=[myTitle ' mean = ' num2str(fldmean) unit];
   if nmean>0; plot(myTimes,fld); hold on; end;
   fld=runmean(fld,nmean,2);
   myplot=plot(myTimes,fld,'LineWidth',2); title(myTitle); set(gca,'FontSize',14); grid on;
   if ~isempty(ylim); aa=[min(myTimes) max(myTimes) ylim]; axis(aa); end;
   aa=axis; xx=aa(1)+(aa(2)-aa(1))/20; yy=aa(4)-(aa(4)-aa(3))/5;  
   cc=text(xx,yy,['(mean = ' num2str(fldmean) unit ')']);
 else;
   fprintf([myTitle '-- mean: ' num2str(fldmean) ' Sv\n']);
 end; 
elseif choicePlot==3|choicePlot==4;%time mean profile
 nr=length(z);
 kk=find(fld==0); if length(kk)>0; kk=[1:min(min(kk)+2,nr)]; else; kk=[1:nr]; end;
 myplot=plot(fld(kk),z(kk),'LineWidth',2); title(myTitle); set(gca,'FontSize',14); grid on;
 aa=axis; tmp1=max(abs(aa(1:2))); aa(1:2)=tmp1*[-1 1]; axis(aa);
end;

