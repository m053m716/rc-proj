function D = gross_output_table(n)
%GROSS_OUTPUT_TABLE Initializes "aggregate" output table for jPCA analyses
%
%  D = analyze.jPCA.gross_output_table();
%     -> Initializes empty table (n == 0)
%  D = analyze.jPCA.gross_output_table(n);
%     -> Initialize table with `n` rows
%
%  Inputs
%     n - Number of rows in table (default -- zero)
%     
%  Output
%     D - Output from jPCA analyses, in table format

if nargin < 1
   n = 0;
end

D = table('Size',[n,9],...
   'VariableType',[repmat({'string'},1,4),{'double'},repmat({'cell'},1,4)],...
   'VariableNames',...
      {'AnimalID','Alignment','Area','Group','PostOpDay',...
       'Data','Projection','Summary','PhaseData'});

end