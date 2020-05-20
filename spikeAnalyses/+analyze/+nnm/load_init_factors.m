function h0 = load_init_factors(varargin)
%LOAD_INIT_FACTORS  Load initial factor coefficients guess
%
%  h0 = analyze.nnmf.load_init_factors();
%  -> Uses `defaults.files('nnmf_h0','nnmf_dir')` to load h0 guess
%
%  h0 = analyze.nnmf.load_init_factors(path);
%  -> Uses `defaults.files('nnmf_h0')` for filename
%
%  h0 = analyze.nnmf.load_init_factors(file);
%  -> Uses `defaults.files('nnmf_dir')` for path
%
%  h0 = analyze.nnmf.load_init_factors(path,file);
%  -> Specify filename explicitly
%
%  h0 = analyze.nnmf.load_init_factors(fullfilename);
%  -> Specify filename explicitly

if nargin == 0
   [nnmf_dir,nnmf_file] = defaults.files('nnmf_dir','nnmf_h0');
   f = fullfile(nnmf_dir,nnmf_file);
else
   fname = fullfile(varargin{:});
   [p,~,e] = fileparts(fname);
   if isempty(e)
      nnmf_file = defaults.files('nnmf_h0');
      f = fullfile(fname,nnmf_file);
   elseif isempty(p)
      nnmf_dir = defaults.files('nnmf_dir');
      f = fullfile(nnmf_dir,fname);
   else
      f = fname;
   end
end

in = load(f,'h0');
h0 = in.h0;

end