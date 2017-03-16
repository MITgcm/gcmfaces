function []=gcmfaces_demo();
% GCMFACES_DEMO demonstrate capabilities of the gcmfaces toolbox.
%
%expected directory structure:
%
%  gcmfaces     (codes)
%  MITprof      (codes)
%  nctiles_grid (ECCO v4 grid)
%  release1     (ECCO v4 output)
%  sample_input (additional demo material)
%
%the ECCO v4 grid can be obtained as follows:
%
%  wget --recursive ftp://mit.ecco-group.org/ecco_for_las/version_4/release1/nctiles_grid 
%  mv mit.ecco-group.org/ecco_for_las/version_4/release1/nctiles_grid . 
%  rm -rf mit.ecco-group.org
%
%to activate example_transports:
%
%  mkdir release1
%  wget --recursive ftp://mit.ecco-group.org/ecco_for_las/version_4/release1/nctiles_climatology
%  mv mit.ecco-group.org/ecco_for_las/version_4/release1/nctiles_climatology release1/.
%  rm -rf mit.ecco-group.org
%
%to activate example_MITprof:
%
%  mkdir release2_climatology
%  wget --recursive ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/nctiles_climatology
%  mv mit.ecco-group.org/ecco_for_las/version_4/release1/nctiles_climatology release2_climatology/.
%  wget --recursive ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/profiles
%  mv mit.ecco-group.org/ecco_for_las/version_4/release1/profiles release2_climatology/.
%  rm -rf mit.ecco-group.org
%
%to activate example_budget:
%
%  mkdir sample_input
%  wget --recursive ftp://mit.ecco-group.org/gforget/nctiles_budget_2d
%  mv mit.ecco-group.org/gforget/nctiles_budget_2d sample_input/.
%  rm -rf mit.ecco-group.org
%
% call sequence:
%  addpath gcmfaces;
%  addpath MITprof;
%  gcmfaces_demo;

%choose verbose level
fprintf('\n Please set the amount of explanatory text display :\n');
fprintf('    0: none.\n');
fprintf('    1: comments.\n');
fprintf('    2: comments preceeded with calling sequence.\n');
fprintf('    3: same as 2, but preceeded with pause.\n');
verbose=input(' and/or type return. 0 is the default. \n');
if isempty(verbose); verbose=0; end;

fprintf('\n');

%so that gcmfaces_msg will work even before calling gcmfaces_global:
tmp1=which('gcmfaces_demo');
[PATH,NAME,EXT] = fileparts(tmp1);
addpath([PATH filesep 'gcmfaces_misc' filesep]); 
global myenv; 
myenv.issueWarnings=0;%skip warnings
myenv.verbose=verbose;%apply verbose level selected by user
%
fprintf('\n\n');
gcmfaces_msg('/////////////////////////////////////');
gcmfaces_msg('demo of gcmfaces_global and MITprof_global','// PART 0 :');
gcmfaces_msg('/////////////////////////////////////');
if myenv.verbose>0; gcmfaces_msg('please hit return','// >> '); pause; end;
fprintf('\n\n');
if myenv.verbose>0;
    gcmfaces_msg(['* gcmfaces_global: adds gcmfaces directories to path' ...
                 ' and define environment variables (see myenv)']);
end;
myenv=[];
gcmfaces_global;%this will display warning
myenv.issueWarnings=0;%skip warnings
myenv.verbose=verbose;%apply verbose level selected by user
if myenv.verbose>0;
    gcmfaces_msg('* (this warning gets resolved below by calling grid_load)');
end;

%if ~isempty(which('MITprof_global'));
%    MITprof_global;
%    if myenv.verbose>0;
%        gcmfaces_msg('* MITprof_global: adds MITprof directories to path');
%    end;
%end;

fprintf('\n\n');
gcmfaces_msg('/////////////////////////////////////');
gcmfaces_msg('demo of grid_load','// PART 1 :');
gcmfaces_msg('/////////////////////////////////////');
if myenv.verbose>0; gcmfaces_msg('please hit return','// >> '); pause; end;
fprintf('\n\n');
grid_load;

fprintf('\n\n');
gcmfaces_msg('/////////////////////////////////////');
gcmfaces_msg('demo of plotting routines','// PART 1 :');
gcmfaces_msg('/////////////////////////////////////');
if myenv.verbose>0; gcmfaces_msg('please hit return','// >> '); pause; end;
fprintf('\n\n');
example_display;

fprintf('\n\n');
gcmfaces_msg('///////////////////////////////////////////');
gcmfaces_msg('demo of interpolation and remapping ','// PART 2 :');
gcmfaces_msg('///////////////////////////////////////////');
if myenv.verbose>0; gcmfaces_msg('please hit return','// >> '); pause; end;
fprintf('\n\n');
example_interp;

fprintf('\n\n');
gcmfaces_msg('///////////////////////////////////////////');
gcmfaces_msg('demo of bin averaging data sample to grid','// PART 2 :');
gcmfaces_msg('///////////////////////////////////////////');
if myenv.verbose>0; gcmfaces_msg('please hit return','// >> '); pause; end;
fprintf('\n\n');
fld=example_bin_average;

fprintf('\n\n');
gcmfaces_msg('///////////////////////////////////////////');
gcmfaces_msg('demo of smoothing through diffusion','// PART 2 :');
gcmfaces_msg('///////////////////////////////////////////');
if myenv.verbose>0; gcmfaces_msg('please hit return','// >> '); pause; end;
fprintf('\n\n');
example_smooth(fld);

fprintf('\n\n');
gcmfaces_msg('/////////////////////////////////////////');
gcmfaces_msg('demo of transport computations','// PART 3 :');
gcmfaces_msg('/////////////////////////////////////////');
if myenv.verbose>0; gcmfaces_msg('please hit return','// >> '); pause; end;
fprintf('\n\n');
diags=example_transports;

if ~isempty(diags);
    fprintf('\n\n');
    gcmfaces_msg('/////////////////////////////////////////');
    gcmfaces_msg('demo of transport display','// PART 3 :');
    gcmfaces_msg('/////////////////////////////////////////');
    if myenv.verbose>0; gcmfaces_msg('please hit return','// >> '); pause; end;
    fprintf('\n\n');
    example_transports_disp(diags);
end;

fprintf('\n\n');
gcmfaces_msg('/////////////////////////////////////////');
gcmfaces_msg('demo of budget computations','// PART 4 :');
gcmfaces_msg('/////////////////////////////////////////');
if myenv.verbose>0; gcmfaces_msg('please hit return','// >> '); pause; end;
fprintf('\n\n');
example_budget;

