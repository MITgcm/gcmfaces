function []=diags_grid(dirModel,doInteractive);
%object :      load grid to mygrid if needed
%input :       dirModel is the model output directory
%              doInteractive=1 allows users to specify parameters interactively
%                whereas doInteractive=0 tries to specify them automatically

%global variables
gcmfaces_global;
global myparms;

if ~isfield(myparms,'dirGrid');

if doInteractive|(isempty(dir('GRID'))&isempty(dir('nctiles_grid'))&...
   isempty(dir([dirModel filesep 'GRID']))&...
   isempty(dir([dirModel filesep 'nctiles_grid'])));

    fprintf('\n');
    gcmfaces_msg('Please specify grid information.','=== ');
    fprintf('\n');

    dirGrid=input(' Step 1: specify grid directory (e.g. ''./'' with quotes).\n');
    fprintf('\n Step 2: specify parameters for grid_load.m; \n');
    fprintf('    e.g. nF=5; frmt=''nctiles''; memoryLimit=0; \n');
    fprintf('    for the ECCO v4 LLC90 grid provided by ECCO.\n');
    nF=input(' Specify the number of faces by typing 1, 4, 5 or 6\n');
    frmt=input(' Specify the file format by typing ''nctiles'', ''straight'', ''cube'' or ''compact''\n');
    memoryLimit=input(' Specify degree of memory limitation (type 0 -- or increase if issue occurs)\n');
    fprintf('\n');
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

myparms.dirGrid=dirGrid; myparms.nF=nF;
myparms.frmt=frmt; myparms.memoryLimit=memoryLimit;

end;%if ~isfield(myparms,'dirGrid');

%load mygrid if needed
test1=isfield(mygrid,'dirGrid');
if test1; 
  test1=strcmp(mygrid.dirGrid,myparms.dirGrid);
end;
if ~test1; 
  fprintf('\n'); gcmfaces_msg('Now loading grid to mygrid ...','=== ');
  grid_load(myparms.dirGrid,myparms.nF,myparms.frmt,myparms.memoryLimit);
end;

%add definition of zonal and transport lines to mygrid
if ~isfield(mygrid,'LATS_MASKS');
  fprintf('\n'); gcmfaces_msg('Now defining zonal lines ...','=== ');
  gcmfaces_lines_zonal;
end;
if ~isfield(mygrid,'LINES_MASKS');
  fprintf('\n'); gcmfaces_msg('Now defining transport lines ...','=== ');
  [lonPairs,latPairs,names]=gcmfaces_lines_pairs;
  gcmfaces_lines_transp(lonPairs,latPairs,names);
end;


