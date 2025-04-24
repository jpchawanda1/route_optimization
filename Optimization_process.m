% Load the matrices from CSV files
% These matrices represent the distances and times between delivery locations
distanceMatrix = readmatrix('distance_matrix_adjusted.csv');
timeMatrix = readmatrix('time_matrix_adjusted.csv');

% Define ACO parameters
numAnts = 50; % Number of ants used in the algorithm
numIterations = 200; %Number of iterations for the ACO algorithm
alpha = 1; %Influence of pheromone
beta = 2; %Influence of distance
evaporationRate = 0.5; %Rate at which pheromone evaporates

% Define number of runs
% We will run the ACO algorithm multiple times to find the best route
numRuns = 10;

% Initialize arrays to store results of multiple runs
allBestRoutes = cell(numRuns, 1);  % Store best routes for each run
allBestDistances = zeros(numRuns, 1);  % Store best distances for each run
allBestTimes = zeros(numRuns, 1);  % Store best times for each run
overallBestRoute = [];  % Store the overall best route found
overallBestDistance = inf;  % Initialize best distance as infinity
overallBestTime = inf;  % Initialize best time as infinity

% Fix the random seed for reproducibility
% This ensures that the results are consistent across multiple runs
rng(1);

% Run ACO multiple times
for run = 1:numRuns
    % Call the ACO function to find the best route, distance, and time
    [bestRoute, bestDistance, bestTime] = aco(distanceMatrix, timeMatrix, numAnts, numIterations, alpha, beta, evaporationRate);
    allBestRoutes{run} = bestRoute;
    allBestDistances(run) = bestDistance;
    allBestTimes(run) = bestTime;

    % Update the overall best route if a better route is found
    if bestDistance < overallBestDistance
        overallBestDistance = bestDistance;
        overallBestRoute = bestRoute;
    end

    % Update the overall best time if a better time is found
    if bestTime < overallBestTime
        overallBestTime = bestTime;
        overallBestRoute = bestRoute;
    end
end

% Display results
disp('Results from multiple runs:');
for run = 1:numRuns
    disp(['Run ', num2str(run), ' - Best Distance: ', num2str(allBestDistances(run)), ', Best Time: ', num2str(allBestTimes(run))]);
end

% Display the overall best distance and time
disp(['Overall Best Distance: ', num2str(overallBestDistance)]);
disp(['Overall Best Time: ', num2str(overallBestTime)]);
disp('Overall Best Route:');
disp(overallBestRoute);

% Calculate statistics
meanDistance = mean(allBestDistances);
stdDistance = std(allBestDistances);
meanTime = mean(allBestTimes);
stdTime = std(allBestTimes);
disp(['Mean Distance: ', num2str(meanDistance)]);
disp(['Standard Deviation of Distances: ', num2str(stdDistance)]);
disp(['Mean Time: ', num2str(meanTime)]);
disp(['Standard Deviation of Times: ', num2str(stdTime)]);

% Plot the locations and overall best route
figure;
hold on;

% Plot all delivery locations
scatter(delivery_longitudes, delivery_latitudes, 100, 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r');

% Highlight the starting location 
scatter(delivery_longitudes(1), delivery_latitudes(1), 150, 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'g');

% Label all delivery locations
text(delivery_longitudes, delivery_latitudes, num2str((1:numLocations)'), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');

% Plot the route with arrows indicating direction
for i = 1:length(overallBestRoute)
    from = overallBestRoute(i);
    to = overallBestRoute(mod(i, length(overallBestRoute)) + 1);

    % Ensure indices are valid
    if from <= numLocations && to <= numLocations
        % Plot a line segment with a very small arrow
        quiver(delivery_longitudes(from), delivery_latitudes(from), ...
               delivery_longitudes(to) - delivery_longitudes(from), ...
               delivery_latitudes(to) - delivery_latitudes(from), ...
               0, 'b', 'LineWidth', 1, 'MaxHeadSize', 0.1, 'AutoScale', 'off');
    else
        error('Route contains invalid indices.');
    end
end

% Enhance the plot
xlabel('Longitude');
ylabel('Latitude');
title('Overall Best Delivery Route');
grid on;
hold off;
