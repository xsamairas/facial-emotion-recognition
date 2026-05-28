%% Initialize and start experiment

% Group 2: Danny Aguilar, Andrew Quihuiz, Samaira Shah, Darren Ung

% Set parameters and initialize variables

load g2_faces.mat; % Please make sure this is in your working directory.

number_trials = 24;
number_people = repmat([1 2 3 4 5 6], 1, number_trials/6); % not technically part of the calc but we still need to know
ishappy   = repmat([1 0 1 0 1 0 1 0], 1, number_trials/8); % 1 = happy, 0 = sad
isup      = repmat([1 1 1 1 0 0 0 0], 1, number_trials/8); % 1 = upright, 0 = inverted
iscovered = repmat([1 1 0 0 1 1 0 0], 1, number_trials/8); % 1 = masked, 0 = full

R = randperm(number_trials); % randoming trials and applying it
ishappy       = ishappy(R);
isup          = isup(R);
iscovered     = iscovered(R);
number_people = number_people(R);

trial_matrix = zeros(number_trials, 6); % Participant trial matrices are 24 x 6 each
column_names = {'trial_num' 'ishappy' 'isup' 'iscovered' 'response' 'rt'};

% Collect participant info
initials = input('Please enter your initials: ', 's');
output_file_name = ['face_data_' initials '.mat'];
clc

disp('Welcome to a facial recognition task!');
disp('In each trial, a happy or sad face will appear.');
disp('Press F for happy faces, and J for sad faces.');
disp('Make your responses as quickly and accurately as you can.');
disp(' ');
input('Press Enter to start...');

figure(5); clf; %set up the figure

for t = 1:number_trials

    % Retrieve this trial's values and store them within the loop
    person  = number_people(t);
    happy   = ishappy(t);
    up      = isup(t);
    covered = iscovered(t);

    % Select the correct image based on emotion and masking conditions, set
    % by prior trial values. Value img can only be one of these conditions.
    if happy == 1 && covered == 1
        img = masked_happy_img{person};
    elseif happy == 0 && covered == 1
        img = masked_sad_img{person};
    elseif happy == 1 && covered == 0
        img = full_happy_img{person};
    else  % happy == 0 && covered == 0
          % else is a catchall statement. We could've used another elseif
          % and ended the loop.
        img = full_sad_img{person};
    end

    % Invert image if isup == 0. We put this loop outside the conditions
    % loop so we don't have to copy and paste for each branch.
    if up == 0
        img = flipud(img);
    end

    % Display face stimulus, given prior condition.
    imshow(img);

    % Start timer and collect response
    tic;
    valid_key = 0;
    while valid_key == 0
        [~, ~, b] = ginput(1); % Tilde suppresses input -- see https://www.mathworks.com/help/matlab/matlab_prog/ignore-function-inputs.html
                               % If we used x and y, ginput would've asked
                               % for mouse input coordinates.

        if b == 102         % F = happy
            resp = 1;
            valid_key = 1;
        elseif b == 106     % J = sad
            resp = 0;
            valid_key = 1;
                            % This while loop needs an alternative way to stop
                            % or control the loop. valid_key stops the loop
                            % after it receives a valid key.
        end
    end
    rt = toc;               % Close "tic" with "toc" and save the reaction time into a variable.

    % Clear stimulus
    clf;

    % Record trial data
    trial_matrix(t, 1) = t;
    trial_matrix(t, 2) = happy;
    trial_matrix(t, 3) = up;
    trial_matrix(t, 4) = covered;
    trial_matrix(t, 5) = resp;
    trial_matrix(t, 6) = rt;

    save(output_file_name, 'trial_matrix', 'column_names');

    pause(0.5);

end

disp('Task complete. Thank you!');

% .mat database files for participants are output to the same
% directory/folder this .m script runs in.

%% ANOVA analysis!

% MAKE SURE YOU ARE IN YOUR .mat files DIRECTORY!

% Initialize analysis variables: we need to know participant_ids, make a
% unified trial matrix across all our participants, and locate only
% face_data_[initials].mat files within that working directory.

participant_ids = {};
all_data = [];
files = dir('face_data_*.mat');

% This loop iterates over arbitrary numbers of participant files,
% 
% loads only the trial_matrix variable of each file into a struct,
% 
% gets the number of rows/trials for each participant (could be less than
% 24),
% 
% creates another column vector of length n filled with participant number i,
% 
% and concatenates participant column at the end of each individual trial
% matrix and concatenates all participants on top of each other into a
% single all_data matrix.


for i = 1:length(files)
    loaded = load(files(i).name, 'trial_matrix');
    n = size(loaded.trial_matrix, 1);
    participant_col = repmat(i, n, 1);
    all_data = [all_data; loaded.trial_matrix, participant_col];
end

% Concatenating all_data in this specific way preserves the column
% names/meaning from trial_matrix: columns 1-6 are still trial_num,
% ishappy, isup, iscovered, rt, and response. We save as slightly
% different variable names to prevent overwriting the experiment variables
% (if we had just ran the experiment).

happy       = all_data(:, 2);
orientation = all_data(:, 3);
occlusion   = all_data(:, 4);
resp        = all_data(:, 5);
rt          = all_data(:, 6);
participant = all_data(:, 7);

accuracy = double(resp == happy); % Making sure the reponse is a number.

correct_idx = accuracy == 1; % Filter for accuracy, per Prof. Davidenko's
                             % recommendation. Thank you!

rt_correct          = rt(correct_idx);
orientation_correct = orientation(correct_idx);
occlusion_correct   = occlusion(correct_idx);
participant_correct = participant(correct_idx);

% RT analysis looks at orientation, occlusion, and participant info.
% We do need participants info for the ANOVA to make sense because they're a
% random effect (specified by 'random', 3). 'model' 'interaction' signals
% ANOVA to compute main effects of orientation and occlusion, and their
% interaction. Variable names make the final table easier to read.

[p_rt, tbl_rt, stats_rt] = anovan(rt_correct, {orientation_correct, occlusion_correct, participant_correct}, 'model', 'interaction', 'random', 3, 'varnames', {'orientation', 'occlusion', 'participant'});

% Accuracy analysis follows the same format as the prior ANOVA function,
% but examines accuracy instead.
[p_acc, tbl_acc, stats_acc] = anovan(accuracy, {orientation, occlusion, participant}, 'model', 'interaction', 'random',   3, 'varnames', {'orientation', 'ccclusion', 'participant'});

    % It turns out one of our group members' data file had zeroes from rows
    % 10 to 48, heavily skewing the data. After making sure all datasets
    % were clean, we no longer find any statistical significance for orientation,
    % occlusion, or their interaction. The slides have also been updated to
    % reflect this revision.

%% Figures for visualization

conditions = [orientation, occlusion]; % We concatenate orientation and
                                       % occlusion column vectors into an
                                       % Nx2 matrix of factor combos. This
                                       % leave us with four kinds of pairs:
                                       % [0,0], [0,1], [1,0], [1,1]
labels = {'Inverted/Full', 'Inverted/Masked', 'Upright/Full', 'Upright/Masked'};
                                       % Labels help us keep track...


% This next block calculates accuracy for figures with mean and STD.

for c = 1:4                 % Four iterations of the loop for four pairs.

    combo = unique(conditions, 'rows');  % gets the 4 unique combos. The additional
                                         % flag(? parameter?) tells MatLab to look
                                         % only at the rows, specifying
                                         % combo pairs.
    idx = orientation == combo(c,1) & occlusion == combo(c,2);
                                         % Create a logical vector the same
                                         % size as the data. Trials are
                                         % true if and only if orientation/
                                         % occlusion matches the first and
                                         % second columns of "combo".

    acc_mean(c) = mean(accuracy(idx));
                % Almost at the finish line now. We index into accuracy
                % with idx, then take the means. We can quickly get mean
                % because accuracy(idx) is a logical vector of 1's and 0's.
    acc_sem(c)  = std(accuracy(idx)) / sqrt(sum(idx));
                % Take the standard deviation of that same logical vector
                % and divide by the square root of the *sum*. This is the
                % standard error of the mean, which we need for errorbars.

                % As MatLab itself warns, acc_mean and acc_sem *grow* with
                % each turn of the loop. Since we only plan to chart the
                % four conditions, this should be OK. If we had many more
                % conditions, tracking this loop might be harder.

end

% MatLab provides dedicated bar() and errorbar() functions which can take
% variables directly. Because acc_mean and acc_sem are both four elements long,
% they appear on the figure just fine.

figure; bar(acc_mean); 
hold on;
errorbar(1:4, acc_mean, acc_sem, 'k.', 'LineWidth', 1.5);
                % This errorbar centers on the previous acc_mean bars and
                % displays the standard error of the mean. 'k.' makes a black
                % dot marker.
set(gca, 'XTickLabel', labels);
ylabel('Mean Accuracy');

% This block Calculates reaction time for figures with median and IQR (not mean).
% Much of the previous comments also apply here.

correct_idx = accuracy == 1;  % Also filter for accuracy here.

for c = 1:4
    idx = orientation == combo(c,1) & occlusion == combo(c,2) & correct_idx;
    rt_med(c)  = median(rt(idx));
    rt_err(c)  = iqr(rt(idx)) / 2;  % Just a rough spread estimate.
end

figure; bar(rt_med);
hold on;
errorbar(1:4, rt_med, rt_err, 'k.', 'LineWidth', 1.5);
set(gca, 'XTickLabel', labels);
ylabel('Median RT (s)');

    % With the proper datasets, all median bars and their IQRs show properly.
    % Interestingly, they do show a *nominal* difference across conditions.
    % In order, it proceeds upright/full, upright/masked, inverted/masked,
    % and inverted/full. With more subjects, we may be able to find (or at
    % least trend to) significance.