%%
% B. Bisighini et al., “Machine learning and reduced order modelling 
% for the simulation of braided stent deployment,” Front. Physiol., no. 
% March, pp. 1–18, 2023, doi: 10.3389/fphys.2023.1148540.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reduced order modelling: Prediction of the stent deployed configuration.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
% CHECK SINGULAR VALUES DECAY TO CHOOSE NUMBER OF BASIS.

%% Load data
clear all; close all; clc

% read stent positions and connectivity
pos = table2array(readtable('pos.txt'));
conn = table2array(readtable('conn.txt'));
pos_vec = reshape(pos', 1, size(pos,1)*size(pos,2));
pos_vec = pos_vec';

% read the snapshots and predictors database 
predictors_900 = table2array(readtable('input/rom_input_900.txt'));
snapshots_900 = table2array(readtable(strcat('input/rom_output_disp_900.txt')));
snapshots_900 = snapshots_900';

% select the sub-database (test cases are fixed: Ntest=50)
test_indices = table2array(readtable('input/test_indices_regr.txt'));
train_indices = table2array(readtable('input/train_indices_900_regr.txt')); % change here for 150, 300, 600, 900
predictors_train = predictors_900(train_indices, :);
predictors_test = predictors_900(test_indices, :);
snapshots_train = snapshots_900(:, train_indices);
snapshots_test = snapshots_900(:, test_indices);

%% Singular value decompution
[U,Sigma,Z] = svd(snapshots_train);

%% Compute cumulative variance 
Nh = size(snapshots_train,1);
Ns = size(snapshots_train,2);

eps_tol = 0.01;
error_num = 0;
error_den = 0;
cum_var = zeros(30,1);

for i=1:30
    error_den = error_den + Sigma(i,i)^2;
end

error_comp = error_num/error_den;

L = 0;
for i=1:30
    L = L+1;
    error_num = error_num + Sigma(L,L)^2;
    error_comp = error_num/error_den;
    cum_var(L) = error_comp;
end

%% Plot
hold on 
plot(1:length(cum_var), cum_var*100, 'LineWidth', 2)
xlabel('{\it L}');
ylabel({'Cumulative sum of the first {\it L}-singular values'});
set(gca,'Fontsize',20)
set(gca,'fontname','Calibri')
xticks([0:5:30]);      
grid on
axis square
