#!/usr/bin/env bash
# 01-tools-detect.sh — 测试工具探测与联网判断（只读，不安装任何东西）
# 用法：bash scripts/01-tools-detect.sh
# 输出 MISSING 的项，按提示词「第 0.5 步」的回退表处理。

echo "===== 工具探测 ====="
for t in gcc g++ make python3 pip3 sysbench schbench fio stress-ng \
         glmark2 vkmark vulkaninfo vainfo glxinfo powerstat upower \
         systemd-analyze nmcli bluetoothctl; do
  if command -v "$t" >/dev/null 2>&1; then
    echo "OK:      $t  -> $(command -v $t)"
  else
    echo "MISSING: $t"
  fi
done

echo
echo "===== 联网判断 ====="
ping -c 3 -W 3 223.5.5.5 2>&1 | tail -2
echo "-- pypi --"
curl -sS -m 8 -o /dev/null -w 'pypi_http=%{http_code}\n' https://pypi.org 2>&1
echo "-- 发行版仓库 --"
if command -v apt-get >/dev/null 2>&1; then apt-cache policy 2>/dev/null | head -5; fi

echo
echo "===== Python 环境 ====="
python3 -c "import sys; print('python', sys.version)" 2>&1
python3 -c "import numpy; print('numpy', numpy.__version__)" 2>&1 | head -3 || echo "numpy 未安装"

echo
echo "===== 缺失工具回退对照表（照着做，不许直接写'未测量'）====="
cat <<'EOF'
sysbench     -> python3 纯计算循环（固定 2e8 次整数乘加 + 2e8 次浮点乘加）
schbench     -> stress-ng --cpu N --cpu-method matrixprod --metrics-brief --timeout 60s
fio 顺序     -> dd if=/dev/zero of=./benchfile bs=1M count=2000 oflag=direct
fio 4K 随机  -> python3 os.pread 随机读脚本（见 README 回退说明）
glmark2      -> glxgears 60 秒 FPS，必须注明「仅证明 3D 管线通，不可用于性能对比」
vulkaninfo   -> ls /usr/share/vulkan/icd.d/ 与 ldconfig -p | grep libvulkan
vainfo       -> ls /dev/dri/ 是否有 renderD128
powerstat    -> cat /sys/class/power_supply/BAT*/power_now
pyperformance-> 跳过，用 scripts/03-python/numpy_bench.py 替代
EOF
