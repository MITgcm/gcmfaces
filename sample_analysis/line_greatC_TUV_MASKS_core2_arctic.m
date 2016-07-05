function [lonPairs,latPairs,names]=line_greatC_TUV_MASKS_core2_arctic();

gcmfaces_global;

for iy=1:10;
    
    switch iy;
        case 1; lonPair=[-21. 17.];    latPair=[79 79]; name='Fram Strait';
        case 2; lonPair=[17. 100.];    latPair=[79 79]; name='Barents/Kara Sea North';
        case 3; lonPair=[-170. -167.]; latPair=[66 66]; name='Bering Strait (66N)';
        case 4; lonPair=[-62. -53.];   latPair=[66 66]; name='Davis Strait (66N)';
        case 5; lonPair=[-37. -23.];   latPair=[66 66]; name='Greenland-Iceland (66N)';
        case 6; lonPair=[-16 13];      latPair=[66 66]; name='Iceland-Norway (66N)';
        case 7; lonPair=[-64 -44];     latPair=[60 60]; name='Newfoundland-Greenland (60N)';
        case 8; lonPair=[-44 5];       latPair=[60 60]; name='Greenland-Norway (60N)';
%
        case 9; lonPair=[17. 17.];     latPair=[68 79]; name='Barents Sea Opening';
        case 10; lonPair=[56. 56.];    latPair=[68 79]; name='Kara Sea Opening';
    end;
    
    if iy==1; lonPairs=lonPair; latPairs=latPair; names={name};
    else; lonPairs(iy,:)=lonPair; latPairs(iy,:)=latPair; names{iy}=name;
    end;
    
end;

