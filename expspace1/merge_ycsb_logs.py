import os
import pandas as pd
import argparse

def merge_csvs(input_dir):
    dfs = []
    for fname in os.listdir(input_dir):
        if fname.endswith(".csv"):
            label = os.path.splitext(fname)[0]   # 파일명(확장자 제거)
            fpath = os.path.join(input_dir, fname)
            df = pd.read_csv(fpath)
            df.insert(0, "config", label)  # 구분자 컬럼 추가
            dfs.append(df)
    merged = pd.concat(dfs, ignore_index=True)
    outpath = os.path.join(input_dir, "merged_results.csv")
    merged.to_csv(outpath, index=False)
    print(f"merged csv saved to {outpath}")
    return outpath

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input_dir", help="Directory containing result csv files")
    args = parser.parse_args()
    merge_csvs(args.input_dir)
