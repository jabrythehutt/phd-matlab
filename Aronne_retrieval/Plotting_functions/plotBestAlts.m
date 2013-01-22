function [ h ] = plotBestAlts( bT,wn,profile,levs,minTemp,maxTemp,alts,temps)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
 
levels = sort(levs);
figure
%h = subplot(1,4,1:3); 
p = zeros(1, length(levels));


[lspec,lstl,mrkr,clr]=generateLineSpec(1);

p(1)=plot(wn,bT(:,levels(1)),['-',clr]);
%annotation('textarrow',wn(1),bT(1,levels(1)),'String',[num2str(profile.alt(levels(1))),'Km']);
ylabel('Brightness temperature (K)','fontsize',12);
xlabel('Wavenumber (cm^-^1)','fontsize',12);
hold on;



for i = 2:length(levels)
    
    
    [lspec,stle,mrkr,clr]=generateLineSpec(i);

    p(i)=plot(wn, bT(:,levels(i)),lspec);
    %annotation('textarrow',wn(1),bT(1,levels(i)),'String',[num2str(profile.alt(levels(i))),'Km']);
    
end

plot(wn, zeros(size(wn))+minTemp,'--r');
%plot(wn, zeros(size(wn))+maxTemp,'--g');

hold off;

legString = 'legend(';

for i = 1:1:length(levels)
    
    legString = [legString,'''',num2str(profile.alt(levels(i))),'Km'', '];

end

legString = [legString,'''Tropopause'', ''location'',''EastOutside'')'];

eval(legString);

figure;
%subplot(1,4,4);

r = zeros(1,length(levels)+3);




r(1)=plot(profile.tdry,profile.alt,'--b');
xlim([min(profile.tdry),max(profile.tdry)]);
ylim([min(profile.alt),max(profile.alt)]);
xlabel('Temperature (K)','fontsize',12);
ylabel('Altitude (Km)','fontsize',12);
hold on;

for i = 1:1:length(levels)

    
     [lspec,stle,mrkr,c]=generateLineSpec(i);

    
    
    r(i+1)=line([min(profile.tdry),max(profile.tdry)],[profile.alt(levels(i)),profile.alt(levels(i))],'Color',c,'LineStyle',stle);
    %Draw four lines for sounding ranges above and below the inversion
    
    %line([temps(i,1),temps(i,1)],[alts(i,1),alts(i,2)],'Color',c);
    %line([temps(i,2),temps(i,2)],[alts(i,1),alts(i,2)],'Color',c);
    %line([temps(i,3),temps(i,3)],[alts(i,3),alts(i,4)],'Color',c);
    %line([temps(i,4),temps(i,4)],[alts(i,3),alts(i,4)],'Color',c);
    crnr = [min(temps(i,1),temps(i,2)),min(alts(i,1),alts(i,2))];
    wh = [abs(temps(i,2)-temps(i,1)),abs(alts(i,1)-alts(i,2))];
    rectangle('Position',[crnr,wh],'FaceColor',c);
    
end


r(length(levels)+2)=line([minTemp,minTemp],[profile.alt(1),profile.alt(end)],'Color','r','LineStyle','--');
%r(length(levels)+3)=line([maxTemp,maxTemp],[profile.alt(1),profile.alt(end)],'Color','g','LineStyle','--');

hold off;

legend(r(1),'Temperature profile','Location','best');


figure;
%Plot obs alts vs trop sounding depths

soundingDepths = zeros(1,length(levs));
obsAlt = zeros(1,length(levs));

for i=1:length(levs)
    
    soundingDepths(i)  = abs(alts(i,1)-alts(i,2));
    obsAlt(i) = min(alts(i,1),alts(i,2));
    
end


plot(obsAlt(:),soundingDepths(:));

xlabel('Observer altitude (Km)','fontsize',12);
ylabel('Tropospheric sounding depth (Km)','fontsize',12);




end

