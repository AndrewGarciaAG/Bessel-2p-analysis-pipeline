
%% 3D Image Stack Processor
% Description: Loads a 3D image stack (TIFF), splits into even/odd frames,
% creates various projections, and generates animated GIFs and JPEGs.
% Supports multiple projection types: max, mean, sum, min, median, std, var

%% Initialize
clc;
close all;
clear variables;

%% Get Input File
[inputFile, inputPath] = uigetfile('*.tif;*.tiff', 'Select TIFF stack');
if isequal(inputFile, 0)
    error('No file selected - script terminated');
end
inputFullPath = fullfile(inputPath, inputFile);

%% Create Output Directory
outputDir = fullfile(inputPath, 'processed_output');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    fprintf('Created output directory: %s\n', outputDir);
end

%% Load TIFF Stack
fprintf('Loading TIFF stack: %s\n', inputFile);

% Get stack metadata
metadata = imfinfo(inputFullPath);
numFrames = numel(metadata);
imgWidth = metadata(1).Width;
imgHeight = metadata(1).Height;

% Preallocate and load stack
stack = zeros(imgHeight, imgWidth, numFrames, 'uint16');
for i = 1:numFrames
    stack(:, :, i) = imread(inputFullPath, i);
end
fprintf('Loaded stack: %d x %d x %d (H x W x Frames)\n', ...
        imgHeight, imgWidth, numFrames);

%% Split Frames
fprintf('Splitting into even/odd frames...\n');
evenStack = stack(:, :, 2:2:end);
oddStack = stack(:, :, 1:2:end);

fprintf('Even frames: %d, Odd frames: %d\n', ...
        size(evenStack, 3), size(oddStack, 3));

%% Projection Parameters
projectionTypes = {'max', 'mean', 'sum', 'min', 'median'};
selectedType = questdlg('Select projection type:', ...
                       'Projection Type', ...
                       projectionTypes{:}, projectionTypes{1});

%% Create and Save Projections
fprintf('Creating "%s" projections...\n', selectedType);

% Create projections
projEven = create_projection(evenStack, selectedType);
projOdd = create_projection(oddStack, selectedType);

% Save as JPEG
save_jpeg(projEven, outputDir, 'even', selectedType);
save_jpeg(projOdd, outputDir, 'odd', selectedType);

%% Create Animated GIFs
fprintf('Generating GIF animations...\n');

% Parameters for GIF creation
delayTime = 0.1;  % seconds between frames
gifQuality = 90;  % quality percentage

create_gif(evenStack, outputDir, 'even', delayTime, gifQuality);
create_gif(oddStack, outputDir, 'odd', delayTime, gifQuality);

%% Complete
fprintf('Processing complete!\n');
disp('Results saved in:');
disp(outputDir);

%% Helper Functions
function projection = create_projection(stack, projType)
    % Create specified projection type from 3D stack
    switch lower(projType)
        case 'max'
            projection = max(stack, [], 3);
        case 'mean'
            projection = mean(stack, 3);
        case 'sum'
            projection = sum(stack, 3);
        case 'min'
            projection = min(stack, [], 3);
        case 'median'
            projection = median(stack, 3);
        case 'std'
            projection = std(double(stack), 0, 3);
        case 'var'
            projection = var(double(stack), 0, 3);
        otherwise
            error('Unsupported projection type: %s', projType);
    end
end

function save_jpeg(proj, outDir, stackType, projType)
    % Save projection as JPEG with proper scaling
    jpegPath = fullfile(outDir, sprintf('%s_%s_projection.jpg', ...
                  stackType, projType));
    
    % Normalize and convert to 8-bit
    img8bit = uint8(255 * mat2gray(proj));
    imwrite(img8bit, jpegPath, 'Quality', 95);
    fprintf('Saved %s projection: %s\n', stackType, jpegPath);
end

function create_gif(stack, outDir, stackType, delayTime, quality)
    % Create animated GIF from stack
    gifPath = fullfile(outDir, sprintf('%s_stack.gif', stackType));
    
    % Convert first frame
    firstFrame = uint8(255 * mat2gray(stack(:, :, 1)));
    imwrite(firstFrame, gifPath, 'gif', ...
            'LoopCount', Inf, ...
            'DelayTime', delayTime);
    
    % Add remaining frames
    for i = 2:size(stack, 3)
        frame = uint8(255 * mat2gray(stack(:, :, i)));
        imwrite(frame, gifPath, 'gif', ...
                'WriteMode', 'append', ...
                'DelayTime', delayTime);
    end
    fprintf('Saved %s GIF: %s\n', stackType, gifPath);
end
