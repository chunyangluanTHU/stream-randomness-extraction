# NIST SP 800-22 Test Notes

This file records the NIST SP 800-22 testing procedure used for the manuscript:

**Stream randomness extraction against quantum side information**

## Software

```text
NIST Statistical Test Suite version: sts-2.1.1
Operating system used for tests: Windows
Command-line program: assess.exe
```

## Command

For all six extracted bitstreams, the following command was used:

```powershell
.\assess.exe 1000000
```

This sets the sequence length to:

```text
1,000,000 bits per sequence
```

## Input mode

The input files were tested in binary mode:

```text
[1] Binary - Each byte in data file contains 8 bits of data
```

## Test selection and parameters

All statistical tests were selected:

```text
Enter Choice: 1
```

Default test parameters were used:

```text
Select Test (0 to continue): 0
```

The default parameters include:

```text
Block Frequency Test - block length(M):         128
NonOverlapping Template Test - block length(m): 9
Overlapping Template Test - block length(m):    9
Approximate Entropy Test - block length(m):     10
Serial Test - block length(m):                  16
Linear Complexity Test - block length(M):       500
```

## Sequence partitions

### Entropy-rate setting: k/n = 0.5

The generated extracted-output length is:

```text
102400 blocks * 640 bits/block = 65,536,000 bits
```

The NIST test used:

```text
Number of sequences: 65
Sequence length:     1,000,000 bits
Tested bits:         65,000,000 bits
```

The remaining `536,000` bits were not used because the NIST test was run with complete `1,000,000`-bit sequences.

### Entropy-rate setting: k/n = 0.8

The generated extracted-output length is:

```text
102400 blocks * 1024 bits/block = 104,857,600 bits
```

The NIST test used:

```text
Number of sequences: 104
Sequence length:     1,000,000 bits
Tested bits:         104,000,000 bits
```

The remaining `857,600` bits were not used because the NIST test was run with complete `1,000,000`-bit sequences.

## Tested files

```text
nist_inputs/NIST_FinalRD_Toeplitz_alpha50.bin
nist_inputs/NIST_FinalRD_Circulant_alpha50.bin
nist_inputs/NIST_FinalRD_ModifiedToeplitz_alpha50.bin
nist_inputs/NIST_FinalRD_Toeplitz_alpha80.bin
nist_inputs/NIST_FinalRD_Circulant_alpha80.bin
nist_inputs/NIST_FinalRD_ModifiedToeplitz_alpha80.bin
```

## Output reports

The corresponding final NIST reports are provided in:

```text
nist_reports/Toeplitz_alpha50_finalAnalysisReport.txt
nist_reports/Circulant_alpha50_finalAnalysisReport.txt
nist_reports/ModifiedToeplitz_alpha50_finalAnalysisReport.txt
nist_reports/Toeplitz_alpha80_finalAnalysisReport.txt
nist_reports/Circulant_alpha80_finalAnalysisReport.txt
nist_reports/ModifiedToeplitz_alpha80_finalAnalysisReport.txt
```

All six extracted bitstreams passed the applicable NIST SP 800-22 statistical tests under the tested sequence partitions.
