function id = name2numeric_id(name)
%NAME2NUMERIC_ID  Convert categorical name to numeric ID
%
%  id = utils.name2numeric_id(name);

if iscell(name)
   id = cellfun(@(C)utils.name2numeric_id(C),name);
   return;
end

if iscategorical(name)
   id = arrayfun(@(C)utils.name2numeric_id(char(C)),name);
   return;
end

id = strsplit(name,'-');
id = str2double(id{end});

end