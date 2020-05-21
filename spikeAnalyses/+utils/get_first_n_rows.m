function varargout = get_first_n_rows(n,varargin)
%GET_FIRST_N_ROWS  Samples first `n` rows for a given Table "split"
%
%  varargout = utils.get_first_n_rows(n,varargin)
%
%  -- Inputs --
%  n : Number of rows to keep (keeps row indices 1:n)
%        -> Set as `inf` to include all rows
%
%  -> Use case e.g.
%     ```
%        % Get first row from every Table "split" in `x`
%        [argsOut{:}] = splitapply(...
%           @(varargin)utils.get_first_n_rows(1,varargin{:}),x,G);
%     ```

varargout = cell(1,numel(varargin));
for iV = 1:numel(varargin)
   if isinf(n)
      data = varargin(iV);
   else
      if n > 1
         data = {varargin{iV}(1:n,:)};
      else
         data = varargin{iV}(1,:);
         if ischar(data)
            data = {data};
         end
      end
   end
   
   varargout{1,iV} = data;
end
end