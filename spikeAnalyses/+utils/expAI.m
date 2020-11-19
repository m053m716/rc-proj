function [fig,outputname] = expAI(fig,filename,varargin)
%EXPAI export figure in appropriate format for Adobe Illustrator
%
%  fig = utils.expAI; % Grab current figure and export with default name
%  fig = utils.expAI(filename); % Grab current figure, export given name
%  fig = utils.expAI(fig);      % Export specific figure, default name
%  fig = utils.expAI(fig,filename); % Export specific figure, given name
%  fig = utils.expAI(fig,filename,pars); % Give parameters struct directly
%  fig = utils.expAI(fig,filename,'Name',value,...); % Modify specific pars
%  fig = utils.expAI(fig,filename,pars,'Name',value,...); % etc
%  [fig, outputname] = ...
%
%  -- Inputs --
%  fig : Handle to the figure you wish to export.
%
%  filename : String with output filename (and extension) of figure
%              to export for Adobe Illustrator.
%
%  varargin : Can pass directly as parameters struct output by 
%              >> pars = p__.defs.Exporting_To_IllustratorOptional;
%
%             + Uses <'Name', value> input argument pairs to modify fields
%                of that struct regardless of whether it is provided as an
%                input option.
%
%  -- Output --
%  fig : Handle to exported figure, with modifications.
%
%  outputname : (Optional) Full filename of exported figure.
%
%  Generates a vector graphics file for Adobe Illustrator or comparable
%  image manipulation software. Name of file is given by second output
%  (`outputname`).

% Parse parameters
pars = struct;

% Default filename
pars.DefaultName = ['Matlab_Vector_Graphics_Export_' ...
   datestr(datetime,'YYYY-mm-dd')];

%Boolean options
pars.AutoFormat = struct(...
   'Font',false,    ...     % Automatically reconfigure axes fonts
   'Figure',false,  ...     % Automatically reconfigure figure properties
   'Filename',false,...     % Automatically fix filename
   'Axes',false     ...     % Automatically reconfigure axes properties
   );

%Figure property modifiers
pars.FontName = 'Arial';                 %Set font name (if FORMATFONT true)
pars.FontSize = 16;                      %Set font size (if FORMATFONT true)

%Print function modifiers
pars.FormatType = '-depsc2';               % EPS Level 3 Color
% pars.FormatType  = '-dpsc2';             % Vector output format
% pars.FormatType = '-dpdf';               % Full-page PDF
% pars.FormatType = '-dsvg';               % Scaleable vector graphics format
% pars.FormatType = '-dpsc';               % Level 3 full-page PostScript, color
% pars.FormatType = '-dmeta';              % Enhanced Metafile (WINDOWS ONLY)
% pars.FormatType = '-dtiffn';             % TIFF 24-bit (not compressed)
pars.UIOpt       = '-noui';              % Excludes UI controls
% pars.FormatOpt   = {'-cmyk'};              % Format options for color
pars.FormatOpt   = {'-loose'};             % Use loose bounding box
% pars.FormatOpt = {'-cmyk','-loose','-tiff'}; % Uses all options in cell ('-tiff' shows preview; eps, ps only)
pars.Renderer    = '-painters';          % Graphics renderer
% pars.Resize = '';
% pars.Resize      = '-fillpage';        % Alters aspect ratio
pars.Resize      = '-bestfit';         % Choose best fit to page
pars.Resolution  = '-r600';              % Specify dots per inch (resolution)
pars.ClassIgnoreList = {...   % List of "bad" child classes to skip setting fonts
   'matlab.ui.container.Menu'; ...
   'matlab.ui.container.Toolbar'; ...
   'matlab.ui.container.ContextMenu'; ...
   'matlab.graphics.illustration.Legend' ...
   };

% Parse second input
if nargin < 2
   if ~hasFileName
      % Put export in current directory
      filename = fullfile(pwd,pars.DefaultName);
   end
end

fn = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
   end
end

% Ensure filename has correct extension
[p,f,ext] = fileparts(filename);

% Make sure that it goes in current directory if no full path specified
if isempty(p)
   p = pwd;
end

% Make sure the extension matches the specified formatting
if (pars.AutoFormat.Filename) || isempty(ext)
   if strcmp(pars.FormatType, '-dtiffn')
      ext = '.tif';
   elseif strcmp(pars.FormatType, '-dpsc2')
      ext = '.ps';
   elseif strcmp(pars.FormatType, '-dsvg')
      ext = '.svg';
   elseif strcmp(pars.FormatType, '-dpdf')
      ext = '.pdf';
   elseif strcmp(pars.FormatType, '-depsc')
      ext = '.eps';
   else
      ext = '.ai';
   end
end
outputname = fullfile(p,[f ext]);

% Modify figure parameters
if pars.AutoFormat.Figure
   set(gcf, 'Renderer', pars.Renderer(2:end));
end

% Modify font parameters
if pars.AutoFormat.Font
   c = get(gcf, 'Children');
   for iC = 1:numel(c)
      if ~ismember(class(c(iC)),pars.ClassIgnoreList)
         set(c(iC),'FontName',pars.FontName);
         set(c(iC),'FontSize',pars.FontSize);
         if isa(c(iC),'matlab.graphics.axis.Axes') && pars.AutoFormat.Axes
            xl = get(c(iC),'XLabel');
            set(xl,'FontName',pars.FontName);
            yl = get(c(iC),'YLabel');
            set(yl,'FontName',pars.FontName);
            t = get(c(iC),'Title');
            set(t,'FontName',pars.FontName);
            set(t,'FontSize',pars.FontSize);
            set(c(iC),'LineWidth',max(c(iC).LineWidth,1));
         end
      end
   end
end

% OUTPUT CONVERTED FIGURE
test = ver;
idx = ismember({test.Name},'MATLAB');
if str2double(test(idx).Version) >= 9.7 % Matlab ver R2019b
   print(fig,          ...
         outputname,   ...
         pars.FormatType,   ...
         pars.FormatOpt{:},    ...
         pars.Renderer);
else
   if isempty(pars.Resize)
      print(pars.UIOpt,        ...
         pars.Resolution,   ...
         fig,          ...
         pars.FormatType,   ...
         pars.FormatOpt{:},    ...
         pars.Renderer,     ...
         outputname);
   else
      print(pars.UIOpt,        ...
         pars.Resolution,   ...
         fig,          ...
         pars.Resize,       ...
         pars.FormatType,   ...
         pars.FormatOpt{:},    ...
         pars.Renderer,     ...
         outputname);
   end
end

% Update UserData property of figure handle to flag that figure has been
% exported already for Vector Graphics, and associate the `outputname` with
% the actual figure as well.
if isempty(fig.UserData)
   fig.UserData = struct;
   fig.UserData.VectorGraphicsExported = true;
   fig.UserData.VectorGraphicsName = outputname;
elseif isstruct(fig.UserData)
   fig.UserData.VectorGraphicsExported = true;
   fig.UserData.VectorGraphicsName = outputname;
end

end