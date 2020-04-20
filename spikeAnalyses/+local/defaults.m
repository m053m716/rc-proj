function varargout = defaults(varargin)
%DEFAULTS  Subset of defaults that will be specific to local machine 
%
%  pars = local.defaults();
%  [var1,var2,...] = local.defaults('var1Name','var2Name',...);

pars = struct;
pars.CommunalDataTank = 'P:\Rat\BilateralReach\RC';
pars.LocalDataTank = 'D:\MATLAB\Data\RC';
pars.LocalMatlabReposFolder = 'D:\MATLAB\Projects';

if nargin < 1
   varargout = {pars};   
else
   F = fieldnames(pars);   
   if (nargout == 1) && (numel(varargin) > 1)
      varargout{1} = struct;
      for iV = 1:numel(varargin)
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{1}.(F{idx}) = pars.(F{idx});
         end
      end
   elseif nargout > 0
      varargout = cell(1,nargout);
      for iV = 1:nargout
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{iV} = pars.(F{idx});
         end
      end
   else
      for iV = 1:nargin
         idx = strcmpi(F,varargin{iV});
         if sum(idx) == 1
            fprintf('<strong>%s</strong>:',F{idx});
            disp(pars.(F{idx}));
         end
      end
   end
end

end