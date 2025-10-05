#!/bin/bash
set -x

# ------------------------------
# sudo executer
# ------------------------------
SUDO_PASSWORD="dcclab"             # sudo password
sudo_with_pass() {
    echo $SUDO_PASSWORD | sudo -S $@
}

sudo_with_pass sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
# <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <! DANGEROUS ZONE > <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!>
sudo_with_pass umount /dev/nvme2n1                                                                                                                            # <!>
#                                                                                                                                                   # <!>
# Clear the DB_dir directory and initialize SSD and drop caches before each run                                                                     # <!>
sudo_with_pass nvme format /dev/nvme2n1 -s 1 -f                                                                                                               # <!>
#sudo nvme sanitize /dev/nvme1n1 -a 2                                                                                                               # <!>
#                                                                                                                                                   # <!>
#sudo yes |                                                                                                                                         # <!>
sudo_with_pass mkfs.ext4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/nvme2n1                                                                               # <!>
sudo_with_pass mount /dev/nvme2n1 /mnt/980pro                                                                                                                 # <!>
# <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!> <!>
sudo_with_pass rm -rf /mnt/980pro/*
sudo_with_pass chmod -R 777 /mnt/980pro
sudo_with_pass sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

