S = getBlockSummary(gData);
fig = figure('Name','Reach-to-Grasp Behavioral Timing',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.05 0.6 0.8]); 
x = [S.PostOpDay,S.ReachToGrasp_All,S.GraspToComplete_All,S.ReachToGrasp_Successful,S.GraspToComplete_Successful];
y = [S.PostOpDay,S.ReachToGrasp_All,S.GraspToComplete_All,S.ReachToGrasp_Successful,S.GraspToComplete_Successful];
xName = {'PostOpDay','Reach-to-Grasp_{All}','Grasp-to-Complete_{All}','Reach-to-Grasp_{Success}','Grasp-to-Complete_{Success}'};
yName = {'PostOpDay','Reach-to-Grasp_{All}','Grasp-to-Complete_{All}','Reach-to-Grasp_{Success}','Grasp-to-Complete_{Success}'};
gplotmatrix(x,y,categorical(S.Group),[],[],[],[],[],xName,yName); 