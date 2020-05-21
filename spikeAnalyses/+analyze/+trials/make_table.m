function Y = make_table(X,event,outcome)
%MAKE_TABLE  Create table where each row represents a trial.
%
%  Y = analyze.trials.make_table(X,event,outcome);
%
%  -- Inputs --
%  X : Table with rate data, such as returned by 
%        ```
%           gData = group.loadGroupData;
%           T = getRateTable(gData);
%           X = analyze.nullspace.get_subset(T);
%        ```
%  event : Name of alignment for trials to include.
%  outcome : char or cell array of outcomes to include.

x = analyze.slice(X,'Alignment',event,'Outcome',outcome);
[G,Y] = findgroups(X(:,'Trial_ID'));
Rate = splitapply(@(rates){rates},x.Rate,G);


end