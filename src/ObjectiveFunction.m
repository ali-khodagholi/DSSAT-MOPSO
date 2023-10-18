function zz=ObjectiveFunction(x)  
    file_name = 'ARIR9203.PTX';
    %% ------ Part 1: Reading X File ------
    fid = fopen(file_name);
    i = 1;
    tline = fgetl(fid);
    all_data = strings(1,1);
    all_data(i,1) = tline;
    while (ischar(tline))
        i = i + 1;
        tline = fgetl(fid);
        all_data(i,1) = tline;
    end
    fclose(fid);
    %% Planting Date
    % Finding Planting Date Line
    pd_last = 0;
    pd_first = 0;
    for i = 1:length(all_data)
        if (all_data(i) == "*PLANTING DETAILS") 
           pd_first = i;
       end
       if (all_data(i) == "" && pd_first ~=0 && pd_last == 0)
           pd_last = i;
       end
    end
    % value of Planting Date
    year = 92;
    line_pd  = sprintf(' 1 %5.0f   -99  4.56  4.56     S     R  86.4   -99    15  2576   -99   -99   -99    10                        -99'...
             ,year*1000+x(1));
    %% Irrigation Scheduling
    % Finding Irrigation Line
    irr_last = 0;
    irr_first = 0;
    for i = 1:length(all_data)
        if (all_data(i) == "*IRRIGATION AND WATER MANAGEMENT") 
           irr_first = i;
       end
       if (all_data(i) == "" && irr_first ~=0 && irr_last == 0)
           irr_last = i;
       end
    end
    % value of Irrigation
    year = 92;
    n_irr = 47;
    line_irr = strings(n_irr,1);
    y = 0;
    operation = 'IR004';
    for i = 120:3:260
        y = y + 1;
        line_irr(y) = sprintf(' 1 %5.0f %s %5.1f',year*1000+i,operation,x(y+1));
    end
    %% Fertilizing
    % Finding Fertilizing Line
    fer_last = 0;
    fer_first = 0;
    for i = 1:length(all_data)
        if (all_data(i) == "*FERTILIZERS (INORGANIC)") 
           fer_first = i;
       end
       if (all_data(i) == "" && fer_first ~=0 && fer_last == 0)
           fer_last = i;
       end
    end
    % value of Irrigation
    year = 92;
    n_fer = 7;
    line_fer = strings(n_fer,1);
    y = 0;
    date = [101 , 138  , 152 , 166  , 180 , 194 , 201];
    fert_material = 'FE005';
    fert_operation = 'AP002';
    for i = 1:n_fer
        y = y + 1;
        line_fer(y) = sprintf(' 1 %5.0f %s %s    15 %5.0f   -99   -99   -99   -99   -99 -99' ...
            ,year*1000+date(y),fert_material,fert_operation,x(1+n_irr+y));
    end
    
    %% ------ Part 2: Writing Values ------
    fid = fopen(file_name, 'w');
    for i = 1:pd_first+1
        fprintf(fid, '%s\r\n', all_data(i));
    end
    fprintf(fid, '%s\r\n', line_pd);
    for i = pd_last:irr_first+3
        fprintf(fid,'%s\r\n',all_data(i));
    end
    for i = 1:n_irr
        fprintf(fid,'%s\r\n',line_irr(i));
    end
    for i = irr_last:fer_first+1
        fprintf(fid,'%s\r\n',all_data(i));
    end
    for i = 1:n_fer
        fprintf(fid,'%s\r\n',line_fer(i));
    end
    for i = fer_last:length(all_data)-1
        if (i < length(all_data)-1)
            fprintf(fid, '%s\r\n', all_data(i));
        else
            fprintf(fid, '%s', all_data(i));
        end
    end
    fclose(fid);
    %% ------ Part 3: Running Model ------
    system('"DSCSM047.EXE" PTSUB047 A ARIR9203.PTX');
    if ans ~= 0
        disp('bingo')
    end

    %% ------ Part 4: Reading Result ------
    fid = fopen('OVERVIEW.OUT');
    tline = fgetl(fid);
    i = 1;
    all_line = strings(1,1);
    all_line(i,1) = tline;
    while (ischar(tline))
        i = i + 1;
        tline = fgetl(fid);
        all_line(i,1) = tline;
    end
    for i = 1:length(all_line)
        if (all_line(i) == "*Resource Productivity") 
           Prod_line = i;
        end
    end
    a = split(all_line(Prod_line+15));
    z.irrigation = str2double(a(6));
    b = split(all_line(Prod_line+19));
    z.fertilizer = str2double(b(7));
    if sum(x(2+n_irr:length(x))) ~= 0
        c = split(all_line(Prod_line+29));
    else
        c = split(all_line(Prod_line+25));
    end
    z.yield = str2double(c(5));
    fclose(fid);
    if length(all_line) > 300
        disp('bingo')
    end
    zz=[z.irrigation, z.fertilizer, z.yield]';
end