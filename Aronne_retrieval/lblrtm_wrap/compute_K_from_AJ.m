function [wavenum, K] = ...
    compute_K_from_AJ(data_dir, FTS_params, use_levels, varargin)
% [wavenum, K] = compute_K_from_AJ(data_dir, FTS_params, use_levels)
%
% Helper function to run fftscan_lbl_files over the output from a LBLRTM AJ
% run. Collects all the radiance derivatives into a K matrix, over all 
% layers (or levels), and one for the layers; includes the surface 
% temperature derivative as the first column of K.
%
% Inputs:
% data_dir - location of the AJ output files. Should be an AJ
%    subdirectory off of the working folder for the LBLRTM run.
% FTS_Params - FTS information passed to fftscan_lbl_files (see help on 
%    that function)
% use_levels - logical variable, set to true to process level files.
%   Set to false to process layer files. Default is true.
%   (levels are the layer boundaries.)
% Optional: angle - used to determine either "UPW" or "DNW" in file names,
% defaults to 180.0
%
% outputs:
% wavenum: wavenumber scale after the fftscan (1/cm).
% K: K matrix, with surface temperature jacobian in the first column,
%   surface emissivity in the second column, 
%   followed by the temperature derivatives at each level (layer), and then
%   the molecular concentration derivatives (whichever are found), in
%   LBLRTM's molecular species ordering. (only looks for 7 species)
%   Final dimension is [Nwave, (K+1)*Nlevel+2], for K molecular species.

%04/07/2012 Updated by Daniel Jabry to include downwelling Jacobians 'DNW'
%files



angle = 180.0;


if containsParam(varargin{:},'HBOUND')
    
    hbound = extractValFromArgs(varargin{:},'HBOUND');
    angle = hbound(3);
    
end

dString = 'UPW';

if angle < 90.0
    
   dString ='DNW'; 
end
    

    


surf_file = dir([data_dir '/*TSF_*']);
emis_file = dir([data_dir '/*EMI_*']);

if nargin < 3
    use_levels = true;
end

max_nmol = 7;
mol_files = cell(max_nmol,1);
% note repeated use of isempty on the mol_files - we don't know from the
% inputs, which molecules were output from the LBLRTM AJ run, so just loop
% over all possible ones and group them together right before fftscan.
if use_levels
    temp_files =  dir(sprintf('%s/LEV_RDderiv%s_%02d_*',data_dir,dString,0));
    for n=1:max_nmol;
        mol_files{n} = dir(sprintf('%s/LEV_RDderiv%s_%02d_*',data_dir,dString, n));
    end
else
    temp_files =dir(sprintf('%s/RDderiv%s_%02d_*',data_dir,dString,0));
    for n=1:max_nmol;
        mol_files{n} =dir(sprintf('%s/RDderiv%s_%02d_*',data_dir,dString, n));
    end
end


% make sure they are sorted - I don't think it is safe to assume.
temp_files = sort_structure(temp_files, 'name');
for n=1:max_nmol;
    if ~isempty(mol_files{n})
        mol_files{n} = sort_structure(mol_files{n}, 'name');
    end
end

% concatenate arrays into one large one to send to the fftscan function.
all_files = [surf_file; emis_file; temp_files];
for n=1:max_nmol;
    if ~isempty(mol_files{n})
        all_files = [all_files; mol_files{n}]; %#ok<AGROW>
    end
end

% run LBLRTM
[wavenum, K] = fftscan_lbl_files_ap(all_files, FTS_params);

