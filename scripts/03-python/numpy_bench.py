#!/usr/bin/env python3
# numpy_bench.py — 纯 numpy 合成数值负载（对应提示词「第 3 步 档 A」+ 档 D 数据）
#
# 【重要】固定随机种子 SEED=42，所有待测系统必须完全相同。
#         严禁修改尺寸、迭代次数、dtype、种子，否则跨系统不可比。
#
# 用法：python3 scripts/03-python/numpy_bench.py [--quick]
#   --quick 用于内存不足(<8GB)的机器，缩小矩阵规模（会注明，且只能与同样 --quick 的结果对比）

import json
import platform
import subprocess
import sys
import sysconfig
import time

import numpy as np

SEED = 42
QUICK = "--quick" in sys.argv

GEMM_N = 2048 if QUICK else 4096
CONV_REPEAT = 5 if QUICK else 20
VEC_LEN = int(2e7) if QUICK else int(5e7)
VEC_REPEAT = 20
REPEAT = 3  # 每个计时项跑 3 次取中位数


def median(xs):
    return sorted(xs)[len(xs) // 2]


def bench_gemm():
    rng = np.random.default_rng(SEED)
    a = rng.standard_normal((GEMM_N, GEMM_N))
    b = rng.standard_normal((GEMM_N, GEMM_N))
    ts = []
    for _ in range(REPEAT):
        t = time.perf_counter()
        a @ b
        ts.append(time.perf_counter() - t)
    gflops = 2.0 * GEMM_N ** 3 / median(ts) / 1e9
    return {"n": GEMM_N, "times_sec": [round(x, 4) for x in ts],
            "median_sec": round(median(ts), 4), "gflops": round(gflops, 1)}


def bench_conv():
    """im2col 卷积，比 GEMM 更贴近 CNN 推理。输入 (1,64,224,224)，核 (64,64,3,3)。"""
    rng = np.random.default_rng(SEED + 1)
    x = rng.standard_normal((1, 64, 224, 224)).astype(np.float32)
    w = rng.standard_normal((64, 64, 3, 3)).astype(np.float32)
    H, W = 222, 222
    ts = []
    try:
        from numpy.lib.stride_tricks import sliding_window_view
        have_swv = True
    except ImportError:
        have_swv = False

    for _ in range(REPEAT):
        t = time.perf_counter()
        for _r in range(CONV_REPEAT):
            if have_swv:
                p = sliding_window_view(x, (3, 3), axis=(2, 3))      # (1,64,222,222,3,3)
                p = p.transpose(0, 1, 4, 5, 2, 3).reshape(1, 64 * 9, H * W)
            else:
                # 等价 as_strided 实现（numpy < 1.20）
                from numpy.lib.stride_tricks import as_strided
                sb = x.strides
                p = as_strided(
                    x,
                    shape=(1, 64, H, W, 3, 3),
                    strides=(sb[0], sb[1], sb[2], sb[3], sb[2], sb[3]),
                )
                p = p.transpose(0, 1, 4, 5, 2, 3).reshape(1, 64 * 9, H * W)
            w.reshape(64, -1) @ p                                      # (1,64,H*W)
        ts.append(time.perf_counter() - t)
    out = {"repeat_per_run": CONV_REPEAT, "runs": REPEAT,
           "times_sec": [round(x, 4) for x in ts], "median_sec": round(median(ts), 4),
           "per_conv_ms": round(median(ts) * 1000 / CONV_REPEAT, 2),
           "impl": "sliding_window_view" if have_swv else "as_strided(降级)"}
    return out


def bench_vec():
    """逐元素乘加 + 归约：考验内存带宽与向量化。"""
    rng = np.random.default_rng(SEED + 2)
    a = rng.standard_normal(VEC_LEN).astype(np.float32)
    ts = []
    for _ in range(REPEAT):
        t = time.perf_counter()
        for _r in range(VEC_REPEAT):
            a *= 1.0001
            a += 0.5
        s = float(a.sum())
        ts.append(time.perf_counter() - t)
    del a
    return {"length": VEC_LEN, "repeat_per_run": VEC_REPEAT,
            "times_sec": [round(x, 4) for x in ts],
            "median_sec": round(median(ts), 4),
            "reduction_check": round(s, 3)}


def blas_info():
    try:
        cfg = np.show_config("dicts")
        bi = cfg.get("Build Dependencies", {})
        return {
            "blas": bi.get("blas", {}).get("name", "unknown"),
            "lapack": bi.get("lapack", {}).get("name", "unknown"),
        }
    except Exception:
        try:
            out = subprocess.run(
                [sys.executable, "-c", "import numpy; numpy.show_config()"],
                capture_output=True, text=True, timeout=20).stdout
            return {"raw": out[:800]}
        except Exception as e:
            return {"error": str(e)}


def compile_flags():
    """提示词第 3 步 档 D：直接核验该系统是否真开了 v3 / O3。"""
    return {
        "CFLAGS": sysconfig.get_config_var("CFLAGS"),
        "OPT": sysconfig.get_config_var("OPT"),
        "MARCH": sysconfig.get_config_var("MARCH") or "none",
        "CC": sysconfig.get_config_var("CC"),
        "numpy_version": np.__version__,
    }


def main():
    result = {
        "bench": "numpy_bench",
        "seed": SEED,
        "quick_mode": QUICK,
        "env": {
            "python": sys.version.split()[0],
            "machine": platform.machine(),
            "processor": platform.processor(),
            "cpu_count": __import__("os").cpu_count(),
            "kernel": platform.platform(),
        },
        "compile_flags": compile_flags(),
        "blas": blas_info(),
        "gemm": bench_gemm(),
        "conv_im2col": bench_conv(),
        "elementwise": bench_vec(),
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    print("\n# 请把上面这段 JSON 原样附进报告第 3 步，并注明是否存在降级/回退。",
          file=sys.stderr)


if __name__ == "__main__":
    main()
