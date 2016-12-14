function []=diags_grid(dirModel,doInteractive);
%object :      load grid to mygrid if needed
%input :       dirModel is the model output directory
%              doInteractive=1 allows users to specify parameters interactively
%                whereas doInteractive=0 tries to specify them automatically

%global variables
gcmfaces_global;
global myparms;

if ~isfield(myparms,'dirGrid');

if isempty(dir('GRID'))&isempty(dir('nctiles_grid'))&...
   isempty(dir([dirModel filesep 'GRID']))&...
   isempty(dir([dirModel filesep 'nctiles_grid']));
    dirGrid=input('grid directory?\n');
    fprintf('\nFor the ECCO v4 LLC90 grid, the following parameters\n');
    fprintf('apply: nF=5; frmt=''compact''; memoryLimit=0; \n\n');
    nF=input('Number of faces? (nF=1, 4, 5 or 6)\n');
    frmt=input('File format? (frmt=''straight'', ''cube'' or ''compact'')\n');
    memoryLimit=input('memoryLimit? (0=load full grid, 1=less, 2=even less)\n');
elseif ~isempty(dir('GRID'));
    dirGrid=['GRID' filesep];
    nF=5;
    frmt='compact';
    memoryLimit=0;
elseif ~isempty(dir('nctiles_grid'));
    dirGrid=['nctiles_grid' filesep];
    nF=5;
    frmt='nctiles';
    memoryLimit=0;
elseif ~isempty(dir([dirModel filesep 'GRID']));
    dirGrid=[dirModel filesep 'GRID' filesep];
    nF=5;
    frmt='compact';
    memoryLimit=0;
elseif ~isempty(dir([dirModel filesep 'nctiles_grid']));
    dirGrid=[dirModel filesep 'nctiles_grid' filesep];
    nF=5;
    frmt='nctiles';
    memoryLimit=0;
end;

if doInteractive;
    nF=input('number of faces? (1, 4, 5or 6)\n'); 
    frmt=input('file format ? (''straight'', ''cube'' or ''compact'')\n');
    memoryLimit=input('memoryLimit ? (0=load full grid, 1=load less, 2=load even less)\n');
end;

myparms.dirGrid=dirGrid; myparms.nF=nF;
myparms.frmt=frmt; myparms.memoryLimit=memoryLimit;

end;%if ~isfield(myparms,'dirGrid');

%load mygrid if needed
test1=isfield(mygrid,'dirGrid');
if test1; 
  test1=strcmp(mygrid.dirGrid,myparms.dirGrid);
end;
if ~test1; 
  fprintf([' diags_grid.m now loading mygrid \n']);
  grid_load(myparms.dirGrid,myparms.nF,myparms.frmt,myparms.memoryLimit);
end;

%add definition of zonal and transport lines to mygrid
if ~isfield(mygrid,'LATS_MASKS');
  fprintf([' diags_grid.m now defining zonal lines\n']);
  gcmfaces_lines_zonal;
end;
if ~isfield(mygrid,'LINES_MASKS');
  fprintf([' diags_grid.m now defining transport lines\n']);
  [lonPairs,latPairs,names]=gcmfaces_lines_pairs;
  gcmfaces_lines_transp(lonPairs,latPairs,names);
end;


