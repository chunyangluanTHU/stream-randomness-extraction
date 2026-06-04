%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File name: Generate_NIST_Input_3Algo_alpha.m
%
% Function:
%   Generate NIST input bitstreams from real rawdata10G using the stream
%   versions of three extractors:
%
%       1. Standard Toeplitz
%       2. Circulant
%       3. Hayashi-type improved Toeplitz
%
% For each block:
%   1. Read an n-bit raw block X from rawdata10G
%   2. Generate an n-bit stream mask P
%   3. Compute Y = X xor P
%   4. Keep only the first k bits:
%          Z = Y(1:k)
%
% This is consistent with the stream extractor definition:
%   z = (x xor w)_0^{m-1}
%
% Input files:
%   rawdata10G      : raw bitstream generated from rawData_000.dat
%   randomdata5G    : fixed structure seed file
%   randomdata10G   : fresh seed file
%
% Output files:
%   NIST_FinalRD_Toeplitz_alpha50.bin
%   NIST_FinalRD_Toeplitz_alpha80.bin
%   NIST_FinalRD_Circulant_alpha50.bin
%   NIST_FinalRD_Circulant_alpha80.bin
%   NIST_FinalRD_Hayashi_alpha50.bin
%   NIST_FinalRD_Hayashi_alpha80.bin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
close all;
clc;
maxNumCompThreads(1);

path = '.';

fraw0   = 'rawdata10G';
ffix0   = 'randomdata5G';
ffresh0 = 'randomdata10G';

n = 1280;
numBlocks = 1024 * 100;

alphaList = [0.5, 0.8];
algNames = {'Toeplitz', 'Circulant', 'Hayashi'};

% -------------------------------------------------------------------------
% Check input files
% -------------------------------------------------------------------------
if isempty(dir(fullfile(path, fraw0)))
    error('Cannot find rawdata10G. Please generate it first.');
end

if isempty(dir(fullfile(path, ffix0)))
    error('Cannot find randomdata5G. This file is required as fixed seed.');
end

if isempty(dir(fullfile(path, ffresh0)))
    error('Cannot find randomdata10G. This file is required as fresh seed.');
end

summaryRows = {};

% -------------------------------------------------------------------------
% Main loop
% -------------------------------------------------------------------------
for ia = 1:length(alphaList)
    alpha = alphaList(ia);
    k = floor(alpha * n);
    alphaTag = sprintf('alpha%02d', round(100 * alpha));

    fprintf('\n============================================================\n');
    fprintf('Generating NIST files for k/n = %.2f, n = %d, k = %d\n', alpha, n, k);
    fprintf('Each output file should contain %d bits.\n', numBlocks * k);
    fprintf('============================================================\n');

    for alg = 1:3
        algName = algNames{alg};

        fout0 = ['NIST_FinalRD_' algName '_' alphaTag '.bin'];

        fprintf('\n--- %s, %s ---\n', algName, alphaTag);
        fprintf('Output file: %s\n', fout0);

        % Open files independently for each extractor and alpha
        fraw = fopen(fullfile(path, fraw0), 'rb');
        if fraw == -1
            error('Cannot open rawdata10G.');
        end

        ffresh = fopen(fullfile(path, ffresh0), 'rb');
        if ffresh == -1
            fclose(fraw);
            error('Cannot open randomdata10G.');
        end

        fout = fopen(fullfile(path, fout0), 'wb');
        if fout == -1
            fclose(fraw);
            fclose(ffresh);
            error('Cannot create output file %s.', fout0);
        end

        % Prepare fixed seed for this algorithm and alpha
        seedStruct = local_prepare_fixed_seed(path, ffix0, n, k, alg);

        validBlocks = 0;
        totalWrittenBits = 0;

        for ib = 1:numBlocks
            % 1. Read one raw block
            x = local_read_bits(fraw, n);

            if length(x) < n
                warning('rawdata10G ended before numBlocks. Stop at block %d.', ib);
                break;
            end

            % 2. Read one fresh seed
            freshSeed = local_read_fresh_seed(ffresh, n, k, alg);

            if isempty(freshSeed)
                warning('randomdata10G ended before numBlocks. Stop at block %d.', ib);
                break;
            end

            % 3. Generate stream mask
            P = local_stream_mask_kernel(freshSeed, seedStruct, n, k, alg);

            % 4. Full masked output
            Y = mod(double(x(:)) + double(P(:)), 2);

            % 5. Keep only first k bits for NIST
            Z = Y(1:k);

            fwrite(fout, Z, 'ubit1');

            validBlocks = validBlocks + 1;
            totalWrittenBits = totalWrittenBits + k;
        end

        fclose(fraw);
        fclose(ffresh);
        fclose(fout);

        fprintf('Valid blocks:      %d\n', validBlocks);
        fprintf('Written bits:      %d\n', totalWrittenBits);
        fprintf('Expected bits:     %d\n', numBlocks * k);
        fprintf('Expected bytes:    %.0f\n', totalWrittenBits / 8);

        summaryRows(end+1,:) = {algName, alpha, n, k, validBlocks, totalWrittenBits, fout0}; %#ok<SAGROW>
    end
end

% -------------------------------------------------------------------------
% Write summary CSV
% -------------------------------------------------------------------------
summaryFile = fullfile(path, 'NIST_Input_Generation_Summary.csv');
fid = fopen(summaryFile, 'w');

fprintf(fid, 'algorithm,alpha,n,k,validBlocks,totalWrittenBits,outputFile\n');

for i = 1:size(summaryRows,1)
    fprintf(fid, '%s,%.2f,%d,%d,%d,%d,%s\n', ...
        summaryRows{i,1}, summaryRows{i,2}, summaryRows{i,3}, ...
        summaryRows{i,4}, summaryRows{i,5}, summaryRows{i,6}, summaryRows{i,7});
end

fclose(fid);

fprintf('\nAll NIST input files generated.\n');
fprintf('Summary saved to: %s\n', summaryFile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local function: read bits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function bits = local_read_bits(fid, nBits)

bits = fread(fid, nBits, 'ubit1');

if isempty(bits)
    bits = [];
else
    bits = double(bits(:));
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local function: prepare fixed seed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function seedStruct = local_prepare_fixed_seed(path, ffix0, n, k, alg)

ffix = fopen(fullfile(path, ffix0), 'rb');
if ffix == -1
    error('Cannot open fixed seed file randomdata5G.');
end

if alg == 1
    % Toeplitz stream
    rLen = n - k;
    L = n + rLen - 1;

    seed = fread(ffix, L, 'ubit1');

    if length(seed) < L
        fclose(ffix);
        error('randomdata5G is too short for Toeplitz fixed seed.');
    end

    seedStruct.seed = double(seed(:));
    seedStruct.Fseed = fft(seedStruct.seed);
    seedStruct.L = L;
    seedStruct.rLen = rLen;

elseif alg == 2
    % Circulant stream
    nRaw = n;
    nCirc = nRaw + 1;
    rLen = nCirc - k - 1;

    seed = fread(ffix, nCirc, 'ubit1');

    if length(seed) < nCirc
        fclose(ffix);
        error('randomdata5G is too short for Circulant fixed seed.');
    end

    seedStruct.seed = double(seed(:));
    seedStruct.Fseed = fft(seedStruct.seed);
    seedStruct.nCirc = nCirc;
    seedStruct.rLen = rLen;

elseif alg == 3
    % Hayashi stream
    rLen = n - k;
    L = n - 1;

    seed = fread(ffix, L, 'ubit1');

    if length(seed) < L
        fclose(ffix);
        error('randomdata5G is too short for Hayashi fixed seed.');
    end

    seedStruct.seed = double(seed(:));
    seedStruct.Fseed = fft(seedStruct.seed);
    seedStruct.L = L;
    seedStruct.rLen = rLen;

else
    fclose(ffix);
    error('Unknown algorithm index.');
end

fclose(ffix);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local function: read fresh seed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function freshSeed = local_read_fresh_seed(ffresh, n, k, alg)

if alg == 1
    rLen = n - k;
elseif alg == 2
    nCirc = n + 1;
    rLen = nCirc - k - 1;
elseif alg == 3
    rLen = n - k;
else
    error('Unknown algorithm index.');
end

freshSeed = fread(ffresh, rLen, 'ubit1');

if length(freshSeed) < rLen
    freshSeed = [];
else
    freshSeed = double(freshSeed(:));
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Local function: stream mask kernel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = local_stream_mask_kernel(freshSeed, seedStruct, n, k, alg)

if alg == 1
    P = local_stream_toeplitz_mask(freshSeed, seedStruct, n, k);
elseif alg == 2
    P = local_stream_circulant_mask(freshSeed, seedStruct, n, k);
elseif alg == 3
    P = local_stream_hayashi_mask(freshSeed, seedStruct, n, k);
else
    error('Unknown algorithm.');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Toeplitz stream mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = local_stream_toeplitz_mask(freshSeed, seedStruct, n, k)

rLen = n - k;
L = seedStruct.L;

if length(freshSeed) ~= rLen
    error('Toeplitz fresh seed length mismatch.');
end

pad = zeros(L, 1);
pad(1:rLen) = double(freshSeed(:));

convResult = ifft(seedStruct.Fseed .* fft(pad));
Pfull = mod(round(real(convResult)), 2);

P = Pfull(1:n);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Circulant stream mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = local_stream_circulant_mask(freshSeed, seedStruct, nRaw, k)

nCirc = nRaw + 1;
rLen = nCirc - k - 1;

if length(freshSeed) ~= rLen
    error('Circulant fresh seed length mismatch.');
end

rExt = zeros(nCirc, 1);
rExt(1:rLen) = double(freshSeed(:));

% Eq. (11): R(x)=(x0,x_{n-1},...,x1)
RrExt = [rExt(1); flipud(rExt(2:end))];

convResult = ifft(fft(RrExt) .* seedStruct.Fseed);
Pfull = mod(round(real(convResult)), 2);

P = Pfull(1:nRaw);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Hayashi stream mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = local_stream_hayashi_mask(freshSeed, seedStruct, n, k)

rLen = n - k;
L = seedStruct.L;

if length(freshSeed) ~= rLen
    error('Hayashi fresh seed length mismatch.');
end

rPad = zeros(L, 1);
rPad(1:rLen) = double(freshSeed(:));

convResult = ifft(seedStruct.Fseed .* fft(rPad));
convResult = mod(round(real(convResult)), 2);

toePart = convResult(rLen:L);

if length(toePart) ~= k
    error('Hayashi toePart length mismatch.');
end

P = zeros(n, 1);
P(1:k) = toePart;
P(k+1:n) = double(freshSeed(:));

end