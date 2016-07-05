function [msgOut]=gcmfaces_msg(msgIn,headerOut,widthOut);
%object:    print formatted message to screen
%input:     msgIn is a char or a cell array of char
%optional:  headerOut is the header(default: no header if  
%               myenv.verbose<2; calling tree if myenv.verbose>=2)
%           widthOut is the line width (75 by default)
%output:    msgOut is a char where line breaks were set
%               so that all lines have approx. the same width.
%note: could also introduce form feeds (page break for print) or

%test case:
% msgIn={'xxxx \ryy\tzz\n' ['1 ' char(9) '2' char(10) '3' char(11) '4' char(12) '5']}
% widthOut=3;
% gcmfaces_msg(msgIn,widthOut);

gcmfaces_global;
if isempty(who('headerOut'))&myenv.verbose<2;
    headerOut='';
elseif isempty(who('headerOut'))&myenv.verbose>=2;
    %pause before each event
    if myenv.verbose>=3; fprintf('\n > hit return to continue <\n'); pause; end;
    %
    [ST,I]=dbstack;
    headerOut={'gcmfaces message from '};
    
    if isempty(ST);
        headerOut={headerOut{:} 'main workspace'};
    else;
        for ii=length(ST):-1:2;
            tmp1=[char(45)*ones(1,length(ST)-ii+1)];
            headerOut={headerOut{:} [tmp1 ST(ii).name ' at line ' num2str(ST(ii).line)]};
        end;
    end;
    
    m=0; for ii=1:length(headerOut); m=max(m,length(headerOut{ii})); end;
    tmpOut=45*ones(1,m+2);
    for ii=1:length(headerOut);
        n=length(headerOut{ii});
        tmpOut=[tmpOut char(10) '|' headerOut{ii} 32*ones(1,m-n) '|'];
    end;
    tmpOut=[tmpOut char(10) 45*ones(1,m+2) char(10)];
    
    headerOut=tmpOut;
end;

if isempty(who('widthOut')); widthOut=75; end;

%step 1: reformat msgIn to one char line, if needed
%=======

%1.1) make cell array
if ischar(msgIn)&size(msgIn,2)>1;
    nLinesIn=size(msgIn,1); tmpIn={};
    for ii=1:nLinesIn; tmpIn{ii}=msgIn(ii,:); end;
    msgIn=tmpIn;
end;
if iscell(msgIn)&size(msgIn,2)>1; msgIn=msgIn'; end;

%2.2) cat to one char line
msgIn=strcat(cell2mat(msgIn'));

%step 2: deformat text -- rm/replace control characters from caller
%=======

%2.1) matlab control characters
ii=strfind(msgIn,'\n'); for jj=ii; msgIn=[msgIn(1:jj-1) ' ' msgIn(jj+2:end)]; end;
ii=strfind(msgIn,'\r'); for jj=ii; msgIn=[msgIn(1:jj-1) ' ' msgIn(jj+2:end)]; end;
ii=strfind(msgIn,'\t'); for jj=ii; msgIn=[msgIn(1:jj-1) ' ' msgIn(jj+2:end)]; end;
ii=strfind(msgIn,'\b'); for jj=ii; msgIn=[msgIn(1:jj-1) ' ' msgIn(jj+2:end)]; end;
ii=strfind(msgIn,'\f'); for jj=ii; msgIn=[msgIn(1:jj-1) ' ' msgIn(jj+2:end)]; end;

%2.2) ANSI C control characters
tmp1=msgIn; tmp2=double(tmp1);
%substitute some with a space
jj=find(tmp2>8&tmp2<13); tmp1(jj)=32;
%remove the others
jj=find(tmp2>=32); tmp1=tmp1(jj);
msgIn=char(tmp1);

%2.3) double spaces
ii=strfind(msgIn,'  ');
while ~isempty(ii);
    jj=ii(1);
    msgIn=[msgIn(1:jj-1) ' ' msgIn(jj+2:end)];
    ii=strfind(msgIn,'  ');
end;

%step 3: reformat text -- according to to gcmfaces_msg standards
%=======

ii=strfind(msgIn,' ');
if isempty(ii); ii=[ii length(msgIn)+1]; end;
if ii(end)~=length(msgIn); ii=[ii length(msgIn)+1]; end;
if ii(1)~=1; ii=[0 ii]; end;

msgOut=headerOut;
nn=0;
for jj=1:length(ii)-1;
    kk=[ii(jj)+1 :ii(jj+1)-1];
    tmp1=msgIn(kk);
    if nn+length(tmp1)+1<=widthOut;
        msgOut=[msgOut tmp1 ' '];
        nn=nn+length(tmp1)+1;
    else;
        msgOut=[msgOut char(10)];
        nn=0;
        msgOut=[msgOut '  ' tmp1 ' '];%start new line with two spaces
        nn=nn+length(tmp1)+1;
    end;
end;
msgOut=[msgOut char(10)];
nn=0;

%step 4: print to screen
%=======
fprintf(msgOut);

