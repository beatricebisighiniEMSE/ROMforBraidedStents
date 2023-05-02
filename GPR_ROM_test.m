%%
% B. Bisighini et al., “Machine learning and reduced order modelling 
% for the simulation of braided stent deployment,” Front. Physiol., no. 
% March, pp. 1–18, 2023, doi: 10.3389/fphys.2023.1148540.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reduced order modelling: Prediction of the stent deployed configuration.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
% STUDY THE EFFECT OF THE NUMBER OF REDUCED BASIS ON THE PREDICTION ERROR. 
% CHANGE PREDICTOR FILENAME TO SEE THE EFFECT ALSO OF THE TRAINING DATABASE
% SIZE ('train_indices_900_regr') AND THE PREDICTOR TYPE (BEZIER OR CENTERLINE)
% ('rom_output_disp_900').

% For the training database size, you can choose between: 
% 'input/train_indices_150_regr.txt' 
% 'input/train_indices_300_regr.txt'
% 'input/train_indices_600_regr.txt'
% 'input/train_indices_900_regr.txt'

% For the predictor type, you can choose between: 
% 'input/rom_input_900.txt' (Bezier-based)
% 'input/rom_input_900_cl_3.txt' (Centerline-based)
% 'input/rom_input_900_cl_5.txt' (Centerline-based)
% 'input/rom_input_900_cl_8.txt' 

%% Load data
clear all; close all; clc

% read stent positions and connectivity
pos = table2array(readtable('pos.txt'));
conn = table2array(readtable('conn.txt'));
pos_vec = reshape(pos', 1, size(pos,1)*size(pos,2));
pos_vec = pos_vec';

% read the whole snapshots and predictors database 
predictors_900 = table2array(readtable('input/rom_input_900.txt')); % change here for predictor type
snapshots_900 = table2array(readtable(strcat('input/rom_output_disp_900.txt')));
snapshots_900 = snapshots_900';

% select the sub-database (test cases are fixed: Ntest=50)
test_indices = table2array(readtable('input/test_indices_regr.txt'));
train_indices = table2array(readtable('input/train_indices_900_regr.txt')); % change here for training database size
predictors_train = predictors_900(train_indices, :);
predictors_test = predictors_900(test_indices, :);
snapshots_train = snapshots_900(:, train_indices);
snapshots_test = snapshots_900(:, test_indices);

%% Singular value decomposition
[U,Sigma,Z] = svd(snapshots_train);

%% Analyse the influence of number of reduced basis 
err_vec_p_L = [];
err_vec_ro_L = [];

for L =  5:20

    % create reduced basis matrix (first L columns of U)
    V = U(:,1:L);
    VTuh = V'*snapshots_train; %projection coefficients

    % single-output GPR 
    pi_GP = cell(1,L);
    for l = 1:L
        s = sprintf('       %d = out of %d ',l,L);
        disp(s);
        pi_GP_i = fitrgp(predictors_train,VTuh(l,:),'KernelFunction', 'ardmatern52', 'Standardize', true);
        pi_GP{l} = pi_GP_i;
    end

    % test
    Ntest = size(predictors_test,1);
    err_vec_p = zeros(Ntest, 1);
    err_vec_ro = zeros(Ntest, 1);
    alpha = 0.005;
    for n = 1:Ntest

        s = sprintf('case %d = out of %d ',n, Ntest);
        disp(s);

        % full-order solution
        predictors_test_n = predictors_test(n, :);
        uFOM = snapshots_test(:, n);
        uFOM_reshaped = reshape(uFOM', 3, int64(size(uFOM, 1)/3));
        uFOM_reshaped = uFOM_reshaped';

        % reduced-order solution
        uRO = V*V'*uFOM;
        uRO_reshaped = reshape(uRO', 3, int64(size(uRO, 1)/3));
        uRO_reshaped = uRO_reshaped';
        diff = uRO_reshaped - uFOM_reshaped;
        err_vec_ro(n) = mean(sqrt(sum(diff.^2,2)));

        % recover output for a new parameter value predictors_test_n
        uL = zeros(L, 1);
        covmat = zeros(L, L);
        for l = 1:L
            [uL(l), covmat(l,l), ci] = predictExactWithCov(pi_GP{l}.Impl,predictors_test_n,alpha);
        end
        up = V*uL;
        up_reshaped = reshape(up', 3, []);
        up_reshaped = up_reshaped';
        diff = up_reshaped - uFOM_reshaped;
        err = sqrt(sum(diff.^2,2));
        err_vec_p(n) = mean(err);

    end

    err_vec_p_L = [err_vec_p_L; mean(err_vec_p)];
    err_vec_ro_L = [err_vec_ro_L; mean(err_vec_ro)];


end
%% Plot
figure
plot(5:20, log10(err_vec_p_L), 'LineWidth', 2)
hold on
plot(5:20, log10(err_vec_ro_L), 'LineWidth', 2)
hold on
plot(5:20, log10(err_vec_p_L-err_vec_ro_L), 'LineWidth', 2)
xlabel('{\it L}');
ylabel('{Validation errors [mm]}');
set(gca,'Fontsize',20)
set(gca,'fontname','Calibri')
grid on
axis square
box on
