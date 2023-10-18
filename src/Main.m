clc
clear
close all
tic
%% Problem Definition
n_irr = 47;
n_fer = 7;
nVar = 1 + n_irr + n_fer;     % Number of Decision Variables

VarSize=[1 nVar];       % Size of Decision Variables Matrix

% Step of Position
step_pd = 1;
step_irr = 0.1;
step_fer = 25;

% Lower Bound of Variables
min_pd = 80;
min_irr = 0;
min_fer = 0;
VarMin = [min_pd , repmat(min_irr,1,n_irr) , repmat(min_fer,1,n_fer)];

% Upper Bound of Variables
max_pd = 120;
max_irr = 12;
max_fer = 125;
VarMax = [max_pd , repmat(max_irr,1,n_irr) , repmat(max_fer,1,n_fer)];

%% MOPSO Parameters

MaxIt=50;           % Maximum Number of Iterations

nPop=300;           % Population Size

nRep=100;            % Repository Size

w=0.5;              % Inertia Weight
wdamp=0.99;         % Intertia Weight Damping Rate
c1=1;               % Personal Learning Coefficient
c2=2;               % Global Learning Coefficient

nGrid=7;            % Number of Grids per Dimension
alpha=0.1;          % Inflation Rate

beta=2;             % Leader Selection Pressure
gamma=2;            % Deletion Selection Pressure

mu=0.1;             % Mutation Rate

%% Initialization

empty_particle.Position=[];
empty_particle.Velocity=[];
empty_particle.Cost=[];
empty_particle.Best.Position=[];
empty_particle.Best.Cost=[];
empty_particle.IsDominated=[];
empty_particle.GridIndex=[];
empty_particle.GridSubIndex=[];

pop=repmat(empty_particle,nPop,1);

for i=1:nPop

    pop(i).Position=unifrnd(VarMin ,VarMax,VarSize);
    %Correct Position
    pop(i).Position(1) = floor(pop(i).Position(1)/step_pd)*step_pd;
    pop(i).Position(2:n_irr+1) = floor(pop(i).Position(2:n_irr+1)/step_irr)*step_irr;
    pop(i).Position(n_irr+2:nVar) = floor(pop(i).Position(n_irr+2:nVar)/step_fer)*step_fer;
    pop(i).Velocity=zeros(VarSize);

    pop(i).Cost=ObjectiveFunction(pop(i).Position);


    % Update Personal Best
    pop(i).Best.Position=pop(i).Position;
    pop(i).Best.Cost=pop(i).Cost;

end

% Determine Domination
pop=DetermineDomination(pop);

rep=pop(~[pop.IsDominated]);

Grid=CreateGrid(rep,nGrid,alpha);

for i=1:numel(rep)
    rep(i)=FindGridIndex(rep(i),Grid);
end


%% MOPSO Main Loop
for it = 1 : MaxIt
    for i=1:nPop
        leader=SelectLeader(rep,beta);

        pop(i).Velocity = w*pop(i).Velocity ...
            +c1*rand(VarSize).*(pop(i).Best.Position-pop(i).Position) ...
            +c2*rand(VarSize).*(leader.Position-pop(i).Position);

        pop(i).Position = pop(i).Position + pop(i).Velocity;
        %Correct Position
        pop(i).Position(1) = floor(pop(i).Position(1)/step_pd)*step_pd;
        pop(i).Position(2:n_irr+1) = floor(pop(i).Position(2:n_irr+1)/step_irr)*step_irr;
        pop(i).Position(n_irr+2:nVar) = floor(pop(i).Position(n_irr+2:nVar)/step_fer)*step_fer;
        pop(i).Position = max(pop(i).Position, VarMin );
        pop(i).Position = min(pop(i).Position, VarMax );

        pop(i).Cost = ObjectiveFunction(pop(i).Position);

        % Apply Mutation
        pm=(1-(it-1)/(MaxIt-1))^(1/mu);
        if rand<pm
            NewSol.Position=Mutate(pop(i).Position,pm,VarMin,VarMax);
            %Correct Position
            NewSol.Position(1) = floor(NewSol.Position(1)/step_pd)*step_pd;
            NewSol.Position(2:n_irr+1) = floor(NewSol.Position(2:n_irr+1)/step_irr)*step_irr;
            NewSol.Position(n_irr+2:nVar) = floor(NewSol.Position(n_irr+2:nVar)/step_fer)*step_fer;
            NewSol.Cost=ObjectiveFunction(NewSol.Position);
            if Dominates(NewSol,pop(i))
                pop(i).Position=NewSol.Position;
                pop(i).Cost=NewSol.Cost;

            elseif Dominates(pop(i),NewSol)
                % Do Nothing

            else
                if rand<0.5
                    pop(i).Position=NewSol.Position;
                    pop(i).Cost=NewSol.Cost;
                end
            end
        end

        if Dominates(pop(i),pop(i).Best)
            pop(i).Best.Position=pop(i).Position;
            pop(i).Best.Cost=pop(i).Cost;

        elseif Dominates(pop(i).Best,pop(i))
            % Do Nothing

        else
            if rand<0.5
                pop(i).Best.Position=pop(i).Position;
                pop(i).Best.Cost=pop(i).Cost;
            end
        end

    end

    % Add Non-Dominated Particles to REPOSITORY
    all = [rep 
        pop];
    all = DetermineDomination(all);
    rep = all(~[all.IsDominated]);
%     rep=[rep
%          pop(~[pop.IsDominated])]; %#ok
% 
%     % Determine Domination of New Resository Members
%     rep=DetermineDomination(rep);
% 
%     % Keep only Non-Dminated Memebrs in the Repository
%     rep=rep(~[rep.IsDominated]);

    % Update Grid
    Grid=CreateGrid(rep,nGrid,alpha);

    % Update Grid Indices
    for i=1:numel(rep)
        rep(i)=FindGridIndex(rep(i),Grid);
    end

    % Check if Repository is Full
    if numel(rep)>nRep

        Extra=numel(rep)-nRep;
        for e=1:Extra
            rep=DeleteOneRepMemebr(rep,gamma);
        end

    end


%         Plot Costs
    figure(1)
    PlotCosts(pop,rep);

    % Show Iteration Information
    disp(['Iteration ' num2str(it) ': Number of Rep Members = ' num2str(numel(rep))]);

    % Damping Inertia Weight
    w=w*wdamp;
end
grid off
rep_costs=[rep.Cost];

figure(2)
plot(rep_costs(1,:),rep_costs(2,:),'xk')
xlabel('Irrigation during growing season (mm)')
ylabel('N applied during growing season (kg/ha)')

figure(3)
plot(rep_costs(1,:),rep_costs(3,:)/1000,'xk')
xlabel('Irrigation during growing season (mm)')
ylabel('Potato YIELD (t/ha)')

figure(4)
plot(rep_costs(2,:),rep_costs(3,:)/1000,'xk')
xlabel('N applied during growing season (kg/ha)')
ylabel('Potato YIELD (t/ha)')


figure(5)
plot3(rep_costs(1,:),rep_costs(2,:),rep_costs(3,:)/1000,'xk')
xlabel('Irrigation during growing season (mm)')
ylabel('N applied during growing season (kg/ha)')
zlabel('Potato YIELD (t/ha)')


% %% Resluts
% hold off;
% for i=1:numel(rep)
%     disp(['Result: ' num2str(i)]);
%     disp(['     Wheat = ' num2str(rep(i).Position(1))]);
%     disp(['     Barley = ' num2str(rep(i).Position(2))]);
%     disp(['     Alfaalfa = ' num2str(rep(i).Position(3))]);
%     disp(['     Rice = ' num2str(rep(i).Position(4))]);
%     disp(['     Maize = ' num2str(rep(i).Position(5))]);
%     disp(['     Beetroot = ' num2str(rep(i).Position(6))]);
%     disp(['     Sunflower = ' num2str(rep(i).Position(7))]);
%     disp(['     Melon = ' num2str(rep(i).Position(8))]);
%     disp(['     Others = ' num2str(rep(i).Position(9))]);
%     disp(['Mean Annual Lost Profit: ' num2str(rep (i).Cost (1)) 'Milliard Toman']);
%     disp(['Mean Annual Groundwater Extraction: ' num2str(rep (i).Cost (2)) 'Mcm']);
%     disp(['Mean Annual Pumping Energy: ' num2str(rep (i).Cost (3)) 'MWh']);
%     ObjectiveFunction(All,Co,rep(i).Position);  
% end
% close all
% %     hold off
% rep_costs=[rep.Cost];
% 
% 
% figure
% plot3(-rep_costs(1,:),rep_costs(2,:),rep_costs(3,:),'*k');
% xlabel('Mean Annual Lost Profit (Milliard Toman)');
% ylabel('Mean Annual Groundwater Extraction (MCM)');
% zlabel('Mean Annual Pumping Energy (MWh)');
% grid on
% 
% 
% figure
% plot(-rep_costs(1,:),rep_costs(2,:),'*k');
% xlabel('Mean Annual Lost Profit (Milliard Toman)');
% ylabel('Mean Annual Groundwater Extraction (MCM)');
% grid on
% 
% 
% figure
% plot(-rep_costs(1,:),rep_costs(3,:),'*k');
% xlabel('Mean Annual Lost Profit (Milliard Toman)');
% ylabel('Mean Annual Pumping Energy (MWh)');
% grid on
% 
% figure
% plot(rep_costs(2,:),rep_costs(3,:),'*k');
% xlabel('Mean Annual Groundwater Extraction (MCM)');
% ylabel('Mean Annual Pumping Energy (MWh)');
% grid on
% 
% Rposition = zeros(nRep,nVar);
% Rcost = zeros(nRep,3);
% 
% for i = 1:nRep
%     for j = 1:nVar
%     Rposition(i,j) = rep(i).Position(j);
%     end
% end
% 
% for i = 1:nRep
%     for j = 1:3
%       Rcost(i,j) = rep(i).Cost(j);
%     end
% end
% xlswrite('Export',Rposition,'sheet1')
% xlswrite('Export',Rcost,'sheet2')

toc