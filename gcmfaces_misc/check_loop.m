
dirIn='release1/nctiles_budg/budgMo/'

for tt=1:238;
  tt
  budgIn.tend=read_nctiles([dirIn 'tend/tend'],'tend',tt);
  budgIn.trU=read_nctiles([dirIn 'trU/trU'],'trU',tt);
  budgIn.trV=read_nctiles([dirIn 'trV/trV'],'trV',tt);
  if dirIn(end-1)=='o';
    budgIn.trW=read_nctiles([dirIn 'trW/trW'],'trW',tt);
    %
    budgIn.trWtop=budgIn.trW;
    budgIn.trWbot=budgIn.trW(:,:,2:50);
    budgIn.trWbot(:,:,50)=0;
    %
    %budgIn.tend(isnan(tend))=0;
    %budgIn.trU(isnan(trU))=0; budgIn.trV(isnan(trV))=0;
    %budgIn.trWtop(isnan(trWtop))=0; budgIn.trWbot(isnan(trWbot))=0;
  else;
    budgIn.trWtop=read_nctiles([dirIn 'trWtop/trWtop'],'trWtop',tt);
    budgIn.trWbot=read_nctiles([dirIn 'trWbot/trWbot'],'trWbot',tt);
  end;
  %
  nr=size(budgIn.tend{1},3);
  for kk=1:nr; prec(kk,:)=check_budg(budgIn,kk); end;
  if 0;
    figureL;
    plot(log10(prec(:,1)),'b');
    hold on;
    plot(log10(prec(:,2)),'r');
    plot(log10(prec(:,3)),'k');
    title(num2str(tt));
  end;%if 0;
  if tt==1;
    store_prec=prec;
  else;
    store_prec(:,:,tt)=prec;
  end;
end;%for tt=[1 119 238];

max(store_prec(:))
eval(['save ' dirIn 'residuals.mat store_prec;']);

