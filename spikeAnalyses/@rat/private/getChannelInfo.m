function channelInfo = getChannelInfo(ratName,icms_datafile)
%GETCHANNELINFO Import information about each microwire channel for a rat
%
%   channelInfo = GETCHANNELINFO(ratName);

%% Initialize variables.
if nargin < 2
   icms_datafile = defaults.files('icms_data_name');
end

%% Read channel info from ICMS data spreadsheet
[~,txt,~] = xlsread(icms_datafile,ratName);

%% Create output struct
L_ICMS = txt(7:end,2);
R_ICMS = txt(7:end,3);

[l_icms,l_ml,l_area] = getICMScode(L_ICMS,'Left',txt{2,2});
[r_icms,r_ml,r_area] = getICMScode(R_ICMS,'Right',txt{2,3});

if strcmp(txt{4,2},'A')
   icms = [l_icms;r_icms];
   ml = [l_ml;r_ml];
   area = [l_area;r_area];
else
   icms = [r_icms;l_icms];
   ml = [r_ml;l_ml];
   area = [r_area;l_area];
end

probe = ones(32,1);
probe(17:32) = 2;
probe = num2cell(probe);


channel = [1:16,1:16].';
channel = num2cell(channel);

channelInfo = struct(...
   'probe',probe,...
   'channel',channel,...
   'ml',ml,...
   'icms',icms,...
   'area',area);

   function [Short_ICMS,Mediolateral,Area_out] = getICMScode(Full_ICMS,Side,Area_in)
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

   Mediolateral = cellfun(@(x) {x(1)},Full_ICMS);

   Area_out = sprintf('%s%s%s',Side,DELIM,Area_in);
   Area_out = repmat({Area_out},numel(Mediolateral),1);

   end


end
