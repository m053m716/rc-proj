function [y,lab] = makeLabels(panel,labels,varargin)
%% MAKELABELS  Make labels at equally spaced increments along left of panel
%
%  MAKELABELS(panel,labels)
%
%  --------
%   INPUTS
%  --------
%    panel     :     Uipanel object where the labels will go along the left
%                    side.
%
%    labels    :     Cell array of strings to use for the labels.
%
%   varargin   :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%     y        :     Y coordinate corresponding to each element of lab
%
%    lab       :     Label cell array
%
% By: Max Murphy  v1.0   08/08/2018    Original version (R2017b)

%% DEFAULTS
TOP_SPACING = 0.025;
BOT_SPACING = 0.025;

LEFT_SPACING = 0.025;
WIDTH = 0.45;

BACKGROUND_COL = 'k';
FOREGROUND_COL = 'w';
FONTSIZE = 14;
FONTNAME = 'Arial';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%%
n = numel(labels);
h = (1/n) - (TOP_SPACING + BOT_SPACING);
w = WIDTH;
x = LEFT_SPACING;
y = linspace(BOT_SPACING,1-TOP_SPACING-h,n);

%% CREATE LABELS
lab = cell(n,1);
for ii = 1:n
   lab{ii} = uicontrol(panel,'Style','text',...
            'Units','Normalized',...
            'FontName',FONTNAME,...
            'FontSize',FONTSIZE,...
            'BackgroundColor',BACKGROUND_COL,...
            'ForegroundColor',FOREGROUND_COL,...
            'Position',[x, y(ii), w, h],...
            'String',labels{ii});
end

end