function Sa = synthetic_Sa(alt, corr_length, diag_var);

% slow to compute (boo) but easy to implement (hooray)

nlevels = length(alt);
Sa = diag(diag_var);
diag_std = sqrt(diag_var);
A = (-1.0/corr_length);
for l1=1:nlevels-1;
    for l2=l1+1:nlevels;
        da = alt(l1) - alt(l2);
        Sa(l1,l2) = diag_std(l1) * diag_std(l2) * exp(A*abs(da));
        Sa(l2,l1) = Sa(l1,l2);
    end
end
