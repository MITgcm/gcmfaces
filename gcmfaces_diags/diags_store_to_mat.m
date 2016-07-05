function []=diags_store_to_mat(dirMat,fileMat,onediag);
%object :  store results to memory as [dirMat fileMat]
%inputs:   dirMat is the matlab output directory name
%          fileMat is the matlab output file name. It is to be specified
%            by the diags_set routine, incl. the relevant time stamp.
%          onediag is a structure containting all fields to output

listDiags=fieldnames(onediag);

for jj=1:length(listDiags);
    eval([listDiags{jj} '=getfield(onediag,''' listDiags{jj} ''');']);
    if jj==1;
        eval(['save ' dirMat fileMat ' ' listDiags{jj} ';']);
    else;
        eval(['save ' dirMat fileMat ' -append ' listDiags{jj} ';']);
    end;
end;
