%% 电站发电数据处理
for n = 1:4
    filename = sprintf('电站%d发电数据.xlsx', n);
    try
        data = readtable(filename);

        headers = data.Properties.VariableNames;
        timeColName = headers{1};
        powerColName = headers{2};

        %将时间列转换为 datetime 类型，并提取时间信息
        data.(timeColName) = datetime(data.(timeColName), 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
        data.Date = dateshift(data.(timeColName), 'start', 'day');
        data.Hour = hour(data.(timeColName));

        %按日期和小时对发电量进行分组求和
        resultTable = groupsummary(data, {'Date', 'Hour'}, 'sum', powerColName);

        %每个小时的数据点数量，用于求平均值并乘以12，从而弥补缺失的数据
        nDataPoints = resultTable.GroupCount;
        
        %计算修正后的发电量（当n>0时：sum/n*12）
        sumColName = ['sum_' powerColName];
        resultTable.(sumColName) = (resultTable.(sumColName) ./ nDataPoints) * 12;

        if width(resultTable) >= 3
            resultTable(:, 3) = [];
        end

        newColumnNames = cell(1, width(resultTable));
        newColumnNames{1} = 'Date';
        newColumnNames{2} = 'Hour';
        newColumnNames{3} = 'generated_energy/kwh';

        resultTable.Properties.VariableNames = newColumnNames;
        resultTable = sortrows(resultTable, {'Date', 'Hour'});

        save_filename = sprintf('电站%d发电数据_每小时汇总.xlsx', n);
        writetable(resultTable, save_filename);
        fprintf('成功处理并保存文件: %s\n', save_filename);
    catch ME
        fprintf('处理文件 %s 出错: %s\n', filename, ME.message);
    end

    %合并前面文件的时间格式
    data = readtable(save_filename);
    
    % 提取日期列和时间列
    dateColumn = data.Date;
    hourColumn = data.Hour;
    
    % 合并日期和时间，并转换为指定格式
    combinedDateTime = datetime(dateColumn, 'InputFormat', 'yyyy/MM/dd') + hours(hourColumn);
    combinedDateTime = datetime(combinedDateTime, 'Format', 'yyyy-MM-dd HH:mm:ss');
    
    data = removevars(data, {'Date', 'Hour'});
    data = addvars(data, combinedDateTime, 'Before', 1, 'NewVariableName', 'DateTime');
    if width(data) >= 3
        data(:, 3) = [];
    end

    % 输出到新的Excel文件
    newFilename = sprintf('电站%d发电数据__每小时汇总.xlsx', n);
    writetable(data, newFilename);
    

    % 删除冗余文件
    delete(save_filename);

    disp('数据已成功输出到新文件！');
end

%% 环境监测仪数据处理
startDate = datetime(2024, 5, 1);

for n = 1:4
    if n >= 1 && n <= 3
        filename = sprintf('电站%d环境检测仪数据.xlsx', n);
    end
    if n == 4
        filename = sprintf('电站%d环境监测仪数据.xlsx', n);
    end
    try
        data = readtable(filename);

        headers = data.Properties.VariableNames;
        timeColName = headers{1};
        powerColName = headers{2};

        % 将时间列转换为 datetime 类型，并提取时间信息
        data.(timeColName) = datetime(data.(timeColName), 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
        data.Date = dateshift(data.(timeColName), 'start', 'day');
        data.Hour = hour(data.(timeColName));

        % 筛选出 5 月 1 日及之后的数据，对这些数据按日期和小时对发电量进行分组求和
        data = data(data.Date >= startDate, :);
        resultTable = groupsummary(data, {'Date', 'Hour'}, 'sum', powerColName);

        % 每个小时的数据点数量，用于求平均值并乘以 20，从而弥补缺失的数据
        nDataPoints = resultTable.GroupCount;

        % 计算修正后的发电站环境检测仪数据（当 n > 0 时：sum/n*20）
        sumColName = ['sum_' powerColName];
        resultTable.(sumColName) = (resultTable.(sumColName) ./ nDataPoints) * 20;

        if width(resultTable) >= 3
            resultTable(:, 3) = [];
        end

        newColumnNames = cell(1, width(resultTable));
        newColumnNames{1} = 'Date';
        newColumnNames{2} = 'Hour';
        newColumnNames{3} = 'radiant_quantity(w/m2)';

        resultTable.Properties.VariableNames = newColumnNames;
        resultTable = sortrows(resultTable, {'Date', 'Hour'});

        save_filename = sprintf('电站%d环境检测仪数据.xlsx_每小时汇总.xlsx', n);
        writetable(resultTable, save_filename);
        fprintf('成功处理并保存文件: %s\n', save_filename);
    catch ME
        fprintf('处理文件 %s 出错: %s\n', filename, ME.message);
    end

    %%合并前面文件的时间格式
    data = readtable(save_filename);
    
    % 提取日期列和时间列
    dateColumn = data.Date;
    hourColumn = data.Hour;
    
    % 合并日期和时间，并转换为指定格式
    combinedDateTime = datetime(dateColumn, 'InputFormat', 'yyyy/MM/dd') + hours(hourColumn);
    combinedDateTime = datetime(combinedDateTime, 'Format', 'yyyy-MM-dd HH:mm:ss');
    
    data = removevars(data, {'Date', 'Hour'});
    data = addvars(data, combinedDateTime, 'Before', 1, 'NewVariableName', 'DateTime');
    if width(data) >= 3
        data(:, 3) = [];
    end

    % 输出到新的Excel文件
    newFilename = sprintf('电站%d环境监测仪数据.xlsx', n);
    writetable(data, newFilename);
    

    % 删除冗余文件
    delete(save_filename);

    disp('数据已成功输出到新文件！');
end

%% 天气数据处理
clearvars; close all; clc;

% 定义中文天气描述到英文的映射
chinese_weather = {'晴', '阴', '多云', '浮尘', '阵雨', '小雨', '大雨', '雾', '霾'};
english_weather = {'Sunny', 'Cloudy', 'Partly Cloudy', 'Dust', 'Showers', 'Light Rain', 'Heavy Rain', 'Fog', 'Haze'};

% 定义中文风向到英文的映射
chinese_wind = {'东风', '南风', '西风', '北风', '西北风', '东北风', '东南风', '西南风'};
english_wind = {'East Wind', 'South Wind', 'West Wind', 'North Wind', 'Northwest Wind', 'Northeast Wind', 'Southeast Wind', 'Southwest Wind'};

for file_num = 1:4
    filename = sprintf('电站%d天气数据.xlsx', file_num);

    %处理中文列名
    opts = detectImportOptions(filename, 'TextType', 'string');
    opts.VariableNames = {'Time', 'now_temp', 'high_temp', 'low_temp', 'weather',...
                         'wind_direct', 'wind_speed', 'humid','sunrise_time','sunset_time'};
    opts = setvartype(opts, {'weather', 'wind_direct'},'string');
    opts = setvartype(opts, {'sunrise_time','sunset_time'}, 'datetime');

    %读取数据并处理编码
    data = readtable(filename, opts);

    %转换时间格式并删除重复项
    data.Time = datetime(data.Time, 'Format', 'yyyy-MM-dd HH:mm:ss');
    cutoff_date = datetime('2024-05-01');
    data = data(data.Time >= cutoff_date, :);

    %将时间对齐到整点
    data.Time = dateshift(data.Time,'start', 'hour') + hours(1);

    %检测并删除重复时间后排序
    [~, unique_idx] = unique(data.Time);
    data = data(unique_idx, :);
    data = sortrows(data, 'Time');

    start_time = dateshift(data.Time(1),'start', 'hour');
    end_time = dateshift(data.Time(end), 'end', 'hour');
    full_hours = (start_time : hours(1) : end_time)';

    hourly_data = table(full_hours, 'VariableNames', {'Time'});
    hourly_data = addvars(hourly_data,...
        nan(height(hourly_data),1),...    % now_temp
        nan(height(hourly_data),1),...    % high_temp
        nan(height(hourly_data),1),...    % low_temp
        strings(height(hourly_data),1),...% weather
        strings(height(hourly_data),1),...% wind_direct
        nan(height(hourly_data),1),...    % wind_speed
        nan(height(hourly_data),1),...    % humid
        NaT(height(hourly_data),1),...    % sunrise_time
        NaT(height(hourly_data),1),...    % sunset_time
        'NewVariableNames', opts.VariableNames(2:end));

    %将原始数据对齐到小时网格
    [~, idx] = ismember(data.Time, hourly_data.Time);
    valid_idx = idx(idx > 0);  % 只保留正整数索引
    corresponding_data_rows = find(idx > 0);  % 原始数据中对应的行

    %填充可对齐数据
    numeric_cols = {'now_temp', 'high_temp', 'low_temp', 'wind_speed', 'humid'};
    for i = 1:length(numeric_cols)
        colName = numeric_cols{i};
        if ismember(colName, data.Properties.VariableNames) &&...
           ismember(colName, hourly_data.Properties.VariableNames)
            hourly_data.(colName)(valid_idx) = data.(colName)(corresponding_data_rows);
        end
    end

    %填充文本数据
    if ismember('weather', data.Properties.VariableNames)
        hourly_data.weather(valid_idx) = data.weather(corresponding_data_rows);
    end
    if ismember('wind_direct', data.Properties.VariableNames)
        hourly_data.wind_direct(valid_idx) = data.wind_direct(corresponding_data_rows);
    end

    %第六步：数值列插值
    numeric_cols = {'now_temp', 'high_temp', 'low_temp', 'wind_speed', 'humid'}; % 确保这些列是数值类型

    for i = 1:length(numeric_cols)
        colName = numeric_cols{i};
        if ismember(colName, data.Properties.VariableNames)
            if isnumeric(data.(colName))
                data.(colName) = fillmissing(data.(colName),'movmean', 2);
                hourly_data.(colName) = fillmissing(hourly_data.(colName), 'linear', 'EndValues', 'nearest');
            else
                warning('列 %s 不是数值类型，已跳过 movmean 填充。', colName);
            end
        end
    end

    %处理字符串天气和风向
    if ismember('weather', data.Properties.VariableNames)
        data.weather = fillmissing(data.weather, 'nearest');
        hourly_data.weather = fillmissing(hourly_data.weather, 'nearest');
        
        % 替换中文天气描述为英文
        for i = 1:length(chinese_weather)
            data.weather(strcmp(data.weather, chinese_weather{i})) = english_weather{i};
            hourly_data.weather(strcmp(hourly_data.weather, chinese_weather{i})) = english_weather{i};
        end
    end

    if ismember('wind_direct', data.Properties.VariableNames)
        data.wind_direct = fillmissing(data.wind_direct, 'nearest');
        hourly_data.wind_direct = fillmissing(hourly_data.wind_direct, 'nearest');
        
        % 替换中文风向为英文
        for i = 1:length(chinese_wind)
            data.wind_direct(strcmp(data.wind_direct, chinese_wind{i})) = english_wind{i};
            hourly_data.wind_direct(strcmp(hourly_data.wind_direct, chinese_wind{i})) = english_wind{i};
        end
    end

    %提取日期
    dates = dateshift(hourly_data.Time,'start', 'day');
    unique_dates = unique(dates);

    for d = 1:length(unique_dates)
        day_mask = (dates == unique_dates(d));
        original_mask = dateshift(data.Time,'start', 'day') == unique_dates(d);
        day_weather = data.weather(original_mask);

        %统计最高频天气（处理并列情况）
        if ~isempty(day_weather)
            [counts, values] = histcounts(categorical(day_weather));
            max_count = max(counts);
            candidates = values(counts == max_count);

            valid_idx = find(candidates ~= "", 1);
            if ~isempty(valid_idx)
                dominant_weather = candidates(valid_idx);
            else
                dominant_weather = "";
            end
        else
            dominant_weather = "";
        end

        hourly_data.weather(day_mask) = dominant_weather;
    end

    hourly_data.wind_direct = fillmissing(hourly_data.wind_direct, 'nearest');

    if ismember('sunrise_time', data.Properties.VariableNames)
        if all(timeofday(data.sunrise_time) == 0)
            data.sunrise_time = dateshift(data.sunrise_time,'start', 'day') + hours(6);
        end
    end

    if ismember('sunset_time', data.Properties.VariableNames)
        if all(timeofday(data.sunset_time) == 0)
            data.sunset_time = dateshift(data.sunset_time,'start', 'day') + hours(18);
        end
    end

    sun_data = table(data.Time, data.sunrise_time, data.sunset_time,...
        'VariableNames', {'Time','sunrise','sunset'});
    sun_data.Date = dateshift(sun_data.Time,'start', 'day');
    sun_data = varfun(@(x) x(1), sun_data, 'GroupingVariables', 'Date');

    for d = 1:length(unique_dates)
        day_mask = (dates == unique_dates(d));
        date_idx = find(sun_data.Date == unique_dates(d), 1);

        if ~isempty(date_idx)
            hourly_data.sunrise_time(day_mask) = sun_data.Fun_sunrise(date_idx);
            hourly_data.sunset_time(day_mask) = sun_data.Fun_sunset(date_idx);
        end
    end

    %确保没有剩余缺失值
    hourly_data = standardizeMissing(hourly_data, {""});
    hourly_data = fillmissing(hourly_data, 'nearest', 'DataVariables', @isnumeric);
    %输出
    writetable(hourly_data, sprintf('电站%d天气数据_清洗后.xlsx', file_num),...
        'WriteMode', 'overwritesheet',...
        'Sheet', 'Hourly Data');

    disp(['处理完成！共生成 ' num2str(height(hourly_data)) ' 条小时数据']);
end


%% 对三个表格的数据进行合并，以第三个表格为基准，按照时间匹配并合并前两个表格的第二列数据
% 假设要处理的电站编号范围是 1 到 4，你可以根据实际情况修改
for file_num = 1:4
    % 生成文件名
    file1 = sprintf('电站%d发电数据__每小时汇总.xlsx', file_num);
    file2 = sprintf('电站%d环境监测仪数据.xlsx', file_num);
    file3 = sprintf('电站%d天气数据_清洗后.xlsx', file_num);

    % 读取表格数据
    data1 = readtable(file1);
    data2 = readtable(file2);
    data3 = readtable(file3);

    % 将三个表格中的时间列都转换为 datetime 类型
    data1.DateTime = datetime(data1.DateTime, 'InputFormat', 'yyyy/MM/dd HH:mm');
    data2.DateTime = datetime(data2.DateTime, 'InputFormat', 'yyyy/MM/dd HH:mm');
    data3.Time = datetime(data3.Time, 'InputFormat', 'yyyy/MM/dd HH:mm');

    % 以第三个表格为基准，按照时间匹配并合并前两个表格的第二列数据
    for i = 1:height(data3)
        currentTime = data3.Time(i);
        % 查找第一个表格中匹配的行
        idx1 = find(data1.DateTime == currentTime);
        if ~isempty(idx1)
            % 避免多个匹配值导致的赋值错误，只取第一个匹配值
            data3.generated_energy_kwh(i) = data1.generated_energy_kwh(idx1(1));
        else
            data3.generated_energy_kwh(i) = NaN;
        end
        % 查找第二个表格中匹配的行
        idx2 = find(data2.DateTime == currentTime);
        if ~isempty(idx2)
            data3.radiant_quantity_w_m2_(i) = data2.radiant_quantity_w_m2_(idx2(1));
        else
            data3.radiant_quantity_w_m2_(i) = NaN;
        end
    end

    % 输出合并后的表格
    outputFile = sprintf('电站%d的总数据.xlsx', file_num);
    writetable(data3, outputFile);
    fprintf('电站 %d 的总数据已输出\n', file_num);
end

disp('已完成！！')