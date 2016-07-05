function [RHOP,RHOIS,RHOR] = density(TN,SN,GDEPT,ZREF)
% [RHOP,RHOIS,RHOR] = density(Tpot,S,P,PREF)
%
% Adapted from OPA, subroutine EOS.F (bferron@ifremer.fr)
%
%                       ROUTINE EOS
%                    *******************
%
%  PURPOSE :
%  -------
%     COMPUTE THE POTENTIAL DENSITY RHOP, IN SITU DENSITY RHOIS, AND, IF A 
%     REFERENCE LEVEL PREF IS SPECIFIED, THE DENSITY RHOR REFERENCED TO PREF
%     FROM POTENTIAL TEMPERATURE AND SALINITY FIELDS.
%
% IMPORTANT NOTE: This version minimize the deviations of in-situ
%                 density compared to the UNESCO equation within
%                 [0-4500]dbars!!!!!! It is the version used in OPA
%                 (differences < 2e-4 kg/m3)
%                 Below 6000 dbar , differences are > 1e-3 kg/m-3
%
%   METHOD :
%   ------
%      JACKETT AND McDOUGALL (1994) EQUATION OF STATE
%      *********************
%      THE IN SITU DENSITY IS COMPUTED DIRECTLY AS A FUNCTION OF
%      POTENTIAL TEMPERATURE RELATIVE TO THE SURFACE, SALT AND PRESSURE 
%
%
%              RHO(T,S,P)
%
%      WITH PRESSURE                    P        DECIBARS
%           POTENTIAL TEMPERATURE       T        DEG CELSIUS
%           SALINITY                    S        PSU
%           DENSITY                     RHO      KG/M**3
%
%      CHECK VALUE: RHO = 1.04183326 KG/M**3 FOR P=10000 DBAR,
%       T = 40 DEG CELCIUS, S=40 PSU
%

%
%  JACKETT AND McDOUGALL (1994) FORMULATION
%--------------------------------------------
%
%...   potential temperature, salinity and depth
ZT = TN;
ZS = SN;
if size(TN,2)>1 & size(TN,1)>1 & size(TN,1)==length(GDEPT)
ZH = GDEPT*ones(1,size(ZT,2)); % comented 13/04/99 for WHP Thorpe calc. 
elseif size(TN,2)>1 & size(TN,1)>1 & size(TN,2)==length(GDEPT)
ZH = ones(size(ZT,1),1) *GDEPT';
elseif sum(size(TN))==2
ZH = ones(size(TN))*GDEPT;
else
ZH = GDEPT; % Added 13/04/99 for WHP Thorpe calc.
end

%...   square root salinity
ZSR= sqrt(ZS);
%...   compute density pure water at atm pressure
ZR1= ((((6.536332E-9*ZT-1.120083E-6).*ZT+1.001685E-4).*ZT ...
              -9.095290E-3).*ZT+6.793952E-2).*ZT+999.842594;
%...   seawater density atm pressure
ZR2= (((5.3875E-9*ZT-8.2467E-7).*ZT+7.6438E-5).*ZT ...
             -4.0899E-3).*ZT+0.824493;
ZR3= (-1.6546E-6*ZT+1.0227E-4).*ZT-5.72466E-3;
ZR4= 4.8314E-4;
%
%...   potential density (referenced to the surface)
RHOP= (ZR4*ZS + ZR3.*ZSR + ZR2).*ZS + ZR1;
%
%...   add the compression terms
ZE = (-3.508914E-8*ZT-1.248266E-8).*ZT-2.595994E-6;
ZBW= ( 1.296821E-6*ZT-5.782165E-9).*ZT+1.045941E-4;
ZB = ZBW + ZE .* ZS;
%
ZD = -2.042967E-2;
ZC = (-7.267926E-5*ZT+2.598241E-3).*ZT+0.1571896;
ZAW= ((5.939910E-6*ZT+2.512549E-3).*ZT-0.1028859).*ZT-4.721788;
ZA = ( ZD*ZSR + ZC).*ZS + ZAW;
%
ZB1= (-0.1909078*ZT+7.390729).*ZT-55.87545;
ZA1= ((2.326469E-3*ZT+1.553190).*ZT-65.00517).*ZT+1044.077;
ZKW= (((-1.361629E-4*ZT-1.852732E-2).*ZT-30.41638).*ZT ...
            +2098.925).*ZT+190925.6;
ZK0= (ZB1.*ZSR + ZA1).*ZS + ZKW;
%
%...   in situ density
RHOIS = RHOP ./ (1.0-ZH./(ZK0-ZH.*(ZA-ZH.*ZB)));

%...   density referenced to level ZREF
if nargin==4
   RHOR = RHOP ./ (1.0-ZREF./(ZK0-ZREF.*(ZA-ZREF.*ZB)));
end
