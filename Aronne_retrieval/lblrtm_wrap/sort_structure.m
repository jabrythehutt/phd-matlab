function out_struct = sort_structure(in_struct, field)
% out_struct = sort_structure(in_struct, field)
% Sort a structure array according to one particular field. Field be either
% an integer denoting the field index, or a string denoting the field name.
% Returns scalar 0 if the field is not valid.

% convert field name to index, if specified as a name.
if ischar(field)
    field_idx = strmatch(field, fieldnames(in_struct));
    if isempty(field_idx);
        disp(['Unknown field ' field]);
        out_struct = 0;
        return
    end
else
    field_idx = field;
end

if field_idx > length(fieldnames(in_struct))
    disp(['Field index ' num2str(field_idx) ' is too large']);
    out_struct = 0;
    return
end

tmp_array = struct2cell(in_struct);
[dummy, sorter] = sort(tmp_array(field_idx,:)); %#ok<ASGLU>

out_struct = in_struct(sorter);
