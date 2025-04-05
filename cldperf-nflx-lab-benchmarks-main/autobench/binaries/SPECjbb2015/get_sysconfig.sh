echo ====================  /etc/release ==============================
cat /etc/*release*
echo =========================== uname ===============================
uname -a
echo ====================  free -h ===================================
free -h
echo ====================  ulimit -a ===================================
ulimit -a
echo ====================== numactl -H ===============================
numactl -H
echo ==================== dmidecode bios-version t 17 ================
dmidecode -s bios-version
echo ===================== tuned-adm active ==========================
tuned-adm active
echo "========= /sys/devices/system/cpu/cpu0 thru 127/cpufreq/scaling_governor |sort -u ============="
for i in $(seq 0 127); do  cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor ; done | sort -u
echo ===================== dmidecode t 17 ============================
dmidecode -t 17
echo ===================== dmidecode t 17 size =======================
dmidecode -t 17 | grep Size
echo ======================= /proc/cpuinfo ===========================
cat /proc/cpuinfo
echo ======================= /proc/meminfo ===========================
cat /proc/meminfo
echo ======================= lscpu ===================================
lscpu
echo ====================   lsblk     ================================
lsblk
echo ===================   ip -4 a    ================================
ip -4 a
echo ===================   sysctl    ================================
sysctl -a
