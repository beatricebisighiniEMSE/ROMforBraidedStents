function [trainedClassifier] = trainModelNN(trainingData)

% Extract predictors and response
% This code processes the data into the right shape for training the
% model.
inputTable = trainingData;
predictorNames = {'Var1', 'Var2', 'Var3', 'Var4', 'Var5', 'Var6'};
predictors = inputTable(:, predictorNames);
response = inputTable.rom;
isCategoricalPredictor = [false, false, false, false, false, false];
rng(1)

% Train a classifier
% This code specifies all the classifier options and trains the classifier.
classificationNeuralNetwork = fitcnet(...
    predictors, ...
    response, ...
    'LayerSizes', [30 20 10], ...
    'Activations', 'relu', ...
    'Lambda', 0.00, ...
    'IterationLimit', 1e3, ...
    'Standardize', true, ...
    'ClassNames', [0; 1],...
    'Verbose', 0);

% Create the result struct with predict function
predictorExtractionFcn = @(t) t(:, predictorNames);
neuralNetworkPredictFcn = @(x) predict(classificationNeuralNetwork, x);
trainedClassifier.predictFcn = @(x) neuralNetworkPredictFcn(predictorExtractionFcn(x));