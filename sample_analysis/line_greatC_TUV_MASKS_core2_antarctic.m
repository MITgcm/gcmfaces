function [lonPairs,latPairs,names]=line_greatC_TUV_MASKS_core2_antarctic();

gcmfaces_global;

for iy=1:5;
    
    switch iy;
        case 1; lonPair=[20. 20.]; latPair=[-80. -50.]; name='Weddell-Indian (20E)';
        case 2; lonPair=[90. 90.]; latPair=[-80. -50.]; name='Indian-West Pacific (90E)';
        case 3; lonPair=[160. 160.]; latPair=[-80. -50.]; name='West Pacific-Ross Sea (160E)';
        case 4; lonPair=[-130 -130]; latPair=[-80 -50.];  name='Ross Sea-Amundson Sea (130W)';
        case 5; lonPair=[-62. -62.]; latPair=[-80 -50]; name='Amundsen Sea-Peninsula (62W)';
    end;
    
    if iy==1; lonPairs=lonPair; latPairs=latPair; names={name};
    else; lonPairs(iy,:)=lonPair; latPairs(iy,:)=latPair; names{iy}=name;
    end;
    
end;

