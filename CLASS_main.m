%%
% B. Bisighini et al., “Machine learning and reduced order modelling 
% for the simulation of braided stent deployment,” Front. Physiol., no. 
% March, pp. 1–18, 2023, doi: 10.3389/fphys.2023.1148540.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Binary classification: Prediction of deployment success.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load data
clc; clear all; close all

rng(1)

train_indices = table2array(readtable(['input/train_indices_300.txt'])); % change here to test the influence of the database size
test_indices = table2array(readtable('input/test_indices.txt'));

predictors_900 = readtable('input/rom_input_900.txt');
snapshots_900 = readtable('input/rom_output_900.txt');
snapshots_900.Properties.VariableNames = "rom";

predictors_train = predictors_900(train_indices, :);
predictors_test = predictors_900(test_indices, :);

snapshots_train = snapshots_900(train_indices, :);
snapshots_test = snapshots_900(test_indices, :);

nTraining = size(predictors_train, 1); 
nTesting = size(predictors_test, 1); 
nTot = nTraining+nTesting;
trainingData = [predictors_train, snapshots_train];
testingData = [predictors_test, snapshots_test];

%% Train

% Pick one model and train
% trainedModel = trainModelLogReg(trainingData);
% trainedModel = trainModelKNN(trainingData);
% trainedModel = trainModelTREE(trainingData);
% trainedModel = trainModelNaiveBayes(trainingData);
% trainedModel = trainModelSVM(trainingData);
trainedModel = trainModelNN(trainingData);

%% Evaluation
% Predict on the testing case
predictResult_vec = [];
trueResults_vec = [];
score_vec = [];
for i=1:nTesting
    [predictResult, score] = trainedModel.predictFcn(testingData(i,1:end-1));
    trueResults = table2array(testingData(i,end));
    predictResult_vec = [predictResult_vec; predictResult];
    trueResults_vec = [trueResults_vec; trueResults];
    score_vec = [score_vec; score];
end

% ROC curve
hold on  
rocObj = rocmetrics(trueResults_vec,score_vec(:,2),'1')
plot(rocObj,'LineWidth', 1.5)
title 'ROC curves'
set(gca,'Fontsize',20)
set(gca,'fontname','Calibri')
ylabel 'Sensitivity'
xlabel '1-Specificity'
axis square
legend

% Confusion matrix
C = confusionmat(trueResults_vec,predictResult_vec);
figure 
confusionchart(C,{'failure','success'});
set(gca,'Fontsize',20)
set(gca,'fontname','Calibri')
title('Confusion matrix');

% True positives, true negatives, false positives, false negatives
TP = C(1,1);
TN = C(2,2);
FP = C(1,2);
FN = C(2,1);

% Compute metrics
accuracy = (TP+TN)/(TP+TN+FP+FN)*100;
sensitivity = TP/(TP+FN)*100;
specificity = TN/(TN+FP)*100;
precision = TP/(TP+FP)*100;
F1_Score = 2*(sensitivity*precision)/(sensitivity+precision);

% Find false positives and false negatives indices
fP_indices = [];
fn_indices = [];
for i=1:length(trueResults_vec)
    if trueResults_vec(i) == 1 && predictResult_vec(i) == 0
        fn_indices = [fn_indices; test_indices(i)-1];
    elseif trueResults_vec(i) == 0 && predictResult_vec(i) == 1
        fP_indices = [fP_indices; test_indices(i)-1];
    end
end 

