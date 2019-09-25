function []=prep_flt_init(dirOut);
% prep_flt_init(dirOut) creates initial conditions for MITgcm/pkg/flt
%   that will be stored into dirOut ('init_flt/' by default).

%in summary:
%- get tile map
%- skip blank tiles
%- loop over tile
%- select all ocean points
%- add uniform noise to i,j (in the -0.5 to 0.5 I think)
%- output to file (single prec for ini or double for pickup)

%to do list:
%- add lon, lat (vector?) input arguments and get i,j, etc using `gcmfaces_interp_coeffs` 

if isempty(whos('dirOut')); dirOut=[pwd filesep 'init_flt' filesep]; end;
if ~isdir(dirOut); mkdir(dirOut); end;

%%

gcmfaces_global; if isempty(mygrid); grid_load; end;
map_tile=gcmfaces_loc_tile(30,30);

tmp1=convert2vector(mygrid.mskC(:,:,1).*map_tile);
tmp1=unique(tmp1);
list_tile=tmp1(find(~isnan(tmp1)));

map_i=NaN*map_tile; map_j=NaN*map_tile;
[tmp_j,tmp_i]=meshgrid(1:30,1:30);
for ff=1:map_i.nFaces;
  [m,n]=size(map_i{ff});
  map_i{ff}=repmat(tmp_i,[m/30 n/30]);
  map_j{ff}=repmat(tmp_j,[m/30 n/30]);
end;

%%

vec_i=convert2vector(map_i);
vec_j=convert2vector(map_j);
vec_tile=convert2vector(map_tile.*mygrid.mskC(:,:,1));

kk=0;
for ii=1:length(list_tile);
  jj=find(vec_tile==list_tile(ii)); 
  tmp_i=vec_i(jj); tmp_j=vec_j(jj);
  nn=length(jj);
  %
  tmp1=[nn 1 3600 0 0 9000 9 0 0];
  tmp2=[kk+[1:nn]' -ones(nn,1) tmp_i tmp_j ones(nn,1) zeros(nn,3) -ones(nn,1)];
  arrOut=[tmp1;tmp2]';
  %
  filOut=sprintf('%s/init_flt.%03d.001.data',dirOut,ii);
  write2file(filOut,arrOut,32);
  kk=kk+nn;
end;


