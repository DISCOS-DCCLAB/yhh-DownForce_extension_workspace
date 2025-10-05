#!/bin/bash

# Run benchmark scripts sequentially
bash ./vanilla_YCSB__Cache-off.sh
bash ./vanilla_YCSB__Cache-on.sh
bash ./DF-Lv_YCSB__Cache-off.sh
bash ./DF-Lv_YCSB__Cache-on.sh
