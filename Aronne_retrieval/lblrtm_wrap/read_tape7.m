function layerdata = read_tape7(tape7_file)
%function layerdata = read_tape7(tape7_file)
%
% read TAPE7 to get the as-used temperature, pressure, and gas
% concentrations, in the LBLRTM run.
%
% With no input, this attempts to read a file named 'TAPE7' in the current
% directory, otherwise use the input to specify the full path+file to the
% desired LBLRTM TAPE7.
%
% output is a structure as follows:
%
% layerdata.nlayer:     N, the number of layers
% layerdata.nmol:       M, the number of molecules
% layerdata.atm:        string description of std atm
% layerdata.H1,H2,ang:  slant path dimension
%
% layerdata.pbar:   (N,1) average layer pressure [hPa]
% layerdata.tbar:   (N,1) average layer temp [K]
% layerdata.zlevel: (N,2) level altitude [km] (this is the altitude of the
%       bottom and top edge of the layer - other (N,2) arrays are similar,
%       e.g. the values at the bottom and top edges)
% layerdata.tlevel: (N,2) level temp [K]
% layerdata.plevel: (N,2) level pressure [hPa]
% layerdata.q:      (N,1) water vapor mass mixing ratio [kg/kg]
% layerdata.mol_vmr:(N,M) molecular volume mixing ratio [m^-3/m^-3], or, 
%       multiply by 1e6 to get ppmv, etc.
%
% the order of molecules in the mol_vmr array is the standard LBLRTM:
%   1: h2o, 2: co2, 3: o3, 4: n2o, 5: co, 6: ch4, ...
%   (see LBLRTM html document, Table I, for further details)
%
% note that layerdata.q and layerdata.mol_vmr[1,:] are redundant.
%

if nargin == 0
    tape7_file = 'TAPE7';
end

fid = fopen(tape7_file, 'r');

fline = fgetl(fid); %#ok<NASGU>
fline = fgetl(fid);

layerdata.nlayer = str2double(fline(3:5));
layerdata.nmol = str2double(fline(8:10));
layerdata.atm = fline(21:36);
layerdata.H1 = str2double(fline(41:48));
layerdata.H2 = str2double(fline(53:60));
layerdata.ang = str2double(fline(66:73));

layerdata.pbar = zeros(layerdata.nlayer,1);
layerdata.tbar = zeros(layerdata.nlayer,1);
layerdata.zlevel = zeros(layerdata.nlayer,2);
layerdata.tlevel = zeros(layerdata.nlayer,2);
layerdata.plevel = zeros(layerdata.nlayer,2);

layerdata.q = zeros(layerdata.nlayer,1);
layerdata.mol_vmr = zeros(layerdata.nlayer, layerdata.nmol+1);

% first line contains the atmosphere data - z,P,t. The first such
% line contains z,P,T at the top at bottom of the layer, the
% remaining lines contain only the values at the top.
atm_line_fmt_first = '%f %f %d %f %f %f %f %f %f';
atm_line_fmt = '%f %f %d %f %f %f';

% the molecular density data is a number of floating point numbers, 
% with at least 8 (8 numbers are always printed, with zero entries
% to pad if need be.). The 8th position is always written as the 
% number of remaining molecules for all skipped species. If more
% than 7 molecules are output, the remaining numbers are written
% into more "line2"'s; for example, if nmol is 18, then 3 lines
% will be written - 8, 8, 3. (remember the first line has only 7
% mol values since position 8 is the remainder.)

min_nmol = max([layerdata.nmol, 7]);
num_mol_lines = (min_nmol+1)/8;
for n = 1:floor(num_mol_lines);
    mol_line_fmt{n} = repmat('%f ', [1 8]);
end
if floor(num_mol_lines) ~= num_mol_lines;
    nremain = round( (num_mol_lines - floor(num_mol_lines))*8 );
    mol_line_fmt{end+1} = repmat('%f ', [1 nremain]);
end
num_mol_lines = ceil(num_mol_lines);

fline = fgetl(fid);
atmdata = sscanf(fline, atm_line_fmt_first);
moldata = [];
for n = 1:num_mol_lines;
    fline = fgetl(fid);
    moldata = [moldata; sscanf(fline, mol_line_fmt{n})];
end

layerdata.pbar(1) = atmdata(1);
layerdata.tbar(1) = atmdata(2);
layerdata.zlevel(1,:) = atmdata([4 7]);
layerdata.plevel(1,:) = atmdata([5 8]);
layerdata.tlevel(1,:) = atmdata([6 9]);

dry_air_col = sum(moldata(2:end));
if layerdata.nmol <= 7;
    layerdata.mol_vmr(1,1:layerdata.nmol) = moldata(1:layerdata.nmol)/dry_air_col;
else
    layerdata.mol_vmr(1,1:7) = moldata(1:7)/dry_air_col;
    layerdata.mol_vmr(1,8:layerdata.nmol) = ...
        moldata(9:layerdata.nmol+1)/dry_air_col;
end
layerdata.mol_vmr(1,layerdata.nmol+1) = moldata(8)/dry_air_col;
% calculation to convert VMR to mass mixing ratio for water vapor
R_d_over_R_v = 287.0 / 461.0;
layerdata.q(1) = R_d_over_R_v*moldata(1)/dry_air_col;

for l = 2:layerdata.nlayer

    line1 = fgetl(fid);
    atmdata = sscanf(line1, atm_line_fmt);
    moldata = [];
    for n = 1:num_mol_lines;
        line2 = fgetl(fid);
        moldata = [moldata; sscanf(line2, mol_line_fmt{n})];
    end

    layerdata.pbar(l) = atmdata(1);
    layerdata.tbar(l) = atmdata(2);
    layerdata.zlevel(l,2) = atmdata(4);
    layerdata.plevel(l,2) = atmdata(5);
    layerdata.tlevel(l,2) = atmdata(6);
    dry_air_col = sum(moldata(2:end));
    if layerdata.nmol <= 7;
        layerdata.mol_vmr(l,1:layerdata.nmol) = moldata(1:layerdata.nmol)/dry_air_col;
    else
        layerdata.mol_vmr(l,1:7) = moldata(1:7)/dry_air_col;
        layerdata.mol_vmr(l,8:layerdata.nmol) = ...
            moldata(9:layerdata.nmol+1)/dry_air_col;
    end
    layerdata.mol_vmr(l,layerdata.nmol+1) = moldata(8)/dry_air_col;
    layerdata.q(l) = R_d_over_R_v*moldata(1)/dry_air_col;

end

fclose(fid);

layerdata.zlevel(2:end,1) = layerdata.zlevel(1:end-1,2);
layerdata.plevel(2:end,1) = layerdata.plevel(1:end-1,2);
layerdata.tlevel(2:end,1) = layerdata.tlevel(1:end-1,2);
