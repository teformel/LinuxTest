# Linux 发行版选型 · 实测数据采集提示词

> 用途：把这份提示词交给任意具备终端执行能力的 AI（WorkBuddy / Claude Code / Codex 等），
> 让它在**你要评估的 Linux 系统上**自动跑完基准测试并产出可对比的报告。
>
> 用法：每个候选系统各跑一次（Ubuntu 26.04 跑一次、PikaOS 跑一次），
> 得到两份 md 文件后，再用「提示词 B」让 AI 做横向对比。

---

## 使用须知（给你，不用发给 AI）

1. **跑之前**：插上电源、关掉浏览器和无关程序、同一台机器、尽量同一室温。
2. **跑几次**：每个系统跑完整一轮约 40–90 分钟（含合成编译负载）。
   **纯净系统可以直接跑**——编译、Python、游戏这三项已改成
   「合成基准必跑 + 真实项目补充」结构，没有项目、没有数据也能出完整报告。
   真实项目是你后来补进去的加分项，不是前提。
3. **可以在 Live 环境跑，但只有一部分数据可信**——详见下面「Live 环境能测什么、不能测什么」。
   结论先说：**Live 适合做「硬件兼容性与能力预判」，不适合做「性能定档」。**
   - 性能类数字（编译、GEMM、磁盘）在 Live 上会被 U 盘速度和 squashfs 解压严重污染，
     只能用来「排除明显异常」，不能用来判定 A 比 B 快 3%。
   - 兼容性类结论（WiFi、触控板、蓝牙、指纹、Vulkan/VA-API 探针、32 位库）
     **在 Live 上基本等同于正式安装**，这才是 Live 真正的价值。
   - 需要重启、需要休眠唤醒、需要跨天的项目在 Live 上要么失效要么严重失真。
4. **AI 做不了的那 20%** 会进「人工待办清单」，你必须自己过一遍。
   尤其是**合盖睡一晚**和**腾讯会议屏幕共享**——这两项是真正的否决项，
   而且**这两项只有在正式安装后才能测**（Live 上测出来的结论无效）。

---

## Live 环境能测什么、不能测什么（重要）

| 步骤 | Live（含持久化）上是否可信 | 说明 |
|---|---|---|
| 第 0 步 环境指纹 | ⚠️ 部分失真 | **Live ISO 的内核与包基线和正式安装后可能不同**（例如 v3 变体、XanMod 内核都是装完才开的），所以指纹只能代表「这个 ISO」，不代表「你将来装好的系统」 |
| 第 0.5 步 工具探测 | ✅ 可信 | — |
| 第 1 步 CPU / 调度器 | ✅ 基本可信 | 纯 CPU 与内存，不受 U 盘影响；但 Live 后台有额外服务，噪声略大 |
| 第 2 步 编译负载 | ⚠️ 偏低且失真 | 源码在 U 盘的 overlay 上，编译过程含大量小文件读写 → **测的有一半是 U 盘速度**。跨系统可比，但绝对值不可用 |
| 第 3 步 Python / 数值 | ✅ 基本可信（档 A / D） | 纯内存计算，装完 numpy 就不受 I/O 影响。**档 D（编译参数核验）在 Live 上最有价值**——它直接告诉你这个 ISO 到底有没有开 v3/O3 |
| 第 4 步 磁盘与启动 | ❌ **Live 上完全无效** | 测的是 U 盘不是硬盘；`systemd-analyze` 在 Live 上没有意义。**必须正式安装后重跑** |
| 第 5 步 图形与游戏 | ⚠️ 探针可信、跑分失真 | Vulkan/VA-API/32 位库探针 ✅ 与安装后一致；glmark2 跑分受 I/O 与着色器缓存影响 ⚠️ |
| 第 6 步 功耗 | ⚠️ 偏差较大 | Live 常驻服务 + U 盘持续耗电，空载功耗会**偏高**，仅作参考 |
| 第 7 步 硬件兼容 | ✅ **这是 Live 的主场** | WiFi、蓝牙、触控板、指纹、摄像头、声音、Fn 键——Live 上通过 = 装完基本也通过 |
| 休眠 / 合盖续航 | ❌ 无效 | Live 通常没有可用 swap，`systemctl suspend` 常直接失败或唤醒黑屏。**别拿 Live 的失败当结论** |
| 人工待办 6 项 | ❌ 全部要在正式安装后做 | — |

**三条 Live 使用铁律：**
1. **非持久化 Live 不要跑完整流程**——重启一次所有安装的测试工具和生成的报告全没了。
   必须用 **Ventoy 持久化**（persistence 分区建议 ≥32GB，ext4，标签 `persistence`），
   或干脆把系统**正式装到外置盘**上。
2. **报告文件名必须带运行模式**：`bench-<系统>-live-<日期>.md` 或 `bench-<系统>-installed-<日期>.md`。
   混在一起对比会得出错误结论。
3. **只用同模式的数据互相比较**：Live vs Live 可比，装 vs 装 可比，**Live vs 装 不可比**。

**还有一条更根本的限制，必须知道：**
**Live 永远测不到"优化后的系统"。** amd64v3 变体要 apt 切换后重装 483 个包才生效、
XanMod/BORE 内核要装完重启才生效、Nix 的 `gcc.arch` 要本地编译才生效——
**Live 里既不能换内核（内核在 squashfs 里），也不能安全切换包架构变体。**
所以 Live 测出来的是**"各发行版的出厂基线"**，而你要比较的恰恰是**"调优之后谁更快"**。
这两个问题答案可能不同，别拿 Live 的数据去否决调优方案。

**另需提前确认**：不是每个发行版的 ISO 都支持 Live 会话与持久化
（有些是 install-only 的安装镜像）。候选系统选好后先确认这一点，
否则它在 Live 阶段根本没法参与对比。

**如果你的 512GB 外置盘是固态（SSD）——已确认是固态，走这条路：**
跳过 Live，直接把系统**正式安装到外置 SSD** 上跑测试。理由：数据可信度远高于 Live、
装完就是能用的系统不浪费、而且拔掉就回 Windows（秋招面试零风险）。
安装时最危险的一个坑见下面「外置 SSD 安装方案」。

**另需提前确认**：不是每个发行版的 ISO 都支持 Live 会话与持久化
（有些是 install-only 的安装镜像）。候选系统选好后先确认这一点，
否则它在 Live 阶段根本没法参与对比。

---

## 外置 SSD 安装方案（推荐路径，已确认你的 512GB 是固态）

### 分区规划（在**外置 SSD** 上做，内置盘一个字节都不动）

| 分区 | 大小 | 文件系统 | 挂载点 | 用途 |
|---|---|---|---|---|
| ESP | 512 MB | FAT32 | /boot/efi | **必须建在外置盘上**（见下方警告） |
| 根分区 | 150 GB | ext4 | / | 系统 + `/nix`（Nix store 会长在 50–100GB，别给太小） |
| 游戏库 | 200 GB | ext4 | /mnt/games | Steam 库 / 绝区零。**必须 ext4，不要 NTFS/exFAT**（Proton prefix 依赖 symlink 与 Unix 权限） |
| 交换区 | 剩余约 160 GB | NTFS | /mnt/share | Windows 也能读的跨系统数据区 |

swap：用 swapfile 即可（你的机器是 S0 现代待机，不做休眠就不需要 swap 分区）。

### ⚠️ 唯一会让你后悔的坑：引导装错盘

Ubuntu 安装器**默认把 GRUB 装到内置 NVMe 的 ESP**，也就是 Windows 那个 EFI 分区。
一旦装错，Windows 启动项被改写，**拔掉外置盘就开不了机**——而你现在不能冒这个险。

正确做法：
1. 安装类型选**「其他选项 / 手动分区」**（不要选"与 Windows 共存"）。
2. 手动在外置 SSD 上新建上面那张表的分区，**在外置盘上建 ESP**。
3. **「安装引导加载器的设备」必须选外置 SSD 那个整盘（如 `/dev/sdb`），不是 `/dev/sdb1`，更不是 `/dev/nvme0n1`。**
4. 装完先别重启看效果，先在 Live 会话里 `efibootmgr -v` 确认新增的 ubuntu 条目指向外置盘。

5. 重启后验收两项，缺一不可：
   - 选 USB 外置盘启动 → 进 Ubuntu
   - **拔掉外置盘开机 → 必须正常进 Windows**（验证了才算安全）

### 如果第 3 步的安装器不让你选引导盘（26.04 新安装器有时没有这个选项）

装完再补救，两条命令：

```bash
# 在外置盘的 ESP 上生成一份"可移动"启动项（/EFI/BOOT/BOOTX64.EFI）
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable --recheck
# 事后确认 Windows 启动项还在
efibootmgr -v | grep -i windows
```

万一 Windows 启动被改坏了，用 WinRE 修复（**不要慌，数据不会丢**）：
```
bcdboot C:\Windows /s <ESP盘符>: /f UEFI
```

### 启动方式

开机按 **F12**（华为笔记本）进启动菜单 → 选外置 SSD → 进 Ubuntu。
不拔盘时默认还是 Windows。**Windows 和 Linux 物理隔离，互不干扰。**

### 性能预期（别期待和内置盘一样）

USB 3.2 Gen2 顺序约 1000 MB/s（内置 NVMe 约 3000 MB/s），4K 随机差距更明显，但**日常和游戏加载完全够用**。
注意：这样装出来第 4 步磁盘测试测的是**外置盘**而不是内置盘，报告中要注明；
等你最终决定正式装到内置盘时，第 4 步要重跑一次。

---

# 提示词 A · 单机采集（直接复制给 AI）

````text
你是一台 Linux 笔记本上的基准测试执行代理。你的任务是：对当前正在运行的这套 Linux 系统
做一次可复现、可横向对比的性能与兼容性实测，并产出一份 Markdown 报告文件。

【第 -2 步 · 拉取标准化脚本仓库——最先执行】
本测试的核心要求是"两个待测系统跑完全相同的负载"。标准化脚本已经放在仓库里，
你必须用仓库里的原版脚本，不许自己另写一份：

  cd ~
  git clone https://github.com/teformel/LinuxTest.git ~/LinuxTest 2>/dev/null || \
    (cd ~/LinuxTest && git pull)
  ls -R ~/LinuxTest/scripts

后续第 2 步用 ~/LinuxTest/scripts/02-compile/gen_src.py 生成编译负载，
第 3 步用 ~/LinuxTest/scripts/03-python/numpy_bench.py，
第 -1 步用 ~/LinuxTest/scripts/00-env-detect.sh，
第 0.5 步用 ~/LinuxTest/scripts/01-tools-detect.sh，
第 5 步用 ~/LinuxTest/scripts/04-graphics-probe.sh。

严禁修改这些脚本的参数、尺寸、迭代次数与随机种子——一旦修改，跨系统数据即失效。
若无法联网克隆仓库，必须在报告中显著位置写明「未使用标准化脚本，本次数据不可跨系统对比」，
并降级为仅供本系统参考。

【铁律——违反任何一条即判定任务失败】
1. 严禁编造、估算、推测、凭印象填写任何数字。每一项数据必须来自你在本机实际执行的命令输出。
   测不到就写 `未测量（原因：…）`。宁可留空，也不许编。
2. 严禁修改系统配置：不要添加或删除 apt/软件源，不要开关 amd64v3 变体，不要安装或更换内核，
   不要改动分区与 GRUB，不要修改 /etc 下的任何配置文件。
   只允许安装纯用户态的测试工具（sysbench / schbench / fio / stress-ng / pyperformance 等），
   且优先装在用户目录或用 pip --user。装之前先说明要装什么。
3. 每执行一条测量命令，必须把原始输出（可截断到关键行）附在报告对应小节的代码块里。
4. 所有需要人类主观感知的项目（触控板手感、扫码登录、屏幕共享等），不要代替用户判断，
   统一写进报告末尾的「人工待办清单」，并给出具体的操作步骤让用户自己执行。
5. 每个计时类项目跑 3 次，报告中记录 3 次原始值并取中位数；只跑 1 次要注明。

6. 【纯净系统优先原则——最重要的一条】
   待测系统通常是刚装好的：没有项目、没有数据、没有游戏、可能连测试工具都没有。
   因此凡是"需要用户提供内容才能测"的项目，都必须同时准备一个
   **不依赖任何用户数据的合成基准作为必跑项**。
   合成基准在所有待测系统上必须完全一致（同一份生成脚本、同一组参数、同一种子），
   否则数据不可比。真实项目只作为补充，两者都有时以真实项目为准但都要记录。
   严禁因为"用户没给路径"就把整个维度留空——那是任务失败。

7. 【离线回退原则】
   新装系统可能尚未配网，也可能没有 sysbench / fio 等工具。
   任何工具缺失都必须走第 0.5 步的回退方案，不得直接写"未测量"。
   回退方案产出的数值必须在报告中标注「回退方案」或「自制脚本」，
   且只能与同样用该回退方案测得的数值对比，不得与标准基准数值混比。

8. 【运行环境必须先判定——Live 模式下的数字不可当定论】
   执行任何测量之前，必须先判定当前系统是「非持久化 Live」「持久化 Live」还是「已正式安装」
   （判定方法见第 -1 步），并把结论写进报告头部。
   - 若为「非持久化 Live」：先提醒用户——重启会丢失所有测试工具与报告，
     询问是否改为持久化或正式安装后再继续。**用户坚持才继续，并在报告显著位置标注该风险。**
   - 若为 Live（含持久化），以下项目必须标注「Live 失真，仅作参考」，
     且**不得**作为跨系统性能优劣的依据：第 2 步编译耗时、第 4 步全部、第 6 步功耗、glmark2 跑分。
   - 若为 Live，以下项目**禁止测量**，直接写「未测量（原因：Live 环境该项无效）」：
     systemd-analyze 启动时间、systemctl suspend 恢复测试、合盖续航。
   - 「第 3 步档 D（编译参数核验）」和「第 7 步硬件兼容性」在任何模式下都必须完整执行，
     **Live 模式下这两项反而是最有价值的**，不要因为其他项失真就省略。

【第 -1 步 · 运行环境判定——先于第 0 步执行】
执行并记录原始输出：
- 是否 Live：
  - cat /proc/cmdline | tr ' ' '\n' | grep -E 'boot=casper|boot=live|iso-scan|toram'
  - ls -d /run/live /lib/live /rofs /cdrom 2>/dev/null
  - mount | grep -E 'overlay|squashfs|aufs' | head
  （任一命中即判为 Live）
- 是否持久化（Live 前提下继续判定）：
  - mount | grep -E 'casper-rw|persistence|overlay.*rw'
  - df -h / 与 df -h /home （看根或 home 是否落在某个镜像文件/分区上，且容量 > ISO 体积）
  - 若无任何可写持久层 → 判为「非持久化 Live」，按铁律 8 先提醒用户
- 介质类型（决定测试值不值得信）：
  - lsblk -d -o NAME,SIZE,ROTA,TRAN,MODEL （ROTA=1 是机械盘，TRAN=usb 说明走 USB）
  - findmnt -no SOURCE / （确认根文件系统所在物理盘）
  - 若系统盘 TRAN=usb，必须在报告中写明：
    「系统运行在 USB 外置盘上，第 4 步的磁盘数值代表该外置盘，不代表内置 NVMe」
  - 若为 Live 且 TRAN=usb，在报告中写明
    「系统运行在 USB 介质上，所有涉及磁盘 I/O 的数值均不代表内置盘性能」
- 持久化层可用空间：df -h（若 < 20GB，提醒用户编译类测试可能写满）

报告头部必须有一行「运行环境：<非持久化 Live | 持久化 Live | 已安装>｜介质：<型号/接口>｜持久化空间：<x GB>」。

【第 0 步 · 环境指纹——必须最先执行，缺一项就写"未测量"】
执行并记录原始输出：
- uname -a
- cat /etc/os-release
- lscpu （重点记录：型号名、性能核/能效核数量、Flags 中是否有 avx2 / fma / bmi2 / avx512f）
- /lib64/ld-linux-x86-64.so.2 --help | grep -A6 'Subdirectories of glibc-hwcaps'
  （判断 x86-64-v3 是否显示 supported）
- echo $XDG_SESSION_TYPE （wayland 还是 x11）
- glxinfo -B 2>/dev/null | head -25 （记录 Mesa 版本、OpenGL renderer、Vulkan 设备名）
- grep CONFIG_SCHED_CLASS_EXT /boot/config-$(uname -r)
  （有输出 = 该系统内核支持 scx 调度器；无输出 = 不支持，写清楚）
- upower -d | grep -iA6 battery （记录是否插电、电池百分比）
- grep -r amd64v3 /etc/apt/apt.conf.d/ 2>/dev/null （判断是否已启用 v3 变体）
- lsblk -f 与 df -h （记录磁盘与分区布局）
- 当前 CPU 频率策略：cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

【第 0.5 步 · 测试工具准备与离线回退——在第 0 步之后立即执行】

新装系统通常没有任何基准工具，且可能尚未配网。严格按以下顺序执行：

1) 先只探测、不安装任何东西，把结果写进报告：
   for t in sysbench schbench fio stress-ng glmark2 vkmark vulkaninfo vainfo glxinfo powerstat python3 pip3; do
     command -v $t >/dev/null 2>&1 && echo "OK: $t" || echo "MISSING: $t"
   done

2) 判断能否联网（记录命令与结论）：
   ping -c 3 -W 3 223.5.5.5 与 curl -sS -m 8 -o /dev/null -w '%{http_code}' https://pypi.org
   （任一项通即可认为联网；都不通则进入离线回退模式）

3) 工具获取优先级，一次只装一类，装完立刻验证可用性：
   a) 发行版官方仓库（apt / dnf / pacman / zypper，按系统判断）
   b) Flatpak（flathub）
   c) pip --user
   d) 源码编译（仅限 sysbench / schbench 这类小工具）

4) 若某工具最终装不上，必须使用回退方案，不许直接写"未测量"：

   | 缺失工具 | 回退方案（报告中标注「回退方案」） |
   |---|---|
   | sysbench | python3 纯计算循环：固定 2e8 次整数乘加 + 2e8 次浮点乘加，记录耗时。注明仅与同脚本结果对比 |
   | schbench | stress-ng --cpu $(nproc) --cpu-method matrixprod --metrics-brief --timeout 60s；再不行用第 2 步档 B 的替代法 |
   | fio（顺序） | dd if=/dev/zero of=./benchfile bs=1M count=2000 oflag=direct 测写；dd if=./benchfile of=/dev/null bs=1M 测读 |
   | fio（4K 随机） | python3 脚本：建 512MB 文件，做 20000 次 os.pread(fd, 4096, random_offset)，记录总耗时与 IOPS |
   | glmark2 / vkmark | glxgears 跑 60 秒记录 FPS，并明确注明「只能证明 3D 管线通，不可用于性能对比」 |
   | vulkaninfo | ls /usr/share/vulkan/icd.d/ 与 ldconfig -p | grep libvulkan，据此判断 Vulkan 是否可用 |
   | vainfo | ls /dev/dri/ 是否有 renderD128，以及 mesa VA 驱动包是否安装 |
   | powerstat | cat /sys/class/power_supply/BAT*/power_now，或 upower -d 的 energy-rate |
   | pyperformance | 跳过，用第 3 步档 A 的 numpy 合成负载替代 |

【第 1 步 · CPU 与调度器】
- sysbench cpu --threads=16 run （若 nproc 不等于 16，改用实际核心数；记录 events per second）
- sysbench cpu --threads=4 run （模拟轻负载下的单核簇表现）
- sysbench memory --threads=1 run （记录 MiB/sec）
- 若 schbench 可安装：schbench -m 2 -t 8 -r 30
  （记录 wakeup latency 的 50% / 99% 分位。这是衡量 P/E 混合架构前台卡顿最对症的指标）
- 若 schbench 装不上，用 stress-ng 替代：stress-ng --cpu 16 --cpu-method matrixprod --metrics-brief --timeout 60s

【第 2 步 · 编译负载（模拟"边编译边用电脑"）】

本步分三档。档 A、档 B 为必跑且不依赖任何用户数据；档 C 为补充。

■ 档 A（必跑，合成编译负载）
**必须使用仓库脚本生成，不得自写**：

  mkdir -p ~/bench-src && cd ~/bench-src
  python3 ~/LinuxTest/scripts/02-compile/gen_src.py .
  cat Makefile            # 确认为 -O2 且无 -march/-mtune
  ls src*.cpp | wc -l     # 必须为 150

脚本会打印文件数、总字节数、循环次数、排序元素数，把这四行原样附进报告。
生成后执行三次并记录，每次前先 make clean：
    time make -j$(nproc) >/dev/null 2>&1
（若因 U 盘空间不足无法生成，改用 --quick 之外的方案：减少到 50 个文件，
  但必须在报告中注明，且只能与同样改为 50 个文件的结果对比。）

■ 档 B（关键对照测试，必跑）
在后台跑 `make -j$(nproc)` 的同时，前台执行 `schbench -m 1 -t 2 -r 20`，
记录此时的 wakeup latency，与第 1 步空载时的数值做差值。
这个差值直接反映"边编译边开 IDE 会不会卡"，是本测试最重要的单项之一。
若 schbench 不可用，退化为：后台满负荷编译时，前台连续执行
  `time python3 -c "pass"` 共 100 次，记录总耗时，与空载时同样测量的结果做对比。

■ 档 C（补充，仅在用户提供了项目路径或构建命令时跑）
  time make -j$(nproc) 于用户指定项目。
  未提供则写"未测量（原因：纯净系统无项目数据）"，并注明档 A 已覆盖该维度。

【第 3 步 · Python / 数值负载（面向机器学习毕设）】

本步分四档。档 A、档 D 为必跑且不依赖任何用户数据；档 B、档 C 为补充。

■ 档 A（必跑，纯 numpy 合成负载）
**必须使用仓库脚本，不得自写**：

  python3 ~/LinuxTest/scripts/03-python/numpy_bench.py 2>/dev/null | tee ~/numpy_bench.json

脚本输出一段 JSON，包含：BLAS 后端、GEMM 4096 三次耗时与中位数与 GFLOPS、
im2col 卷积（输入 1x64x224x224、核 64x64x3x3，每次跑 20 次前向）、
逐元素乘加 + 归约（长度 5e7 float32，20 次）、以及 sysconfig 的 CFLAGS/OPT/MARCH。
**把整段 JSON 原样附进报告。**
若内存 < 8GB 或报 MemoryError，改用 `python3 ... --quick`（矩阵 2048、长度 2e7），
并在报告中注明「quick 模式」，且只能与同样 quick 模式的结果对比。

■ 档 B（可选，需联网且用户同意，下载约 200MB）
   pip install --user torch（CPU 版）
   跑 ResNet-18 forward 100 次计时：固定输入 1x3x224x224、eval 模式、torch.no_grad()、
   torch.set_num_threads(0)（用满所有核），记录总耗时与单次均值。
   用户不同意或离线则写"未测量（原因：…）"。

■ 档 C（补充，仅在用户提供了 YOLO 评估脚本时跑）
   执行三次并记录耗时。**必须先向用户确认命令与参数，不得擅自猜测路径或数据集位置。**
   未提供则写"未测量（原因：纯净系统无项目数据）"，并注明档 A 已覆盖该维度。

■ 档 D（必跑，编译优化可复现性核验——这是判断"发行版到底有没有优化"的关键）
   记录该系统 Python 与 numpy 实际使用的编译参数：
   - python3 -c "import sysconfig; print(sysconfig.get_config_var('CFLAGS')); print(sysconfig.get_config_var('OPT'))"
   - python3 -c "import sysconfig; print(sysconfig.get_config_var('MARCH') or 'none')"
   - 检查是否为 amd64v3 构建（Debian/Ubuntu 系）：
     dpkg-query -W -f='${Package} ${Architecture}\n' python3 2>/dev/null | head
   - 记录 gcc 默认优化级别：gcc -Q --help=optimizers 2>/dev/null | grep -E '^\s+-O[0-3s]'
   结论要写清楚：该系统是否真的对 Python / numpy 启用了 x86-64-v3 与 O3。
   这项比任何跑分都更能解释档 A 的数值差异。

【第 4 步 · 磁盘与启动】

■ 可比性前提（先读）
若所有候选系统都装在**同一块外置 SSD** 上（本项目的做法），第 4 步是**有效的横向对比**——
硬件、介质、接口全部相同，测出的差异就是发行版差异（内核 USB 存储驱动、I/O 调度器、
默认挂载参数）。但**必须锁死以下变量**，否则测的是"接线方式"而不是"系统"：

1. **同一个 USB 口 + 同一根线**。USB 3.2 Gen2（10Gbps）与 Gen1（5Gbps）差一倍，
   插到 USB 2.0 口更是差一个数量级。报告中要写明接口（`lsusb -t` 看 5000M/10000M）。
2. **必须记录 UASP 是否启用**，这是最关键的一项：
     lsusb -t | grep -E 'Driver=(uas|usb-storage)'
   - `uas` = USB Attached SCSI，正常高速路径
   - `usb-storage` = 回退到 BOT 协议，**速度可能差 2–3 倍**
   两个系统若一个 uas 一个 usb-storage，这是真实差异但**必须写明原因**，
   不要笼统说"A 的磁盘比 B 快一倍"。
3. **必须记录 I/O 调度器**：
     cat /sys/block/<设备>/queue/scheduler
   （多队列下常见 none / mq-deadline / bfq / kyber）
   不同发行版默认值不同，这是真实差异，记录下来才有解释力。
4. fio 一律加 `direct=1` 绕过 page cache；每个测试跑 3 次取中位数；
   两次测试之间给 SSD 30 秒空闲（避免 pSLC 缓存未回收导致后跑的系统吃亏）。
5. 测试文件大小建议 ≥ 4GB 或 `--runtime=60 --time_based`，避免整段跑在 SLC 缓存里。
6. 报告中必须写明：
   「本组数据代表<外置盘型号>经 USB 通路的性能，**跨系统排名可外推，绝对值不可外推**；
     最终若改装内置 NVMe，需重测。」

■ 执行条件
若第 -1 步判定为 Live（含持久化），**跳过本步全部内容**，
在报告对应小节写「未测量（原因：Live 环境下测量的是 USB 启动介质而非内置盘，数据无意义；
需正式安装后重测）」，跳过后继续执行第 5 步。
仅当判定为「已正式安装」时执行以下全部内容：
- systemd-analyze （记录总启动时间、kernel / userspace 分项）
- systemd-analyze blame | head -15
- 用 fio 测 4K 随机读（这是决定"系统/游戏能不能放外置盘"的关键）：
  fio --name=randread --ioengine=libaio --rw=randread --bs=4k --numjobs=4 \
      --size=1G --runtime=60 --time_based --direct=1 --group_reporting \
      --directory=<用户指定的测试目录>
  测试目录必须覆盖：根分区（系统所在盘）以及用户插入的任意外置盘挂载点。
  两块盘都要测，报告中分开列。
- 顺序读带宽：fio --name=seqread --rw=read --bs=1M --size=2G --runtime=60 \
      --time_based --direct=1 --group_reporting --directory=<同上>
- 补充记录（各一行命令即可）：
  lsblk -d -o NAME,SIZE,MODEL,TRAN / findmnt -no SOURCE,FSTYPE,OPTIONS /
  lsusb -t | grep -E 'Driver=(uas|usb-storage)'
  cat /sys/block/<根设备>/queue/scheduler
  sudo fstrim -av 2>&1 | head -3   （记录 TRIM/discard 是否被外置盘支持；不支持会报错，属正常）

【第 5 步 · 图形与游戏能力】

本步分三档。档 A、档 C 为必跑且不依赖任何游戏数据；档 B 为补充。

■ 档 A（必跑，能力探针 + 合成图形基准——用于预判"将来能不能玩"）
1) Vulkan：vulkaninfo --summary 2>/dev/null | head -30
   记录 deviceName、driverName、apiVersion。Proton 强依赖它。
   装不上则用第 0.5 步回退法判断，并注明。
2) VA-API 硬解：vainfo 2>/dev/null | head -20
   云游戏网页版依赖它。不可用必须写明。
3) OpenGL：glxinfo -B（记录 renderer / core version / 是否为 llvmpipe 软渲染）
   若为 llvmpipe 软渲染，必须高亮——说明显卡驱动没起来，后续所有图形数据无效。
4) 合成图形基准（给可跨系统对比的分数，必跑）：
   - glmark2：装好后跑标准流程，记录总分与各子项分（尤其 shading / terrain / conditionals）
   - vkmark：若有，记录总分
   - 都装不上则用 glxgears 跑 60 秒记录 FPS，且必须注明
     「仅证明 3D 管线通，不可用于性能对比」
5) 32 位图形库检查（Proton 必需，新装系统常缺）：
   - dpkg --print-foreign-architectures（Debian/Ubuntu 系）或等效命令
   - ls /usr/lib/i386-linux-gnu/ 2>/dev/null | head -30
   - 检查是否存在 32 位的 libvulkan、libGL、libasound2、libfreetype
   缺失要逐项写明——这决定将来装 Steam 时会不会踩坑。
6) Steam 与 Proton 的"可安装性预判"（不下载任何游戏）：
   - 官方仓库 / Flatpak 里是否有 steam（apt-cache policy steam、flatpak search steam）
   - Proton 依赖是否齐全：vulkan、32 位库、gamemode、libgamemodeauto
   - 给出结论：「能否安装」「预计还需手动配置什么」
   
■ 档 B（可选，仅当用户已安装 Steam、已安装《绝区零》且明确同意时）
   Steam appid 4162040。启用 MangoHUD，运行 30 分钟，记录：
   平均帧率、1% low、显存占用、着色器编译期是否卡顿、反作弊是否正常通过登录。
   启动参数：MANGOHUD=1 MANGOHUD_CONFIG=fps,frametimes,gpu,temp %command%
   同时记录当前 Proton 版本以及是否为 Proton-GE。
   **未经用户明确同意，不得下载或安装任何游戏客户端（体积数十 GB）。**
   若未满足条件，写"未测量（原因：纯净系统未安装游戏）"，并注明档 A 已覆盖能力预判。

■ 档 C（必跑，外部兼容性核验——不需要装游戏也能做）
   查询《绝区零》（Steam appid 4162040）在当前 Proton 版本下的社区兼容状态，
   记录：评级、近期报告数量、已知问题、典型帧率。
   **必须给出来源链接与查询日期；不得凭印象填写，查不到就写"未查询到"。**

【第 6 步 · 功耗】
- 若可安装 powerstat：powerstat -d 0 60 5 （记录空闲功耗，单位瓦）
- 记录 upower 的 energy-rate
- 合盖续航必须由用户人工完成，写进人工待办清单

【第 7 步 · 硬件兼容性逐项核验】
对以下每一项，用命令或实际检查给出"通过 / 不通过 / 未测量"，并附证据：
- Wi-Fi：nmcli device status + ip link，实际连一次网并 ping -c 10 一个外网地址记录丢包与延迟
- 蓝牙：bluetoothctl list / 能否发现设备
- 触控板：xinput list 或 libinput list-devices，确认设备被识别、多指手势是否可用
- 指纹（Goodix Fingerprint SPI）：fprintd-list 或 lsusb，明确给出是否可用
- 摄像头：能否被 Cheese / Firefox 调用
- 声音：扬声器与麦克风
- 亮度/音量 Fn 功能键
- 休眠与合盖：systemctl suspend 能否恢复（测一次，失败要写明现象）
  **Live 环境禁止执行本项**，直接写「未测量（原因：Live 无可用 swap / 无持久会话，suspend 结果不代表真实系统）」。
  不要因为 Live 上 suspend 失败就判定该系统不支持休眠。
- 输入法：fcitx5 / ibus 中文输入是否可用
  （Live 环境常未预装输入法，只需记录「ISO 是否自带 / 官方仓库是否有包」，
   不要判定为「不通过」）

【输出要求】
1. 【报告命名】按运行环境分两种，不可混用：
   - Live / 持久化 Live：/home/<用户名>/bench-<系统标识>-live-<YYYYMMDD>.md
     例：/home/maorila/bench-ubuntu2604-live-20261020.md
   - 已正式安装：/home/<用户名>/bench-<系统标识>-installed-<YYYYMMDD>.md
     例：/home/maorila/bench-ubuntu2604-installed-20261020.md
   若报告保存在 Live 的非持久层，必须在结论里警告：重启后文件会丢失，
   并要求用户手动复制到外置盘或 U 盘的持久化区。
   报告生成后，再复制一份到 ~/LinuxTest/reports/ 目录（便于 git 上传与跨机器比对）。
2. 报告结构严格如下：
   # 环境与性能实测报告 — <系统名> <版本>
   ## -1. 运行环境判定（Live / 持久化 Live / 已安装；介质类型；持久化空间）
   ## 0. 环境指纹
   ## 1. CPU 与调度器
   ## 2. 编译负载
   ## 3. Python / 数值负载
   ## 4. 磁盘与启动
   ## 5. 图形与游戏
   ## 6. 功耗
   ## 7. 硬件兼容性逐项核验
   ## 8. 人工待办清单（AI 无法代劳，必须用户亲自完成）
   ## 9. 本次测量的局限与未测项
3. 每个数字后面用一句话说明它意味着什么（好还是差），但不要给发行版选择的最终建议——
   那是提示词 B 的事。
4. 最后在终端打印一句话总结：已完成 N 项，未测量 M 项，人工待办 K 项。
````

