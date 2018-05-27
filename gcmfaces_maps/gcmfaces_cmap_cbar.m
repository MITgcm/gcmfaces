function [myColorbar]=gcmfaces_cmap_cbar(vecLimCol,varargin);
%object :   non linear colormap + colorbar
%inputs :   vecLimCol, vector of color intervals
%optional:  optional paramaters take the following form {'name',param1,param2,...}
%           the two that are currently active are
%               {'myCmap',myCmap} is the colormap name ('jet' by default)
%               {'myBW',myBW} put white/black at colorbar edges/center (0 by default)
%output : 	myColorbar, the colorbar handle
%
%notes:     - myBW==0 does nothing; myBW~=0 modifies the colormap as follows
%               myBW==1;     blanks the center of colorscale
%               myBW==2;     blacks the low&high ends and blanks the middle 
%               myBW==-1;    blanks the low end
%               myBW==-2;    blacks the low end and blanks the high end
%           - to remove a resulting colorbar, type delete(myColorbar);
%           - since this routine regenerates the colormap according to 
%           vecLimCol and there can be only one colormap per figure, you 
%           dont want to change vecLimCol from one subplot to the next.
%           - the colorbar position is hard coded (for now) as 'to the right
%           of the parent axis'. You can change it via the myColorbar handle.
%           - the colormap density is hard coded (for now). It may need to 
%           be increased if you specify a very non-linear colormap such as
%           [[0:0.5:4] [5:10] [20 30 50 100 500]]; spanning 3 orders of magnitue

if isempty(vecLimCol); myColorbar=colorbar; return; end;

%set optional paramaters to default values
myCmap='jet'; myBW=0;
%set more optional paramaters to user defined values
for ii=1:nargin-1;
    if ~iscell(varargin{ii});
        warning('inputCheck:gcmfaces_cmap_cbar_1',...
            ['As of june 2011, gcmfaces_cmap_cbar expects \n'...
            '         its optional parameters as cell arrays. \n'...
            '         Argument no. ' num2str(ii+1) ' was ignored \n'...
            '         Type ''help gcmfaces_cmap_cbar'' for details.']);
    elseif ~ischar(varargin{ii}{1});
        warning('inputCheck:gcmfaces_cmap_cbar_2',...
            ['As of june 2011, gcmfaces_cmap_cbar expects \n'...
            '         its optional parameters cell arrays \n'...
            '         to start with character string. \n'...
            '         Argument no. ' num2str(ii+1) ' was ignored \n'...
            '         Type ''help gcmfaces_cmap_cbar'' for details.']);
    else;
        if strcmp(varargin{ii}{1},'myCmap')|...
                strcmp(varargin{ii}{1},'myBW');
            eval([varargin{ii}{1} '=varargin{ii}{2};']);
        else;
            warning('inputCheck:gcmfaces_cmap_cbar_3',...
                ['unknown option ''' varargin{ii}{1} ''' was ignored']);
        end;
    end;
end;

%white/black at colorbar edges/center?
if strcmp(myCmap,'jetBW1'); myCmap='jet'; myBW=1; end;
if strcmp(myCmap,'jetBW2'); myCmap='jet'; myBW=2; end;

%flip colormap direction?
flipCmap=0;
if ~isempty(strfind(myCmap,'FLIP')); flipCmap=1; myCmap=myCmap(5:end); end;

%need to revert to known colormap?
test1=isempty(which(myCmap));
if test1; 
    warning(['Colormap ' myCmap ' not found => reverting to jet.']); 
    myCmap='jet';
end;

%vecLimCol must be strickly increasing :
tmp1=vecLimCol(2:end)-vecLimCol(1:end-1);
if ~isempty(find(tmp1<=0)); 
    error('Non-increasing sequence in vecLimCol');
end;

%original colormap precision :
%nb_colors=64*3;
tmp1=min(vecLimCol(2:end)-vecLimCol(1:end-1));
tmp2=vecLimCol(end)-vecLimCol(1);
tmp3=ceil(tmp2/tmp1/64);
nb_colors=64*10*tmp3;
%nb_colors=64*500*tmp3;

%colormap and caxis :
eval(['tmp_map=colormap(' myCmap  '(nb_colors));']);
if flipCmap; tmp_map=flipdim(tmp_map,1); end;
tmp_val=[vecLimCol(1) vecLimCol(end)];
tmp_val=[tmp_val(1) : (tmp_val(2)-tmp_val(1))/(nb_colors-1) : tmp_val(2)];
caxis([tmp_val(1) tmp_val(end)]);

%subset of colours :
tmp_colors=round( [1:length(vecLimCol)-1] * nb_colors/(length(vecLimCol)-1) );
tmp_colors(1)=1; tmp_colors(end)=nb_colors;
tmp_colors=tmp_map(tmp_colors,:);

%final colormap :
tmp_map2=tmp_map;
for kkk=1:nb_colors
    tmp1=min(find(vecLimCol>=tmp_val(kkk)));
    if isempty(tmp1)
        tmp_map2(kkk,:)=tmp_colors(end,:);
    elseif tmp1==1
        tmp_map2(kkk,:)=tmp_colors(1,:);
    elseif tmp1==length(vecLimCol)
        tmp_map2(kkk,:)=tmp_colors(end,:);
    else
        tmp_map2(kkk,:)=tmp_colors(tmp1-1,:);
    end
end

%to blank the center of colorscale:
if myBW==1;
    tmp1=tmp_map2(floor(length(tmp_map2)/2),:);
    tmp2=find(sum(abs(tmp_map2-ones(length(tmp_map2),1)*tmp1),2)==0);
    tmp_map2(tmp2,:)=1;
end;

%to black the lowest/highest range and blank the middle range:
%=> if problem with colormap==gray ...
if myBW==2;
    tmp1=tmp_map2(1,:);
    tmp2=find(sum(abs(tmp_map2-ones(length(tmp_map2),1)*tmp1),2)==0);
    tmp1=tmp_map2(end,:);
    tmp3=find(sum(abs(tmp_map2-ones(length(tmp_map2),1)*tmp1),2)==0);
    tmp_map2(tmp2,:)=0;
    tmp_map2(tmp3,:)=0;
    tmp1=tmp_map2(floor(length(tmp_map2)/2),:);
    tmp2=find(sum(abs(tmp_map2-ones(length(tmp_map2),1)*tmp1),2)==0);
    tmp_map2(tmp2,:)=1;
end;

%to blank the lowest range:
if myBW==-1;
    tmp1=tmp_map2(1,:);
    tmp2=find(sum(abs(tmp_map2-ones(length(tmp_map2),1)*tmp1),2)==0);
    tmp_map2(tmp2,:)=1;
end;

%to black the lowest range and blank the highest range:
%=> if problem with colormap==gray ...
if myBW==-2;
    tmp1=tmp_map2(1,:);
    tmp2=find(sum(abs(tmp_map2-ones(length(tmp_map2),1)*tmp1),2)==0);
    tmp1=tmp_map2(end,:);
    tmp3=find(sum(abs(tmp_map2-ones(length(tmp_map2),1)*tmp1),2)==0);
    tmp_map2(tmp2,:)=0;
    tmp_map2(tmp3,:)=1;
end;

%set colormap
colormap(tmp_map2);

%axes for colorbar:
aaa=gca;
tmp1=get(aaa,'Position'); tmp1=[sum(tmp1([1 3]))+0.01 tmp1(2) 0.02 tmp1(4)];
myColorbar=axes('position',tmp1);
set(myColorbar,'Position',tmp1);%to account for m_map

tmp1=get(myColorbar,'Position');
if tmp1(1)>=0.9150; 
 tmp1(1)=tmp1(1)-0.04; 
 set(myColorbar,'Position',tmp1);
 tmp1=get(aaa,'Position');
 tmp1(1)=tmp1(1)-0.04;
 set(aaa,'Position',tmp1);
 axes(myColorbar);
end;

%colobar itself:
tmp1=[1:2]'*ones(1,length(vecLimCol));
tmp2=[1:length(vecLimCol)]; tmp2=[tmp2;tmp2];
tmp3=[0.5*( vecLimCol(2:end)+vecLimCol(1:end-1) ) vecLimCol(end)]; tmp3=[tmp3;tmp3];

pcolor(tmp1,tmp2,tmp3); caxis([vecLimCol(1) vecLimCol(end)]);
set(myColorbar,'YAxisLocation','right');
set(myColorbar,'XTick',[]);
set(myColorbar,'YTick',[1:length(vecLimCol)]);

%labels:
%-------

tmp2=''; for kcur=1:length(vecLimCol); tmp2=strvcat(tmp2,sprintf('%6.6g',vecLimCol(kcur))); end;
tmp2(1,:)=' '; %do not display the first value
tmp2(end,:)=' '; %do not display the last value

set(myColorbar,'YTickLabel',tmp2);

%add tag spec. to colorbar generated with this routine
set(myColorbar,'Tag','gfCbar');

axes(aaa);


