% Importing and Cleaning Zomato Delivery Data 
% We also transformed it for easy computations

% Let's creatte import options based on the CSV file
opts = detectImportOptions('bangalore_zomato_data.csv');

% We'll specify formats for the date and time columns
opts = setvaropts(opts, 'Order_Date', 'Type', 'string');
opts = setvaropts(opts, {'Time_Orderd', 'Time_Order_picked'}, 'Type', 'string');

% Now we read the data using the specified options
data = readtable('bangalore_zomato_data.csv', opts);

% Convert Order_Date to datetime format
data.Order_Date = datetime(data.Order_Date, 'InputFormat', 'dd-MM-yyyy', 'Format', 'dd-MM-yyyy');
invalidDates = isnat(data.Order_Date);
data.Order_Date(invalidDates) = datetime(data.Order_Date(invalidDates), 'InputFormat', 'M/d/yyyy', 'Format', 'dd-MM-yyyy');

% Convert Time_Ordered and Time_Order_picked to datetime format
data.Time_Orderd = datetime(data.Time_Orderd, 'InputFormat', 'HH:mm', 'Format', 'HH:mm');
data.Time_Order_picked = datetime(data.Time_Order_picked, 'InputFormat', 'HH:mm', 'Format', 'HH:mm');

% Handle special cases for Time_Order_picked where values might be missing
data.Time_Order_picked = fillmissing(data.Time_Order_picked, 'constant', NaT);

% Handle numeric time values that might have slipped through
numericTimes = ~ismissing(data.Time_Order_picked) & ~isnan(str2double(data.Time_Order_picked));
numericValues = str2double(data.Time_Order_picked(numericTimes));
data.Time_Order_picked(numericTimes) = datetime(numericValues * 24 * 3600, 'ConvertFrom', 'epochtime', 'Epoch', '1970-01-01', 'Format', 'HH:mm');

% Convert latitude and longitude columns to numeric format
data.Restaurant_latitude = double(data.Restaurant_latitude);
data.Restaurant_longitude = double(data.Restaurant_longitude);
data.Delivery_location_latitude = double(data.Delivery_location_latitude);
data.Delivery_location_longitude = double(data.Delivery_location_longitude);

% Check for any inconsistent geolocation data
geoVars = {'Restaurant_latitude', 'Restaurant_longitude', 'Delivery_location_latitude', 'Delivery_location_longitude'};
for var = geoVars
    data.(var{1})(data.(var{1}) < -90 | data.(var{1}) > 90) = NaN;
end

% Ensure consistency in categorical variables
catVars = {'Weather_conditions', 'Road_traffic_density', 'Vehicle_condition', 'Type_of_order', 'Type_of_vehicle', 'City', 'Festival'};
for var = catVars
    data.(var{1}) = categorical(data.(var{1}));
    data.(var{1}) = standardizeMissing(data.(var{1}), {'', 'NaN'});
end

% Handle numeric columns and ensure no negative values
data.multiple_deliveries = double(data.multiple_deliveries);
data.multiple_deliveries(data.multiple_deliveries < 0) = NaN;

data.Time_taken_min = double(data.Time_taken_min);
data.Time_taken_min(data.Time_taken_min < 0) = NaN;

% Remove rows with critical missing values to maintain data integrity
criticalVars = {'Restaurant_latitude', 'Restaurant_longitude', 'Delivery_location_latitude', 'Delivery_location_longitude', 'Time_taken_min'};
data = rmmissing(data, 'DataVariables', criticalVars);

% Calculate Time_Difference in minutes for further analysis
data.Time_Difference = minutes(data.Time_Order_picked - data.Time_Orderd);
data.Time_Difference(data.Time_Difference < 0) = data.Time_Difference(data.Time_Difference < 0) + 1440; % 1440 minutes in a day

% Impute missing values for Time_Difference
data.Time_Difference = fillmissing(data.Time_Difference, 'constant', 0); % Assuming 0 minutes if missing

% Extract Order_Hour from Time_Ordered for potential time-based analysis
data.Order_Hour = hour(data.Time_Orderd);

% Impute missing values for Order_Hour
data.Order_Hour = fillmissing(data.Order_Hour, 'constant', 0); % Assuming 0 if missing (or we can choose a different strategy)

% Impute missing values for non-critical variables manually
data.multiple_deliveries = fillmissing(data.multiple_deliveries, 'constant', 0);

% Impute missing values for categorical variables with the most frequent value
for var = {'Weather_conditions', 'Road_traffic_density', 'Vehicle_condition', 'Type_of_order', 'Type_of_vehicle'}
    catVar = var{1};
    mostFrequentValue = mode(data.(catVar));
    data.(catVar) = fillmissing(data.(catVar), 'constant', mostFrequentValue);
end

% Calculate distance using the Haversine formula for accurate distance measurement
R = 6371; % Radius of the Earth in kilometers
lat1 = deg2rad(data.Restaurant_latitude);
lon1 = deg2rad(data.Restaurant_longitude);
lat2 = deg2rad(data.Delivery_location_latitude);
lon2 = deg2rad(data.Delivery_location_longitude);

dlat = lat2 - lat1;
dlon = lon2 - lon1;

a = sin(dlat/2).^2 + cos(lat1) .* cos(lat2) .* sin(dlon/2).^2;
c = 2 * atan2(sqrt(a), sqrt(1-a));
data.Distance = R * c; % Distance in kilometers

% One-hot encode categorical variables using dummyvar and table operations for compatibility with machine learning algorithms
categoricalVars = {'Weather_conditions', 'Road_traffic_density', 'Vehicle_condition', 'Type_of_order', 'Type_of_vehicle'};
for var = categoricalVars
    catVar = var{1};
    dummies = dummyvar(data.(catVar));
    dummyNames = strcat(catVar, '_', string(categories(data.(catVar))));
    data = [data, array2table(dummies, 'VariableNames', dummyNames)];
    data.(catVar) = [];
end

% Drop unnecessary columns to clean up our dataset
data = removevars(data, {'Festival', 'City', 'Order_Date', 'Time_Orderd', 'Time_Order_picked'});

% Split data into training and testing sets (70% training, 30% testing) for our model evaluation
cv = cvpartition(height(data), 'HoldOut', 0.3);
trainData = data(training(cv), :);
testData = data(test(cv), :);

% Display the first few rows of our cleaned dataset to verify the process
disp(head(data));

% The final data we Exported the cleaned data to a CSV file for further analysis and model building
writetable(data, 'cleaned_bangalore_zomato_data.csv');
