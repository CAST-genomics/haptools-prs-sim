from pathlib import Path


out = "results/split/"


rule create_sample_info:
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

rule extract_snps_only:
    input:
        pgen = config["reference"],
        pvar = Path(config["reference"]).with_suffix(".pvar.zst"),
        psam = Path(config["reference"]).with_suffix(".psam"),
        samples = rules.create_sample_info.output,
    params:
        in_prefix = lambda w, input: Path(input.pgen).with_suffix(""),
        out_prefix = lambda w, output: Path(output.pgen).with_suffix(""),
    output:
        pgen = out+"ref.pgen",
        pvar = out+"ref.pvar",
        psam = out+"ref.psam",
        log = temp(out+"ref.log"),
    resources:
        runtime="1:00:00",
    log:
        out+"logs/extract_snps_only/ref.log"
    benchmark:
        out+"bench/extract_snps_only/ref.txt"
    conda:
        "../envs/default.yml"
    shell:
        "plink2 --snps-only 'just-acgt' --aec --chr 1-22, XY "
        "--keep <(cut -f1 {input.samples}) "
        "--make-pgen erase-dosage 'pvar-cols=' 'psam-cols=' "
        "--pfile {params.in_prefix} vzs --out {params.out_prefix} &>{log}"

rule choose_train_test_validate_samples:
    input:
        psam = rules.extract_snps_only.output.psam,
    output:
        training = out+"/samples_split/training.tsv",
        testing = out+"/samples_split/testing.tsv",
        validation = out+"/samples_split/validation.tsv",
    resources:
        runtime="0:05:00",
    log:
        out+"logs/choose_train_test_validate_samples/samples_split.log"
    benchmark:
        out+"bench/choose_train_test_validate_samples/samples_split.txt"
    conda:
        "../envs/default.yml"
    shell:
        " >{output.sample_info} 2>{log}"
