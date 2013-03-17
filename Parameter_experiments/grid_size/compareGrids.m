function [ rslt ] = compareGrids( truthProf,startLims,limsStep,n,se, wnRange,lblArgs,fileName )

%This function generates a 'truth' spectrum and compares how well the truth
%profile is retrieved based on mean profiles and their covariances downloaded from ERA-interim.

%truthProf: The profile used to generate the measurement spectrum in the
%retrieval. Note: Currently H2O units must be specified in g/kg for compatibility
%with ERA-Interim

%startLims: The limits used to constrain the first calculation of the mean
%profile and covariance matrices. Specified in terms of [lon; lat; levs; time]

%limsStep: The change in the limits for every test specified in the same
%format as the start lims

%n: the number of tests, this would be the number of retrievals performed

%se: The covariance of instrument noise

%wnRange: The spectral range over which the measurement spectrum and
%retrievals are performed

%The output is a structure array containing a range of parameters from each test


%First step is to generate the measurement spectrum and Jacobians using
%simple_matlab_lblrun(...)


[wn, y] = simple_matlab_lblrun(true,1,truthProf,wnRange,lblArgs{:});

rslt=[];


%For each set of limits, download the mean profiles and associated
%covariance matrices.

for i =1:n
    
    lims = startLims + limsStep*(i-1);
    
    [ prof,cov_prof] = constructMeanProfile(lims);
    
    %Assign the same altitude grid to the mean profile as the one used in
    %the truthProfile
    prof.alt = truthProf.alt;
    
    sa = blkdiag(cov_prof.tdry, cov_prof.h2o);
    
    aJParams = [0,1];
    
     %Then perform the retrievals with the starting 'mean' profiles,
    %measurement vector and retrieval arguments
    
    [xhat_final, convergence_met, iter, xhat, G, A, K, hatS,Fxhat,final_prof] = ...
        simple_nonlinear_retrieval2(prof,sa,y, se, wnRange, lblArgs, aJParams);

    

    res = [];
    res.truthProf = truthProf;
    res.priorProf = prof;
    res.finalProf = final_prof;
    res.hatS = hatS{end};
    res.sa = sa;
    res.K = K;
    res.Fxhat = Fxhat;
    res.xhat = xhat;
    res.y=y;
    res.nIter = iter;
    res.se = se;
    res.lblArgs = lblArgs;
    res.wnRange = wnRange;
    
        
    %Add to results
    if i==1
        
        rslt = res;
    else
        
        
        rslt(i) =res;
        
    end
    
    
    
end


save(fileName,'rslt');

end

