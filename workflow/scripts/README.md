# scripts
This directory contains various scripts used by the pipeline.
However, you can use most of these scripts on their own, too. Some may even be helpful in day-to-day use.

All python scripts implement the `--help` argument. For R scripts, you can run `head <script>` to read about their usage.

### [train_test_validate_split.py](train_test_validate_split.py)
A python script that splits your samples into a set of training, testing, and validation sets, whilst maintaining the population fractions.

### [choose_variants.py](choose_variants.py)
A python script that randomly chooses causal SNPs to use in our simulation, such that they come from a wide distribution of allele frequencies. It outputs a `.hap` file suitable for `simphenotype`.
