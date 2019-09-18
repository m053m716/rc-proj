function Short_ICMS = getICMScode(Full_ICMS,varargin)
%% GETICMSCODE   Get a condensed code representation of ICMS area
%
%  Short_ICMS = GETICMSCODE(Full_ICMS)
%
%  --------
%   INPUTS
%  --------
%  Full_ICMS      :     Cell array, where each array element is a character
%                       vector describing the ICMS-elicited response in the
%                       territory closest to that recording shank.
%
%  varargin       :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Short_ICMS     :     Cell array with same number of elements as
%                       Full_ICMS, but with shorter names for all the
%                       different elicited responses.
%
% By: Max Murphy  v1.0  03/19/2018  Original version (R2017b)

%% DEFAULTS
CODE = {'Distal Forelimb', 'DF'; ...
        'Proximal Forelimb', 'PF'; ...
        'No Response', 'NR'};
     
DEFAULT = 'O';
DELIM = '-';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% LOOP THROUGH AND CONVERT
Short_ICMS = cell(size(Full_ICMS));
for ii = 1:numel(Full_ICMS)
   Short_ICMS{ii} = cell(size(CODE,1),1);
   for ik = 1:size(CODE,1)
      if contains(Full_ICMS{ii},CODE{ik,1})
         Short_ICMS{ii}{ik} = CODE{ik,2};
      end
   end
   
   idx = ~cellfun(@isempty,Short_ICMS{ii});
   if sum(idx)<1
      Short_ICMS{ii} = DEFAULT;
   else
      wvec = sort(Short_ICMS{ii}(logical(idx)));
      Short_ICMS{ii} = strjoin(wvec,DELIM);
   end
      
end


end