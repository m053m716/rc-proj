function fig = plotPosterior(rClass,v1,v2,type)
%PLOTPOSTERIOR Plot posterior based on Naive Bayes classifier
%
%  fig = analyze.trials.plotPosterior(rClass,v1,v2);
%  fig = analyze.trials.plotPosterior(rClass,v1,v2,'simple'); --> Plot simple surface
%
% Inputs
%  rClass   - Table with Naive Bayes Classifier predictions
%  v1       - Name of x variable
%  v2       - Name of y variable
%  type     - (Optional) 'standard' (default) | 'simple'
%
% Output
%  fig      - Figure handle
%
% See also: Contents, unit_learning_stats

NREP = 10;
% offset = linspace(-2,2,NREP);
% C = [1 0.4 0.4; 0.7 0.1 0.1; 0.4 0.4 1; 0.1 0.1 0.7];
% Pred = ["Successful"; "Unsuccessful"; "Successful"; "Unsuccessful"];
% Obs = ["Unsuccessful"; "Successful"; "Successful"; "Unsuccessful"];
% Type = ["FP"; "FN"; "TP"; "TN"];
% Marker = ["x"; "x"; "."; "."];
% Index = [2; 1; 2; 1];
% p = table(C,Type,Marker,Obs,Pred,Index);

if nargin < 2
   v1 = 'N_Pre_Grasp';
end

if nargin < 3
   v2 = 'N_Retract';
end

if nargin < 4
   type = 'standard';
end

fig = figure('Name','Bayesian Classifier Posterior',...
   'Color','w','Units','Normalized',...
   'Position',[0.2 0.2 0.5 0.5]);

ax = axes(fig,'XColor','k','YColor','k',...
   'LineWidth',1.5,'NextPlot','add',...
   'FontName','Arial','CLim',[0 1],'ZLim',[0 1]);
nObs = size(rClass,1);
switch lower(type)
   case 'standard'
      X = [rClass.N_Pre_Grasp,rClass.N_Reach,rClass.N_Retract,rClass.Duration,rClass.Retract_Epoch_Duration];
      
      mdl = rClass.mdl{1};
      varOrder = {'N_Pre_Grasp','N_Reach','N_Retract','Duration','Retract_Epoch_Duration'};
   case 'simple'
      X = [rClass.N_Pre_Grasp,rClass.N_Reach,rClass.N_Retract];
      mdl = rClass.simple_mdl{1};
      varOrder = {'N_Pre_Grasp','N_Reach','N_Retract'};      
   otherwise
      error('Unrecognized value for `type` input (''%s'')',type);
end
MU = nanmean(X,1);
SD = nanstd(X,[],1);
X = (X - MU)./SD;

v1_idx = find(strcmp(varOrder,v1));
v2_idx = find(strcmp(varOrder,v2));
if isempty(v1) || isempty(v2)
   error('Double-check variable names');
end

X1 = repmat(X,NREP,1);
X2 = X1;

vec = 1:nObs;
for ii = 1:NREP
   X1(vec,v1_idx) = X1(vec,v1_idx) + randn(nObs,1);
   vec = vec + nObs;
end

vec = 1:nObs;

for ii = 1:NREP
   X2(vec,v2_idx) = X2(vec,v2_idx) + randn(nObs,1);
   vec = vec + nObs;
end


[~,Z] = predict(mdl,[X1; X2]);

xx = [X1(:,v1_idx); X2(:,v1_idx)];
yy = [X1(:,v2_idx); X2(:,v2_idx)];
X = [xx,yy];

tic;
fprintf(1,'Fitting bivariate normal distribution for <strong>Unsuccessful</strong> trials...');
Rho = corrcoef(X);
beta0 = [nanmean(X,1), nanstd(X,[],1), Rho(1,2)];
z = Z(:,1); % Failure
mdl = fitnlm(X,z,@fitBivariateNormal,beta0);
fprintf(1,'complete (%5.2f sec)\n',toc);

xg = linspace(min(xx),max(xx),32);
yg = linspace(min(yy),max(yy),32);
[XG,YG] = meshgrid(xg,yg);
XGg = XG.*SD(v1_idx)+MU(v1_idx);
YGg = YG.*SD(v2_idx)+MU(v2_idx);
sz = size(XG);
xy = [XG(:),YG(:)];

zz = reshape(predict(mdl,xy),sz); % Probability of failure
surf(ax,XGg,YGg,zz,'EdgeColor','none','FaceColor','r','FaceAlpha',0.25);
drawnow;

fprintf(1,'Fitting bivariate normal distribution for <strong>Successful</strong> trials...');
z = Z(:,2); % Success
mdl = fitnlm(X,z,@fitBivariateNormal,beta0);
fprintf(1,'complete (%5.2f sec)\n',toc);
zz = reshape(predict(mdl,xy),sz); % Probability of failure
surf(ax,XGg,YGg,zz,'EdgeColor','none','FaceColor','b','FaceAlpha',0.25);
drawnow;
xlim(ax,[0 ax.XLim(2).*0.75]);
ylim(ax,[0 ax.YLim(2).*0.75]);
xlabel(ax,strrep(v1,'_',' '),'FontName','Arial','Color','k');
ylabel(ax,strrep(v2,'_',' '),'FontName','Arial','Color','k');
legend(ax,{'Unsuccessful','Successful'},'TextColor','black',...
   'AutoUpdate','off','FontName','Arial');
alpha(0.2);
view(3);
% colorbar(ax);
title(ax,'Posterior Class Probabilities',...
   'FontName','Arial','Color','k');
zlabel(ax,'pdf','FontName','Arial','Color','k');

   function z = fitBivariateNormal(b,X)
      m = b(1:2);
      s = b(3:4);
      rho = b(5);
      x = (X(:,1) - m(1))./s(1);
      y = (X(:,2) - m(2))./s(2);
      C1 = 1 ./ (2.*pi.*s(1).*s(2).*sqrt(1-rho.^2));
      C2 = -1 ./ (2.*(1 - rho.^2));
      z =  C1.*exp(C2 .* (x.^2 - 2.*rho.*x.*y + y.^2)); 
      z(isinf(z)) = 5; % Very large probability density
      z(isnan(z)) = 0; 
   end

end