function X = get_subset(T)
%GET_SUBSET  Gets subset of T (uses `analyze.complete.get_subset`)
%
%  X = analyze.nullspace.get_subset(T);
%
%  -- Inputs --
%  T : Full rate table from `T = getRateTable(gData);`
%
%  -- Output --
%  X : Table to use for nullspace analyses (same as T, but includes
%        'Duration' column and a few additional UserData properties). 
%
%  See also: analyze.complete.get_subset

X = analyze.complete.get_subset(T);
end