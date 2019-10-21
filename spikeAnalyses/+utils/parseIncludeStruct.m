function includeStruct = parseIncludeStruct(outcome,pellet,reach,grasp,support,complete)
%% PARSEINCLUDESTRUCT   Parse include struct from weird format for setting cross condition mean using loops
%
%  includeStruct =
%  utils.PARSEINCLUDESTRUCT(outcome,pellet,reach,grasp,support,complete);
%     or
%  includeString = utils.PARSEINCLUDESTRUCT(includeStruct);

%%
if isstruct(outcome) % Opposite parsing
   includeStruct = outcome;
   str_out = [];   
   if ismember('Outcome',includeStruct.Include)
      str_out = [str_out 'Successful-'];
   elseif ismember('Outcome',includeStruct.Exclude)
      str_out = [str_out 'Unsuccessful-'];
   else
      str_out = [str_out 'AnyOutcome-'];
   end
   
   if ismember('PelletPresent',includeStruct.Include)
      str_out = [str_out 'PelletPresent-'];
   elseif ismember('PelletPresent',includeStruct.Exclude)
      str_out = [str_out 'PelletAbsent-'];
   else
      str_out = [str_out 'AnyPellet-'];
   end
   
   if ismember('Reach',includeStruct.Include)
      str_out = [str_out 'ReachPresent-'];
   elseif ismember('Reach',includeStruct.Exclude)
      str_out = [str_out 'ReachAbsent-'];
   else
      str_out = [str_out 'AnyReach-'];
   end
   
   if ismember('Grasp',includeStruct.Include)
      str_out = [str_out 'GraspPresent-'];
   elseif ismember('Grasp',includeStruct.Exclude)
      str_out = [str_out 'GraspAbsent-'];
   else
      str_out = [str_out 'AnyGrasp-'];
   end
   
   if ismember('Support',includeStruct.Include)
      str_out = [str_out 'SupportPresent-'];
   elseif ismember('Support',includeStruct.Exclude)
      str_out = [str_out 'SupportAbsent-'];
   else
      str_out = [str_out 'AnySupport-'];
   end
   
   if ismember('Complete',includeStruct.Include)
      str_out = [str_out 'Complete'];
   elseif ismember('Complete',includeStruct.Exclude)
      str_out = [str_out 'Incomplete'];
   else
      str_out = [str_out 'AnyCompletion'];
   end
   includeStruct = str_out;
else
   includeStruct = struct;
   includeStruct.Include = [];
   includeStruct.Exclude = [];

   switch outcome
      case 'Include'
         includeStruct.Include = [includeStruct.Include, {'Outcome'}];
      case 'Exclude'
         includeStruct.Exclude = [includeStruct.Exclude, {'Outcome'}];
   end

   switch pellet
      case 'Include'
         includeStruct.Include = [includeStruct.Include, {'PelletPresent'}];
      case 'Exclude'
         includeStruct.Exclude = [includeStruct.Exclude, {'PelletPresent'}];
   end

   switch reach
      case 'Include'
         includeStruct.Include = [includeStruct.Include, {'Reach'}];
      case 'Exclude'
         includeStruct.Exclude = [includeStruct.Exclude, {'Reach'}];
   end

   switch grasp
      case 'Include'
         includeStruct.Include = [includeStruct.Include, {'Grasp'}];
      case 'Exclude'
         includeStruct.Exclude = [includeStruct.Exclude, {'Grasp'}];
   end

   switch support
      case 'Include'
         includeStruct.Include = [includeStruct.Include, {'Support'}];
      case 'Exclude'
         includeStruct.Exclude = [includeStruct.Exclude, {'Support'}];
   end

   switch complete
      case 'Include'
         includeStruct.Include = [includeStruct.Include, {'Complete'}];
      case 'Exclude'
         includeStruct.Exclude = [includeStruct.Exclude, {'Complete'}];
   end
end


end