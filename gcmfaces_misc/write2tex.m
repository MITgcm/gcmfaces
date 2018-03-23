function []=write2tex(myFile,myStep,varargin);
%object:	create/increment/complete/compile a tex file from within matlab
%input:		myFile is the file name
%		myStep is the operation to perform on the tex file
%			0   create file starting with title page (see myText)
%         		1   add section or subsection (see myLev)
%			2   add a figure plus caption (see myFig)
%			3   add a paragraph
%			4   finish file
%                       5   compile (latex x 2 then dvipdf)
%			6   remove temporary files (incl. *fig*.ps)
%optional	myText is a cell array of text lines (for myStep=1 to 2)
%		myLev is the title level (for myStep=1)
%			1=section, 2=subsection (not yet implemented)
%		myFig is a figure handle (for myStep=2)

gcmfaces_global;

if isempty(myFile)&&myStep==2;
    myText=varargin{1};
    myText=[myText{:}];
    gcmfaces_caption(myText);
    return;
elseif isempty(myFile);
    %if no file name, then do nothing
    return; 
end;
if iscell(myFile);
    %extecute alternative command (myFile{1}) passing rest as arguments  
    eval([myFile{1} '(myFile{2:end});']); 
    return; 
end;


myText=[]; myLev=[]; myFig=[]; myRdm=[];
if myStep<4; myText=varargin{1}; end;
if myStep==0; myRdm=varargin{2};
elseif myStep==1; myLev=varargin{2};
elseif myStep==2; myFig=varargin{2};
end;

%format use for printing out plots :
frmt='eps';
if ispc; frmt='jpg'; end;

%create file starting with write2tex.header
if myStep==0;
    test0=dir(myFile);
    if ~isempty(test0);
        test0=input(['you are about to overwrite ' myFile ' !!! \n   type 1 to proceed, 0 to stop \n']);
    else;
        test0=1;
    end;
    if ~test0;
        return;
    else;
	fid=fopen(myFile,'w');

	fprintf(fid,'\\documentclass[12pt]{beamer}\n');
	fprintf(fid,'%%a nice series of examples for the beamer class:\n');
	fprintf(fid,'%%http://www.informatik.uni-freiburg.de/~frank/ENG/beamer/example/beamer-class-example-en-5.html\n');
        fprintf(fid,'\\usepackage{multicol}\n');

        fprintf(fid,'\n');
        fprintf(fid,'\\newcommand\\Fontvi{\\fontsize{6}{7.2}\\selectfont}\n');
        fprintf(fid,'\n');

	fprintf(fid,'\\begin{document} \n\n');

        fprintf(fid,'\\title{\n');
	for ii=1:length(myText); fprintf(fid,[myText{ii} '\\\\ \n']); end;
        fprintf(fid,'}\n\n');
        fprintf(fid,'\\date{\\today}\n\n');
        fprintf(fid,'\\frame{\\titlepage}\n\n');

	fprintf(fid,'\\frame{\n');
	fprintf(fid,'\\frametitle{Table of contents}\n');
        fprintf(fid,'\\begin{multicols}{2}\n');
        fprintf(fid,'\\Fontvi\n');
	fprintf(fid,'\\tableofcontents\n');
        fprintf(fid,'\\end{multicols}\n');
	fprintf(fid,'} \n\n');

        if ~isempty(myRdm);
          fprintf(fid,'\\frame{\n');
          fprintf(fid,'\\section{README}\n');
          fprintf(fid,'\\Fontvi\n');
          for pp=1:length(myRdm);
            fprintf(fid,[myRdm{pp} '\n\n']);
          end;
          fprintf(fid,'} \n\n');
        end;

	fclose(fid);
    end;
    myFigNumTex=0;
    mySection='';
    eval(['save ' myFile(1:end-4) '.mat myFigNumTex mySection;']);
end;

%open file and go to last line
fid=fopen(myFile,'a+');
eval(['load ' myFile(1:end-4) '.mat;']);

%add title or section page (see myLev)
if myStep==1;
    mySection=myText;
    if myLev==1; fprintf(fid,'\\section{\n');
    else; fprintf(fid,'\\subsection{\n');
    end;
    fprintf(fid,mySection);
    fprintf(fid,'} \n\n');
end;

%add a figure plus caption (see myFig)
if myStep==2;
    figure(myFig);
    drawnow;
    %add (but hide) caption directly in figure
    captionHandle=gcmfaces_caption([myText{:}]);
    set(captionHandle,'Visible','off');
    set(get(captionHandle,'Children'),'Visible','off');
    %set file names
    myFigNumTex=myFigNumTex+1;
    [dirTex,fileTex,EXT] = fileparts(myFile);
    %print figure
    if strcmp(frmt,'eps');
      print(myFig,'-depsc',[dirTex fileTex '_fig' num2str(myFigNumTex) '.eps']);
    elseif strcmp(frmt,'jpg');
      print(myFig,'-djpeg90',[dirTex fileTex '_fig' num2str(myFigNumTex) '.jpg']);
    elseif strcmp(frmt,'png');
      print(myFig,'-dpng',[dirTex fileTex '_fig' num2str(myFigNumTex) '.png']);
    end
    %save figure (with visible caption)
    set(captionHandle,'Visible','on');
    set(get(captionHandle,'Children'),'Visible','on');
    if ~myenv.usingOctave; saveas(myFig,[dirTex fileTex '_fig' num2str(myFigNumTex)],'fig'); end;
    %close figure
    close;
    %add figure to text file
    fprintf(fid,'\\frame{ \n');
    fprintf(fid,['\\frametitle{' mySection '} \n']);
    fprintf(fid,'\\begin{figure}[tbh] \\centering \n');
%     fprintf(fid,'\\includegraphics[width=\\textwidth,height=0.9\\textheight]');
    fprintf(fid,'\\includegraphics[width=0.75\\textwidth]');
    fprintf(fid,['{' fileTex '_fig' num2str(myFigNumTex) '.' frmt '}\n']);
    fprintf(fid,'\\caption{');
    for ii=1:length(myText); fprintf(fid,[myText{ii} '\n']); end;
    fprintf(fid,'} \\end{figure} \n');
    fprintf(fid,'} \n\n');
end;

%add a paragraph
if myStep==3;
    for ii=1:length(myText);
        fprintf(fid,[myText{ii} '\n']);
    end;
end;

%finish file
if myStep==4; fprintf(fid,'\n\n \\end{document} \n\n'); end;

%close file
fprintf(fid,'\n\n');
fclose(fid);
eval(['save ' myFile(1:end-4) '.mat myFigNumTex mySection;']);

%compile
if myStep==5;
    fprintf('\nNow we can attempt to compile the tex file from within Matlab. \n');
    fprintf('If the latex implementation is incomplete then this may fail, and \n');
    fprintf('user should then abort and compile the tex file from outside Matlab. \n');
    fprintf('The beamer class is required by in particular. In Matlab, if prompted \n');
    fprintf(' with a question mark then typing ''quit'' will abort compilation. \n');
    test0=input('\n type 1 to proceed or 0 to skip this attempt\n');
    if test0;
      dirOrig=pwd;
      [PATHSTR,fileTex,EXT] = fileparts(myFile);
      cd(PATHSTR);
      system(['latex ' fileTex]);
      system(['latex ' fileTex]);
      system(['dvipdf ' fileTex]);
      cd(dirOrig);
    end;
end;


%compile
if myStep==6&&ispc;
    fprintf('warning : compiling tex to pdf is bypassed on PCs\n');
end;

if myStep==6&&~ispc;
    dirOrig=pwd;
    nn=strfind(myFile,filesep);
    if ~isempty(nn);
        cd(myFile(1:nn(end))); fileTex=myFile(nn(end)+1:end-4);
    else;
        fileTex=myFile(1:end-4);
    end;
    delete([fileTex '_fig*']);
    delete([fileTex '.aux']);
    delete([fileTex '.log']);
    delete([fileTex '.out']);
    delete([fileTex '.dvi']);
    cd(dirOrig);
end;
