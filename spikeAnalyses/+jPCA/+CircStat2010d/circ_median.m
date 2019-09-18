function med = circ_median(alpha,dim)
%
% med = circ_median(alpha)
%   Computes the median direction for circular data.
%
%   Input:
%     alpha	sample of angles in radians
%     [dim  compute along this dimension, default is 1, must 
%           be either 1 or 2 for circ_median]
%
%   Output:
%     mu		mean direction
%
% PHB 3/19/2009
%
% References:
%   Biostatistical Analysis, J. H. Zar (26.6)
%
% Circular Statistics Toolbox for Matlab

% By Philipp Berens, 2009
% berens@tuebingen.mpg.de - www.kyb.mpg.de/~berens/circStat.html

if nargin < 2
  dim = 1;
end

M = size(alpha);
for i=1:M(3-dim)
  if dim == 2
    beta = alpha(i,:)';
  elseif dim ==1
    beta = alpha(:,i);
  else
    error('circ_median only works along first two dimensions')
  end
  
  beta = mod(beta,2*pi);
  n = size(beta,1);

  m1 = sum(jPCA.CircStat2010d.circ_dist2(beta,beta)>0,1);
  m2 = sum(jPCA.CircStat2010d.circ_dist2(beta,beta)<0,1);

  dm = abs(m1-m2);
  if mod(n,2)==1
    [m idx] = min(dm);
  else
    m = min(dm);
    idx = find(dm==m,2);
  end

  if m > 1
    warning('Ties detected.') %#ok<WNTAG>
  end

  md = jPCA.CircStat2010d.circ_mean(beta(idx));

  if abs(jPCA.CircStat2010d.circ_dist(jPCA.CircStat2010d.circ_mean(beta),md)) > abs(jPCA.CircStat2010d.circ_dist(jPCA.CircStat2010d.circ_mean(beta),md+pi))
    md = mod(md+pi,2*pi);
  end
  
  med(i) = md;
end

if dim == 2
  med = med';
end