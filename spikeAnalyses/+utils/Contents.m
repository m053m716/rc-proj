% UTILS - Package containing basic utility functions for ad hoc purposes
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
% Functions
%   addHelperRepos         - Adds all fields of paths to Matlab search path
%   addSlicing             - Add 'Slicing' field to UserData struct table property or append to existing 'Slicing' list
%   addStructField         - Add field(s) to an existing struct.
%	 addProcessing 		   - Add 'Processing' field to UserData struct table property or append to existing 'Processing' list
%   check_table_type       - Return char indicating "type" of data table
%   doPCAreconstruction    - Y = utils.doPCAreconstruction(score,coeff,mu);
%   doTrialPCA             - Do PCA where rows are channels and columns are concatenated time-series
%   filterByNTrials        - Get subset of T based on minimum `N` trials by `BlockID`
%   get_first_n_rows       - Samples first `n` rows for a given Table "split"
%   getCrossCondKeyCombos  - Returns key cross-condition combinations
%   getFirstNonEmptyCell   - out = utils.getFirstNonEmptyCell(in);
%   getParamField          - f = utlis.getParamField(p,'paramName');
%   initCellArray          - [var1,var2,...] = utils.initCellArray(dim1,dim2,...);
%   initDataArray          - [var1,var2,...] = utils.initDataArray(dim1,dim2,...);
%   initEmpty              - [var1,var2,...] = utils.initEmpty; % Initialize empty array
%   initFalseArray         - [var1,var2,...] = utils.initFalseArray(dim1,dim2,...); 
%   initNaNArray           - [var1,var2,...] = utils.initNaNArray(dim1,dim2,...);
%   initOnesArray          - [var1,var2,...] = utils.initOnesArray(dim1,dim2,...);
%   initTrueArray          - [var1,var2,...] = utils.initTrueArray(dim1,dim2,...); 
%   initZerosArray         - [var1,var2,...] = utils.initZerosArray(dim1,dim2,...);
%   load_ratskull_plot_img - utils.load_ratskull_plot_img;
%   makeIncludeStruct      - Make "include" struct for GETRATE method of BLOCK
%   mtb                    - Move variable to base workspace
%   name2numeric_id        - Convert categorical name to numeric ID
%   parseIncludeStruct     - Parse include struct from weird format for setting cross condition mean using loops
%   parseParams            - p = utils.parseParams(cfg_key,arg_pairs);
%   plotPCAreconstruction  - fig = utils.plotPCAreconstruction(xPC);
%   remove_cols            - Simple function checks for a variable column & removes it
%   screencapture          - screencapture - get a screen-capture of a figure frame, component handle, or screen area rectangle
%   setParamField          - p = utils.setParamField(p,'paramName',paramValue);