function [ pmid ] = createPressureGrid( flePath,lims )
%Open the prsurf file and construct a 3d grid of the pressure data points

%Adapted from IDL code:

% nlev=40 ; number of GISS model levels
% grav=9.81
% psf=984.
% ptop=150.
% pmtop=0.1
% plbot=fltarr(nlev+1)
% plbot=[psf,964.,942.,917.,890.,860.,825.,785.,740.,692.,642.,591., $
% 539.,489.,441.,396.,354.,316.,282.,251.,223.,197.,173.,ptop,128.,  $
% 108.,90.,73.,57.,43.,31.,20.,10.,5.62,3.16,1.78,1.,0.562,0.316,0.178,pmtop]
% if ((n_elements(plbot)-1) ne nlev) then STOP
% sige=fltarr(nlev+1)
% sige[*]=(plbot[*]-ptop)/(psf-ptop)
% sig=fltarr(nlev)
% for k=0,nlev-1 do begin
%  sig[k]=(sige[k]+sige[k+1])/2
% endfor
%
% ; Note: prsurf is the input 2D pressure from the GISS model output (e.g. from
% ; DEC2009.aijEcadiAG3nF40_prsurf.nc)
% ; pmid is the 3D pressure that we want (e.g. for interpolation)
% pmid=fltarr(nlon,nlat,nlev)
% LS1=24
% for k=0,LS1-1-1 do begin
%   pmid[*,*,k]=sig[k]*(prsurf[*,*]-ptop)+ptop
% endfor
% for k=LS1-1,nlev-1 do begin
%   pmid[*,*,k]=sig[k]*(psf-ptop)+ptop
% endfor


nlev = 40;
psf = 984.0;
ptop = 150.0;
pmtop = 0.1;

plbot=[psf,964.,942.,917.,890.,860.,825.,785.,740.,692.,642.,591.,...,
    539.,489.,441.,396.,354.,316.,282.,251.,223.,197.,173.,ptop,128.,...,
    108.,90.,73.,57.,43.,31.,20.,10.,5.62,3.16,1.78,1.,0.562,0.316,0.178,pmtop];

sige = zeros(1,nlev+1);
sige(:) = (plbot(:)-ptop)/(psf-ptop);
sig = zeros(1,nlev);

for k =1:nlev
    
    sig(k)=(sige(k)+sige(k+1))/2;
    
end


lons = ncread(flePath,'lon');
lonix = lons>=lims(1,1)&lons<=lims(1,2);

lats = ncread(flePath,'lat');
latix = lats>=lims(2,1)&lats<=lims(2,2);

startix = [find(lonix,1,'first'),find(latix,1,'first')];
endix = [find(lonix,1,'last'),find(latix,1,'last')];

stride = ones(size(startix));
v = 'prsurf';
%This array should be 2D (lon-lat)
prsurf = double(ncread(flePath,v,startix,(endix-startix)+stride,stride));

nlon = size(prsurf,1);
nlat = size(prsurf,2);

pmid = zeros(nlon,nlat,nlev);
LS1=24;

for k= 1:LS1-1
    pmid(:,:,k)=sig(k)*(prsurf(:,:)-ptop)+ptop;
end

for k = LS1:nlev
    pmid(:,:,k)=sig(k)*(psf-ptop)+ptop;
end

end

