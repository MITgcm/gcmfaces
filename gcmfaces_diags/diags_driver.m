function []=diags_driver(dirModel,dirMat,years,setDiags,doInteractive);
% DIAGS_DRIVER(dirModel,dirMat,years,setDiags,doInteractive);
%
%  computes estimation and physical diagnostics (setDiags) that 
%  can be included in the standard analysis from the data (for 
%  selected years) located in dirModel and stores the results 
%  in dirMat.
%
%notes: dirModel is the directory containing 'diags/' or 'nctiles/'
%       dirMat is [dirModel 'mat/'] by default
%       years may be set to a vector (e.g. [1992:2011]) or to
%          'climatology' when using a climatological year
%       setDiags is by default set to {'A','B','C','MLD'}
%       doInteractive=1 allows users to specify parameters interactively
%          whereas doInteractive = 0 (default) uses ECCO v4 parameters

gcmfaces_global; global myparms;

%%%%%%%%%%%%%%%
%pre-processing
%%%%%%%%%%%%%%%

if isempty(who('doInteractive')); doInteractive=0; end;
myswitch=diags_pre_process(dirModel,dirMat,doInteractive);
diags_grid(dirModel,doInteractive); %reload mygrid if needed

dirModel=[dirModel '/'];
if isempty(dirMat); dirMat=[dirModel 'mat/']; else; dirMat=[dirMat '/']; end;

%%%%%%%%%%%%%%%%%%%%
%set loop parameters
%%%%%%%%%%%%%%%%%%%%

if ischar(years);
  if strcmp(years,'climatology');
    years=myparms.yearFirst;
  else;
    error('unknown specification of years');
  end;
end;

years=years-myparms.yearFirst+1;
if myparms.diagsAreMonthly;
    years=years(years<=myparms.recInAve(2)/12);
    lChunk=12;
end;
if myparms.diagsAreAnnual;
    years=years(years<=myparms.recInAve(2));
    lChunk=1;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%now do the selected computation chunk:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(who('setDiags'));
  setDiags={'A','B','C','MLD'};
  if myswitch.doBudget; setDiags={setDiags{:},'D'}; end;
  if myswitch.doProfiles; setDiags={setDiags{:},'profiles'}; end;
  if myswitch.doCost; setDiags={setDiags{:},'ecco'}; end;
  if myswitch.doCtrl; setDiags={setDiags{:},'ctrl'}; end;
elseif ischar(setDiags);
  setDiags={setDiags};
end;

for iDiag=1:length(setDiags);

    nmDiag=setDiags{iDiag};

    normalLoop=~strcmp(nmDiag,'B')&~strcmp(nmDiag,'D')&~strcmp(nmDiag,'drwn3')&...
               ~strcmp(nmDiag,'profiles')&~strcmp(nmDiag,'ecco')&~strcmp(nmDiag,'ctrl');

    if normalLoop;
      for myYear=years;
        diags_select(dirModel,dirMat,nmDiag,lChunk,myYear);
      end;
      if isempty(years);
        gcmfaces_msg('!! Nothing to compute for specified years !!','==== '); fprintf('\n');
      end;

    elseif strcmp(nmDiag,'B');
      recInAve=[myparms.recInAve(1):myparms.recInAve(2)];
      diags_select(dirModel,dirMat,'B',1,recInAve);

    elseif strcmp(nmDiag,'drwn3');
      recs=(years(1)-1)*12+1:years(end)*12;
      recs=recs(recs<=myparms.diagsNbRec);
      diags_select(dirModel,dirMat,'drwn3',1,recs);

    elseif strcmp(nmDiag,'D');
      for kk=myparms.budgetList;
      for myYear=years;
        diags_select(dirModel,dirMat,{nmDiag,kk},lChunk,myYear);
      end;
      end;

    elseif strcmp(nmDiag,'profiles')&&myswitch.doProfiles;
        fprintf('> starting insitu_diags\n');
        insitu_diags(dirMat,1);

    elseif strcmp(nmDiag,'ecco')&&myswitch.doCost;
        fprintf('!cost_altimeter is commented out because it requires >32G and >30min\n');
        fprintf('! User may uncomment the following line if enough memory is available\n\n');
        %cost_altimeter(dirModel,dirMat);
        fprintf('> starting cost_sst\n');
        cost_sst(dirModel,dirMat,1);
        fprintf('> starting cost_seaice\n');
        cost_seaicearea(dirModel,dirMat,1);

    elseif strcmp(nmDiag,'ctrl')&&myswitch.doCtrl;
        cost_xx(dirModel,dirMat,1);
        
    end;

end;

