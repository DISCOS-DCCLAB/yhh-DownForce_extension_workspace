#!/bin/bash
set -x

# ------------------------------
#  Default environment setup
# ------------------------------
SUDO_PASSWORD="dcclab"             # sudo password
db_bench_target_="db_bench"        # benchmark binary file
DB_dir_="/mnt/980pro"              # DB path
servername=${USER}                 # servername

# ------------------------------
# Experiment parameter block
# ------------------------------
# Repeat counter
repeat_num=1

## Declare arrays to iterate over 
#size_arr=("16") 
lsm_num=("1" "2" "4" "8" "12" "16")
#l0_size=("268435456" "134217728" "67108864" "44040192" "33554432") 
#l1_size=("134217728" "67108864" "33554432" "22020096" "16777216") 
#compaction_num=("16" "8" "4" "3" "2") 
#run_num_arr=("1000000" "100000" "10000" "1000")

# Mapping workload if need
declare -A run_num_map
run_num_map=(
  ["workloade_16_06"]=1000000
  ["workloade_128_06"]=100000
  ["workloade_1024_06"]=10000
  ["workloade_8192_06"]=1000
)

# Declare workload array
workload_arr=("workloada" "workloadb" "workloadc" "workloade" "workloadf")

# ------------------------------
# sudo executer
# ------------------------------
sudo_with_pass() {
    echo $SUDO_PASSWORD | sudo -S $@
}

# ------------------------------
# 로그 디렉토리 준비
# ------------------------------
script_name=$(basename "$0" .sh)
timestamp=$(date +"%Y-%m-%d_%H-%M") # Current timestamp (YYYY-MM-DD_HH-MM)

dirname="${script_name}_${timestamp}/" #must include "/" at the end.

original_dirname="$dirname"
counter=1
while [ -d "./$dirname" ]; do
    ((counter++))
    dirname="${original_dirname%/}_${counter}/"
done

mkdir -p "./$dirname"
sudo_with_pass chown $servername:$servername ./$dirname

ulimit -n 1048576

# ------------------------------
# 메인 루프 시작
# ------------------------------
for workload in "${workload_arr[@]}"; do
  echo "=================================================================="
  echo " Starting benchmark: workload=${workload}, runs=${repeat_num} "
  echo "=================================================================="

  for run in $(seq 1 $repeat_num); do
    echo "--- Run #${run} for workload ${workload} ---"

    for size in "${lsm_num[@]}"; do
      echo ">>> Running with subcompactions=${size}"

      # NVMe 초기화
      sh /home/dccmoon/yhh/DownForce_workspace/format_nvme2n1.sh

      # 로그 파일명 구성
      log_file="./${dirname}_YCSB-${workload}__Vanilla_Cache-off.log"
      DB_log_="${log_file%.log}.LOG"
      report_file_="${log_file%.log}.csv"

      # 실행 명령어 구성 (예시)
      cmd="./${db_bench_target_} -benchmarks=ycsb_load,ycsb_run,stats,levelstats,memstats \
        -db=${DB_dir_} \
        -statistics -histogram \
      -stats_interval=1 \
      -stats_interval_seconds=1 \
      -stats_per_interval=0 \
      -report_interval_seconds=1 \
      -report_bg_io_stats=true \
      -threads=1 -value_size=1024 \
      -num=50000000 \
      -load_num=10000000 -running_num=10000000 \
      -load_duration=0 -ycsb_workload=ycsb_workload/${workload} -ycsb_request_speed=100 \
      -seed=1 \
      -write_buffer_size=67108864 -max_write_buffer_number=2 \
	    -target_file_size_multiplier=1 \
      -max_background_flushes=1 \
      -compaction_style=0 \
      -max_background_compactions=16 \
      -subcompactions=4 \
      -force_consistency_checks=true \
      -verify_checksum=false \
      -level0_file_num_compaction_trigger=4 \
      -level0_slowdown_writes_trigger=20 -level0_stop_writes_trigger=36 \
      -use_direct_io_for_flush_and_compaction=true \
      -use_direct_reads=true \
      -disable_wal=true \
      -disable_auto_compactions=false \
      -soft_pending_compaction_bytes_limit=18446744073709551615 \
      -hard_pending_compaction_bytes_limit=18446744073709551615 \
      -compression_ratio=1.0 \
      -compression_type=none \
      -cache_size=0 \
      -open_files=-1 \
      -min_write_buffer_number_to_merge=1 \
      -max_bytes_for_level_multiplier=5 \
      -in_memory_merge=false \
      -monitor_each_level_sst=true \
      -disable_intra_l0_compaction=true \
      -l0_size_based_stop=false"

      # 로그 출력 및 실행
      echo "$cmd" | tee "$log_file" >/dev/null
      bash -c "$cmd" 2>&1 | tee -a "$log_file" && wait

      # RocksDB LOG, report.csv 보관
      cp "${DB_dir_}/LOG" "${DB_log_}"
      cp ./report.csv "${report_file_}"
      rm ./report.csv

      sleep 10
    done
  done
done

# ------------------------------
# 결과 디렉토리 권한 설정
# ------------------------------
sudo_with_pass chown $servername:$servername ./$dirname/
sudo_with_pass chown $servername:$servername ./$dirname/*
sudo_with_pass chmod 775 ./$dirname
sudo_with_pass chmod 664 ./$dirname/*

echo "=================================================================="
echo " Benchmark completed. All results stored in $dirname "
echo "=================================================================="
