# Stream Randomness Extraction against Quantum Side Information

This repository contains the supporting code and processed data for the manuscript:

**Stream randomness extraction against quantum side information**

## Archived version

The archived version of this repository corresponding to the manuscript submission is available at:

https://doi.org/10.5281/zenodo.20542218

## Suggested citation

If this repository is used, please cite the manuscript and the archived repository:

```text
C.-Y. Luan et al., "Stream randomness extraction against quantum side information", arXiv:2605.09556 [quant-ph] (2026).
Manuscript: https://arxiv.org/abs/2605.09556
Supporting data and scripts: https://doi.org/10.5281/zenodo.20542218
```

## Repository contents

```text
scripts/
    Benchmark_Block_Runtime_3Algo_alpha_rawdata.m
    Benchmark_Stream_Runtime_3Algo_alpha_rawdata.m
    Plot_Block_Stream_Comparison_3Algo_alpha_rawdata.m
    Generate_NIST_Input_3Algo_alpha.m
    Check_NIST_Input_Files.m
    BasicStats_NIST_Input_Files.m

runtime_data/
    Block_Runtime_3Algo_alpha_rawdata.csv
    Stream_Runtime_3Algo_alpha_rawdata.csv

nist_inputs/
    NIST_FinalRD_Toeplitz_alpha50.bin
    NIST_FinalRD_Circulant_alpha50.bin
    NIST_FinalRD_ModifiedToeplitz_alpha50.bin
    NIST_FinalRD_Toeplitz_alpha80.bin
    NIST_FinalRD_Circulant_alpha80.bin
    NIST_FinalRD_ModifiedToeplitz_alpha80.bin

nist_reports/
    Toeplitz_alpha50_finalAnalysisReport.txt
    Circulant_alpha50_finalAnalysisReport.txt
    ModifiedToeplitz_alpha50_finalAnalysisReport.txt
    Toeplitz_alpha80_finalAnalysisReport.txt
    Circulant_alpha80_finalAnalysisReport.txt
    ModifiedToeplitz_alpha80_finalAnalysisReport.txt

figures/
    Figure_Runtime_alpha50_rawdata.png
    Figure_Runtime_alpha80_rawdata.png
```

## Data source and scope

The original quantum random number generation data used in the numerical benchmark are from the experimental data associated with Nie et al. The original large raw-data and seed files are not redistributed in this repository by default.

Files such as the following are therefore not included unless explicitly stated by the authors:

```text
rawData_000.dat
rawdata10G
randomdata5G
randomdata10G
```

Instead, this repository provides:

1. MATLAB scripts used in the benchmark and NIST-input preparation;
2. processed runtime data used to reproduce the runtime figures;
3. extracted bitstreams used as inputs to the NIST SP 800-22 statistical tests;
4. NIST final analysis reports;
5. final runtime figures.

The processed runtime CSV files and plotting script are sufficient to reproduce the runtime figures reported in the manuscript. The NIST input files and final reports are sufficient to verify the NIST pass/fail statements reported in the manuscript. Regenerating all extracted bitstreams from the original raw QRNG data requires the original raw-data and seed files, which are not redistributed here.

## Runtime benchmark

The manuscript figures can be reproduced from:

```text
runtime_data/Block_Runtime_3Algo_alpha_rawdata.csv
runtime_data/Stream_Runtime_3Algo_alpha_rawdata.csv
scripts/Plot_Block_Stream_Comparison_3Algo_alpha_rawdata.m
```

The tested extractor families are:

1. Standard Toeplitz hashing
2. Circulant hashing
3. Modified Toeplitz construction

The tested entropy-rate settings are:

```text
k/n = 0.5
k/n = 0.8
```

## NIST SP 800-22 statistical tests

The extracted bitstreams in `nist_inputs/` were tested using the NIST SP 800-22 Statistical Test Suite, version `sts-2.1.1`.

The command used was:

```bash
assess 1000000
```

The input mode was binary.

For `k/n = 0.5`, 65 sequences of length `1,000,000` bits were tested, corresponding to `6.5e7` tested bits.

For `k/n = 0.8`, 104 sequences of length `1,000,000` bits were tested, corresponding to `1.04e8` tested bits.

The corresponding final reports are provided in `nist_reports/`.

## Notes on block size

In the MATLAB implementation used for generating the NIST inputs, the raw bitstream is partitioned into:

```text
N_blk = 102400 blocks
n     = 1280 raw bits per block
```

Thus, the total amount of raw data used to generate the extracted bitstreams is:

```text
N_blk * n = 102400 * 1280 = 1.31072e8 raw bits
```

The value `n = 1280` is only the numerical block size used in the MATLAB implementation and runtime benchmark. It is not a restriction of the theoretical stream-extraction framework.

For each block, the stream implementation generates an `n`-bit mask `w`, computes `x xor w`, and retains only the first `m = k` bits as the extracted output:

```text
z = (x xor w)[0 : m-1]
```

The generated extracted-output lengths are:

```text
k/n = 0.5: 102400 * 640  = 65,536,000 bits
k/n = 0.8: 102400 * 1024 = 104,857,600 bits
```

The NIST tests used complete `1,000,000`-bit sequences, so the actual tested bits are:

```text
k/n = 0.5: 65  * 1,000,000 = 65,000,000 bits
k/n = 0.8: 104 * 1,000,000 = 104,000,000 bits
```

## License

The software license should be confirmed by all authors before public release. A draft license note is provided in `LICENSE_TO_BE_CONFIRMED.txt`.
