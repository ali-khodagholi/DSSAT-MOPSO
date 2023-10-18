function PlotCosts(pop,rep)
    %Black Circle
    pop_costs=[pop.Cost];
    plot3(pop_costs(1,:),pop_costs(2,:),pop_costs(3,:)/1000,'ko');
%     plot(pop_costs(1,:),pop_costs(2,:),'ko');
    hold on;
    grid on
    rep_costs=[rep.Cost];
    %Red Star
    plot3(rep_costs(1,:),rep_costs(2,:),rep_costs(3,:)/1000,'rx');
%     plot(rep_costs(1,:),rep_costs(2,:),'r*');
    xlabel('Irrigation during growing season (mm)');
    ylabel('N applied during growing season (kg/ha)');
    zlabel('Potato YIELD (kg/ha)');
    hold off
end