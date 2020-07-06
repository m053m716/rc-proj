function varargout = ratskull_plot(varargin)
%RATSKULL_PLOT Return parameters associated with ratskull_plot class
%
%  varargout = defaults.ratskull_plot(varargin);
%
%  Examples:
%  par = defaults.ratskull_plot('par_name');
%  [par_1,...,par_k] = defaults.ratskull_plot('name_p1',...,'name_pk'); 
%
%  # Parameters (`name` values) #
%  -> 'CData'            : Default image data
%  -> 'XData'            : Default scaling on image [xmin, xmax] (mm)
%  -> 'YData'            : Default scaling on image [ymin, ymax] (mm)
%  -> 'Font'             : Cell array of 'Name',value pairs for font
%  -> 'XLim'             : Default axes x-limits (mm)
%  -> 'YLim'             : Default axes y-limits (mm)
%  -> 'Bregma'           : Default bregma-related parameters (struct)
%  -> 'Fig'              : Default figure-related parameters (struct)


% % % Create struct with default parameters % % %
p = struct;

% % Image-related % %
if any(strcmpi(varargin,'CData')) % Only load if requested
   p.CData = utils.load_ratskull_plot_img('low');
end
p.XData = [-11, 9.65];    % mm
p.YData = [-6.10 7.00];   % mm

% % Axes-related % %
p.XLim = [-6.50 6.50]; % mm
p.YLim = [-5.50 5.50]; % mm

% % Label-related % %
p.Font = {'FontName','Arial','Color','k','FontWeight','bold','FontSize',14};

% % "Bregma" marker-related % %
p.Bregma.Theta = linspace(-pi,pi,180);
p.Bregma.R = 0.20;
p.Bregma.Xt = 0.25;        % Text x-coordinate (mm)
p.Bregma.X  = cos(p.Bregma.Theta) * p.Bregma.R + 0.5; % Marker outline x (mm)
p.Bregma.Y = sin(p.Bregma.Theta)  * p.Bregma.R; % Marker outline y (mm)
p.Bregma.Yt = 0.15;        % Text y-coordinate (mm)
p.Bregma.C = 'm';          % Bregma marker color
p.Bregma.Text = 'Bregma';  % Text label for marker

% % Figure-property related % %
p.Fig.Name = 'Rat Skull Plot';
p.Fig.Col = 'w';
p.Fig.Units = 'Normalized';
p.Fig.Pos = [0.15 0.1 0.6 0.8];

% % Scale_Compass (property)-related % %
p.Scale.Name = 'Compass'; % DisplayName property of scale
p.Scale.X = 1.0; % mm
p.Scale.Y = 1.0; % mm
p.Scale.Pos = [-5.00,-5.00]; % mm
p.Scale.Up_Str = '1 mm';
p.Scale.R_Str = '1 mm (Rostral)';
p.Scale.Arrow_Col = [0 0 0];
p.Scale.Arrow_W = 1.25;
p.Scale.Str_Col = [0 0 0];

% % Scatter (method)-related % %
p.Scatter.MarkerSize = 100;
p.Scatter.MarkerEdgeColor = 'none';
p.Scatter.MarkerFaceColor = 'k';
p.Scatter.Marker = 'o';
p.Scatter.MarkerFaceAlpha = 0.6;
p.Scatter.Parent = [];

% % % Display defaults (if no input or output supplied) % % %
if (nargin == 0) && (nargout == 0)
   disp(p);
   return;
end

% % % Parse output % % %
if nargin < 1
   varargout = {p};   
else
   F = fieldnames(p);   
   if (nargout == 1) && (numel(varargin) > 1)
      varargout{1} = struct;
      for iV = 1:numel(varargin)
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{1}.(F{idx}) = p.(F{idx});
         end
      end
   elseif nargout > 0
      varargout = cell(1,nargout);
      for iV = 1:nargout
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{iV} = p.(F{idx});
         end
      end
   else
      for iV = 1:nargin
         idx = strcmpi(F,varargin{iV});
         if sum(idx) == 1
            fprintf('<strong>%s</strong>:',F{idx});
            disp(p.(F{idx}));
         end
      end
   end
end
end