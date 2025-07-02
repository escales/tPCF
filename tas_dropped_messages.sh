#!/bin/bash
# TAS 6.x Dropped Message Detector
# Author: Scales

set -euo pipefail

FOUNDATION_NAME="xxxx"
TMP_LOG="tas_dropped_check.log"
DATE=$(date)
CF_API=$(cf api | grep 'API endpoint' | awk '{print $3}')

echo "Running Dropped Message Check on $FOUNDATION_NAME at $DATE"
echo "CF API Endpoint: $CF_API"
echo "Output will be saved to $TMP_LOG"
echo "-----------------------------------------------------"

# 1. Check Doppler metrics for dropped envelopes
echo "[1/5] Checking Doppler drops..."
cf nozzle --no-filter --debug --drain --recent 2>&1 | grep -i "dropped" > $TMP_LOG || echo "No dropped messages found via nozzle."

# 2. Search Firehose metrics for drops
echo "[2/5] Checking Firehose drops (log-cache or firehose plugin)..."
cf tail log-cache --recent 2>/dev/null | grep -i 'dropped' >> $TMP_LOG || echo "No Firehose drop logs found."

# 3. Get BOSH VMs and inspect Metron/Doppler
echo "[3/5] Inspecting Metron / Doppler logs on VMs..."
bosh -d cf vms --json | jq -r '.Tables[0].Rows[].instance' | grep -E '(doppler|metron)' | while read vm; do
    echo "Checking logs on $vm"
    bosh ssh $vm -c "grep -i 'dropped' /var/vcap/sys/log/*/*.log" >> $TMP_LOG || true
done

# 4. Check for syslog drains that may be backing up or erroring
echo "[4/5] Inspecting syslog drains (e.g., SIEM)..."
cf curl /v2/syslog_drain_urls | jq -r '.[]?' >> $TMP_LOG || echo "No syslog drains found or no errors logged."

# 5. Optional: check VM-level metrics (cpu/io wait)
echo "[5/5] Checking Diego Cells for iowait or network issues..."
bosh -d cf vms --json | jq -r '.Tables[0].Rows[].instance' | grep 'cell' | while read vm; do
    echo "Checking vmstat on $vm"
    bosh ssh $vm -c "vmstat 1 5" >> $TMP_LOG
done

# Summary Output
echo "-----------------------------------------------------"
echo "Summary of Dropped Message Issues:"
grep -i 'dropped' $TMP_LOG | sort | uniq -c | sort -nr | head -20
echo
echo "Full log available at $TMP_LOG"

# Optional: alert/email
# mail -s "TAS Dropped Message Report [$FOUNDATION_NAME]" you@home.com < $TMP_LOG
