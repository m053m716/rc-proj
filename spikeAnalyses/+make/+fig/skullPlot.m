function ratSkullObj = skullPlot(GroupID,varargin)
%SKULLPLOT  Puts a rat skull plot object on current axes
%
%  ratSkullObj = make.fig.skullPlot(GroupID);
%  ratSkullObj = make.fig.skullPlot(GroupID,'name',value,...);
%     -> 'axes' : gca (default)
%     -> 'scatterparams' : {'MarkerSize',60};
%  
% Inputs
%  GroupID  - 'Intact' | 'Ischemia'
%  varargin - (Optional) 'Name',value parameter pairs
%
% Output
%  ratSkullObj - ratskull_plot class object for plotting spatial elements

% Parse inputs
pars = struct;
pars.axes = [];
pars.scatterparams = {'SizeData',60,'LineWidth',1.5};

if nargin < 1
   GroupID = 'Intact';
end

fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

if isempty(pars.axes)
   pars.axes = gca;
end

% % Create object % %
ratSkullObj = ratskull_plot(pars.axes);

% % Add lesion indicators % %
if strcmpi(GroupID,'Ischemia')
   scatter(ratSkullObj,...
      defaults.group('skull_et1_x'),...
      defaults.group('skull_et1_y'),...
      'ET-1',...
      'MarkerEdgeColor','none',...
      'MarkerFaceColor','k',...
      pars.scatterparams{:} ...
      );
else
   scatter(ratSkullObj,...
      defaults.group('skull_et1_x'),...
      defaults.group('skull_et1_y'),...
      'Sham',...
      'MarkerFaceColor','none',...
      'MarkerEdgeColor','k',...
      pars.scatterparams{:} ...
      );
end
end