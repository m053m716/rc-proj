function D = tab2cohensd(T)
%TAB2COHENSD Convert weekly comparisons to Cohen's-d for post-hoc tests
%
%  D = utils.tab2cohensd(T);
%
% Inputs
%  T - Table with variables: ["GroupID","Area","Week","Spikes","SD","N"]
%  
% Output
%  D - Table with variables: ["Area","Week","d"]
%
% Where "d" is Cohen's d that compares matched weekly observations using
% GroupID.
%
% See also: Contents

[G,D] = findgroups(T(:,{'Area','Week'}));
D.d = splitapply(@(g,m,s,n)computeEffect(g,m,s,n),T.GroupID,T.Spikes,T.SD,T.N,G);

   function d = computeEffect(g,m,s,n)
      %COMPUTEEFFECT Compute Cohen's d effect size
      %
      % d = computeEffect(g,m,s,n);
      %
      % Inputs:
      %  g - Sample groupings (2 elements)
      %  m - Sample means (2 elements)
      %  s - Sample standard deviations (2 elements)
      %  n - Number of samples (2 elements)
      %
      % Output:
      %  d - Cohen's d estimate for effect size comparing weekly trends by
      %        group for post-hoc analysis
      
      TREATMENT = "Ischemia";
      iT = g==TREATMENT;
      iC = ~iT;
      
      % Treated and Control sample means
      m_t = m(iT);
      m_c = m(iC);
      % Treated and Control sample standard deviations
      s_t = s(iT);
      s_c = s(iC);
      % Number of Treated and Control samples (Animals!)
      n_t = n(iT);
      n_c = n(iC);
      % Pooled standard deviation
      s_p = sqrt(((n_t-1).*s_t.^2 + (n_c-1).*s_c.^2)./(n_t + n_c));
      
      % Typically reported as absolute value
      d = abs((m_t - m_c) ./ s_p);
      
   end

end