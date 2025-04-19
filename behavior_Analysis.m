%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%  Single-Run Behavior Analysis with Trigger Detection         %%%
%%%             For Bessel 2P microscopy data only               %%%
%%%                       Last Updated: MM/DD/YY                 %%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all
clear all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%            PATH SPECIFICATION                          %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% User needs to specify these paths
base_folder = '/path/to/your/experiment_folder'; 
video_folder_name = 'VideoXZ';      % Video folder to analyze
trigger_filename = 'Run_XYZ.mat';    % Trigger file to use

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%            Animal data - adjust info below!            %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
date = 'YY_MM_DD';          % Experiment date
animal_id = 'Animal_XYZ';   % Animal identifier
run_num = 'runXY';          % Run number

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                    Set up directories                  %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
root_folder = fullfile(base_folder, video_folder_name);
save_folder = fullfile(base_folder, 'Analysis_Results');  
accel_file = fullfile(base_folder, trigger_filename);

% Create directories if they don't exist
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end

save_fig = fullfile(save_folder, 'figures');
save_mat = save_folder;

if ~exist(save_fig, 'dir')
    mkdir(save_fig);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                         Sort Files                         %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filenames = natsortfiles(dir(root_folder));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                           Pupil                            %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pupil_raw = [];
pupil_smooth = [];
trigger = [];
pupil_data_available = false;

try
    [pupil_raw, pupil_smooth, trigger] = pupil2P(root_folder);
    pupil_data_available = true;
    fprintf('Pupil data loaded successfully\n');
catch ME
    warning('Pupil data not found - skipping pupil analysis');
    fprintf('Error: %s\n', ME.message);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                 Plot pupil signal                         %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if pupil_data_available && ~isempty(pupil_raw)
    time = 0:X/ZZ:length(pupil_raw)/ZZ;
    time = time(1:end-1);

    t = tiledlayout(2,1);
    t.Title.String = sprintf('%s - %s - %s', animal_id, date, run_num);
    t.Title.FontWeight = 'bold';

    nexttile
    plot(time,pupil_raw)
    title('Raw pupil signal')
    xlabel('Time [s]')
    ylabel('Pupil dilation [%]')

    nexttile
    plot(time, pupil_smooth)
    title('Smoothed pupil signal')
    xlabel('Time [s]')
    ylabel('Pupil dilation [%]')

    save_filename = sprintf('%s_%s_%s_pupil.png', animal_id, date, run_num);
    exportgraphics(t, fullfile(save_fig, save_filename))
else
    disp('Skipping pupil plots - no data available');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                          Whisker                          %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
whisker_data_available = false;
whisker_vars = {'raw_pad', 'smooth_pad', 'raw_long', 'smooth_long'};
for i = 1:length(whisker_vars)
    eval(sprintf('%s = [];', whisker_vars{i}));
end

try
    [whisker_raw_pad, whisker_smooth_pad, whisker_raw_long, whisker_smooth_long] = ...
        whisking(root_folder, save_folder, animal_id, date, run_num);
    whisker_data_available = true;
catch ME
    warning('Whisker data not found - skipping whisker analysis');
    fprintf('Error: %s\n', ME.message);
end

if whisker_data_available && pupil_data_available
    % Process whisker data with trigger
    whisker_types = {'raw_pad', 'smooth_pad', 'raw_long', 'smooth_long'};
    for i = 1:length(whisker_types)
        var_name = whisker_types{i};
        temp_var = eval(var_name) .* trigger;
        eval(sprintf('%s = temp_var(~isnan(temp_var));', var_name));
    end

    % Plot whisker signals
    t = tiledlayout(2,1, 'TileSpacing','compact');
    t.Title.String = sprintf('%s - %s - %s', animal_id, date, run_num);
    
    nexttile
    plot(time, whisker_smooth_long, time, whisker_raw_long)
    title('Long whiskers')
    xlabel('Time [s]')
    ylabel('Speed [%]')
    
    nexttile
    plot(time, whisker_smooth_pad, time, whisker_raw_pad)
    title('Whisker pad')
    xlabel('Time [s]')
    ylabel('Speed [%]')
    
    save_filename = sprintf('%s_%s_%s_whisker.png', animal_id, date, run_num);
    exportgraphics(t, fullfile(save_fig, save_filename))

    % User selection for analysis
    whisker_choice = input('Choose whisker signal for analysis (0=Long, 1=Pad): ');
    if whisker_choice == 0
        whisker = whisker_smooth_long;
        settings.binning_choice = 'long';
    else
        whisker = whisker_smooth_pad;
        settings.binning_choice = 'pad';
    end

    threshold = input("Enter threshold value [0-1]: ");
    whisker_bins = thresholding(whisker, threshold);

    % Plot binned data
    t = tiledlayout(2,1);
    t.Title.String = sprintf('%s - %s - %s', animal_id, date, run_num);
    
    nexttile
    plot(time, whisker)
    title('Whisking signal')
    xlabel('Time [s]')
    
    nexttile
    plot(time, whisker_bins)
    title('Binned signal')
    ylim([0,2])
    xlabel('Time [s]')
    
    save_filename = sprintf('%s_%s_%s_bins.png', animal_id, date, run_num);
    exportgraphics(t, fullfile(save_fig, save_filename))
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                     Accelerometer Data                    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
accel_data_available = false;
accel_vars = {'accX', 'accY', 'accZ', 'time_accel', 'Fs'};
for i = 1:length(accel_vars)
    eval(sprintf('info.%s = [];', accel_vars{i}));
end

try
    accel_data = load(accel_file);
    
    if istimetable(accel_data.data.ai)
        accel = timetable2table(accel_data.data.ai);
        accel = table2array(accel(:, 3:5));
    else
        accel = accel_data.analogInput(:, 3:5);
    end

    Fs = ZYX;
    duration = ZZZ; % Recording duration in seconds
    N = Fs * duration;
    accel = accel(1:min(N, size(accel,1)), :);
    
    info.accX = accel(:,1);
    info.accY = accel(:,2);
    info.accZ = accel(:,3);
    info.time_accel = (0:size(accel,1)-1)/Fs;
    info.Fs = Fs;
    
    accel_data_available = true;
catch ME
    warning('Accelerometer data not found');
    fprintf('Error: %s\n', ME.message);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                         Save Data                         %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
info.animal_id = animal_id;
info.date = date;
info.run = run_num;

% Organize data structures
pupil_data = struct('raw', pupil_raw, 'smooth', pupil_smooth);

whisker_data = struct();
if exist('whisker_bins', 'var')
    whisker_data = struct(...
        'bins', whisker_bins,...
        'raw_long', whisker_raw_long,...
        'raw_pad', whisker_raw_pad,...
        'smooth_long', whisker_smooth_long,...
        'smooth_pad', whisker_smooth_pad);
end

settings = struct(...
    'root_folder', root_folder,...
    'save_folder', save_folder,...
    'threshold', ifexist('threshold', 'var', []),...
    'trigger', trigger);

% Save results
save_filename = fullfile(save_mat, sprintf('%s_%s_%s_behavior.mat', animal_id, date, run_num));
save(save_filename, 'pupil_data', 'whisker_data', 'info', 'settings');

fprintf('\nAnalysis complete for %s - %s!\n', animal_id, run_num);
