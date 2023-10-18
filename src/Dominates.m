function b=Dominates(u,v)
%%  Body of Dominate
    % Define Cost u
    if isstruct(u)
        x=u.Cost;
    end
    % Define Cost v
    if isstruct(v)
        y=v.Cost;
    end
    b = false;
    
    % Compare Irrigation / y Dominated
    if x(1) < y(1) && x(2)<= y(2) && x(3) >= y(3)
        b = true;
    end
    % Compare Fertilizer / y Dominated
    if x(2) < y(2) && x(1) <= y(1) && x(3) >= y(3)
        b = true;
    end
    if x(3) > y(3) && x(1) <= y(1) && x(2) <= y(2)
        b = true;
    end
%     
% %%  Constraint
%  
% % Total Area
%     if sum(v.Position) < 20000
%         b = true;
%     end
%     

end
