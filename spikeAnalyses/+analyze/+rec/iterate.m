function varargout = iterate(fcn,T,varargin)
%ITERATE  Iterate a function on individual recording blocks
%
%  varargout = analyze.rec.iterate(fcn,T,varargin);
%
%  -- Inputs --
%  fcn : Function handle to iterate on all blocks.
%  T   : Data table. Should have the variable 'BlockID' for `iterate` to
%           work properly.
%  varargin : Any other arguments required by `fcn`
%
%  -- Output --
%  varargout : Any outputs returned by `fcn`. Results are concatenated
%                 vertically for each iterated recording.

uBlock = unique(T.BlockID);
nBlock = numel(uBlock);
nArgOut = nargout(fcn);
varargout = cell(1,nArgOut);
if nBlock > 1
   argOut = cell(1,nArgOut);
   for iBlock = 1:nBlock
      iThis = T.BlockID==uBlock(iBlock);
      [argOut{iBlock,:}] = analyze.rec.iterate(fcn,T(iThis,:),varargin{:});
   end
   for iArgOut = 1:nArgOut
      varargout{1,iArgOut} = vertcat(argOut{:,iArgOut});
   end
   return;
end

[varargout{:}] = feval(fcn,T,varargin{:});
end