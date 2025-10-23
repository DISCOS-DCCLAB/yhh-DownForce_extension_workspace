et -x
# ------------------------------
# DownForce NVMe Initialization Script
#   Modes: --full / --quick
# ------------------------------

SUDO_PASSWORD="dcclab"
TARGET_DEV="/dev/nvme2n1"
CTRL="/dev/nvme2"
MOUNT_POINT="/mnt/980pro"

sudo_with_pass() {
	    echo "$SUDO_PASSWORD" | sudo -S "$@"
    }

    log() {
	        echo -e "\033[1;34m[INFO]\033[0m $1"
	}

	err() {
		    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
		        exit 1
		}

		# ------------------------------
		# Mode selection
		# ------------------------------
		MODE="quick"
		if [[ "$1" == "--full" ]]; then
			    MODE="full"
		    elif [[ "$1" == "--quick" ]]; then
			        MODE="quick"
			else
				    log "No mode specified → defaulting to quick mode."
		fi

		log "Selected mode: $MODE"

		# ------------------------------
		# Sanity check
		# ------------------------------
		if ! lsblk | grep -q "$(basename $TARGET_DEV)"; then
			    err "Target device $TARGET_DEV not found. Check NVMe connection."
		fi

		if mount | grep -q "$TARGET_DEV"; then
			    log "Unmounting existing mount of $TARGET_DEV..."
			        sudo_with_pass umount "$TARGET_DEV" || err "Failed to unmount $TARGET_DEV"
		fi

		# ------------------------------
		# Drop caches
		# ------------------------------
		log "Dropping OS page caches..."
		sudo_with_pass sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

		# ------------------------------
		# Controller reset
		# ------------------------------
		log "Resetting NVMe controller..."
		sudo_with_pass nvme reset "$CTRL" || log "nvme reset not supported, skipping."

		# ------------------------------
		# Format & sanitize
		# ------------------------------
		if [[ "$MODE" == "full" ]]; then
			    log "Performing FULL initialization (format + sanitize)..."
			        sudo_with_pass nvme format "$TARGET_DEV" -s 1 -f || err "nvme format failed"
				    sudo_with_pass nvme sanitize "$CTRL" -a 2 || log "sanitize not supported or skipped"
			    else
				        log "Performing QUICK initialization (format only)..."
					    sudo_with_pass nvme format "$TARGET_DEV" -s 1 -f || err "nvme format failed"
		fi

		sleep 3
		lsblk | grep -q "$(basename $TARGET_DEV)" || err "Device disappeared after format/sanitize"

		# ------------------------------
		# Low-level I/O probe
		# ------------------------------
		log "Testing raw write access..."
		sudo_with_pass dd if=/dev/zero of="$TARGET_DEV" bs=1M count=16 oflag=direct status=none || err "Raw write failed — possible hardware issue"

		# ------------------------------
		# Filesystem creation & mount
		# ------------------------------
		log "Creating ext4 filesystem..."
		sudo_with_pass mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0 "$TARGET_DEV" || err "mkfs.ext4 failed"

		sudo_with_pass mkdir -p "$MOUNT_POINT"
		log "Mounting to $MOUNT_POINT..."
		sudo_with_pass mount "$TARGET_DEV" "$MOUNT_POINT" || err "Mount failed"

		sudo_with_pass chmod -R 777 "$MOUNT_POINT"
		sudo_with_pass sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"

		log "✅ NVMe initialization complete: $TARGET_DEV → $MOUNT_POINT"

	
