function [proj,zMu] = zeroCenterPoints(proj,izero,fApply,fGet)
%ZEROCENTERPOINTS  Ensures that element "zero_index" starts at 0
%
% [proj,zMu] = analyze.jPCA.zeroCenterPoints(proj,izero);
% [proj,zMu] = analyze.jPCA.zeroCenterPoints(proj,izero,fApply,fGet);
%
% Inputs
%  proj   - Array element from `Projection` struct array
%  izero  - Index corresponding to t==0
%  fApply - Cell array of fields to apply the normalization to. Must have
%              equal number of elements as `fGet`, the fields from which
%              the normalization values will be estimated.
%              -> Default (if unspecified):
%                      {'proj';
%                       'projAllTimes';
%                       'tradPCAproj';
%                       'tradPCAprojAllTimes'};
%  fGet   - Cell array of fields to use to get norm. Must have a matching
%              element for each element in `fApply`, the cell array specifying 
%              the fields to apply the norm to.
%              -> Default (if unspecified): 
%                       {'projAllTimes';
%                        'projAllTimes';
%                        'tradPCAprojAllTimes',
%                        'tradPCAprojAllTimes'};

if isstruct(proj)
   if nargin < 3
      fApply = {...
         'proj';
         'projAllTimes';
         'tradPCAproj';
         'tradPCAprojAllTimes'};
   end
   if nargin < 4
      fGet = {...
         'projAllTimes';
         'projAllTimes';
         'tradPCAprojAllTimes';
         'tradPCAprojAllTimes'};
   end
   
   if numel(fGet) ~= numel(fApply)
      error(['JPCA:' mfilename ':BadSyntax'],...
         ['\n\t->\t<strong>[ZEROCENTERPOINTS]:</strong> ' ...
          '`fGet` (%d) must have same number of elements ' ...
          ' as `fApply` (%d)\n'],numel(fGet),numel(fApply));
   end
   
   zMu = cell(numel(fApply),1);
   for iF = 1:numel(fApply)
      if isfield(proj,fApply{iF})
         [proj,zMu{iF}] = doNorm(proj,fApply{iF},fGet{iF},izero);
      else
         fprintf(1,'Missing field to norm: <strong>%s</strong>\n',fApply{iF});
      end
   end
else
   zMu = proj(zero_indx,:);
   proj = proj - repmat(zMu,size(proj,1),1);
end

   function [s,mu] = doNorm(s,field2norm,field4norm,zi)
      if isfield(s,field4norm)
         x = cat(3,s.(field2norm));
         y = cat(3,s.(field4norm));
         mu = mean(y,3);
         mu = mu(zi,:);
         x = x - repmat(mu,1,1,size(x,3));
         for iX = 1:size(x,3)
            s(iX).(field2norm) = x(:,:,iX);
         end
      else
         fprintf(1,'Missing field to get norm: %s\n',field4norm);
      end
   end

end