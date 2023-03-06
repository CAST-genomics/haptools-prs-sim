from pathlib import Path


out = "results/split/"


rule create_sample_info:
    """
        subset sampleID and superpopulation column for desired populations
        and exclude header
    """
    input:
        psam = Path(config["reference"]).with_suffix(".psam"),
    params:
        pops = "|".join(config["super_populations"]),
    output:
        sample_info = out+"sample_info.tsv",
    resources:
        runtime="0:05:00",
    log:
        out+"logs/create_sample_info/sample_info.log"
    benchmark:
        out+"bench/create_sample_info/sample_info.txt"
    conda:
        "../envs/default.yml"
    shell:
        "cut -f1,5 {input.psam} | tail -n+2 | "
        "grep -P '\\t({params.pops})$' >{output.sample_info} 2>{log}"

rule compute_allele_freqs:
    """
        compute allele frequencies for all SNPs in non-canonical chroms
        using the samples of interest
    """
    input:
        pgen = config["reference"],
        pvar = Path(config["reference"]).with_suffix(".pvar.zst"),
        psam = Path(config["reference"]).with_suffix(".psam"),
        samples = rules.create_sample_info.output.sample_info,
    params:
        in_prefix = lambda w, input: Path(input.pgen).with_suffix(""),
        out_prefix = lambda w, output: Path(output.freqs).with_suffix(""),
        maf_thresh = config["maf_threshold"],
        hwe_thresh = config["hwe_threshold"],
        missing_thresh = config["missing_threshold"],
    output:
        freqs = out+"all.afreq",
        log = temp(out+"all.log"),
    resources:
        runtime="0:05:00",
        queue="hotel",
    threads: 12
    log:
        out+"logs/compute_allele_freqs/all.log"
    benchmark:
        out+"bench/compute_allele_freqs/all.txt"
    conda:
        "../envs/default.yml"
    shell:
        "plink2 --snps-only 'just-acgt' --aec --chr 1-22, XY --threads {threads} "
        "--hwe {params.hwe_thresh} --geno {params.missing_thresh} --keep-founders "
        "--keep <(cut -f1 {input.samples}) --maf {params.maf_thresh} --max-alleles 2 "
        "--pfile {params.in_prefix} vzs --freq {params.out_prefix} &>{log}"

rule choose_causal_vars:
    """
        randomly choose 1000 causal variants from a range of different
        allele frequencies
    """
    input:
        freqs = rules.compute_allele_freqs.output.freqs,
    output:
        chosen = out+"causal_variants.tsv",
    resources:
        runtime="0:05:00",
    log:
        out+"logs/choose_causal_vars/all.log"
    benchmark:
        out+"bench/choose_causal_vars/all.txt"
    conda:
        "../envs/default.yml"
    shell:
        "workflow/scripts/choose_variants.py {input.freqs} >{output.chosen} 2>{log}"

rule choose_train_test_validate_samples:
    """
        randomly choose samples (stratified by superpopulation label) for
        training/testing/validation from the sample_info file
    """
    input:
        sample_info = rules.create_sample_info.output.sample_info,
    output:
        training = out+"samples_split/training.tsv",
        testing = out+"samples_split/testing.tsv",
        validation = out+"samples_split/validation.tsv",
    resources:
        runtime="0:10:00",
    log:
        out+"logs/choose_train_test_validate_samples/samples_split.log"
    benchmark:
        out+"bench/choose_train_test_validate_samples/samples_split.txt"
    conda:
        "../envs/default.yml"
    shell:
        "workflow/scripts/train_test_validate_split.py {input.sample_info} "
        "{output.training} {output.testing} {output.validation} 2>{log}"

rule subset_dataset:
    """
        create training/testing/validation based on 'type' wildcard
        also, exclude the non-canonical chroms and anything that isn't a SNP
        or a SNP with a low MAF
    """
    input:
        pgen = config["reference"],
        pvar = Path(config["reference"]).with_suffix(".pvar.zst"),
        psam = Path(config["reference"]).with_suffix(".psam"),
        samples = lambda w: getattr(
            rules.choose_train_test_validate_samples.output, w.type,
        ),
    params:
        in_prefix = lambda w, input: Path(input.pgen).with_suffix(""),
        out_prefix = lambda w, output: Path(output.pgen).with_suffix(""),
        maf_thresh = config["maf_threshold"],
        hwe_thresh = config["hwe_threshold"],
        missing_thresh = config["missing_threshold"],
    output:
        pgen = temp(out+"datasets/{type}.pgen"),
        pvar = temp(out+"datasets/{type}.pvar"),
        psam = temp(out+"datasets/{type}.psam"),
        log = temp(out+"datasets/{type}.log"),
    resources:
        runtime="0:05:00",
        queue="hotel",
    threads: 12
    log:
        out+"logs/extract_snps_only/{type}.log"
    benchmark:
        out+"bench/extract_snps_only/{type}.txt"
    conda:
        "../envs/default.yml"
    shell:
        "plink2 --snps-only 'just-acgt' --aec --chr 1-22, XY --threads {threads} "
        "--hwe {params.hwe_thresh} --geno {params.missing_thresh} --keep-founders "
        "--keep <(cut -f1 {input.samples}) --maf {params.maf_thresh} --max-alleles 2 "
        "--make-pgen erase-dosage 'pvar-cols=' 'psam-cols=' "
        "--pfile {params.in_prefix} vzs --out {params.out_prefix} &>{log}"
