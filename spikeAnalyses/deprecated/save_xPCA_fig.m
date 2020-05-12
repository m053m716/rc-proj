function save_xPCA_fig(fig,name,dest_folder)
%% SAVE_XPCA_FIG     save_xPCA_fig(fig,name,folder); % Export xPCA figs
%
%  SAVE_XPCA_FIG(name); % Uses current figure, saves using 'name' (do not
%                       %     file extension)
%
%  SAVE_XPCA_FIG(fig,name); % Specify figure handle and save name
%
%  SAVE_XPCA_FIG(fig,name,dest_folder); % Specifies output path (makes sure
%                                       %    it is a valid path first; 
%                                       %    if not, then the folder is 
%                                       %    created)

%% PARSE INPUT
if nargin < 3
   if isa(fig,'matlab.ui.Figure')
      dest_folder = defaults.image_export('folder');
   else
      dest_folder = name;
      name = fig;
      fig = gcf; % Input was just the name and folder, not figure handle
   end
end

if nargin < 2
   if ~ischar(fig)
      error('If only 1 input, argument must be name');
   else
      name = fig;
      fig = gcf;
   end
end

%% CLEAR OTHER FIGS (IF FIG IS ARRAY)
for i = 2:numel(fig)
   if isvalid(fig(i))
      delete(fig(i));
   end
end

%% MAKE PATH (IF DOESN'T EXIST)
if exist(dest_folder,'dir')==0
   mkdir(dest_folder);
   fprintf(1,'-->\tMade new path:\n');
   fprintf(1,'\t-->\t%s\n\n',dest_folder);
end

%% SAVE VERSIONS
fprintf(1,'\t\t-->\tSaving %s...',name);
figure(fig(1)); % Set current figure to correct one
savefig(fig(1),fullfile(dest_folder,[name '.fig']));
saveas(fig(1),fullfile(dest_folder,[name '.png']));
expAI(fig(1),fullfile(dest_folder,name));
fprintf(1,'complete\n');

%% REMOVE FIGURE
delete(fig(1));

end