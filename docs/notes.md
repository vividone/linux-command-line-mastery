# Command Observations & Troubleshooting Notes

## 1. File Management & Path Navigation
- **Observation:** Using `mkdir -p` prevents errors when parent directories do not yet exist and makes setup scripts idempotent.
- **Safety Practice:** Used `rm -i` during interactive cleanup tests to confirm file deletions before execution.

## 2. Permissions & Process Monitoring
- **Observation:** `ps aux --sort=-%mem | head -n 6` quickly isolates top memory consumers without needing interactive mode in `top`.
- **Permissions:** Applied `chmod 640` to sensitive system reports (`artifacts/system_health.txt`) so the owner can read/write, group members can read, and others have no access.

## 3. Networking & Redirection
- **Observation:** `ss -tuln` replaces legacy `netstat` on Ubuntu 24.04 LTS for inspecting listening TCP/UDP ports without DNS resolution delays.
- **Redirection:** Separated standard output (`>`) from standard error (`2>`) during network diagnostics to keep report files clean.

## 4. Shell Scripting Troubleshooting
- **Issue:** New script files created with `cat` or `touch` default to `664` (`-rw-rw-r--`) and return `Permission denied` when executed directly.
- **Resolution:** Applied `chmod +x scripts/workspace_provisioner.sh` and included `#!/usr/bin/env bash` with `set -euo pipefail` for safe error handling.
