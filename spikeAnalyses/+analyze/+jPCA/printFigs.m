% useage:
%   printFigs(figNums, folderName)
%   printFigs(figNums, folderName, format)
%   printFigs(figNums, folderName, format, fileTitle)
%
%   figNums is just a list of the figure numbers (e.g., 1:10)
%   if folderName doesn't exist, it will be created, and you will be told
%
%   'format' is optional.  The default is '-dpdf'.
%   You can also use '-depsc2' (postscript lv 2), '-djpeg', '-dill' (ai), '-dtiff', 
%
% examples:
%   printFigs(1:16, '')     prints 16 pdf files into the current directory
%   printFigs(1:16, 'printedFigures2')   puts the files in the directory printedFigures2 (created if necessary)
%   printFigs(1:16, '', '-djpeg')  output as jpeg into the current directory
%   printFigs(2, 'printedFigures2', '-dpdf', 'myFig');  prints fig 2 as a single pdf named 'myFig' into 
%           % the folder 'printedFigures2'.  Note that the fig number should be a scalar.
%   
function printFigs(figNums, folderName, format, fileTitle)

% default file format is encapsulated postscript level 2
if ~exist('format', 'var')
   format = '-dpdf'; 
end

if ~isempty(folderName)
    if ~isdir(folderName)
        fprintf('making folder %s\n', folderName);
        mkdir(folderName);
    end
    folderName = strcat(folderName, '/');
end

% fprintf('printing as %s\n', format(3:end));
for f = 1:length(figNums)
    if exist('fileTitle', 'var')
       if iscell(fileTitle)
          filename = fullfile(folderName,fileTitle{f});
       else
          filename = fullfile(folderName,fileTitle);
       end
    else
        filename = fullfile(folderName,sprintf('figure%d',figNums(f)));
    end
    
    thisVersion = 0;
    while exist([filename '_v' num2str(thisVersion,'%02g') '.pdf'],'file')~=0
       thisVersion = thisVersion + 1;
    end
    fname = [filename '_v' num2str(thisVersion,'%02g')];
    
    figure(figNums(f));  % make current
    print(format, '-r300', [fname '.pdf']);
    saveas(figure(figNums(f)),[fname '.png']);
    delete(figure(figNums(f))); % close the figure
end