
%expected result:
%
%difference in dirGrid
%difference in fileFormat
%difference in RF
%structure LATS_MASKS remains to be checked
%structure LINES_MASKS remains to be checked

clear all;

load mygrid_nctiles.mat;
%load mygrid_new.mat;
mygrid1=mygrid; mygrid=[];
load mygrid_old.mat;
mygrid2=mygrid; mygrid=[];

list1=fieldnames(mygrid1);
list2=fieldnames(mygrid2);
if length(list1)~=length(list2);
 error('missing variables');
end;

for ii=1:length(list1);
 if sum(strcmp(list2,list1{ii}))~=1;
  error('missing variable');
 end;
 tmp1=getfield(mygrid1,list1{ii});
 tmp2=getfield(mygrid2,list1{ii});
 if ischar(tmp1);
   if ~strcmp(tmp1,tmp2); fprintf(['\n difference in ' list1{ii} '\n']); end;
 elseif isstruct(tmp1);
   fprintf(['\n structure ' list1{ii} ' remains to be checked\n']);
   %disp(tmp1); disp(tmp2);
 elseif isnumeric(tmp1);
   if sum(size(tmp1)~=size(tmp2))>0;
     fprintf(['\n size difference in ' list1{ii} '\n']);
   else;
     tmp3=max(abs(tmp1(:)-tmp2(:)));
     tmp4=max(abs(isnan(tmp1(:))-isnan(tmp2(:))));
     if tmp3~=0|tmp4~=0; fprintf(['\n difference in ' list1{ii} '\n']); end;
   end;
 elseif islogical(tmp1)|isa(tmp1,'gcmfaces');
   tmp3=max(abs(tmp1(:)-tmp2(:)));
   tmp4=max(abs(isnan(tmp1(:))-isnan(tmp2(:))));
   if tmp3~=0|tmp4~=0; fprintf(['\n difference in ' list1{ii} '\n']); end; 
 else;
  error('missing type');
 end;
end;

