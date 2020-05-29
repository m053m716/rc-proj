function param = ratskull_plot(name)
%RATSKULL_PLOT Return default parameters for "ratskull_plot" object (deprecated)

% DEFINE DEFAULTS
p = struct;
% Image
p.CData = utils.load_ratskull_plot_img('low');
p.XData = [-11, 9.65];    % mm
p.YData = [-6.10 7.00];    % mm
% Axes
p.XLim = [-6.50 6.50]; % mm
p.YLim = [-5.50 5.50]; % mm
% Bregma
p.Bregma_Theta = linspace(-pi,pi,180);
p.Bregma_R = 0.20;
p.Bregma_X = cos(p.Bregma_Theta) * p.Bregma_R;
p.Bregma_Y = sin(p.Bregma_Theta) * p.Bregma_R;
p.Bregma_C = 'r';
% Figure
p.Fig_Name = 'Rat Skull Plot';
p.Fig_Col = 'w';
p.Fig_Units = 'Normalized';
p.Fig_Pos = [0.15 0.1 0.6 0.8];
% Scale_Compass
p.Scale_X = 1.0; % mm
p.Scale_Y = 1.0; % mm
p.Scale_Pos = [-5.00,-5.00]; % mm
p.Scale_Up_Str = '1 mm';
p.Scale_R_Str = '1 mm (Rostral)';
p.Scale_Arrow_Col = [0 0 0];
p.Scale_Arrow_W = 1.25;
p.Scale_Str_Col = [0 0 0];
% Scatter
p.Scatter.MarkerSize = 100;
p.Scatter.MarkerEdgeColor = 'none';
p.Scatter.MarkerFaceColor = 'k';
p.Scatter.Marker = 'o';
p.Scatter.MarkerFaceAlpha = 0.6;
p.Scatter.Parent = [];
p.Scatter_GroupName = 'Electrodes';

% PARSE OUTPUT
if nargin == 1
   if ismember(name,fieldnames(p))
      param = p.(name);
   else % Check capitalization just in case
      f = fieldnames(p);
      idx = ismember(lower(f),lower(name));
      if any(idx)
         param = p.(f{find(idx,1,'first')});
      else % OK it just isn't a field:
         error('%s is not a valid parameter. Check spelling?',lower(name));
      end
   end
elseif nargin == 0
   param = p;
end

end