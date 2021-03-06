#! /bin/sh


bench_db_path="/home/lzw/ceshi"
wal_dir="/home/lzw/ceshi"
bench_value="4096"
bench_compression="none" #"snappy,none"

#bench_benchmarks="fillseq,stats,readseq,readrandom,stats" #"fillrandom,fillseq,readseq,readrandom,stats"
#bench_benchmarks="fillrandom,stats,readseq,readrandom,stats"
#bench_benchmarks="fillrandom,stats,wait,stats,readseq,readrandom,stats"
#bench_benchmarks="fillrandom,stats,wait,clean_cache,stats,readseq,readrandom,stats"
bench_benchmarks="stats,readrandom,stats"
bench_num="2000000"
bench_readnum="100000"
#bench_max_open_files="1000"
max_background_jobs="2"
max_bytes_for_level_base="`expr 8 \* 1024 \* 1024 \* 1024`" 
#max_bytes_for_level_base="`expr 256 \* 1024 \* 1024`" 
use_existing_db="true"

pmem_path="/pmem/nvm"
use_nvm="true"

const_params="
    --db=$bench_db_path \
    --use_existing_db=$use_existing_db \
    --wal_dir=$wal_dir \
    --value_size=$bench_value \
    --benchmarks=$bench_benchmarks \
    --num=$bench_num \
    --reads=$bench_readnum \
    --compression_type=$bench_compression \
    --max_background_jobs=$max_background_jobs \
    --max_bytes_for_level_base=$max_bytes_for_level_base \
    --use_nvm_module=$use_nvm \
    --pmem_path=$pmem_path \
    "

bench_file_path="$(dirname $PWD )/db_bench"

if [ ! -f "${bench_file_path}" ];then
bench_file_path="$PWD/db_bench"
fi

if [ ! -f "${bench_file_path}" ];then
echo "Error:${bench_file_path} or $(dirname $PWD )/db_bench not find!"
exit 1
fi

cmd="$bench_file_path $const_params "

if [ -n "$1" ];then
cmd="nohup $bench_file_path $const_params >>out.out 2>&1 &"
echo $cmd >out.out
fi

echo $cmd
eval $cmd
