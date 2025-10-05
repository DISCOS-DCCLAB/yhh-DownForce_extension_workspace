import pandas as pd
import matplotlib.pyplot as plt
import argparse
import os

def plot_from_csv(csv_path):
    df = pd.read_csv(csv_path)

    # CSV에 등장한 순서대로 config 순서를 유지
    config_order = df["config"].drop_duplicates().tolist()
    df["config"] = pd.Categorical(df["config"], categories=config_order, ordered=True)

    # run_ops/sec 값을 막대그래프로
    pivot = df.pivot(index="workload", columns="config", values="run_ops/sec")

    ax = pivot.plot(kind="bar", figsize=(12,6))

    plt.ylabel("Throughput (ops/sec)")
    plt.title("YCSB Throughput Comparison")
    plt.xticks(rotation=0)
    plt.tight_layout()

    outpng = os.path.splitext(csv_path)[0] + ".png"
    plt.savefig(outpng)
    print(f"plot saved to {outpng}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path", help="merged csv file")
    args = parser.parse_args()
    plot_from_csv(args.csv_path)
