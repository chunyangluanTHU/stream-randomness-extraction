%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File name: BasicStats_NIST_Input_Files.m
%
% Function:
%   Compute basic sanity-check statistics for NIST input files:
%       1. Number of bits
%       2. Fraction of ones
%       3. Lag-1 covariance in +/-1 representation
%
% Output:
%   NIST_Input_BasicStats.csv
%
% This script reads files in chunks to avoid excessive memory usage.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;

path = '.';

alphaList = [0.5, 0.8];
algNames = {'Toeplitz', 'Circulant', 'Hayashi'};

chunkBits = 5e6;

outCSV = 'NIST_Input_BasicStats.csv';
fidCSV = fopen(fullfile(path, outCSV), 'w');

fprintf(fidCSV, 'algorithm,alpha,numBits,fractionOnes,lag1Covariance\n');

fprintf('Basic statistics for NIST input files:\n\n');

for ia = 1:length(alphaList)
    alpha = alphaList(ia);
    alphaTag = sprintf('alpha%02d', round(100 * alpha));

    for alg = 1:length(algNames)
        algName = algNames{alg};
        fname = ['NIST_FinalRD_' algName '_' alphaTag '.bin'];

        fid = fopen(fullfile(path, fname), 'rb');

        if fid == -1
            warning('Cannot open %s. Skip.', fname);
            continue;
        end

        totalBits = 0;
        totalOnes = 0;

        pairSum = 0;
        countPairs = 0;
        sumS1 = 0;
        sumS2 = 0;

        lastBitAvailable = false;
        lastBit = 0;

        while true
            bits = fread(fid, chunkBits, 'ubit1');

            if isempty(bits)
                break;
            end

            bits = double(bits(:));
            numBits = length(bits);

            totalBits = totalBits + numBits;
            totalOnes = totalOnes + sum(bits);

            if lastBitAvailable
                bitsForCorr = [lastBit; bits];
            else
                bitsForCorr = bits;
            end

            if length(bitsForCorr) >= 2
                s = 2 * bitsForCorr - 1;
                s1 = s(1:end-1);
                s2 = s(2:end);

                pairSum = pairSum + sum(s1 .* s2);
                sumS1 = sumS1 + sum(s1);
                sumS2 = sumS2 + sum(s2);
                countPairs = countPairs + length(s1);
            end

            lastBit = bits(end);
            lastBitAvailable = true;
        end

        fclose(fid);

        if totalBits == 0
            warning('%s is empty. Skip.', fname);
            continue;
        end

        fractionOnes = totalOnes / totalBits;

        if countPairs > 0
            meanS1 = sumS1 / countPairs;
            meanS2 = sumS2 / countPairs;
            lag1 = pairSum / countPairs - meanS1 * meanS2;
        else
            lag1 = NaN;
        end

        fprintf('%-40s bits=%12d, Pr(1)=%.8f, lag1Cov=%.6g\n', ...
            fname, totalBits, fractionOnes, lag1);

        fprintf(fidCSV, '%s,%.2f,%d,%.12g,%.12g\n', ...
            algName, alpha, totalBits, fractionOnes, lag1);
    end
end

fclose(fidCSV);

fprintf('\nSaved: %s\n', outCSV);