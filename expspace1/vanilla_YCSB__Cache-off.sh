#!/bin/bash
set -x

# ------------------------------
# Default environment setup
# ------------------------------
SUDO_PASSWORD="dcclab"             # sudo password
DB_dir_="/mnt/980pro"              # DB path
servername=${USER}                 # servername

# ------------------------------
# Input argument: db_bench directory (default = script location)
# ------------------------------
if [ -z "$1" ]; then
  SCRIPT_DIR=$(dirname "$(realpath "$0")")
  DB_BENCH_DIR="$SCRIPT_DIR"
else
  DB_BENCH_DIR="$1"
fi

db_bench_target_="${DB_BENCH_DIR}/db_bench_vanilla"

if [ ! -x "$db_bench_target_" ]; then
  echo "Error: db_bench not found or not executable in $DB_BENCH_DIR"
  exit 1
fi

# ------------------------------
# Experiment parameter block
# ------------------------------
repeat_num=1                       # repeat counter

# Mapping workload if needed
declare -A run_num_map
run_num_map=(
  ["workloade_16_06"]=1000000
  ["workloade_128_06"]=100000
  ["workloade_1024_06"]=10000
  ["workloade_8192_06"]=1000
)

# Declare workload array
workload_arr=("workloada" "workloadb" "workloadc" "workloadd" "workloade" "workloadf")

# ------------------------------
# sudo executer
# ------------------------------
sudo_with_pass() {
    echo $SUDO_PASSWORD | sudo -S $@
}

# ------------------------------
# Prepare log directory
# ------------------------------
script_name=$(basename "$0" .sh)
timestamp=$(date +"%Y-%m-%d_%H-%M")

dirname="${script_name}_${timestamp}/"

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
# Main loop
# ------------------------------
for workload in "${workload_arr[@]}"; do
  echo "=================================================================="
  echo " Starting benchmark: workload=${workload}, runs=${repeat_num} "
  echo "=================================================================="

  for run in $(seq 1 $repeat_num); do
    echo "--- Run #${run} for workload ${workload} ---"

    # Reset NVMe
    sh /home/dccmoon/yhh/DownForce_workspace/format_nvme2n1.sh

    # Build log file names
    log_file="./${dirname}YCSB-${workload}_run${run}.log"
    DB_log_="${log_file%.log}.LOG"
    report_file_="${log_file%.log}.csv"

    # Build benchmark command
    cmd="${db_bench_target_} -benchmarks=ycsb_load,ycsb_run,stats,levelstats,memstats \
      -db=${DB_dir_} \
      -statistics -histogram \
      -stats_interval=1 \
      -stats_interval_seconds=1 \
      -stats_per_interval=0 \
      -report_interval_seconds=1 \
      -report_bg_io_stats=true \
      -threads=10 -value_size=1024 \
      -num=50000000 \
      -load_num=10000000 -running_num=10000000 \
      -load_duration=0 -ycsb_workload=ycsb_workload/${workload} -ycsb_request_speed=100 \
      -seed=1 \
      -write_buffer_size=67108864 -max_write_buffer_number=2 \
      -target_file_size_multiplier=1 \
      -max_background_flushes=1 \
      -max_background_compactions=16 \
      -subcompactions=4 \
      -compaction_style=0 \
      -force_consistency_checks=true \
      -verify_checksum=false \
      -level0_file_num_compaction_trigger=4 \
      -level0_slowdown_writes_trigger=20 -level0_stop_writes_trigger=32 \
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

    # Print and run command
    echo "$cmd" | tee "$log_file" >/dev/null
    bash -c "$cmd" 2>&1 | tee -a "$log_file" && wait

    # Copy RocksDB LOG and report.csv from DB_BENCH_DIR
    if [ -f "${DB_dir_}/LOG" ]; then
      cp "${DB_dir_}/LOG" "${DB_log_}"
    fi

    if [ -f "${DB_BENCH_DIR}/report.csv" ]; then
      cp "${DB_BENCH_DIR}/report.csv" "${report_file_}"
      rm "${DB_BENCH_DIR}/report.csv"
    fi

    sleep 10
  done
done

# ------------------------------
# Post-processing: permissions
# ------------------------------
sudo_with_pass chown $servername:$servername ./$dirname/
sudo_with_pass chown $servername:$servername ./$dirname/*
sudo_with_pass chmod 775 ./$dirname
sudo_with_pass chmod 664 ./$dirname/*

echo "=================================================================="
echo " Benchmark completed. All results stored in $dirname "
echo "=================================================================="
