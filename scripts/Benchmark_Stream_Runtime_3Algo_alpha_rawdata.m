%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File name: Benchmark_Stream_Runtime_3Algo_alpha_rawdata.m
%
% Function:
%   使用真实 rawdata10G 文件，测量三种 extractor 在 stream mode 下的：
%
%       T_mask  : 生成 pseudo-random mask 的时间
%       T_xor   : 从 rawdata10G 读取 n-bit raw block 并 XOR 的时间
%       T_total : T_mask + T_xor
%
% Compare:
%   1. Standard Toeplitz
%   2. Circulant
%   3. Hayashi-type improved Toeplitz
%
% Entropy rates:
%   k/n = 0.5 and 0.8
%
% Output:
%   Stream_Runtime_3Algo_alpha_rawdata.mat
%   Stream_Runtime_3Algo_alpha_rawdata.csv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
close all;
clc;
maxNumCompThreads(1);
rng(2);

path = '.';
fraw0 = 'rawdata10G';

quickMode = false;

if quickMode
    nList = [256, 512, 1024];
    Nrep = 5;
    warmupLoop = 2;
else
    nList = [512, 1024, 2048, 4096, 8192, 16384, 32768];
    Nrep = 100;
    warmupLoop = 5;
end

alphaList = [0.5, 0.8];

algNames = {'Toeplitz', 'Circulant', 'Hayashi'};

Tmask_median  = zeros(length(alphaList), length(nList), 3);
Tmask_mean    = zeros(length(alphaList), length(nList), 3);
Tmask_std     = zeros(length(alphaList), length(nList), 3);

Txor_median   = zeros(length(alphaList), length(nList), 3);
Txor_mean     = zeros(length(alphaList), length(nList), 3);
Txor_std      = zeros(length(alphaList), length(nList), 3);

Ttotal_median = zeros(length(alphaList), length(nList), 3);
Ttotal_mean   = zeros(length(alphaList), length(nList), 3);
Ttotal_std    = zeros(length(alphaList), length(nList), 3);

fraw = fopen(fullfile(path, fraw0), 'rb');

if fraw == -1
    error('无法打开 rawdata10G。请确认 rawdata10G 与本脚本在同一文件夹。');
end

for ia = 1:length(alphaList)
    alpha = alphaList(ia);

    for in = 1:length(nList)
        n = nList(in);
        k = floor(alpha * n);

        fprintf('\n[Stream rawdata] alpha = %.1f, n = %d, k = %d\n', alpha, n, k);

        for alg = 1:3
            fseek(fraw, 0, 'bof');

            seedStruct = local_prepare_stream_seed(n, k, alg);

            for warm = 1:warmupLoop
                freshSeed = local_generate_fresh_seed(n, k, alg);
                P = local_stream_mask_kernel(freshSeed, seedStruct, n, k, alg);
                X = local_read_raw_block(fraw, n);
                Y = mod(X + P, 2); %#ok<NASGU>
            end

            tMask  = zeros(Nrep, 1);
            tXor   = zeros(Nrep, 1);
            tTotal = zeros(Nrep, 1);

            for rep = 1:Nrep
                freshSeed = local_generate_fresh_seed(n, k, alg);

                tic;
                P = local_stream_mask_kernel(freshSeed, seedStruct, n, k, alg);
                tMask(rep) = toc;

                tic;
                X = local_read_raw_block(fraw, n);
                Y = mod(X + P, 2); %#ok<NASGU>
                tXor(rep) = toc;

                tTotal(rep) = tMask(rep) + tXor(rep);
            end

            Tmask_median(ia,in,alg)  = median(tMask);
            Tmask_mean(ia,in,alg)    = mean(tMask);
            Tmask_std(ia,in,alg)     = std(tMask);

            Txor_median(ia,in,alg)   = median(tXor);
            Txor_mean(ia,in,alg)     = mean(tXor);
            Txor_std(ia,in,alg)      = std(tXor);

            Ttotal_median(ia,in,alg) = median(tTotal);
            Ttotal_mean(ia,in,alg)   = mean(tTotal);
            Ttotal_std(ia,in,alg)    = std(tTotal);

            fprintf('  %-10s: Tmask=%.6g s, Txor=%.6g s, Ttotal=%.6g s\n', ...
                algNames{alg}, ...
                Tmask_median(ia,in,alg), ...
                Txor_median(ia,in,alg), ...
                Ttotal_median(ia,in,alg));
        end
    end
end

fclose(fraw);

save('Stream_Runtime_3Algo_alpha_rawdata.mat', ...
     'nList', 'alphaList', 'algNames', ...
     'Tmask_median', 'Tmask_mean', 'Tmask_std', ...
     'Txor_median',  'Txor_mean',  'Txor_std', ...
     'Ttotal_median', 'Ttotal_mean', 'Ttotal_std');

fid = fopen('Stream_Runtime_3Algo_alpha_rawdata.csv', 'w');

fprintf(fid, ['alpha,n,algorithm,' ...
              'Tmask_median,Tmask_mean,Tmask_std,' ...
              'Txor_median,Txor_mean,Txor_std,' ...
              'Ttotal_median,Ttotal_mean,Ttotal_std\n']);

for ia = 1:length(alphaList)
    for in = 1:length(nList)
        for alg = 1:3
            fprintf(fid, ['%.2f,%d,%s,' ...
                          '%.12g,%.12g,%.12g,' ...
                          '%.12g,%.12g,%.12g,' ...
                          '%.12g,%.12g,%.12g\n'], ...
                alphaList(ia), nList(in), algNames{alg}, ...
                Tmask_median(ia,in,alg), Tmask_mean(ia,in,alg), Tmask_std(ia,in,alg), ...
                Txor_median(ia,in,alg),  Txor_mean(ia,in,alg),  Txor_std(ia,in,alg), ...
                Ttotal_median(ia,in,alg), Ttotal_mean(ia,in,alg), Ttotal_std(ia,in,alg));
        end
    end
end

fclose(fid);

fprintf('\nStream rawdata benchmark finished.\n');
fprintf('Saved: Stream_Runtime_3Algo_alpha_rawdata.mat\n');
fprintf('Saved: Stream_Runtime_3Algo_alpha_rawdata.csv\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 读取 rawdata10G 中的 n-bit block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function X = local_read_raw_block(fraw, n)

X = fread(fraw, n, 'ubit1');

if length(X) < n
    fseek(fraw, 0, 'bof');
    X = fread(fraw, n, 'ubit1');
end

if length(X) < n
    error('rawdata10G 中 bit 数不足。');
end

X = double(X(:));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prepare fixed stream seed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function seedStruct = local_prepare_stream_seed(n, k, alg)

if alg == 1
    rLen = n - k;
    L = n + rLen - 1;
    seed = randi([0, 1], L, 1);
    seedStruct.seed = double(seed(:));
    seedStruct.Fseed = fft(seedStruct.seed);
    seedStruct.L = L;
    seedStruct.rLen = rLen;

elseif alg == 2
    nRaw = n;
    nCirc = nRaw + 1;
    rLen = nCirc - k - 1;
    seed = randi([0, 1], nCirc, 1);
    seedStruct.seed = double(seed(:));
    seedStruct.Fseed = fft(seedStruct.seed);
    seedStruct.nCirc = nCirc;
    seedStruct.rLen = rLen;

elseif alg == 3
    rLen = n - k;
    L = n - 1;
    seed = randi([0, 1], L, 1);
    seedStruct.seed = double(seed(:));
    seedStruct.Fseed = fft(seedStruct.seed);
    seedStruct.L = L;
    seedStruct.rLen = rLen;
else
    error('Unknown algorithm.');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate fresh seed outside timing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function freshSeed = local_generate_fresh_seed(n, k, alg)

if alg == 1
    rLen = n - k;
elseif alg == 2
    nCirc = n + 1;
    rLen = nCirc - k - 1;
elseif alg == 3
    rLen = n - k;
else
    error('Unknown algorithm.');
end

freshSeed = randi([0, 1], rLen, 1);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stream mask kernel
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
% Stream Toeplitz mask
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
% Stream Circulant mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = local_stream_circulant_mask(freshSeed, seedStruct, nRaw, k)

nCirc = nRaw + 1;
rLen = nCirc - k - 1;

if length(freshSeed) ~= rLen
    error('Circulant fresh seed length mismatch.');
end

rExt = zeros(nCirc, 1);
rExt(1:rLen) = double(freshSeed(:));

RrExt = [rExt(1); flipud(rExt(2:end))];

convResult = ifft(fft(RrExt) .* seedStruct.Fseed);
Pfull = mod(round(real(convResult)), 2);

P = Pfull(1:nRaw);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Stream Hayashi mask
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