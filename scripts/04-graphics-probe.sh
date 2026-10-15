#!/usr/bin/env bash
# 04-graphics-probe.sh — 图形与游戏能力探针（只读，不下载任何游戏）
# 对应提示词「第 5 步 档 A」。这些探针在 Live 与已安装模式下结论一致，是 Live 的主场。

echo "===== 1. OpenGL / Mesa ====="
glxinfo -B 2>/dev/null | head -25 || echo "  glxinfo 不可用 → 回退：ls /dev/dri/"
ls /dev/dri/ 2>/dev/null || echo "  无 /dev/dri（显卡驱动可能没起来）"
echo "  判定：renderer 若含 llvmpipe / softpipe → 软渲染，后续所有图形数据无效"

echo
echo "===== 2. Vulkan（Proton 强依赖）====="
vulkaninfo --summary 2>/dev/null | head -30 || echo "  vulkaninfo 不可用"
echo "-- ICD --"; ls /usr/share/vulkan/icd.d/ 2>/dev/null || echo "  无 ICD 目录"
echo "-- libvulkan --"; ldconfig -p 2>/dev/null | grep -i libvulkan || echo "  未找到 libvulkan"

echo
echo "===== 3. VA-API 硬解（云游戏网页版依赖）====="
vainfo 2>/dev/null | head -20 || echo "  vainfo 不可用"
echo "-- VA 驱动 --"; ls /usr/lib/x86_64-linux-gnu/dri/ 2>/dev/null | grep -i va || echo "  未找到 VA 驱动"

echo
echo "===== 4. 32 位图形库（Proton 必需，新装系统常缺）====="
if command -v dpkg >/dev/null 2>&1; then
  echo "[foreign-arch]"; dpkg --print-foreign-architectures
  echo "[i386 libs]"; ls /usr/lib/i386-linux-gnu/ 2>/dev/null | head -40 || echo "  无 i386 库目录"
  for l in libvulkan.so.1 libGL.so.1 libasound.so.2 libfreetype.so.6 libX11.so.6; do
    ls /usr/lib/i386-linux-gnu/$l >/dev/null 2>&1 && echo "  OK:      $l" || echo "  MISSING: $l"
  done
else
  echo "  非 deb 系，请手动检查 32 位库（rpm 系：dnf list glibc.i686 libvulkan.i686 ...）"
fi

echo
echo "===== 5. Steam / Proton 可安装性预判（只看，不装）====="
if command -v apt-cache >/dev/null 2>&1; then apt-cache policy steam 2>/dev/null | head -6; fi
if command -v flatpak >/dev/null 2>&1; then flatpak search steam 2>/dev/null | head -5; else echo "  flatpak 未安装"; fi
for t in vulkan-tools gamemode libgamemodeauto0 steam; do
  command -v $t >/dev/null 2>&1 && echo "  OK:      $t" || echo "  MISSING: $t"
done

echo
echo "===== 6. 合成图形基准（可选）====="
if command -v glmark2 >/dev/null 2>&1; then
  echo "运行 glmark2（约 1-2 分钟）…"
  glmark2 2>/dev/null | tail -25
elif command -v vkmark >/dev/null 2>&1; then
  echo "运行 vkmark…"; vkmark 2>/dev/null | tail -20
elif command -v glxgears >/dev/null 2>&1; then
  echo "回退：glxgears 60 秒（仅证明 3D 管线通，不可用于性能对比）"
  timeout 65 glxgears 2>/dev/null | tail -3
else
  echo "  glmark2 / vkmark / glxgears 均不可用 → 本项未测量（原因：无图形基准工具）"
fi
