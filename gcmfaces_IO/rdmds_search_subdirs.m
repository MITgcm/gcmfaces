function [subDir]=rdmds_search_subdirs(dirDiags,fileDiags);
% [subDir]=rdmds_search_subdirs(dirDiags,fileDiags);
%  searches for fileDiags within the subdirectories of dirDiags
%  and returns the result (subDir). If fileDiags is not found
%  then subDir is left empty. If fileDiags if found in several
%  subdirectories the rdmds_search_subdirs returns an error message.

   listDirs=dir(dirDiags);
   jj=find([listDirs(:).isdir]&[~strcmp({listDirs(:).name},'.')]&[~strcmp({listDirs(:).name},'..')]);
   listDirs=listDirs(jj);

   if ~isempty(dir([dirDiags fileDiags '*.data']));
     subDir='./';
   else;
     subDir='';
   end;
   
   alldirs = {};
   
   for ff=1:length(listDirs);
       tmp1=dir([dirDiags listDirs(ff).name '/' fileDiags '.*.data']);
       if ~isempty(tmp1)&isempty(subDir); subDir=[listDirs(ff).name '/']; alldirs = [alldirs {listDirs(ff).name}];
       elseif ~isempty(tmp1);
           alldirs = [alldirs {listDirs(ff).name}];
       end;
   end;
   
   if length(alldirs) > 1
       warning('fileDiags were found in multiple different locations. Selecting first location:');
       disp(['Selecting ' subDir ' of:' char(10) strjoin(alldirs,',')])
   end

