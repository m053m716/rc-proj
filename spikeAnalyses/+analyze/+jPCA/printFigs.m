function printFigs(figNums,folderName,format,fileTitle)
%PRINTFIGS Export vectorized figures for insertion to other documents etc
%
% printFigs(figNums);
% printFigs(figNums,folderName);
% printFigs(figNums,folderName,format);
% printFigs(figNums,folderName,format,fileTitle);
%
% Inputs
%  figNums - Scalar integer or vector of figure numbers (e.g., 1:10)
%  folderName - (Optional) Char array of output file folder location
%     -> If it does not exist, the folder is created.
%  format - (Optional) Char array of output format. Default is '-dpdf'
%               You can also use any of the following options:
%                 * '-depsc2' (postscript lv 2)
%                 * '-djpeg'
%                 * '-dill' (ai)
%                 * '-dtiff'
%  fileTitle - (Optional) Char array of file to output
%     -> If not specified, default is 'Figure' (if multiple `figNums` then
%        the number is appended to each)
%
% Examples:
%   printFigs(1:16, '')
%     * prints 16 pdf files into the current directory
%   printFigs(1:16, 'printedFigures2')
%     * puts the files in the directory printedFigures2
%        -> (created if necessary)
%   printFigs(1:16, '', '-djpeg')
%     * output as jpeg into the current directory
%   printFigs(2, 'printedFigures2', '-dpdf', 'myFig');
%     * prints fig 2 as a single pdf named 'myFig' into the folder
%       'printedFigures2'.

% Parse input
if nargin < 2
   folderName = pwd;
end

if nargin < 3
   format = '-dpdf';
end

if nargin < 4
   fileTitle = 'Figure';
end

% default file format is encapsulated postscript level 2
if ~exist('format', 'var')
   format = '-dpdf';
end

if ~isempty(folderName)
   if ~isfolder(folderName)
      fprintf('making folder %s\n', folderName);
      mkdir(folderName);
   end
end

% fprintf('printing as %s\n', format(3:end));
for f = 1:length(figNums)
   thisFig = figNums(f);
   if iscell(fileTitle)
      fThis = fileTitle{f};
   elseif isscalar(figNums)
      fThis = fileTitle;
   else
      fThis = sprintf('%s_%02d',fileTitle,thisFig);
   end
   thisVersion = 0;
   fname = sprintf('%s_v%02g',fThis,thisVersion);
   F = dir(fullfile(folderName,[fname '.*']));
   while ~isempty(F)
      thisVersion = thisVersion + 1;
      fname = sprintf('%s_v%02g',fThis,thisVersion);
      F = dir(fullfile(folderName,[fname '.*']));
   end
   
   filename = fullfile(folderName,fname);
   fprintf(1,...
      ['\t->\tPrinting ' ...
      '<a href="matlab:winopen(''%s'');"><strong>%s</strong></a>'...
      'as %s...'],folderName,fname,format(3:end));
   
   figure(figNums(f));  % make current
   print(format, '-r300', [filename '.pdf']);
   saveas(figure(figNums(f)),[filename '.png']);
   delete(figure(figNums(f))); % close the figure
   fprintf(1,'complete\n');
end

end