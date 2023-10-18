function xnew=Mutate(x,pm,VarMin,VarMax)
    nVar=numel(x);
    j=randi([1 nVar]);
    dx=pm*(VarMax-VarMin);
    lb = max(x(j)-dx(j),VarMin(j));
    ub = min(x(j)+dx(j),VarMax(j));
    xnew=x;
    xnew(j)=unifrnd(lb,ub);
end