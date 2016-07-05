function [msk]=gcmfaces_close_basin(basinEdge,landMsk,doLargerBasin);
%object : compute closed basin mask from a specificed edge and a "land" mask
%         By design basinEdge is required to split the global ocean into two and 
%         only two basins. Successive calls allow for numerous basin definitions.
%
%input :  - basinEdge is an index (standard cases; defined by great circle arcs
%           between pairs of locations; see below) or a 2D map (interactive case)
%           - test cases : basinEdge = 0 to -3 (included hereafter)
%           - user cases : basinEdge > 0 (for user to add hereafter)
%           - interactive case : basinEdge is a 2D map of 1s and NaNs 
%             where NaNs delineate the "wet" egde of the basin.
%         - landMsk is the "land" mask (1s & NaNs; mygrid.mskC(:,:,1) default)
%           basinEdge values where landMsk is NaN are of no consequence. 
%         - doLargerBasin is 0 (default) or 1. If set to 1 then output 
%           larger basin mask, otherwise output smaller basin mask. The ocean 
%           edge points are always counted as part of the output basin mask. 
%
%output : msk is the closed basin mask, with 1s over the basin of interest, 
%         0s over the rest of the ocean, and NaNs consistent with landMsk.
%
%notes : - unless used in interactive mode the ocean basin edge is based on 
%          great circle arcs. That is usually perfectly adequate. The most 
%          notable exception is when one wants to delimit a basin by latitude lines, 
%          but those are easy to do in interactive mode. The NOT implemented general 
%          approach would use small circle arcs rather than great circle arcs.
%        - the test cases below demonstrate the algorithm using great circles (0), 
%          the algorithm error cases (-1, -2) and the limitation of great circles (-3)

gcmfaces_global;

if isempty(whos('basinEdge')); basinEdge=0; end;
if isempty(whos('landMsk')); landMsk=mygrid.mskC(:,:,1); end;
if isempty(whos('doLargerBasin')); doLargerBasin=0; end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%BEGINING OF EDGE DEFINITION%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isnumeric(basinEdge)&length(basinEdge(:))==1;
%standard cases: to be extended by user

if basinEdge==0;
lonPairs=[[  10   19];[  19   60];[  60  100];[ 100  110]];
latPairs=[[  60   80];[  80   81];[  81   80];[  80   60]];
%a case that matches v4_basin_one
elseif basinEdge==-1;
lonPairs=[[ -70   20];[  20  110];[ 110  200];[ 200  -70]];
latPairs=[[ -30  -30];[ -30  -30];[ -30  -30];[ -30  -30]];
%a case that fails because it delimits three basins
elseif basinEdge==-2;
lonPairs=[[ -70   20];[  20  145]];
latPairs=[[ -35  -35];[ -35  -35]];
%a case that fails because it does not close basins
elseif basinEdge==-3;
lonPairs=[[ -70   20];[  20  145];[ 145  -70]];
latPairs=[[ -35  -35];[ -35  -35];[ -35  -35]];
%a case that does not fail, but illustrates that long great 
%circle arcs are not always the most appopriate basin edges 
%(a line of constant latitude would be better in this case)
else;
error('unknown basin');
end;

%close basin:
msk=landMsk;
msk0=msk;
for iy=1:size(lonPairs,1);
    %define great circle line by end points:
    lonPair=lonPairs(iy,:);
    latPair=latPairs(iy,:);
    %get line:
    line_cur=gcmfaces_lines_transp(lonPair,latPair,{'tmp'});
    %close line:
    msk(line_cur.mskCedge==1)=NaN;
end;


else;
%interactive cases: based on field provided by user

msk=landMsk;
msk0=msk;
msk(isnan(basinEdge))=NaN;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%END OF EDGE DEFINITION%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%compute the closed basin labels for each grid face:
msk1=msk;
msk=1*~isnan(msk);
for iF=1:msk.nFaces; 
  msk{iF}=bwlabel(msk{iF},4); 
end;

%remove potential aliases / account for domain periodicity:
msk2=msk;
test0=1;%do at least one faces sweep
while test0;
   test0=0;%unless something changes in the upcoming sweep we will stop
   tmpmsk=exch_T_N(msk);
   %list aliases
   list0=[];
   for iF=1:msk.nFaces;
     for iS=1:4;
       tmp1=msk{iF};
       if iS==1;     tmp2=tmpmsk{iF}(1:end-2,2:end-1);
       elseif iS==2; tmp2=tmpmsk{iF}(3:end,2:end-1);
       elseif iS==3; tmp2=tmpmsk{iF}(2:end-1,1:end-2); 
       elseif iS==4; tmp2=tmpmsk{iF}(2:end-1,3:end); 
       end;
       tmp3=find( (tmp1~=tmp2)&(tmp1>0)&(tmp2~=0));
       %note : tmp1~=tmp2 is an alias if the two other conditions apply
       %note : "land" (label 0) is not an alias (tmp1>0&tmp2~=0 test)
       %note : basins cannot be relabeld multiple times (tmp1>0 test) but
       %       relabeld basins can be tested against (tmp2~=0 rather than tmp2>0)
       list0=[list0;[tmp1(tmp3) tmp2(tmp3) iF+0*tmp3]];
     end;
   end;
   %not needed : list0=unique(list0,'rows');
   if ~isempty(list0); 
     %start with previously relabeld basin if any (needed to avoid conflicts)
     ii=find(list0(:,2)==min(list0(:,2))); ii=ii(1);
     iF=list0(ii,3);
     list1=list0(ii,1:2);
     tmp1=msk{iF};
     %since we will have relabeld at least one basin in this 
     %faces sweep, then another faces sweep will be needed :
     test0=1;
     %apply unique negative label
     if list1(2)<0;
       %carry over unique label from previously relabeld basin
       tmp4=list1(2);
     else;
       %define new unique negative label
       tmp4=min(min(msk)-1,-1);
     end;
     tmp1(tmp1==list1(1))=tmp4;
     msk{iF}=tmp1;
   end;
end;

%final list should have 2 elements (1 per basin)
list2=convert2array(msk);
list2=unique(list2(:));
list2=list2(find(~isnan(list2)&list2~=0));
if length(list2)<2; msk=msk1; fprintf('failure : basin was not closed properly\n'); return; end;
if length(list2)>2; fprintf('failure : more than two basins\n'); return; end;

%attribute edge and prepare output:
tmp1=sum(mygrid.RAC.*(msk==list2(1)));
tmp2=sum(mygrid.RAC.*(msk==list2(2)));
if     doLargerBasin&tmp1>=tmp2; excl=list2(2);
elseif doLargerBasin           ; excl=list2(1);
elseif               tmp1<=tmp2; excl=list2(2);
else                           ; excl=list2(1);
end;
msk3=msk;
msk=(msk~=excl).*mygrid.mskC(:,:,1);


