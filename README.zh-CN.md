# MIPS32 五级流水线 CPU

[English](README.md) | [中文](README.zh-CN.md)

这是一个源于课程设计的 MIPS32 五级流水线 CPU，保留 SRAM 类接口基线、AXI 功能版和 AXI 预取/Cache 版三套 Verilog RTL。

## 项目概述

设计采用取指、译码、执行、访存、回写五级流水线。AXI 版本增加地址转换、总线桥、CP0 异常处理和指令/数据 Cache。本仓库提供 RTL、可移植源文件检查和 HDL 编译脚本，不分发预构建 FPGA 镜像。

## 特性

- 具备前递与冒险处理的 MIPS32 流水线。
- ALU、分支比较、HI/LO、乘除法和 CLZ。
- AXI 版本支持 CP0 异常与中断处理。
- 提供 SRAM 类、AXI 功能和 AXI 预取/Cache 三种变体。
- 自动检查模块依赖关系，并在 CI 中编译 HDL。

## 截图

本项目以 RTL 和命令行工具为主，没有图形界面，因此不提供截图。请参阅[架构说明](docs/architecture.md)和[验证说明](docs/verification.md)。

## 安装

```bash
git clone https://github.com/XXXXXQ-0206/mips32-five-stage-cpu.git
cd mips32-five-stage-cpu
```

运行源文件检查需要 Python 3.10 及以上版本；编译 HDL 需要 Icarus Verilog 和 Verilator，CI 会在 Ubuntu 中安装它们。

## 使用

```bash
python tools/rtl_inventory.py rtl/axi-prefetch
python -m unittest discover -s tests -v
bash scripts/test-hdl.sh
```

Windows 下可运行 `scripts/test.ps1`。只有 `PATH` 中存在 Icarus Verilog 时，脚本才会编译 HDL。

## 构建说明

`mycpu_top` 是综合顶层。面向具体板卡的综合还需要兼容时钟、约束、存储系统集成和受许可的工具链材料。仓库有意排除 Vivado 生成结果、比特流和板卡文件。

```bash
iverilog -g2012 -s mycpu_top -tnull rtl/axi-prefetch/*.v
verilator --lint-only --Wno-fatal --top-module mycpu_top rtl/axi-prefetch/*.v
```

## 项目结构

```text
rtl/sram/             SRAM 类接口基线
rtl/axi-functional/   AXI 功能版
rtl/axi-prefetch/     AXI 预取/Cache 版
tests/                Python 源文件检查测试
tools/                RTL 清单工具
scripts/              本地验证入口
docs/                 架构、变体和来源说明
```

## 路线图

- 增加周期级自检的体系结构测试。
- 在获得可再分发板卡材料后，补充开放 FPGA 参考集成。
- 以可复现实验约束和工具版本记录性能结果。

## 参与贡献

请阅读[贡献指南](CONTRIBUTING.md)，遵守[行为准则](CODE_OF_CONDUCT.md)，并向 `dev` 分支提交变更。

## 许可证

仓库中的本人原创文件采用 [MIT License](LICENSE)。加入课程提供或厂商文件前，请先阅读[课程框架说明](docs/course-framework-notice.md)。

## 常见问题

**这是龙芯杯正式参赛作品吗？** 不是。这是遵循兼容 MIPS32 实验规范完成的课程项目，不作为竞赛参赛作品发布。

**可以立即综合到 FPGA 吗？** 可移植 RTL 能在 CI 中编译。FPGA 综合还需兼容的受许可工具链和目标板卡集成材料。

**为什么没有 Vivado 生成文件？** 它们依赖机器和工具版本，属于生成结果，不是设计的权威源文件。

## 致谢

本项目在高校硬件设计课程环境中完成。MIPS、Xilinx、Vivado、AXI 及相关标识归各自权利人所有，提及它们不代表获得认可或背书。

## 免责声明

本软件按**现状（AS IS）**提供，不附带任何明示或暗示担保。对于因使用本软件而产生的任何直接、间接、附带、特殊或后果性损失，作者概不承担责任。使用、修改、综合或部署本软件所产生的一切风险均由使用者自行承担。除非自行完成验证并承担全部责任，否则不得将其用于违法用途、安全关键、生命关键、生产网络或其他失效后可能造成伤害的场景。
