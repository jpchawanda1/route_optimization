function [bestRoute, bestDistance, bestTime] = aco(distanceMatrix, timeMatrix, numAnts, numIterations, alpha, beta, evaporationRate)
    % Number of nodes (locations)
    numNodes = size(distanceMatrix, 1);
    % Initialize pheromone matrix with ones
    pheromoneMatrix = ones(numNodes, numNodes);
    % Initialize variables to store the best route, distance, and time
    bestRoute = [];
    bestDistance = inf;
    bestTime = inf;

    % Main loop for iterations
    for iter = 1:numIterations
        % Initialize arrays to store routes and their lengths/times for each ant
        allRoutes = zeros(numAnts, numNodes);
        allRouteLengths = zeros(numAnts, 1);
        allRouteTimes = zeros(numAnts, 1);

        % Loop over each ant
        for ant = 1:numAnts
            % Initialize the visited nodes array
            visited = false(numNodes, 1);           % Keep track of visited nodes
            % Start from the restaurant node
            currentNode = 1;                        
            visited(currentNode) = true;
            
            % Initialize the route 
            route = zeros(numNodes, 1);             
            route(1) = currentNode;

            % Construct the route for the ant
            for step = 2:numNodes
                % Calculate probabilities for next node based on pheromone and distance
                prob = pheromoneMatrix(currentNode, :) .^ alpha .* (1 ./ distanceMatrix(currentNode, :)) .^ beta;
                prob(visited) = 0; % Set probabilities of visited nodes to zero
                prob = prob / sum(prob); % Normalize probabilities

                % Select the next node based on probabilities
                nextNode = find(rand <= cumsum(prob), 1);
                if isempty(nextNode)
                    % If no valid next node, randomly select from remaining nodes
                    remainingNodes = find(~visited);
                    nextNode = remainingNodes(randi(length(remainingNodes)));
                end

                % Update the route and visited nodes
                route(step) = nextNode;
                visited(nextNode) = true;
                currentNode = nextNode;
            end

            % Store the route and its length/time
            allRoutes(ant, :) = route;
            allRouteLengths(ant) = sum(distanceMatrix(sub2ind(size(distanceMatrix), route(1:end-1), route(2:end))));
            allRouteTimes(ant) = sum(timeMatrix(sub2ind(size(timeMatrix), route(1:end-1), route(2:end))));
        end

        % Update pheromones
        pheromoneMatrix = pheromoneMatrix * (1 - evaporationRate);
        % Update pheromones based on routes found by ants
        for ant = 1:numAnts
            for step = 1:(numNodes - 1)
                pheromoneMatrix(allRoutes(ant, step), allRoutes(ant, step + 1)) = ...
                    pheromoneMatrix(allRoutes(ant, step), allRoutes(ant, step + 1)) + 1 / allRouteLengths(ant);
            end
        end

        % Find the best route of this iteration based on distance
        [minLength, minIndex] = min(allRouteLengths);
        if minLength < bestDistance
            bestDistance = minLength;
            bestRoute = allRoutes(minIndex, :);
        end

        % Find the best route of this iteration based on time
        [minTime, minIndex] = min(allRouteTimes);
        if minTime < bestTime
            bestTime = minTime;
            bestRoute = allRoutes(minIndex, :);
        end
    end
end
