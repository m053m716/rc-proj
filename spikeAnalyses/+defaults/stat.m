function varargout = stat(varargin)
%STAT Return default parameters associated with analyze.stat package
%
%  param = defaults.stat(name);
%  [param1,...,paramk] = defaults.stat('par1Name',...,'parkName');
%
%  <strong>Parameters</strong>
%  -> 'param_grid'     - Struct with coarse parameter grid for estimating
%                        gradient & hessian during optimization
%  -> 'modelspec_glme' - Default model specification for generalized linear
%                        mixed effects statistical model.
%
% See also: analyze.stat, analyze.stat.fit_transfer_fcn

p = struct;
% Initialization parameters
% % For fitting `gauspuls` % %
p.param_grid = struct; % Contains: 'tau','sigma','omega'
p.param_grid.tau = -1.75:0.50:1.25;         % Offset times
p.param_grid.sigma = 0.1:0.60:2.5;          % Bandwidth (% of omega) for peak frequency
p.param_grid.omega = 0.1:0.8:4.1;           % Center freq of oscillation (Hz)
p.param_grid.noise.tau = 0.100;
p.param_grid.noise.sigma = 0.05;
p.param_grid.noise.omega = 0.05;
% `A` from fmincon (k x 3) for k constraints (or empty) %
p.gaus_A = []; 
p.gaus_Aeq = [];
% `b` from fmincon (k x 1) for k constraints (or empty) %
p.gaus_b = [];
p.gaus_beq = [];
% Note that parameters are to be bounded by the grid %
% p.gaus_nonlcon = @analyze.stat.nonlinear_constraint;
p.gaus_nonlcon = [];
p.gaus_niter = 1;
% can be: 'iter-detailed',
% 'iter','notify','notify-detailed','final','final-detailed':
p.gaus_dispstyle = 'off'; 

p.modelspec = [...
   "EnvelopeBW~GroupID*Area*PostOpDay+(1|AnimalID)"; ...
   "PeakOffset~GroupID*Area*PostOpDay+(1|AnimalID)"; ...
   "Z~GroupID*Area*PostOpDay+(1|AnimalID)" ...
   ];
p.modelspec_jpca = "RotationStrength~GroupID*Area*PostOpDay+(1|AnimalID)";

% For exclusion/restrictions %
p.max_env_bw = 10; % (Hz) - This actually excludes the most "bad" fits
p.max_sse = 50;    % (should only remove a few really bad outliers)
p.peak_offset_lims = [-1.000 0.750];
p.included_outcome = "Successful";
p.included_alignment = "Grasp";
p.removed_days = [];
p.default_z_pc_index = 1;

% % Graphics parameters % %
p.axParams = {'NextPlot','add','XColor','k','YColor','k','LineWidth',1.25,'FontName','Arial'};
p.figParams = {'Color','w','Units','Normalized','Position',[0.1 0.1 0.8 0.8],'NumberTitle','off'};
p.fontParams = {'FontName','Arial','Color','k'};

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