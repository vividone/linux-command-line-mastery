# Linux & Command Line Mastery — Detailed Command Notes & Explanations

This document provides conceptual explanations, command syntax breakdowns, observed outputs, and troubleshooting steps from exercises executed on **Ubuntu 24.04 LTS** (`opsninja`).

---

## 1. File System Navigation & Linux Hierarchy
Understanding the Filesystem Hierarchy Standard (FHS) and path resolution is critical for navigating servers without a GUI:
* **`pwd` (Print Working Directory):** Outputs the full absolute path from the root directory `/` (e.g., `/home/volaitan/linux-command-line-mastery`), confirming exact location before running destructive commands.
* **`cd` (Change Directory) — Absolute vs. Relative Paths:**
  * **Absolute paths** start at `/` (e.g., `cd /var/log`) and work regardless of current location.
  * **Relative paths** resolve from the current directory (e.g., `cd ../scripts` moves up one level via `..` and enters `scripts`).
* **Standard Linux Directories Explored:**
  * **`/etc`:** Stores host-specific system and service configuration files (e.g., `/etc/os-release`, `/etc/ssh/sshd_config`).
  * **`/var`:** Holds variable data that changes during normal operation, such as system logs (`/var/log/syslog`), caches, and spool files.
  * **`/tmp`:** World-writable temporary storage (`drwxrwxrwt` with the sticky bit set so users can only delete their own files) cleared across reboots.

---

## 2. Package Installation & System Tooling (`apt`)
On Ubuntu 24.04 LTS, software lifecycle management is handled via **APT (Advanced Package Tool)**:
* **`sudo apt update`:** Downloads the latest package index metadata from configured repositories in `/etc/apt/sources.list.d/` without modifying installed binaries. Running this first prevents `404 Not Found` errors from stale package versions.
* **`sudo apt install -y <package>`:** Resolves dependency trees, downloads `.deb` archives, and installs binaries into `/usr/bin/`.
* **Core Utilities Verified & Used:**
  * `coreutils` (`ls`, `cp`, `mv`, `rm`, `mkdir`, `chmod`, `chown`, `cat`, `head`, `tail`)
  * `grep` & `findutils` (`grep`, `find`) for text and file discovery
  * `gawk` (`awk`) for column-based stream processing
  * `procps` (`ps`, `top`, `free`, `uptime`) for kernel/process telemetry
  * `iproute2` (`ip`, `ss`) and `iputils-ping` (`ping`) for network stack inspection

---

## 3. File & Directory Management
* **`mkdir -p artifacts/playground/{logs,configs,backups}`:** The `-p` flag creates parent directories automatically and suppresses errors if directories already exist (essential for idempotent automation scripts). Brace expansion `{a,b,c}` creates multiple sibling directories in one call.
* **`touch`:** Updates file access/modification timestamps or creates empty placeholder files (`app.log`, `settings.conf`) with default `rw-rw-r--` (`664`) permissions.
* **`cp` & `mv`:** `cp` duplicates file data to a new inode (`cp settings.conf settings.conf.bak`), whereas `mv` renames or relocates directory pointers without copying data blocks on the same filesystem.
* **`rm`, `rm -i`, & `rm -r`:** `rm` unlinks files permanently (no trash bin on Linux CLI). `rm -i` prompts for interactive confirmation before each deletion, and `rm -r` recursively removes directories and their contents.
* **Viewing & Searching Contents:**
  * `cat`: Concatenates and prints entire small files to stdout.
  * `less`: Opens large logs in a scrollable pager without loading the entire file into RAM.
  * `head -n 6` / `tail -n 20`: Inspects the first or last N lines of logs or sorted outputs.
  * `find artifacts/playground -type f`: Recursively walks the directory tree and filters strictly for regular files (`-type f`), returning `app.log`, `settings.conf`, and `settings.conf.bak`.
  * `grep "ERROR" artifacts/playground/logs/app.log`: Scans line-by-line using pattern matching to isolate error events (`ERROR: Connection timeout`, `ERROR: Disk threshold warning`).

---

## 4. Permissions & Ownership (`chmod`, `chown`, `sudo`)
Linux enforces multi-user security through discretionary access control (DAC) across three scopes: **User/Owner (`u`)**, **Group (`g`)**, and **Others (`o`)**, using **Read (`r=4`)**, **Write (`w=2`)**, and **Execute (`x=1`)**.

* **Example 1 — Securing Sensitive Reports (`chmod 640`):**
  * Command: `chmod 640 artifacts/system_health.txt`
  * Result: `-rw-r----- 1 volaitan volaitan 2628 system_health.txt`
  * **Explanation:** Owner `volaitan` has `rw-` (`6`), group `volaitan` has `r--` (`4`), and all other system users have `---` (`0`), protecting host telemetry from unauthorized local users.
* **Example 2 — Making Scripts Executable (`chmod +x` & `750`):**
  * Command: `chmod +x scripts/workspace_provisioner.sh`
  * Result: `-rwxrwxr-x 1 volaitan volaitan 1037 scripts/workspace_provisioner.sh`
  * **Explanation:** Text files lack execute bits by default (`664`). Adding `+x` enables the kernel to invoke the script directly via its `#!/usr/bin/env bash` shebang. Inside the script, directories are created with `chmod 750` (`drwxr-x---`) so only the owner can modify files while group members can traverse and read.
* **Ownership & Privilege Escalation (`chown` & `sudo`):**
  * `sudo chown user:group <file>` transfers file ownership (requires root privileges via `sudo` because normal users cannot give away file ownership).
  * `sudo` delegates time-limited root execution for privileged tasks like package installation and system log inspection while logging actions to `/var/log/auth.log`.

---

## 5. Redirection & Filtering Pipelines
Every Linux process opens three standard file descriptors: **`0` (stdin)**, **`1` (stdout)**, and **`2` (stderr)**.

* **Output & Error Redirection:**
  * `>` (Overwrite): Truncates the target file and writes stdout (e.g., `grep "ERROR" app.log > artifacts/errors_only.txt`).
  * `>>` (Append): Adds stdout to the end of an existing file without erasing prior entries (used in logging).
  * `2>` (Error Stream): Captures error messages separately from clean data:
    * Command: `ping -c 3 8.8.8.8 > artifacts/network_report.txt 2> artifacts/network_errors.log`
    * Outcome: Successful diagnostics go to `network_report.txt`, while any DNS/socket errors go to `network_errors.log` (`0` bytes when healthy).
* **Pipe Chains (`|`) & Stream Filtering:**
  * Command: `awk -F":" "{print \$1}" artifacts/playground/logs/app.log | sort | uniq -c`
  * **Step-by-step data flow:**
    1. `awk -F":" "{print \$1}"` splits each log line on `:` and extracts the first field (`INFO` or `ERROR`).
    2. `sort` groups identical strings adjacent to each other (required because `uniq` only collapses consecutive duplicates).
    3. `uniq -c` counts consecutive occurrences, producing `2 ERROR` and `2 INFO`.

---

## 6. Process & System Monitoring
* **`uptime`:** Showed `up 2:16, 1 user, load average: 0.91, 1.10, 1.02` — measuring system availability and average runnable/uninterruptible processes over 1-, 5-, and 15-minute intervals.
* **`free -m`:** Displayed physical RAM in mebibytes (`7855 MiB` total, `4505 MiB` used, `2528 MiB` buff/cache, `2632 MiB` available) and `2047 MiB` swap. The `available` column accurately reflects memory usable for new containers without swapping.
* **`df -h /`:** Reported human-readable filesystem capacity on `/dev/sda5` (`116G` total, `17G` used, `94G` available, `15%` utilization), confirming ample headroom for Docker images and logs.
* **`ps aux --sort=-%mem | head -n 6`:** Captured a point-in-time snapshot of all system processes (`a` = all users, `u` = user-oriented format, `x` = background daemons without a TTY), sorted descending by memory percentage (`%MEM`), isolating the top 5 consumers (`firefox` content processes at `6.4%`–`4.0%` RSS).
* **`top`:** Provides a real-time, interactive process and CPU scheduler view (`us` user space, `sy` kernel space, `wa` I/O wait) for diagnosing live performance spikes.
