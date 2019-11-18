if exist('gData','var')==0
   load('gData.mat','gData');
end


[xs,ys] = build_xPCobj(gData,3:28,false,utils.makeIncludeStruct({'Reach','Grasp','Outcome'},[]));
[xf,yf] = build_xPCobj(gData,3:28,false,utils.makeIncludeStruct({'Reach','Grasp','Complete','PelletPresent'},{'Outcome'}));

%%
gs1 = {xs.ChannelInfo.Group}.';
gs2 = {xs.ChannelInfo.area}.';
gs2 = cellfun(@(x)(x((end-2):end)),gs2,'UniformOutput',false);
gs3 = repmat({'Successful'},numel(gs1),1);
gs = cell(size(gs1));
for i = 1:numel(gs1)
   gs{i} = [gs1{i} '-' gs2{i} '-' gs3{i}];
end

gf1 = {xf.ChannelInfo.Group}.';
gf2 = {xf.ChannelInfo.area}.';
gf2 = cellfun(@(x)(x((end-2):end)),gf2,'UniformOutput',false);
gf3 = repmat({'Unsuccessful'},numel(gf1),1);
gf = cell(size(gf1));
for i = 1:numel(gf1)
   gf{i} = [gf1{i} '-' gf2{i} '-' gf3{i}];
end

g = ([gs; gf]).';
X = ([xs.X, xf.X]).';

[d,p,stats] = manova1(X,g);
figure('Name','MANOVA: GROUP * AREA * OUTCOME',...
   'NumberTitle','off',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.25 0.2 0.3 0.6]);

manovacluster(stats);
ylabel('Group Mean Mahalanobis Distance','FontName','Arial','Color','k','FontSize',16);
set(gca,'XTickLabelRotation',75);

%% FIT REPEATED-MEASURES MODEL
Group = [gs1;gf1];
Area  = [gs2;gf2];
Outcome = [gs3;gf3];
% Score = [
T = table(Group,Area,Outcome,X);
T = [T(:,1:3),table(T.X(:,1),'VariableNames',{'X1'}),table(T.X(:,2),'VariableNames',{'X2'}),table(T.X(:,3),'VariableNames',{'X3'}),table(T.X(:,4),'VariableNames',{'X4'}),table(T.X(:,5),'VariableNames',{'X5'}),table(T.X(:,6),'VariableNames',{'X6'}),table(T.X(:,7),'VariableNames',{'X7'}),table(T.X(:,8),'VariableNames',{'X8'}),table(T.X(:,9),'VariableNames',{'X9'}),table(T.X(:,10),'VariableNames',{'X10'}),table(T.X(:,11),'VariableNames',{'X11'}),table(T.X(:,12),'VariableNames',{'X12'}),table(T.X(:,13),'VariableNames',{'X13'}),table(T.X(:,14),'VariableNames',{'X14'}),table(T.X(:,15),'VariableNames',{'X15'}),table(T.X(:,16),'VariableNames',{'X16'}),table(T.X(:,17),'VariableNames',{'X17'}),table(T.X(:,18),'VariableNames',{'X18'}),table(T.X(:,19),'VariableNames',{'X19'}),table(T.X(:,20),'VariableNames',{'X20'}),table(T.X(:,21),'VariableNames',{'X21'}),table(T.X(:,22),'VariableNames',{'X22'}),table(T.X(:,23),'VariableNames',{'X23'}),table(T.X(:,24),'VariableNames',{'X24'}),table(T.X(:,25),'VariableNames',{'X25'}),table(T.X(:,26),'VariableNames',{'X26'}),table(T.X(:,27),'VariableNames',{'X27'}),table(T.X(:,28),'VariableNames',{'X28'}),table(T.X(:,29),'VariableNames',{'X29'}),table(T.X(:,30),'VariableNames',{'X30'}),table(T.X(:,31),'VariableNames',{'X31'}),table(T.X(:,32),'VariableNames',{'X32'}),table(T.X(:,33),'VariableNames',{'X33'}),table(T.X(:,34),'VariableNames',{'X34'}),table(T.X(:,35),'VariableNames',{'X35'}),table(T.X(:,36),'VariableNames',{'X36'}),table(T.X(:,37),'VariableNames',{'X37'}),table(T.X(:,38),'VariableNames',{'X38'}),table(T.X(:,39),'VariableNames',{'X39'}),table(T.X(:,40),'VariableNames',{'X40'}),table(T.X(:,41),'VariableNames',{'X41'}),table(T.X(:,42),'VariableNames',{'X42'}),table(T.X(:,43),'VariableNames',{'X43'}),table(T.X(:,44),'VariableNames',{'X44'}),table(T.X(:,45),'VariableNames',{'X45'}),table(T.X(:,46),'VariableNames',{'X46'}),table(T.X(:,47),'VariableNames',{'X47'}),table(T.X(:,48),'VariableNames',{'X48'}),table(T.X(:,49),'VariableNames',{'X49'}),table(T.X(:,50),'VariableNames',{'X50'}),table(T.X(:,51),'VariableNames',{'X51'}),table(T.X(:,52),'VariableNames',{'X52'}),table(T.X(:,53),'VariableNames',{'X53'}),table(T.X(:,54),'VariableNames',{'X54'}),table(T.X(:,55),'VariableNames',{'X55'}),table(T.X(:,56),'VariableNames',{'X56'}),table(T.X(:,57),'VariableNames',{'X57'}),table(T.X(:,58),'VariableNames',{'X58'})];

Time = table(xs.t.','VariableNames',{'Time'});
rmm = fitrm(T,'X1-X58~Group*Area*Outcome','WithinDesign',Time);
[manovatbl,Am,Cm,Dm] = manova(rmm);

rmr = fitrm(T,'X1-X58~Group*Area*Outcome','WithinDesign',Time,'WithinModel','orthogonalcontrasts');
[ranovatbl,Ar,Cr,Dr] = ranova(rmr);