function [ h ] = plot_prior_vecs( temp,wv,pressureVec )
%PLOT_PRIOR_VECS Summary of this function goes here
%   Detailed explanation goes here

subplot(121);

plot(temp,pressureVec);
ylabel('Pressure (mb)','fontsize', 12);
xlabel('Temperature (K)','fontsize',12);
title('Temperature profile','fontsize',13);
ylim([min(pressureVec),max(pressureVec)]);
set(gca,'yDir','reverse');



subplot(122);

semilogx(wv,pressureVec);
xlabel('Water vapour mass mixing ratio (g/Kg)','fontsize',12);
title('Water vapour profile','fontsize',13);
set(gca,'yDir','reverse');
ylim([min(pressureVec),max(pressureVec)]);

end

