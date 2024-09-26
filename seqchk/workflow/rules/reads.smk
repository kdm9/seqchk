rule subsample:
    input:
        r1=lambda wc: config["SAMPLE_FASTQ"][wc.sample]["R1"],
        r2=lambda wc: config["SAMPLE_FASTQ"][wc.sample]["R2"],
    output:
        r1=temp(dirs["temp"]/"reads/sub/sample}_subsample_R1.fastq"),
        r2=temp(dirs["temp"]/"reads/sub/sample}_subsample_R2.fastq"),
    log:
        dirs["temp"]/"{sample}_subsample.log",
    threads: 2
    container: "docker://quay.io/mbhall88/rasusa"
    params:
        seed=config["subsample_seed"],
        nreads=config["subsample_nreads"],
    shell:
        "( rasusa reads"
        "   --num {params.nreads}"
        "   --seed {params.seed}"
        "   -o {output.r1} -o {output.r2}"
        "   {input.r1} {input.r2}"
        ") 2>{log}"


def fastp_input(wc):
    if config["subsample"]:
        return {
                "r1": dirs["temp"]/f"reads/sub/{wc.sample}_subsample_R1.fastq",
                "r2", dirs["temp"]/f"reads/sub/{wc.sample}_subsample_R2.fastq",
        }
    else:
        return {
                "r1": config["SAMPLE_FASTQ"][wc.sample]["R1"],
                "r2", config["SAMPLE_FASTQ"][wc.sample]["R2"],
        }

rule fastp:
    input:
        unwrap(fastp_input)
    output:
        r1=temp(dirs["temp"]/"reads/qc/{sample}_qc_R1.fastq"),
        r2=temp(dirs["temp"]/"reads/qc/{sample}_qc_R2.fastq"),
        rs=temp(dirs["temp"]/"reads/qc/{sample}_qc_SE.fastq"),
        json=temp(dirs["temp"]/"reads/qc/{sample}_qc.json"),
        html=temp(dirs["temp"]/"reads/qc/{sample}_qc.html"),
    log:
        dirs["temp"]/"reads/qc/{sample}_qc.log",
    threads: 2
    container: "docker://quay.io/biocontainers/fastp"
    shell:
        "fastp "
        "   --in1 {input.r1}"
        "   --in2 {input.r2}"
        "   --out1 {output.r1}"
        "   --out2 {output.r2}"
        "   --unpaired1 {output.rs}"
        "   --unpaired2 {output.rs}"
        "   --thread {threads}"
        "   --json {output.json}"
        "   --html {output.html}"
        "   --low_complexity_filter"
        "   --detect_adapter_for_pe"
        "   --cut_tail"
        "   --trim_poly_x"
        "   --length-required 32"
        ">{log} 2>&1"


rule idxref:
    input:
        ref=lambda wc: config["REFERENCES"][wc.ref],
    output:
        idx=temp(dirs["temp"]/"ref/{ref}.mmi"),
    log:
        dirs["temp"]/"ref/{ref}.mmi.log",
    threads: 4
    container: "docker://ghcr.io/kdm9/minimap2-samtools:latest"
    shell:
        "minimap2 -x sr -d {output.idx} -t {threads} {input.ref} &>{log}"

rule map:
    input:
        r1=temp(dirs["temp"]/"reads/qc/{sample}_qc_R1.fastq"),
        r2=temp(dirs["temp"]/"reads/qc/{sample}_qc_R2.fastq"),
        idx=temp(dirs["temp"]/"ref/{ref}.mmi"),
    output:
        bam=temp(dirs["temp"]/"aln/{ref}_{sample}.bam"),
        bai=temp(dirs["temp"]/"aln/{ref}_{sample}.bam.bai"),
    log:
        dirs["temp"]/"aln/{ref}_{sample}.log",
    container: "docker://ghcr.io/kdm9/minimap2-samtools:latest"
    threads: 4
    params:
        mem=lambda wc, input, output, resources: int((resources.mem_mb*0.6)/resources._cores),
    shell:
        "( minimap2 -ax sr"
        "   {input.idx}"
        "   {input.r1} {input.r2}"
        " | samtools fixmate "
        "   -m"
        "   -@ {threads}"
        "   -u"
        "   /dev/stdin"
        "   /dev/stdout"
        " | samtools sort"
        "   -T ${{TMPDIR:-/tmp}}/{wildcards.sample}_sort_$RANDOM"
        "   --output-fmt bam,level=0"
        "   -@ {threads}"
        "   -m {params.mem}m" # multiplied by {threads}
        "   /dev/stdin"
        " | samtools markdup"
        "   -T ${{TMPDIR:-/tmp}}/{wildcards.sample}_markdup_$RANDOM"
        "   -s" # report stats
        "   -@ {threads}"
        "   --output-fmt bam,level=0"
        "   /dev/stdin"
        "   /dev/stdout"
        " | tee {output.bam}"
        " | samtools index - {output.bai}"  # indexing takes bloody ages, we may as well do this on the fly
        " ) > {log} 2>&1"

