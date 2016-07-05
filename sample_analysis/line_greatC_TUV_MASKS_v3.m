function [lonPairs,latPairs,names]=line_greatC_TUV_MASKS_v3();

gcmfaces_global;

for iy=1:21;
    
    switch iy;
        case 1; lonPair=[-173 -164]; latPair=[65.5 65.5]; name='Bering Strait';
        case 2; lonPair=[-5 -5]; latPair=[34 40]; name='Gibraltar';
        case 3; lonPair=[-81 -75]; latPair=[28 26]; name='Florida Strait';
        case 4; lonPair=[-81 -79]; latPair=[28 22]; name='Florida Strait W1';
        case 5; lonPair=[-76 -76]; latPair=[21 8]; name='Florida Strait S1';
        case 6; lonPair=[-75 -75]; latPair=[26 24]; name='Florida Strait E1';
        case 7; lonPair=[-75 -75]; latPair=[24 21]; name='Florida Strait E2';
        case 8; lonPair=[-65 -50]; latPair=[66 66]; name='Davis Strait';
        case 9; lonPair=[-35 -20]; latPair=[67 65]; name='Denmark Strait';
        case 10; lonPair=[-16 -7]; latPair=[65 62.5]; name='Iceland Feroe';
        case 11; lonPair=[-6.5 -4]; latPair=[62.5 57]; name='Feroe England';
        case 12; lonPair=[-4 8]; latPair=[57 62];  name='England Norway';
        case 13; lonPair=[-68 -63]; latPair=[-54 -66]; name='Drake Passage';
        case 14; lonPair=[103 103]; latPair=[4 -1]; name='Indonesia W1';
        case 15; lonPair=[104 109]; latPair=[-3 -7]; name='Indonesia W2';
        case 16; lonPair=[113 118]; latPair=[-7.5 -7.5]; name='Indonesia W3';
        case 17; lonPair=[118 127 ]; latPair=[-7.5 -15]; name='Indonesia W4';
        case 18; lonPair=[127 127]; latPair=[-25 -68]; name='Australia Antarctica';
        case 19; lonPair=[38 46]; latPair=[-10 -22]; name='Madagascar Channel';
        case 20; lonPair=[46 46]; latPair=[-22 -69]; name='Madagascar Antarctica';
        case 21; lonPair=[20 20]; latPair=[-30 -72]; name='South Africa Antarctica';
    end;
    
    lonPair(lonPair<0)=lonPair(lonPair<0)+360;
    
    if iy==1; lonPairs=lonPair; latPairs=latPair; names={name};
    else; lonPairs(iy,:)=lonPair; latPairs(iy,:)=latPair; names{iy}=name;
    end;
    
end;
