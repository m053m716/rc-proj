if exist('xPC','var')==0
   load('xPC_struct.mat','xPC');
end

g = fieldnames(xPC);
for iG = 1:numel(g)
   a = fieldnames(xPC.(g{iG}));
   for iA = 1:numel(a)
      d = fieldnames(xPC.(g{iG}).(a{iA}));
      for iD = 1:numel(d)
         icms = fieldnames(xPC.(g{iG}).(a{iA}).(d{iD}));
         for iICMS = 1:numel(icms)
            inc = fieldnames(xPC.(g{iG}).(a{iA}).(d{iD}).(icms{iICMS}));
            for iInc = 1:numel(inc)
               name = sprintf('%s-%s %s %s %s',...
                  g{iG},a{iA},d{iD},icms{iICMS},inc{iInc});
               save_PCfreq_fig(xPC.(g{iG}).(a{iA}).(d{iD}).(icms{iICMS}).(inc{iInc}),name);            
               
            end
         end
      end
   end   
end



