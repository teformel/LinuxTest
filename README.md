# LinuxTest

Linux 发行版选型的**实测数据采集**仓库。

用途：把「选哪个发行版」从凭感觉争论，变成可复现的数字对比。
同一份脚本在多个候选系统上各跑一遍，产出格式统一的报告，再做横向对比。

---

## 三步流程

```bash
# 1) 在待测系统上拉取本仓库
git clone https://github.com/teformel/LinuxTest.git ~/LinuxTest

# 2) 把 prompts/prompt-A.md 的正文（````text ... ```` 之间）交给 AI 执行
#    → 产出 ~/LinuxTest/reports/bench-<系统>-<live|installed>-<日期>.md

# 3) 两份报告都拿到后，把 prompts/prompt-B.md 连同两个报告路径交给 AI
#    → 产出 ~/LinuxTest/reports/compare-<日期>.md
```

---

## 目录结构

```
LinuxTest/
├── README.md                      本文件
├── prompts/
│   ├── prompt-A.md                单机采集提示词（含环境须知、Live 可信度表、外置 SSD 安装方案）
│   └── prompt-B.md                跨系统对比提示词（含运行环境一致性检查、显著性分级）
├── scripts/
│   ├── 00-env-detect.sh           运行环境判定：Live / 持久化 Live / 已安装 + 介质类型
│   ├── 01-tools-detect.sh         测试工具探测 + 联网判断 + 缺失回退对照表
│   ├── 02-compile/
│   │   └── gen_src.py             生成 150 个 .cpp 的标准编译负载（确定性，无随机数）
│   ├── 03-python/
│   │   └── numpy_bench.py         GEMM + im2col 卷积 + 逐元素归约（固定种子 42）
│   └── 04-graphics-probe.sh       OpenGL / Vulkan / VA-API / 32 位库 / Steam 可安装性探针
└── reports/
    ├── README.md                  报告命名规范 + 人工待办 + 判读标准
    └── （实测报告放这里）
```

---

## 为什么脚本要放仓库里

测试的核心要求是**两个系统跑完全相同的负载**。如果 AI 每次自己写一份基准脚本，
参数、尺寸、种子就会各不相同，测出来的差异里有相当一部分是"脚本不同"而不是"系统不同"。

仓库里的脚本是唯一权威版本：

- `gen_src.py` 不含任何随机数，150 个文件的内容只由索引决定
- `numpy_bench.py` 固定 `SEED = 42`，矩阵尺寸 / 迭代次数写死
- 编译负载的 `Makefile` **只允许 `-O2`**，禁止 `-march` / `-mtune` ——
  否则会把发行版自身的编译优化差异人为放大

**严禁修改这些参数。** 一旦修改，该次数据与历史数据即不可比，必须在报告中注明。

---

## 待评估的候选系统

| 系统 | 状态 | 报告文件 |
|---|---|---|
| Ubuntu 26.04 LTS | 待装（外置 512GB SSD） | — |
| PikaOS | 备选（开题后再试） | — |
| CachyOS | 备选 | — |

---

## 被测机器（华为 NbF-XX）

| 项目 | 实测值 |
|---|---|
| CPU | i7-1260P（4 性能核 + 8 能效核，支持 x86-64-v3，不支持 v4） |
| 内存 | 15.7 GB |
| 显卡 | Intel Iris Xe（无独显，开源驱动） |
| 无线 | Intel Wi-Fi 6 AX201（iwlwifi 原生支持） |
| 指纹 | Goodix Fingerprint SPI（Linux 基本无驱动） |
| 电源 | S0 现代待机，S3 不可用 |
| 内置盘 | 单 NVMe 477 GB，Windows 占约 370 GB |
| 外置盘 | 512 GB **固态**（USB），用于装 Linux + 游戏库 |
