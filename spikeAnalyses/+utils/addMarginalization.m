function T = addMarginalization(T,grouping,MID,mu)
%ADDMARGINALIZATION  Add 'Marginalization' field to UserData struct table property or append to existing 'Marginalization' list
%
% T = utils.addMarginalization(T,grouping,MID,mu)
%
% Inputs
%  T - Data table
%  grouping - Cell array of "grouping" variables used in marginalization
%  MID - Table where rows represent the values of each grouping
%  mu - Means corresponding to rows of MID, the groupings
%
% Output
%  T - Same as input but with updated 'Slicing' field of UserData struct property

if ~isstruct(T.Properties.UserData)
   T.Properties.UserData = struct;
end

if isfield(T.Properties.UserData,'Marginalization')
   T.Properties.UserData.Marginalization(end+1,1) = addValue(grouping,MID,mu);
else
   T.Properties.UserData.Marginalization = addValue(grouping,MID,mu);
end

   function marg_array = addValue(grouping,MID,mu)
      %ADDVALUE Add value to marginalizations array tracking struct
      %
      %  marg_array = addValue(sVar,sVal);
      marg_array = struct('grouping',[],'MID',[],'mu',[]);
      marg_array.grouping = grouping;
      marg_array.MID = MID;
      marg_array.mu = mu;
   end

end