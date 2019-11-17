function param = image_export(name)
%% IMAGE_EXPORT   param = defaults.image_export('paramName');

%%
p = struct;
p.folder = 'G:\Lab Member Folders\Max Murphy\Writing\_MANUSCRIPTS\2019-11-12_RC_Nat-Comms\Figures';

%%
if nargin < 1
   param = p;
   return;
end

if ismember(name,fieldnames(p))
   param = p.(name);
else
   error('%s is not a valid parameter. Check spelling?',name);
end

end