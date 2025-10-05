import os
import re
import csv
import argparse

def human_readable_ops(val: int) -> str:
    """정수 operations 값을 K/M 단위 문자열로 변환"""
    if val >= 1_000_000:
        return f"{val/1_000_000:.1f}M"
    elif val >= 1_000:
        return f"{val/1_000:.1f}K"
    else:
        return str(val)

def parse_log_file(filepath):
    results = {"load": {}, "run": {}}
    with open(filepath, "r") as f:
        for line in f:
            if line.startswith("ycsb_load"):
                m = re.search(r"(\d+(?:\.\d+)?) micros/op (\d+) ops/sec (\d+\.\d+) seconds (\d+) operations", line)
                if m:
                    results["load"]["ops/sec"] = int(m.group(2))
                    results["load"]["seconds"] = float(m.group(3))
                    results["load"]["operations"] = human_readable_ops(int(m.group(4)))
            elif line.startswith("ycsb_run"):
                m = re.search(r"(\d+(?:\.\d+)?) micros/op (\d+) ops/sec (\d+\.\d+) seconds (\d+) operations", line)
                if m:
                    results["run"]["ops/sec"] = int(m.group(2))
                    results["run"]["seconds"] = float(m.group(3))
                    results["run"]["operations"] = human_readable_ops(int(m.group(4)))
    return results

def extract_workload_name(filename: str) -> str:
    m = re.search(r"(workload[a-z])", filename)
    if m:
        return m.group(1)
    return os.path.splitext(filename)[0]

def main(log_dir):
    log_dir = os.path.abspath(log_dir)
    if not os.path.isdir(log_dir):
        raise NotADirectoryError(f"'{log_dir}' is not a valid directory")

    data_dict = {}
    for fname in os.listdir(log_dir):
        if fname.endswith(".log"):
            workload = extract_workload_name(fname)
            filepath = os.path.join(log_dir, fname)
            parsed = parse_log_file(filepath)
            data_dict[workload] = [
                workload,
                parsed["load"].get("ops/sec", ""),
                parsed["load"].get("seconds", ""),
                parsed["load"].get("operations", ""),
                parsed["run"].get("ops/sec", ""),
                parsed["run"].get("seconds", ""),
                parsed["run"].get("operations", "")
            ]

    # 정렬 순서: workloada, workloadb, workloadc, ...
    ordered_keys = sorted(data_dict.keys(), key=lambda x: x)
    data = [data_dict[k] for k in ordered_keys]

    outname = os.path.join(log_dir, os.path.basename(log_dir) + "_results.csv")
    with open(outname, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["workload", "load_ops/sec", "load_seconds", "load_operations",
                         "run_ops/sec", "run_seconds", "run_operations"])
        writer.writerows(data)

    print(f"CSV file saved as {outname}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("log_dir", help="Directory containing .log files")
    args = parser.parse_args()
    main(args.log_dir)
