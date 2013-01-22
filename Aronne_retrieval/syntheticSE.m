function [ se ] = syntheticSE( wn_grid,type )

%Generate a synthetic se matrix of a pre-determined type for the specified wavenumber
%grid

%type - 'ln' = low noise case described in Merelli et al. 2011;
%'hn' = high noise case




%Generate using sample points from Figure 3 in Merelli et al. 2011


wn = [100 350 500 700 1000 1200 1500 2000];

highN  = [1.5 0.6 0.6 0.7 0.75 0.8 0.9 1.2];

lowN = [0.5 0.2 0.2 0.19 1.21 0.25 0.3 0.42];

selected = highN;

if strcmpi(type,'ln')
    
    selected = lowN;
end

%Convert to W/cm^2... from mW/m^2...
selected = selected*1e-7;

var = (interp1(wn,selected,wn_grid,'spline','extrap')).^2;

se = sparse(diag(var));







end

