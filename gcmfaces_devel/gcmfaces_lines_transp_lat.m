function [line_out]=gcmfaces_lines_transp_lat(varargin);
%object:    compute a section along a latitude for a longitude section 
%           by pair of coordinates, for use in calc_transports
%inputs:    lonPairs is the pair of longitudes
%           latPairs is the pair of latgitudes, the same value 
%           names (e.g. {'Drake Passage'} by default) is the transport line name
%output:    (optional) line_out is a strcuture with the following fields 
%           lonPair, latPair, name, mskCedge, mskWedge, mskSedge
%           If no output is specified then line_out is copied to 
%           mygrid (global variable) as 'mygrid.LINES_MASKS'
%
% Should be used for lat section. Not used together with gcmfaces_lines_transp.m 
% Modified from gcmfaces_line_transp.m 
%
% XC WANG 
% 20131017 

global mygrid;
c1 = 1;  c180=180;  c360=360; 

if nargin>0;
    lonPairs=varargin{1};
    latPairs=varargin{2};
    names=varargin{3};
else;
    display('Input Error') 
end;  

lat_check = latPairs(:, 1) - latPairs(:, 2) ;   
[value pos] = max(abs(lat_check)); 
if (value ~= 0 ) 
    display('Not on a latitudinal section') 
   return 
end 


for iy=1:length(names);
    
    lonPair=lonPairs(iy,:);
    latPair=latPairs(iy,:);
    name=names{iy}; 

% Here we assume north of the latPairs is the interest region. 
% Transport into it is positive 
% When the east longitude is larger than 180 (as for Pacific),
% longitude is converted to 0-360.
    if(lonPair(2) > c180) 
     lonface = mygrid.XC ; 
     neg = lonface < 0; 
     lonface(neg) = lonface(neg) + c360 ; 
     mskCint1=(lonface >=lonPair(1) & lonface <= lonPair(2));
     mskCint2=(mygrid.YC>=latPair(1));
     else  
     mskCint1=(mygrid.XC>=lonPair(1) & mygrid.XC <= lonPair(2));
     mskCint2=(mygrid.YC>=latPair(1));
    end 
    farawayc = abs(mygrid.YC-latPair(1)) > c1 ; 
    farawayg = abs(mygrid.YG-latPair(1)) > c1 ; 
    mskCint = 1*(mskCint1&mskCint2) ; 

    [mskCedge,mskWedge,mskSedge]=gcmfaces_edge_mask(mskCint); 
    mskCedge(farawayc) = 0; 
    mskWedge(farawayg) = 0; 
    mskSedge(farawayg) = 0; 
    
    %store so-defined line:
    line_cur=struct('lonPair',lonPair,'latPair',latPair,'name',name,...
        'mskCedge',mskCedge,'mskWedge',mskWedge,'mskSedge',mskSedge);
        
    %add to lines:
    if iy==1;
        LINES_MASKS=line_cur;
    else;
        LINES_MASKS(iy)=line_cur;
    end;
    
end;

if nargout==0; %add to mygrid
  mygrid.LINES_MASKS=LINES_MASKS;
else;          %output to line_out 
  line_out=line_cur;
end;


