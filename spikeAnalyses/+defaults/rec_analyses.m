function varargout = rec_analyses(varargin)
%REC_ANALYSES  Defaults for single-recording analyses
%
%  p = defaults.rec_analyses();
%  [v1,v2,...] = defaults.rec_analyses('v1Name','v2Name',...);

p = struct;
p.rate_xtick = [-1000 -500 0 500];
p.rate_ytick = [-2 0 2];
p.rate_ylim = [0 30];
p.rate_colors = struct(...
   'CFA',getColorMap(18,'blue'),...
   'RFA',getColorMap(18,'red'));
p.n_trial_max = 32;

% Parse output
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
