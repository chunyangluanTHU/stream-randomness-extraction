%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File name: Check_NIST_Input_Files.m
%
% Function:
%   Check whether the generated NIST input files have expected sizes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;

path = '.';

n = 1280;
numBlocks = 1024 * 100;

alphaList = [0.5, 0.8];
algNames = {'Toeplitz', 'Circulant', 'Hayashi'};

fprintf('Checking NIST input files...\n\n');

for ia = 1:length(alphaList)
    alpha = alphaList(ia);
    k = floor(alpha * n);
    alphaTag = sprintf('alpha%02d', round(100 * alpha));

    expectedBits = numBlocks * k;
    expectedBytes = expectedBits / 8;

    fprintf('alpha = %.2f, k = %d\n', alpha, k);
    fprintf('Expected bits  = %d\n', expectedBits);
    fprintf('Expected bytes = %.0f\n', expectedBytes);

    for alg = 1:length(algNames)
        fname = ['NIST_FinalRD_' algNames{alg} '_' alphaTag '.bin'];
        info = dir(fullfile(path, fname));

        if isempty(info)
            fprintf('  %-40s : NOT FOUND\n', fname);
        else
            if info.bytes == expectedBytes
                status = 'OK';
            else
                status = 'SIZE MISMATCH';
            end

            fprintf('  %-40s : %12d bytes  [%s]\n', fname, info.bytes, status);
        end
    end

    fprintf('\n');
end