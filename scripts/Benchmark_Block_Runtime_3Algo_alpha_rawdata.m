%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File name: Benchmark_Block_Runtime_3Algo_alpha_rawdata.m
%
% Function:
%   使用真实 rawdata10G 文件，测量三种 extractor 在 block mode 下
%   一次 hash evaluation 的实际运行时间。
%
%   计时包含:
%       1. 从 rawdata10G 读取 n-bit raw block
%       2. 执行一次 block hash z = h_y(x)
%
%   计时不包含:
%       1. 生成随机 seed 的时间
%       2. 写输出文件的时间
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
%   Block_Runtime_3Algo_alpha_rawdata.mat
%   Block_Runtime_3Algo_alpha_rawdata.csv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
close all;
clc;
maxNumCompThreads(1);
rng(1);

path = '.';
fraw0 = 'rawdata10G';

% -------------------------------------------------------------------------
% 调试模式
% -------------------------------------------------------------------------
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

T_median = zeros(length(alphaList), length(nList), 3);
T_mean   = zeros(length(alphaList), length(nList), 3);
T_std    = zeros(length(alphaList), length(nList), 3);

% -------------------------------------------------------------------------
% 打开 rawdata10G
% -------------------------------------------------------------------------
fraw = fopen(fullfile(path, fraw0), 'rb');

if fraw == -1
    error('无法打开 rawdata10G。请确认 rawdata10G 与本脚本在同一文件夹。');
end

% -------------------------------------------------------------------------
% 主循环
% -------------------------------------------------------------------------
for ia = 1:length(alphaList)
    alpha = alphaList(ia);

    for in = 1:length(nList)
        n = nList(in);

        % 为运行时间比较，令输出长度 m = k。
        % 这里暂时忽略 2*log(1/epsilon) 的加性安全开销。
        k = floor(alpha * n);
        m = k;

        fprintf('\n[Block rawdata] alpha = %.1f, n = %d, m = %d\n', alpha, n, m);

        for alg = 1:3
            % 每个算法从 rawdata10G 文件开头重新读取，使比较更一致
            fseek(fraw, 0, 'bof');

            % 准备固定 hash seed，不计入时间
            seedStruct = local_prepare_block_seed(n, m, alg);

            % warm-up：包括读取 raw block + hash
            for warm = 1:warmupLoop
                x = local_read_raw_block(fraw, n);
                z = local_block_hash_kernel(x, seedStruct, m, alg); %#ok<NASGU>
            end

            tTmp = zeros(Nrep, 1);

            for rep = 1:Nrep
                tic;

                % 计时包含读取 rawdata10G 的 n-bit block
                x = local_read_raw_block(fraw, n);

                % 计时包含一次 block hash
                z = local_block_hash_kernel(x, seedStruct, m, alg); %#ok<NASGU>

                tTmp(rep) = toc;
            end

            T_median(ia, in, alg) = median(tTmp);
            T_mean(ia, in, alg)   = mean(tTmp);
            T_std(ia, in, alg)    = std(tTmp);

            fprintf('  %-10s: median = %.6g s, mean = %.6g s, std = %.6g s\n', ...
                algNames{alg}, ...
                T_median(ia,in,alg), ...
                T_mean(ia,in,alg), ...
                T_std(ia,in,alg));
        end
    end
end

fclose(fraw);

save('Block_Runtime_3Algo_alpha_rawdata.mat', ...
     'nList', 'alphaList', 'algNames', ...
     'T_median', 'T_mean', 'T_std');

fid = fopen('Block_Runtime_3Algo_alpha_rawdata.csv', 'w');

fprintf(fid, 'alpha,n,algorithm,T_median,T_mean,T_std\n');

for ia = 1:length(alphaList)
    for in = 1:length(nList)
        for alg = 1:3
            fprintf(fid, '%.2f,%d,%s,%.12g,%.12g,%.12g\n', ...
                alphaList(ia), nList(in), algNames{alg}, ...
                T_median(ia,in,alg), ...
                T_mean(ia,in,alg), ...
                T_std(ia,in,alg));
        end
    end
end

fclose(fid);

fprintf('\nBlock rawdata benchmark finished.\n');
fprintf('Saved: Block_Runtime_3Algo_alpha_rawdata.mat\n');
fprintf('Saved: Block_Runtime_3Algo_alpha_rawdata.csv\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 读取 rawdata10G 中的 n-bit block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function x = local_read_raw_block(fraw, n)

x = fread(fraw, n, 'ubit1');

if length(x) < n
    fseek(fraw, 0, 'bof');
    x = fread(fraw, n, 'ubit1');
end

if length(x) < n
    error('rawdata10G 中 bit 数不足，无法读取一个完整 block。');
end

x = double(x(:));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 准备 block hash 的固定 seed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function seedStruct = local_prepare_block_seed(n, m, alg)

if alg == 1
    % Standard Toeplitz block hash
    L = n + m - 1;
    seed = randi([0, 1], L, 1);
    seedStruct.seed = double(seed(:));
    seedStruct.Fseed = fft(seedStruct.seed);
    seedStruct.L = L;

elseif alg == 2
    % Circulant block hash
    nCirc = n + 1;
    seed = randi([0, 1], nCirc, 1);
    seedStruct.seed = double(seed(:));
    seedStruct.Fseed = fft(seedStruct.seed);
    seedStruct.nCirc = nCirc;

elseif alg == 3
    % Hayashi-type modified Toeplitz
    L = n - 1;
    seed = randi([0, 1], L, 1);
    seedStruct.seed = double(seed(:));
    seedStruct.Fseed = fft(seedStruct.seed);
    seedStruct.L = L;
else
    error('Unknown algorithm.');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 一次 block hash kernel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function z = local_block_hash_kernel(x, seedStruct, m, alg)

if alg == 1
    z = local_block_toeplitz_hash(x, seedStruct, m);
elseif alg == 2
    z = local_block_circulant_hash(x, seedStruct, m);
elseif alg == 3
    z = local_block_hayashi_hash(x, seedStruct, m);
else
    error('Unknown algorithm index.');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Block Toeplitz hash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function z = local_block_toeplitz_hash(x, seedStruct, m)

x = double(x(:));
n = length(x);
L = seedStruct.L;

if L ~= n + m - 1
    error('Toeplitz seed length mismatch.');
end

xPad = zeros(L, 1);
xPad(1:n) = x;

convResult = ifft(seedStruct.Fseed .* fft(xPad));
convResult = mod(round(real(convResult)), 2);

z = convResult(n:n+m-1);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Block Circulant hash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function z = local_block_circulant_hash(x, seedStruct, m)

x = double(x(:));

nRaw = length(x);
nCirc = nRaw + 1;

if seedStruct.nCirc ~= nCirc
    error('Circulant dimension mismatch.');
end

if m <= 0 || m > nRaw
    error('m must satisfy 0 < m <= nRaw.');
end

xExt = zeros(nCirc, 1);
xExt(1:nRaw) = x;

% Eq. (11): R(x) = (x0, x_{n-1}, ..., x1)
RxExt = [xExt(1); flipud(xExt(2:end))];

convResult = ifft(fft(RxExt) .* seedStruct.Fseed);
fullOutput = mod(round(real(convResult)), 2);

z = fullOutput(1:m);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Block Hayashi-type modified Toeplitz hash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function z = local_block_hayashi_hash(x, seedStruct, m)

x = double(x(:));

n = length(x);
rLen = n - m;
L = n - 1;

if seedStruct.L ~= L
    error('Hayashi seed length mismatch.');
end

if rLen <= 0
    error('rLen = n-m must be positive.');
end

xHead = x(1:rLen);
xTail = x(rLen+1:n);

xPad = zeros(L, 1);
xPad(1:rLen) = xHead;

convResult = ifft(seedStruct.Fseed .* fft(xPad));
convResult = mod(round(real(convResult)), 2);

toePart = convResult(rLen:L);

if length(toePart) ~= m
    error('toePart length mismatch.');
end

z = mod(toePart + xTail, 2);

end