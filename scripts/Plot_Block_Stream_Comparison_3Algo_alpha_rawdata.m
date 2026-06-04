%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File name: Plot_Block_Stream_Comparison_3Algo_alpha_rawdata.m
%
% Function:
%   Plot two PNG figures with enlarged fonts and updated legend labels:
%
%   Figure_Runtime_alpha50_rawdata.png
%       fixed k/n = 0.5
%
%   Figure_Runtime_alpha80_rawdata.png
%       fixed k/n = 0.8
%
% Each figure contains:
%   1. block-Toeplitz
%   2. block-Circulant
%   3. block-Modified Toeplitz
%   4. stream-total-Toeplitz
%   5. stream-total-Circulant
%   6. stream-total-Modified Toeplitz
%
% Open markers indicate stream mask-only time t_mask.
%
% Note:
%   This script only redraws the figures.
%   It does not rerun the benchmark.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
close all;
clc;

% -------------------------------------------------------------------------
% Load data
% -------------------------------------------------------------------------
B = load('Block_Runtime_3Algo_alpha_rawdata.mat');
S = load('Stream_Runtime_3Algo_alpha_rawdata.mat');

nList = B.nList;
alphaList = B.alphaList;

% -------------------------------------------------------------------------
% Important:
%   The old benchmark data may still contain algNames = {'Toeplitz',
%   'Circulant', 'Hayashi'}.
%
%   Here we override the display names only, without changing the data.
% -------------------------------------------------------------------------
algNamesPlot = {'Toeplitz', 'Circulant', 'Modified Toeplitz'};

% -------------------------------------------------------------------------
% Consistency check
% -------------------------------------------------------------------------
if any(S.nList ~= B.nList)
    error('nList mismatch between block and stream data.');
end

if any(S.alphaList ~= B.alphaList)
    error('alphaList mismatch between block and stream data.');
end

% -------------------------------------------------------------------------
% Style settings
% -------------------------------------------------------------------------
colors = lines(3);

% Enlarged font settings
fontAxes   = 20;   % tick labels
fontLabel  = 22;   % x/y labels
fontTitle  = 22;   % title
fontLegend = 16;   % legend

% Enlarged line and marker settings
lineWidthBlock  = 2.4;
lineWidthStream = 2.4;
markerSize      = 9;
scatterSize     = 120;

% -------------------------------------------------------------------------
% Plot each entropy-rate setting separately
% -------------------------------------------------------------------------
for ia = 1:length(alphaList)

    alpha = alphaList(ia);

    % Create figure and keep its handle explicitly
    fig = figure('Position', [100, 100, 1200, 820]);
    ax = axes(fig);
    hold(ax, 'on');

    % ---------------------------------------------------------------------
    % Block curves: solid lines
    % ---------------------------------------------------------------------
    for alg = 1:3
        yBlock = squeeze(B.T_median(ia,:,alg));

        plot(ax, nList, yBlock, '-', ...
            'Color', colors(alg,:), ...
            'LineWidth', lineWidthBlock, ...
            'Marker', 'o', ...
            'MarkerSize', markerSize, ...
            'DisplayName', ['Block ' algNamesPlot{alg}]);
    end

    % ---------------------------------------------------------------------
    % Stream total curves: dashed lines
    % ---------------------------------------------------------------------
    for alg = 1:3
        yStream = squeeze(S.Ttotal_median(ia,:,alg));

        plot(ax, nList, yStream, '--', ...
            'Color', colors(alg,:), ...
            'LineWidth', lineWidthStream, ...
            'Marker', 's', ...
            'MarkerSize', markerSize, ...
            'DisplayName', ['Stream total ' algNamesPlot{alg}]);
    end

    % ---------------------------------------------------------------------
    % Stream mask-only markers: open markers
    % ---------------------------------------------------------------------
    for alg = 1:3
        yMask = squeeze(S.Tmask_median(ia,:,alg));

        scatter(ax, nList, yMask, scatterSize, ...
            'MarkerEdgeColor', colors(alg,:), ...
            'MarkerFaceColor', 'none', ...
            'LineWidth', 2.0, ...
            'DisplayName', ['Mask only ' algNamesPlot{alg}]);
    end

    % ---------------------------------------------------------------------
    % Axis settings
    % ---------------------------------------------------------------------
    set(ax, 'XScale', 'log');
    set(ax, 'YScale', 'log');

    set(ax, ...
        'FontSize', fontAxes, ...
        'LineWidth', 1.3, ...
        'TickDir', 'out');

    xlabel(ax, 'Input length n', 'FontSize', fontLabel);
    ylabel(ax, 'Runtime t (s)', 'FontSize', fontLabel);

    title(ax, sprintf('Runtime comparison using rawdata10G, k/n = %.1f', alpha), ...
        'FontSize', fontTitle, ...
        'FontWeight', 'normal');

    grid(ax, 'on');
    box(ax, 'on');

    % Legend: two columns to avoid crowding
    legend(ax, 'Location', 'northwest', ...
        'FontSize', fontLegend, ...
        'NumColumns', 2, ...
        'Box', 'on');

    % ---------------------------------------------------------------------
    % Save PNG figure only
    % ---------------------------------------------------------------------
    alphaTag = sprintf('alpha%02d', round(100 * alpha));
    figNamePNG = ['Figure_Runtime_' alphaTag '_rawdata.png'];

    % Prefer exportgraphics if available
    try
        exportgraphics(fig, figNamePNG, 'Resolution', 600);
    catch
        print(fig, figNamePNG, '-dpng', '-r600');
    end

    fprintf('Saved figure: %s\n', figNamePNG);

    % Close the figure after saving to avoid handle conflicts
    close(fig);
end

fprintf('All PNG figures saved successfully.\n');