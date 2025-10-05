import pandas as pd
import matplotlib.pyplot as plt
import argparse
import os

def plot_from_csv(csv_path):
    df = pd.read_csv(csv_path)

    # CSV 순서 유지
    config_order = df["config"].drop_duplicates().tolist()
    df["config"] = pd.Categorical(df["config"], categories=config_order, ordered=True)

    # -------------------
    # Load 평균 처리 (workload=Load처럼 pivot화)
    # -------------------
    load_df = df.groupby("config", as_index=False)["load_ops/sec"].mean()
    load_df["workload"] = "Load"
    load_pivot = load_df.pivot(index="workload", columns="config", values="load_ops/sec")

    # Run 처리
    run_df = df[["config", "workload", "run_ops/sec"]]
    run_pivot = run_df.pivot(index="workload", columns="config", values="run_ops/sec")

    # workload 그룹 분리
    run_af = run_pivot.loc[["a","b","c","d","f"]]  # A, B, C, D, F
    run_e  = run_pivot.loc[["e"]]                  # E만 따로

    # -------------------
    # 플롯
    # -------------------
    fig, axes = plt.subplots(1, 3, figsize=(18,6))

    # Load subplot (pivot → bar 두께 동일)
    load_pivot.plot(kind="bar", ax=axes[0])
    axes[0].set_title("Load")
    axes[0].set_ylabel("Throughput (ops/sec)")
    axes[0].tick_params(axis='x', rotation=0)

    # Run A,B,C,D,F subplot
    run_af.plot(kind="bar", ax=axes[1])
    axes[1].set_title("A–D, F")
    axes[1].set_ylabel("Throughput (ops/sec)")
    axes[1].tick_params(axis='x', rotation=0)

    # Run E subplot (bar 두께 Load와 동일)
    run_e.plot(kind="bar", ax=axes[2])
    axes[2].set_title("E")
    axes[2].set_ylabel("Throughput (ops/sec)")
    axes[2].tick_params(axis='x', rotation=0)

    # 범례는 전체 공유
    handles, labels = axes[1].get_legend_handles_labels()
    fig.legend(handles, labels, loc="upper center", ncol=len(config_order))

    plt.tight_layout(rect=[0,0,1,0.9])  # legend 공간 확보

    outpng = os.path.splitext(csv_path)[0] + ".png"
    plt.savefig(outpng, dpi=300)
    print(f"plot saved to {outpng}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path", help="merged csv file")
    args = parser.parse_args()
    plot_from_csv(args.csv_path)
