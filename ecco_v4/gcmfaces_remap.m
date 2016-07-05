function []=gcmfaces_remap(dirIn,fileIn,gridIn,dirOut,fileOut);
%object:    use bin average to remap a lat-lon grid product to a gcmfaces grid
%inputs:    dirIn is the input directory
%           fileIn is the input file name without the final four year characters 
%               (e.g. 'SST_monthly_r2_' to process 'SST_monthly_r2_1992' etc.)
%           gridIn states the originating grid. It can be set to 
%               1 implying that the grid is [0.5:359.5] & [-89.5:89.5]
%               2 implying that the grid is [0.5:359.5] & [-79.5:79.5]
%               3 implying that the grid is [.125:.25:360-.125] & [-90+.125:.25:90-.125]
%               {x,y} where x and y are the position arrays
%           dirOut and filOut are the corresponding output names
%
%assumption: mygrid has been read using grid_load
%            for the input grid, lon must be 0-360 (see gcmfaces_remap_2d)

global mygrid mytri;
%create triangulation
gcmfaces_bindata;
%list files to be processed
listFiles=dir([dirIn fileIn '*']);

%case of user defined grid
if iscell(gridIn); x=gridIn{1}; y=gridIn{2}; [nx,ny]=size(x); mis=0;
else;
%standard cases
if gridIn==1;%gloabl 1 degree grid
    x=[0.5:359.5]'*ones(1,180);
    y=ones(360,1)*[-89.5:89.5];
    [nx,ny]=size(x);
    mis=0;
elseif gridIn==2;%ECCO 1 degree grid
    x=[0.5:359.5]'*ones(1,160);
    y=ones(360,1)*[-79.5:79.5];
    [nx,ny]=size(x);
    mis=0;
elseif gridIn==3;%1/4 degree grid (e.g. REMSS)
    x=[.125:.25:360-.125]'*ones(1,180*4);
    y=ones(360*4,1)*[-90+.125:.25:90-.125];
    [nx,ny]=size(x);
    mis=-9999;
else;
    error('unknown grid');
end;
end;

%process one file after the other
for ii=1:length(listFiles);
    yy=listFiles(ii).name(end-3:end); fprintf(['processing ' fileIn '   for year   ' yy '\n']);
    nt=listFiles(ii).bytes/nx/ny/4; if round(nt)~=nt; error('inconsistent sizes'); end;
    %read data
    fld=reshape(read2memory([dirIn listFiles(ii).name],[nx*ny*nt 1]),[nx ny nt]);
    %mask land
    fld(fld==mis)=NaN;
    %map to v4 grid
    FLD=convert2array(zeros(360,360,nt));
    for tt=1:nt; FLD(:,:,tt)=gcmfaces_remap_2d(x,y,fld(:,:,tt),3); end;
    %set missing value
    FLD(find(isnan(FLD)))=mis;
    %write data
    write2file([dirOut fileOut yy],convert2gcmfaces(FLD));
end;

