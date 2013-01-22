prior_temp = prior.tdry;
prior_wvap = exp(prior.h2o);

%retrieved_temp = xhat_final(1:nlevels);




temp_mask = state_mask(1:nlevels);
wv_mask = state_mask(nlevels+1:2*nlevels);

retrieved_temp = prior_temp;
retrieved_temp(temp_mask)=xhat_final([temp_mask;false(nlevels,1)]);


retrieved_wvap = prior_wvap;
retrieved_wvap(wv_mask)=exp(xhat_final([false(nlevels,1);wv_mask]));

truth_temp = truth_profile.tdry;
truth_wvap = truth_profile.h2o;

expected_x = prior.x0;

expected_x(state_mask) = A{end}*([truth_temp(temp_mask); log(truth_wvap(wv_mask))] - prior.x0(state_mask));
expected_temp = expected_x(1:nlevels) + prior_temp;
expected_wvap = exp(expected_x(nlevels+1:2*nlevels) + prior.h2o);

subplot(231)
plot(prior_temp - prior_temp, profile.alt, '--k');
hold on
plot(truth_temp - prior_temp, profile.alt, 'k');
plot(expected_temp - prior_temp, profile.alt, 'r');
plot(retrieved_temp - prior_temp, profile.alt, 'b');
hold off
legend({'prior', 'truth', 'expected (Ax)', 'retrieved'})
xlabel('temperature [K]')
ylabel('altitude [km]')
title('temp profile (rel. to prior)')

subplot(232)
semilogx(prior_wvap, profile.alt, '--k')
hold on
plot(truth_wvap, profile.alt, 'k');
plot(expected_wvap, profile.alt, 'r');
plot(retrieved_wvap, profile.alt, 'b');
hold off
xlim([1e-3, 50.0])
legend({'prior', 'truth', 'expected (Ax)', 'retrieved'})
xlabel('water vapor mixing ratio [g/kg]')
ylabel('altitude [km]')
title('water vapor profile')

subplot(234)
plot(wn, (obs_radiance - prior_F.Fxhat)*1e7)
xlabel('wavenumber [1/cm]')
ylabel('mW/(m^2 sr cm^{-1})')
title('Observed - first guess radiance')

subplot(235)
plot(wn(channel_mask), (obs_radiance(channel_mask) - Fxhat{end})*1e7)
xlabel('wavenumber [1/cm]')
ylabel('mW/(m^2 sr cm^{-1})')
title('Observed - radiance from retrieved state')

subplot(233)
imagesc(A{end})
title('A')

subplot(236)
imagesc(hatS)
title('$\hat{S}$', 'interpreter', 'latex')