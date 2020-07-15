function pars = parseParameters(p,varargin)
%PARSEPARAMETERS Utility to parse <'Name', value> parameter pairs
%
%  pars = utils.parseParameters(p);
%  -> Simply returns pars as p
%
%  pars = utils.parseParameters(p,newPars);
%  -> Replaces struct `p` with new parameters struct, `newPars`
%
%  pars = utils.parseParameters(p,'Name1',val1,...,'NameK',valK);
%  -> Update parameters 1-K with values in variables val1 - valK
%
%  pars = utils.parseParameters(p,newPars,'Name1',val1,...);
%  -> Gets fieldnames from default parameter struct (p), replaces `p` with
%     `newPars`, then matches and adds any (case-insensitive) field name
%     matches from the <'Name',value> pairs as an updated field of
%     `newPars` which is then returned as `pars`.
%
% Inputs
%  p        - Default parameters struct
%  varargin - Optional <'Name',value> pairs.
%              -> Values of the original are updated by any matched 'Name'
%                 (case-insensitive) corresponding value.
%              -> If the first element is a struct, then `p` is replaced by
%                 that element, but the original (default) field names are
%                 used for matching and upating the fields of the new
%                 (replaced) parameters struct.
%
% Output
%  pars     - Parameters struct after parsing optional inputs
%
% See also: utils, utils.parseParams

if numel(varargin) > 0
   if isstruct(varargin{1})
      p = varargin{1};
      varargin(1) = [];
   end
end

fn = fieldnames(p);

for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      p.(fn{idx}) = varargin{iV+1};
   end   
end

pars = p;

end