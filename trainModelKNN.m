function [trainedClassifier] = trainModelKNN(trainingData)

% Extract predictors and response
% This code processes the data into the right shape for training the
% model.
inputTable = trainingData;
predictorNames = {'Var1', 'Var2', 'Var3', 'Var4', 'Var5', 'Var6'};
predictors = inputTable(:, predictorNames);
response = inputTable.rom;
isCategoricalPredictor = [false, false, false, false, false, false];

% Train a classifier
% This code specifies all the classifier options and trains the classifier.
classificationKNN = fitcknn(...
    predictors, ...
    response, ...
    'Distance', 'mahalanobis', ...
    'Exponent', [], ...
    'NumNeighbors', 5, ...
    'DistanceWeight', 'squaredinverse', ...
    'Standardize', true, ...
    'ClassNames', [0; 1]);

% Create the result struct with predict function
predictorExtractionFcn = @(t) t(:, predictorNames);
knnPredictFcn = @(x) predict(classificationKNN, x);
trainedClassifier.predictFcn = @(x) knnPredictFcn(predictorExtractionFcn(x));
