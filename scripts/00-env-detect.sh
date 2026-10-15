#!/usr/bin/env bash
# 00-env-detect.sh — 运行环境判定
# 用途：在任何测量之前先判清"这套系统到底是什么状态"，
#       因为 Live / 持久化 Live / 已安装 三种模式下，同一份数据的含义完全不同。
# 只读脚本，不修改任何系统配置。

echo "===== 运行环境判定 ====="
echo "-- date --"; date -Is

echo
echo "-- 1. 是否 Live 会话 --"
echo "[cmdline]"; cat /proc/cmdline | tr ' ' '\n' | grep -E 'boot=casper|boot=live|iso-scan|toram|live-media' || echo "  (无 Live 相关内核参数)"
echo "[live dirs]"; ls -d /run/live /lib/live /rofs /cdrom 2>/dev/null || echo "  (无 Live 目录)"
echo "[squashfs/overlay]"; mount | grep -E 'overlay|squashfs|aufs' | head -5 || echo "  (无 overlay/squashfs 挂载)"

echo
echo "-- 2. 是否持久化（仅 Live 时有效）--"
echo "[persistence]"; mount | grep -E 'casper-rw|persistence' || echo "  (无持久化挂载层)"
echo "[df / and /home]"; df -h / /home 2>/dev/null
echo "[可写层容量判定] 若 / 的容量接近 ISO 体积(2-6G)且文件系统为 overlay → 非持久化"

echo
echo "-- 3. 介质类型（决定磁盘数据是否可信）--"
lsblk -d -o NAME,SIZE,ROTA,TRAN,MODEL,VENDOR
echo "[根文件系统所在设备]"; findmnt -no SOURCE /
echo "[根设备 TRAN]"; ROOT_SRC=$(findmnt -no SOURCE /); ROOT_DEV=$(lsblk -no PKNAME "$ROOT_SRC" 2>/dev/null | head -1)
if [ -n "$ROOT_DEV" ]; then lsblk -d -no NAME,TRAN,ROTA "/dev/$ROOT_DEV" 2>/dev/null; fi
echo "  判定提示：TRAN=usb → 系统盘走 USB，第 4 步磁盘数据只代表该外置盘，不代表内置 NVMe"
echo "            ROTA=1  → 机械盘"

echo
echo "-- 4. CPU 与内存基线 --"
lscpu | grep -E 'Model name|^CPU\(s\)|Core|Socket|Thread|Flags' | head -8
echo "[flags 关键点]"; lscpu | grep -o -E 'avx2|fma|bmi2|avx512f' | sort -u | tr '\n' ' '; echo
echo "[mem]"; free -g | head -2

echo
echo "-- 5. glibc hwcaps（判断 x86-64-v3 是否受支持）--"
/lib64/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -A8 'Subdirectories of glibc-hwcaps' \
  || /lib/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -A8 'Subdirectories of glibc-hwcaps' \
  || echo "  未获取到 hwcaps 信息"

echo
echo "===== 判定结论（由执行者填写）====="
echo "运行环境：<非持久化 Live | 持久化 Live | 已安装>"
echo "系统介质：<型号 / 接口(usb|nvme|sata) / SSD|HDD>"
echo "持久化可用空间：<x GB>"
echo "本报告文件名应记为：bench-<系统标识>-<live|installed>-<YYYYMMDD>.md"
