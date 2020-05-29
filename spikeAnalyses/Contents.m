% SPIKEANALYSES All analyses in RC-Project related to spiking data
% MATLAB Version 9.7 (R2019b Update 5) 28-May-2020
%
% Analytical workflow was as follows:
%  0. Apply pre-processing and spike detection (beyond scope of this
%       repository; see `CPLTools` sub-folders `MoveData_Isilon` and `_SD`)
%  1. Score videos for behavioral outcomes and trial metadata
%        * See scripts in <a href="matlab:cd('../videoAnalyses'); help('Contents.m');"> videoAnalyses</a> sub-folder.
%  2. Aggregate extracted data and metadata using object-oriented
%        hierarchical structure: from lowest (most-granular) to highest,
%        this is ordered as
%        * <a href="matlab:doc block/Contents">block</a> class object
%        * <a href="matlab:doc rat/Contents">rat</a> class object
%        * <a href="matlab:doc group/Contents">group</a> class object
%  3. Curate and extract analytical endpoints (e.g. spike rates) using the
%     object-oriented custom class hierarchy here. Similarly, these were
%     initially used to apply analyses but that part eventually got shifted
%     over to:
%  4. Export data into "Table" format so it will be compatible with other
%     analytical or visualization tools (external to Matlab). Since these
%     tools (such as Tableau) are convenient and produce nice graphics that
%     are dynamic in terms of parameter selection, some endpoint
%     figures/graphics are produced that way. Therefore, final data
%     analyses were conducted with the data in <strong>Table</strong>
%     format.
%  5. To that end, analysis pipelines for any analyses that were
%     "downstream" of rate estimation are contained in <strong>packages</strong>, primarily 
%     residing in <strong>+analyze</strong>. See individual <a href="matlab:help analyze">sub-packages</a> for more details.
%
% <strong>Classes</strong> (used to initially aggregate & curate data)
%  block                   - organizes all data from a single recording in RC project
%  rat                     - organizes all data from an individual rat in RC project
%  group                   - organizes all data from an experimental group in RC project
%
% Helper Functions (usually not referenced directly)
%  applyTransform          - Applies rate smoothing if not yet applied
%  channelInfo2channelMask - Helper function to infer channel mask from info
%  construct_gData_array   - gData = construct_gData_array(RAT,skip_save);
%  disc_rat                - Rational approximation (TO REPLACE CONFLICT WITH "RAT" CLASS)
%  fastsmooth              - Method for smoothing data
%  getColorMap             - Helper function to return CubeHelix colormap
%  parsePostOpDate         - Sub-function to get recording date from name
%  parseStruct             - Parse struct based on expression in field_expr (e.g. 'structname.field1.field2')
%
% <strong>Packages</strong> (contain most analytical export pipelines)
%  analyze                 - Package for analyses of spike data
%  cb                      - Package for miscellaneous callback functions
%  defaults                - Package with parameter defaults files
%  local                   - Package for local parameter configurations (to avoid `git` conflicts by adding it to `.gitignore`)
%  make                    - Package for making tables and figures
%  utils                   - Package containing basic utility functions for ad hoc purposes
%  write                   - Package for writing data from different pipelines to disk files
%
% <strong>Scripts</strong> (used as code workflow outlines)
%  main                    - Main code for initializing and running analyses <strong>START HERE</strong>
%  <a href="matlab:opentoline('marg.mlx',1,1);">marg</a>                    - <strong>MATLAB Live Script</strong> demonstrating Population-Dynamics analysis applied to marginalized spike rate data