function [fig,S] = outcomes(S,varargin)
%OUTCOMES Plot scatters of the 4 outcome response variables across days
%
%  fig = analyze.behavior.outcomes(S);
%  [fig,S] = analyze.behavior.outcomes(S,'Name',value,...);
%
% Inputs
%  S        - Reduced rates table; see analyze.behavior.score for details
%  varargin - (Optional) <'Name',value> parameter pairs.
%
% Output
%  fig   -  Array of figure handles corresponding to response scatters
%           -> fig(1) : Total number of trials by day
%           -> fig(2) : Total number of successful trials by day
%           -> fig(3) : Total number of failed trials by day
%           -> fig(4) : Trial accuracy by day
%  S     - (Optional) Modified version of input table
%
% See also: analyze.behavior, analyze.behavior.score, behavior_timing.mlx

p = struct;
p.BatchIndex = 1:4; % Indexing vector for which responses to plot
p.FigParams = {...
      'Units','Normalized',...
      'Color','w'
   };
p.FigPosition = [...
   0.13 0.48 0.43 0.37 ; ....
   0.43 0.48 0.43 0.37 ; ...
   0.13 0.13 0.43 0.37 ; ...
   0.48 0.13 0.43 0.37 ...
   ];
                 
p.Response = [...
   "Total_Trials"; ...
   "Successful_Trials"; ...
   "Unsuccessful_Trials"; ...
   "Success_Rate" ...
   ];
p.Title = [ ...
	"Total Number of Retrieval Attempts: Day x Group"; ...
	"Total Number of Successful Retrievals: Day x Group"; ... 
	"Total Number of Unsuccessful Retrievals: Day x Group"; ...
	"Pellet Retrieval Success Rate: Day x Group" ...
];
p.YLim = [...
	0 400; ...
	0 50;  ...
	0 200; ...
	0 50   ...
];
pars = utils.parseParameters(p,varargin{:});

S.AnimalID = categorical(S.Rat);
S.BlockID = categorical(S.Name);
S.Total_Trials = S.N;
S.Successful_Trials = round(S.N .* S.Score);
S.Unsuccessful_Trials = S.Total_Trials - S.Successful_Trials;
S.Success_Rate = S.Score * 100;

scoreIdx = find(...
   strcmpi(S.Properties.VariableNames,'Success_Rate'), ...
   1,'first');
S.Properties.VariableUnits{scoreIdx} = '%';

n = size(S,1);
S.Properties.RowNames = strcat(...
   string(strrep(S.Rat,'-','')),repmat("_",n,1),string(S.PostOpDay));

fig = gobjects(numel(pars.Response),1);
vec = 1:numel(pars.Response);

for ii = vec(pars.BatchIndex)
   fig(ii,1) = ...
      analyze.behavior.blocks(...
         S,pars.Response(ii),...
         'YLim',pars.YLim(ii,:),...
         'Title',pars.Title(ii),...
         'FigParams',pars.FigParams,...
         'FigPosition',pars.FigPosition(ii,:) ...
         );
end


end