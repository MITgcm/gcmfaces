function [myMean,myAnom]=annualmean(myTimes,myFld,myYear);
%object: compute an annual mean for myYear (= 'first','last',n (int) or 'all')
%        of a gcmfaces or array object (myFld) provided at myTimes (in years)
%input:  myTimes,myFld,myYear
%output: myMean if the corresponding time mean
%       (optional: myAnom is myFld-myMean)
%
%algorithm :
%  - determine the number of records in one year (lYear)
%  - determine the number of full years (nYears)
%  - prepare list of records to average (depending on myYear, lYear and nYears)
%  - in case when lYear<2 we use records as years
%
%by assumption:
%  - the time dimension is last in myFld, and matches the length of myTimes

%determine the number of records in one year (lYear)
tmp1=mean(myTimes(2:end)-myTimes(1:end-1));
lYear=round(1/tmp1);

%in case when lYear<2 we use records as years
if ~(lYear>=2); lYear=1; myTimes=[1:length(myTimes)]; end;

%determine the number of full years (nYears)
nYears=floor(length(myTimes)/lYear);

%determine records that correspond to myYear, which
%  may be 'first','last',n (an integer) or 'all'
if ischar(myYear);
    if strcmp(myYear,'first');
        recInAve=[1:lYear];
    elseif strcmp(myYear,'last');
        recInAve=[1:lYear]+(nYears-1)*lYear;
    elseif strcmp(myYear,'all');
        recInAve=[1:nYears*lYear];
    else;
        error('inconsistent specification of myYear');
    end;
elseif (myYear>=1)&(myYear<=nYears);
    recInAve=[1:lYear]+(myYear-1)*lYear;
else;
    error('inconsistent specification of myYear');
end;
nRecs=length(recInAve);

%determine last dimension, which need to match the length myTimes
if strcmp(class(myFld),'gcmfaces'); nDim=size(myFld{1}); else; nDim=size(myFld); end;
if length(myTimes)>1;
    if nDim(end)~=length(myTimes);
        error('last dimension should match the length of myTimes');
    end;
    nDim=length(nDim); tt=''; for jj=1:nDim-1; tt=[tt ':,']; end;
else;
    nDim=length(nDim)+1; tt=''; for jj=1:nDim-1; tt=[tt ':,']; end;
end;

%compute time mean:
eval(['myMean=mean(myFld(' tt 'recInAve),nDim);']);

%compute anomaly:
if nargout>1;
    myAnom=myFld-repmat(myMean,[ones(1:nDim-1) length(myTimes)]);
end;

