%userStep is set in basic_diags_ecco in 'user' blocs
%this routine is by choice not a function, in
%order to have access to entire workspace)

if ~strcmp(setDiags,'user')
    error(['unknown setDiags ' setDiags]);
end;

%%%%%%%%%%%%%%%%%%TEMPLATE%%%%%%%%%%%%%%%%%%%

if strcmp(setDiags,'user')&userStep==1;%diags to be computed
    fprintf('this is a place-holder for an extra set of diags : to be defined by you if you please\n')
    fprintf('how to proceed : 1) define listDiags HERE 2) define listFlds etc. below \n');
    fprintf('how to proceed : 3) add the computation code below 4) add the display code below\n');
    fprintf('how to proceed : 5) once done, remove this print the ''return'' call below\n');
    return;
end;

if strcmp(setDiags,'user')&userStep==2;%input files and variables
    fprintf('this is a place-holder for an extra set of diags : to be defined by you if you please\n')
    fprintf('how to proceed : 1) define listDiags above 2) define listFlds etc. HERE \n');
    fprintf('how to proceed : 3) add the computation code below 4) add the display code below\n');
    fprintf('how to proceed : 5) once done, remove this print the ''return'' call below\n');
    
    listSubdirs={[dirMat 'BUDG/' ],[dirModel 'diags/BUDG/' ],[dirModel 'diags/OTHER/' ],...
        [dirModel 'diags/STATE/' ],[dirModel 'diags/TRSP/'],[dirModel 'diags/' ]};
    listFiles={listFiles{:},'diags_2d_set1','diags_ice_set1','diags_3d_set1','diags_3d_set2','diags_3d_set3'};%for backward compatibility
    return;
end;

if strcmp(setDiags,'user')&userStep==3;%computational part;
    fprintf('this is a place-holder for an extra set of diags : to be defined by you if you please\n')
    fprintf('how to proceed : 1) define listDiags above 2) define listFlds etc. above \n');
    fprintf('how to proceed : 3) add the computation code HERE 4) add the display code below\n');
    fprintf('how to proceed : 5) once done, remove this print the ''return'' call below\n');
    return;
end;

if strcmp(setDiags,'user')&userStep==-1;%computational part;
    fprintf('this is a place-holder for an extra set of diags : to be defined by you if you please\n')
    fprintf('how to proceed : 1) define listDiags above 2) define listFlds etc. above \n');
    fprintf('how to proceed : 3) add the computation code above 4) add the display code below\n');
    fprintf('how to proceed : 5) once done, remove this print the ''return'' call below\n');
    return;
end;

