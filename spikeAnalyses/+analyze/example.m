function T = example(T,nRow)
%EXAMPLE Returns random rows from table T (always includes first/last row)
%
%  T = analyze.example(T);
%  T = analyze.example(T,nRow);
%
% Inputs
%  T    - Some table of interest
%  nRow - (Optional; default: 5) Number of rows to return. Output table
%                                will always contain nRow+2 rows.
%
% Output
%  T    - Same as input but with reduced # rows
%
% See also: analyze.slice, analyze.stat

if nargin < 2
   nRow = 5;
end

lastRow = size(T,1);
T = T([1,lastRow,randi(lastRow,1,nRow)],:);

end