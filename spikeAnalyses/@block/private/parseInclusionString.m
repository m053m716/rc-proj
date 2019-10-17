function idx = parseInclusionString(b,includeString)
%% PARSEINCLUSIONSTRING    Recursively parse inclusion string
EXPR = '(?<Var>\w+)(?<Delim>\W)';

str = strsplit(includeString,'(');
if numel(str) > 1 % Parse parentheticals first
   for ii = 1:numel(str)
      idx = parseInclusionString(b,str{ii});
   end
   
else % Only reaches this once fully inside a parenthetical
   if strcmp(includeString(1),'~') % Negate is the only "leading" delimiter currently
      [tmp,k] = regexp(includeString(2:end),EXPR,'names','end');
      if isempty(tmp)
         idx = ~b.(includeString(2:end));
      else
         for ii = 1:numel(tmp)
            switch tmp(ii).Delim
               case '&'
                  idx = ~b.(tmp.Var) & ...
                     parseInclusionString(b,includeString((k(ii)+1):end));
               case '|'
                  idx = ~b.(tmp.Var) | ...
                     parseInclusionString(b,includeString((k(ii)+1):end));
               case '^'
                  idx = xor(~b.(tmp.Var), ...
                     parseInclusionString(b,includeString((k(ii)+1):end)));
               otherwise
                  error('Unrecognized delimiter (%s) or bad syntax: %s',tmp(ii).Delim,includeString);
            end
             
         end
      end
   else % Otherwise, do not negate
      [tmp,k] = regexp(includeString(2:end),EXPR,'names','end');
      if isempty(tmp)
         idx = b.(includeString(2:end));
      else
         for ii = 1:numel(tmp)
            switch tmp(ii).Delim
               case '&'
                  idx = b.(tmp.Var) & ...
                     parseInclusionString(b,includeString((k(ii)+1):end));
               case '|'
                  idx = b.(tmp.Var) | ...
                     parseInclusionString(b,includeString((k(ii)+1):end));
               case '^'
                  idx = xor(b.(tmp.Var), ...
                     parseInclusionString(b,includeString((k(ii)+1):end)));
               otherwise
                  error('Unrecognized delimiter (%s) or bad syntax: %s',tmp(ii).Delim,includeString);
            end
             
         end
      end
      
   end
end