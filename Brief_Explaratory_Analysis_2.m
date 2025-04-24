% Load the cleaned dataset
data = readtable('cleaned_bangalore_zomato_data.csv');

%% Exploratory Data Analysis (EDA)

% Univariate Analysis
figure;
histogram(data.Time_taken_min);
title('Distribution of Delivery Times');
xlabel('Time Taken (minutes)');
ylabel('Frequency');

% Bivariate Analysis
figure;
scatter(data.Distance, data.Time_taken_min);
title('Delivery Time vs Distance');
xlabel('Distance (km)');
ylabel('Time Taken (minutes)');

% Multivariate Analysis
corr_matrix = corr(table2array(data(:, {'Time_taken_min', 'Distance', 'multiple_deliveries'})), 'type', 'Pearson');
figure;
imagesc(corr_matrix);
colorbar;
title('Correlation Matrix');

% Categorical Data Analysis
figure;
boxplot(data.Time_taken_min, data.Weather_conditions_Sunny); % Change this to one of we weather condition columns
title('Delivery Time by Weather Conditions');
xlabel('Weather Conditions');
ylabel('Time Taken (minutes)');

% Temporal Analysis
figure;
plot(data.Order_Hour, data.Time_taken_min, '.');
title('Delivery Time by Order Hour');
xlabel('Order Hour');
ylabel('Time Taken (minutes)');

%% Feature Engineering

% Derived Features
data.Distance_Time_Ratio = data.Distance ./ data.Time_taken_min;

% Calculate Weather Severity Index
weather_vars = {'Weather_conditions_Cloudy', 'Weather_conditions_Fog', ...
                'Weather_conditions_Sandstorms', 'Weather_conditions_Stormy', ...
                'Weather_conditions_Sunny', 'Weather_conditions_Windy'};
data.Weather_Severity_Index = sum(data{:, weather_vars}, 2);

% Interaction Features
data.Weather_Traffic_Interaction = data.Weather_Severity_Index .* data.Road_traffic_density_High; % Adjust as necessary
data.Distance_Vehicle_Interaction = data.Distance .* data.Type_of_vehicle_motorcycle; % Adjust as necessary

% Temporal Features
data.Time_of_Day = zeros(height(data), 1);
data.Time_of_Day(data.Order_Hour >= 6 & data.Order_Hour < 12) = 1; % Morning
data.Time_of_Day(data.Order_Hour >= 12 & data.Order_Hour < 18) = 2; % Afternoon
data.Time_of_Day(data.Order_Hour >= 18 & data.Order_Hour < 24) = 3; % Evening
data.Time_of_Day = categorical(data.Time_of_Day, [1, 2, 3], {'Morning', 'Afternoon', 'Evening'});

data.Day_of_Week = weekday(data.Order_Hour);

% Spatial Features (assuming we have latitude and longitude data)
data.Proximity_to_Mall = sqrt((data.Delivery_location_latitude - 12.9699).^2 + (data.Delivery_location_longitude - 77.5980).^2);
data.Neighborhood_Density = 1000 ./ (data.Proximity_to_Mall + 1); % Assuming higher density near malls

% Display the updated dataset
disp(data);