from pathlib import Path


out = "results/ancestry/"
# get the ID of the causal SNP from the hap filename
config["hap"] = Path(config["hap"])
snp_id = config["hap"].with_suffix("")
if snp_id.suffix == ".hap":
    snp_id = snp_id.with_suffix("")
snp_id = str(snp_id.name)


rule sim_gts:
    input:
        ref = config["reference"],
        samps = config["sample_info"],
        model = lambda wildcards: config["models"][wildcards.samp],
        mapdir = config["mapdir"],
    params:
        chroms = ",".join(range(1, 22)),
        out_prefix = lambda w, output: Path(output.gts).with_suffix(""),
        nsamps = 10*10000,
    output:
        gts = temp(out+"sim_gts/{samp}.vcf"),
        bkpt = out+"sim_gts/{samp}.bp",
    resources:
        runtime="3:00:00"
    log:
        out+"logs/sim_gts/{samp}.log"
    benchmark:
        out+"bench/sim_gts/{samp}.txt"
    conda:
        "../envs/haptools.yml"
    shell:
        "haptools simgenotype --invcf {input.ref} --sample_info {input.samps} "
        "--model {input.model} --mapdir {input.mapdir} --chroms {params.chroms} "
        "--out {params.out_prefix} --popsize {params.nsamps} &> {log}"
