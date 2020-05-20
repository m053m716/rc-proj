function varargout = fails_analyses(varargin)
%FAILS_ANALYSES  Subset of defaults that deals with PCA analysis parameters
%
%  p = defaults.pca_analyses();
%  [var1,var2,...] = defaults.fails_analyses('var1Name','var2Name',...);
%
%  # Parameters (`name` values) #
%  -> 'n_factors'
%  -> 'color_order'

p = struct;
p.n_factors = 4;
p.factor_names = {'Excitation_to_Suppression','Leading_Gaussian',...
   'Task_Modulation','Multiphasic'};
p.color_order = getColorMap(p.n_factors,'pastel');
p.variable_weights = sin(linspace(0.1*pi,0.75*pi,28));
p.alignment_events = {'Reach','Grasp'};

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
