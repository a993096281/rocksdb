#! /bin/sh

value_array=(256 1024 4096 16384 65536)
#value_array=(256)
test_all_size=81920000000   #80G


db="/mnt/ssd/test"

value_size="4096"
compression_type="none" #"snappy,none"

benchmarks="fillrandom,stats,wait,clean_cache,stats,readseq,clean_cache,stats,readrandom,stats"
#benchmarks="fillseq,stats"

num="20000000"
reads="1000000"
max_background_jobs="3"
max_bytes_for_level_base="`expr 8 \* 1024 \* 1024 \* 1024`" 

threads="1"

pmem_path="/mnt/pmem0/nvm"
use_nvm_module="true"


bench_file_path="$(dirname $PWD )/db_bench"

bench_file_dir="$(dirname $PWD )"

if [ ! -f "${bench_file_path}" ];then
bench_file_path="$PWD/db_bench"
bench_file_dir="$PWD"
fi

if [ ! -f "${bench_file_path}" ];then
echo "Error:${bench_file_path} or $(dirname $PWD )/db_bench not find!"
exit 1
fi

const_params=""

function FILL_PATAMS() {

    if [ -n "$db" ];then
        const_params=$const_params"--db=$db "
    fi

    if [ -n "$pmem_path" ];then
        const_params=$const_params"--pmem_path=$pmem_path "
    fi

    if [ -n "$use_nvm_module" ];then
        const_params=$const_params"--use_nvm_module=$use_nvm_module "
    fi

    if [ -n "$wal_dir" ];then
        const_params=$const_params"--wal_dir=$wal_dir "
    fi

    if [ -n "$value_size" ];then
        const_params=$const_params"--value_size=$value_size "
    fi

    if [ -n "$compression_type" ];then
        const_params=$const_params"--compression_type=$compression_type "
    fi

    if [ -n "$benchmarks" ];then
        const_params=$const_params"--benchmarks=$benchmarks "
    fi

    if [ -n "$num" ];then
        const_params=$const_params"--num=$num "
    fi

    if [ -n "$reads" ];then
        const_params=$const_params"--reads=$reads "
    fi

    if [ -n "$max_background_jobs" ];then
        const_params=$const_params"--max_background_jobs=$max_background_jobs "
    fi

    if [ -n "$max_bytes_for_level_base" ];then
        const_params=$const_params"--max_bytes_for_level_base=$max_bytes_for_level_base "
    fi

    if [ -n "$perf_level" ];then
        const_params=$const_params"--perf_level=$perf_level "
    fi

    if [ -n "$threads" ];then
        const_params=$const_params"--threads=$threads "
    fi

    if [ -n "$stats_interval" ];then
        const_params=$const_params"--stats_interval=$stats_interval "
    fi

    if [ -n "$stats_interval_seconds" ];then
        const_params=$const_params"--stats_interval_seconds=$stats_interval_seconds "
    fi

    if [ -n "$histogram" ];then
        const_params=$const_params"--histogram=$histogram "
    fi

    if [ -n "$benchmark_write_rate_limit" ];then
        const_params=$const_params"--benchmark_write_rate_limit=$benchmark_write_rate_limit "
    fi

    if [ -n "$request_rate_limit" ];then
        const_params=$const_params"--request_rate_limit=$request_rate_limit "
    fi

    if [ -n "$report_ops_latency" ];then
        const_params=$const_params"--report_ops_latency=$report_ops_latency "
    fi

    if [ -n "$YCSB_uniform_distribution" ];then
        const_params=$const_params"--YCSB_uniform_distribution=$YCSB_uniform_distribution "
    fi

    if [ -n "$ycsb_workloada_num" ];then
        const_params=$const_params"--ycsb_workloada_num=$ycsb_workloada_num "
    fi

    if [ -n "$report_fillrandom_latency" ];then
        const_params=$const_params"--report_fillrandom_latency=$report_fillrandom_latency "
    fi

}

RUN_ONE_TEST() {
    const_params=""
    FILL_PATAMS
    cmd="$bench_file_path $const_params >>out.out 2>&1"
    echo $cmd >out.out
    echo $cmd
    eval $cmd
}

CLEAN_CACHE() {
    if [ -n "$bench_db_path" ];then
        rm -f $bench_db_path/*
    fi
    sleep 2
    sync
    echo 3 > /proc/sys/vm/drop_caches
    sleep 2
}

#------ Warning ------#
#为了保证SSD性能，重新挂载SSD，看测试需要，因为SSD会越跑越慢
#一定不要错误格式化盘了

function REDO_MOUNT_SSD() {
    umount "/mnt/ssd/"
    mkfs.ext4 "/dev/sdb1"
    mount "/dev/sdb1" "/mnt/ssd"
}
#---------------------#

COPY_OUT_FILE() {
    mkdir $bench_file_dir/result_matrixkv_value > /dev/null 2>&1
    res_dir=$bench_file_dir/result_matrixkv_value/value-$value_size
    mkdir $res_dir > /dev/null 2>&1
    \cp -f $bench_file_dir/compaction.csv $res_dir/
    \cp -f $bench_file_dir/OP_DATA $res_dir/
    \cp -f $bench_file_dir/OP_TIME.csv $res_dir/
    \cp -f $bench_file_dir/out.out $res_dir/
    #\cp -f $bench_file_dir/Latency.csv $res_dir/
    #\cp -f $bench_file_dir/NVM_LOG $res_dir/
    #\cp -f $bench_db_path/OPTIONS-* $res_dir/
    #\cp -f $bench_db_path/LOG $res_dir/
}
RUN_ALL_TEST() {
    for value in ${value_array[@]}; do
        CLEAN_CACHE
        REDO_MOUNT_SSD

        value_size="$value"
        num="`expr $test_all_size / $value_size`"

        RUN_ONE_TEST
        if [ $? -ne 0 ];then
            exit 1
        fi
        COPY_OUT_FILE
        sleep 5
    done
}

RUN_ALL_TEST
