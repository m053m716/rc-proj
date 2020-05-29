function out = minusPi2Pi(in)
%MINUSPI2PI Return value in range [-pi,pi]
%
% out = analyze.jPCA.minusPi2Pi(in);
%
% Inputs
%  in - Numeric data (scalar, vector, matrix)
%        -> For example, if computing phase and want to stay in range -pi
%              to pi, this is helpful.
% 
% Output
%  out - Same dimensions as in, but scaled between [-pi, pi]

out = atan2(sin(in), cos(in));
end