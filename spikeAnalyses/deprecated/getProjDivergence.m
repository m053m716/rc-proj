function [Td,S,Cs] = getProjDivergence(J,planeNum,rowNum)
%% GETPROJDIVERGENCE    Get divergence (similar to PLOTPROJ3D) stats
%
%  [Td,S,Cs] = GETPROJDIVERGENCE(J);
%  [Td,S,Cs] = GETPROJDIVERGENCE(J,planeNum);
%  [Td,S,Cs] = GETPROJDIVERGENCE(J,planeNum,rowNum);
%
%  --------
%   INPUTS
%  --------
%     J        :     Table returned by GETJPCA method of GROUP class.
%
%  planeNum    :     jPCA plane (1, 2, or 3) index to evaluate.
%
%   rowNum     :     Row of table to evaluate.
%
%  --------
%   OUTPUT
%  --------
%     Td       :     Times of maximal cosine divergence, relative to grasp.
%
%     S        :     Values of cosine similarity at divergence points.
%
%    Cs        :     Value of cosine similarity over course of trajectory.
%
% By: Max Murphy  v1.0  2019-06-19  Original version (R2017a)

%%
if nargin < 3
   rowNum = 1:size(J,1);
end

if nargin < 2
   planeNum = 1;
end

if numel(rowNum) > 1
   Td = cell(numel(rowNum),1);
   S = cell(size(Td));
   Cs = cell(size(Td));
   for ii = 1:numel(rowNum)
      [Td{ii},S{ii},Cs{ii}] = getProjDivergence(J,planeNum,rowNum(ii));
   end
   return;
end

d1 = (planeNum-1)*2 + 1;
d2 = planeNum*2;

Z = cat(3,J.Data(rowNum).Projection.proj);
T = J.Data(rowNum).Projection(1).times;
X = cell(2,1);
for ii = 1:numel(X)
   idx = J.Data(rowNum).Summary.outcomes==ii;
   if sum(idx)==0
      Td = [];
      S = [];
      Cs = [];
      return;
   end
   X{ii}(:,1) = mean(squeeze(Z(:,d1,idx)),2);
   X{ii}(:,2) = mean(squeeze(Z(:,d2,idx)),2);

end

dX = cell(1,2);
dX{1} = diff(X{1});
dX{1} = [dX{1}(1,:); dX{1}];
dX{2} = diff(X{2});
dX{2} = [dX{2}(1,:); dX{2}];

Cs = nan(numel(T),1);
for ii = 1:numel(T)
   Cs(ii) = getCosineSimilarity(dX{1}(ii,:),dX{2}(ii,:));
   MV = 
end
[~,idx] = findpeaks(-Cs);


Td = T(idx);
S = Cs(idx);



end