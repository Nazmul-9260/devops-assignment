#!/usr/bin/env bash
# ==============================================================================
# Script Name: system_health.sh
# Description: Production-grade system health check script with JSON support,
#              configurable thresholds, log rotation, and exit codes.
# ==============================================================================

set -euo pipefail

# Default thresholds
CPU_THRESHOLD=90
MEM_THRESHOLD=85
DISK_THRESHOLD=80
LOG_FILE="health_log.txt"
MAX_LOG_SIZE=$((5 * 1024 * 1024)) # 5 MB
JSON_OUTPUT=false

# Exit codes
EXIT_HEALTHY=0
EXIT_WARNING=1
EXIT_CRITICAL=2
CURRENT_STATUS=$EXIT_HEALTHY

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --cpu <num>      CPU usage warning threshold percentage (default: 90)
  --mem <num>      Memory usage warning threshold percentage (default: 85)
  --disk <num>     Disk usage warning threshold percentage (default: 80)
  --log <path>     Path to log file (default: health_log.txt)
  --json           Output log entry in JSON format
  -h, --help       Display this help message and exit
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cpu) CPU_THRESHOLD="$2"; shift 2 ;;
        --mem) MEM_THRESHOLD="$2"; shift 2 ;;
        --disk) DISK_THRESHOLD="$2"; shift 2 ;;
        --log) LOG_FILE="$2"; shift 2 ;;
        --json) JSON_OUTPUT=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

rotate_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        local file_size
        file_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)
        if [[ "$file_size" -gt "$MAX_LOG_SIZE" ]]; then
            mv "$LOG_FILE" "${LOG_FILE}.1"
        fi
    fi
}

# 1. Collect Metrics
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' 2>/dev/null || echo "0")
CPU_INT=${CPU_USAGE%.*}
CPU_INT=${CPU_INT:-0}

MEM_INFO=$(free | grep Mem)
MEM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
MEM_USED=$(echo "$MEM_INFO" | awk '{print $3}')
MEM_USAGE=$(( 100 * MEM_USED / MEM_TOTAL ))

MAX_DISK_USAGE=0
while read -r usage_pct; do
    clean_pct=${usage_pct%\%}
    if [[ "$clean_pct" -gt "$MAX_DISK_USAGE" ]]; then
        MAX_DISK_USAGE="$clean_pct"
    fi
done < <(df -P | awk 'NR > 1 {print $5}')

LOAD_AVG=$(awk '{print $1, $2, $3}' /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}')
TOP_MEM_PROCS=$(ps aux --sort=-%mem | awk 'NR>1 && NR<=6 {printf "%s(PID:%s,MEM:%s%%) ", $11, $2, $4}')

# 2. Check Thresholds
WARNING_MESSAGES=()

if [[ "$CPU_INT" -ge "$CPU_THRESHOLD" ]]; then
    WARNING_MESSAGES+=("CPU usage is high: ${CPU_USAGE}% (Threshold: ${CPU_THRESHOLD}%)")
    CURRENT_STATUS=$EXIT_WARNING
fi

if [[ "$MEM_USAGE" -ge "$MEM_THRESHOLD" ]]; then
    WARNING_MESSAGES+=("Memory usage is high: ${MEM_USAGE}% (Threshold: ${MEM_THRESHOLD}%)")
    CURRENT_STATUS=$EXIT_WARNING
fi

if [[ "$MAX_DISK_USAGE" -ge "$DISK_THRESHOLD" ]]; then
    WARNING_MESSAGES+=("Disk usage is high: ${MAX_DISK_USAGE}% (Threshold: ${DISK_THRESHOLD}%)")
    CURRENT_STATUS=$EXIT_WARNING
fi

# Critical check (e.g., if any metric hits >= 95%)
if [[ "$CPU_INT" -ge 95 || "$MEM_USAGE" -ge 95 || "$MAX_DISK_USAGE" -ge 95 ]]; then
    CURRENT_STATUS=$EXIT_CRITICAL
fi

if [[ ${#WARNING_MESSAGES[@]} -gt 0 ]]; then
    for msg in "${WARNING_MESSAGES[@]}"; do
        echo "[WARNING] $TIMESTAMP - $msg" >&2
    done
fi

# 3. Format, Print to Screen & Append to Log
rotate_logs

STATUS_TEXT="HEALTHY"
[[ $CURRENT_STATUS -eq 1 ]] && STATUS_TEXT="WARNING"
[[ $CURRENT_STATUS -eq 2 ]] && STATUS_TEXT="CRITICAL"

if [[ "$JSON_OUTPUT" == true ]]; then
    LOG_ENTRY=$(cat <<EOF
{"timestamp": "$TIMESTAMP", "status": "$STATUS_TEXT", "cpu_pct": "$CPU_USAGE", "mem_pct": "$MEM_USAGE", "max_disk_pct": "$MAX_DISK_USAGE", "load_avg": "$LOAD_AVG", "top_procs": "$TOP_MEM_PROCS"}
EOF
)
else
    LOG_ENTRY="[$TIMESTAMP] STATUS: $STATUS_TEXT | CPU: ${CPU_USAGE}% | MEM: ${MEM_USAGE}% | DISK: ${MAX_DISK_USAGE}% | LOAD: $LOAD_AVG | TOP_MEM: $TOP_MEM_PROCS"
fi

# Print on terminal AND save to file
echo "$LOG_ENTRY" | tee -a "$LOG_FILE"

exit "$CURRENT_STATUS"
