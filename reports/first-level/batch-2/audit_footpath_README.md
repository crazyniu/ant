# 第一关足底 / 路线几何复验

> 历史版本边界：本文及下方结果属于 `0491e05`。大体积输入/输出已从当前树精简，但 [完整历史证据](https://github.com/crazyniu/ant/tree/0491e05510829dee88b930bd5f86698f86e43082/reports/first-level/batch-2) 仍可检索。完整复跑请在独立 `0491e05` worktree 中按下方命令解压并运行，不把旧报告当最新 UI/动作验收。

## 已完成结论

当前集成生产版，经 Godot 4.6.3 导出真实 `CarrierRoute` 后复算，369 条可达路线覆盖 240 个取球目标，测得全部脚端步相的保守边界均留在声明可行走多边形内。保持球直径 33.5、蚁物理宽 62、foot_anchor、16 × 15 球矩阵、巢与 gateway，不靠缩图通过。

以下表格为 120 Hz 位置 / 朝向采样结果，不直接称为连续净空：

| 指标 | 原路线 / 当前脚端 metadata 对照 | 当前生产路线 |
| --- | ---: | ---: |
| 平面脚端最小余量，含 0.5 px 安全垫 | -7.745941 px | +3.032726 px |
| 抬脚屏幕投影最小余量，含同一安全垫 | -8.756363 px | +1.654878 px |
| 脚端到龙路 baked 中心线最小距离 | 71.267352 px | 80.979971 px |

当前生产结果另外扣除 120 Hz 完整一帧移动的保守余量 0.753371 px 后，平面脚端仍 +2.279355 px，抬脚投影仍 +0.901507 px。这是几何检查，不是 GL、自然步态或用户视觉验收。

120 Hz 共测 970,656 个时刻 / 姿态样本与 38,465,372 个包络顶点。所有路线起点、取球终点、逻辑路径、distance_cells 均与归档原路线一致。生产采样函数与 Python 端口 101 点 / 路线最大位置差为 0.00007618 px；生产路线与最初 Python 修复候选最大位置差为 0.000136 px。

## 实际接入的最小路线调整

仅第一关外环中心点与外环屏幕圆角：

- 顶侧 `(x,-1)`，x = 0…15，保持 x 坐标，统一 y = 322。
- 左上 `(-1,-1) = (196,326)`。
- 右上 `(16,-1) = (730,334)`。
- 右侧首点 `(16,0) = (750,360)`。
- 右下 `(16,15) = (739,857)`。
- 外环二次曲线圆角半径 12 px，最大不超过任一邻边屏幕长度的 45%；不圆化巢入口与巢相邻逻辑转角。内圈 0.22 格圆角不变。
- `BoardPlane` 显式外环 override 仅匹配整数格中心，不把分数坐标投影吸到整数点。

完整浮点坐标在 `audit_footpath_candidate.json` 的 exterior_centers；已集成到生产 layout。当前真实路线应以 `audit_footpath_production_routes.json` 为准。

## 代价和规则边界

- 真实路线屏幕长度相对原版变化：[-41.4185446501, 0] px。
- 同一规则时长内，单路线屏幕平均移动速率最大降低 3.534107%。不是修改规则速度掩盖穿出。
- 最大路线平均 outbound 速率前后均为 84.997867 px/s。
- 12 段弧长近似的区间导数另行精确上界：倍率 1.043048，最大局部屏幕速率上界 88.004574 px/s。因此一帧余量不能只用平均速率除以 120。
- Rules、资源、奖励、预算、动作延时不改；第一关既有输入序列纯规则仍在 110.425 秒胜利。没有跑别的关卡。

## 真实脚端、shader 和背球分层

脚端依据每向源图不透明像素（alpha ≥ 128）圈选，排除软阴影与低透明边。原四腿 metadata 存在空白点、腹部点与漏腿，已按实测调整。

| 视角 | 可见腿数 | 当前生产交替组 |
| --- | ---: | --- |
| E | 4 | 0,1,1,0 |
| SE | 4 | 0,1,1,0 |
| S | 6 | 0,1,0,1,0,1 |
| SW | 4 | 0,1,1,0 |
| W | 4 | 0,1,0,0 |
| NW | 3 | 0,1,0 |
| N | 4 | 0,1,0,1 |
| NE | 3 | 0,1,0 |

- `audit_footpath_corrected_endpoint_overlay.png`：旧点红、新点绿及腿连接示意。`audit_footpath_measured_endpoints.json` 是标注提案；生产 manifest 的 groups 才是当前运行权威数据。
- `audit_footpath_shader_bounds.json`：当前所有方向的源图足端范围、720 步相数值测量、解析最大步幅和抬脚位移上界，以及 pickup 姿态作用上界。
- Shader 对两步组按权重有界混合，不能叠成双倍步幅。审计包络为真实朝向脚端 hull 加 ±12 源像素（载球 ±9）的轴向上界，投影另加最多 15 源像素向上 lift（载球 11）。不使用所有八向同时展开的大圆包络。
- 数值测量实现实际 shader 两次逆向采样公式，使用固定点后 Newton 收敛精修，最大反投影残差 < 0.000001 源像素；最终通路余量来自解析位移上界，不依赖这一数值求解器。
- 0.5 px 安全垫覆盖像素边缘、步行姿态偏移与取球 crouch 在脚端的残留权重。不是把整个 body 的 0.95 px crouch 错当脚底位移。
- 身体、触角、背球是高处屏幕投影，不当作地面足底。已接入八向背球接触点，圆球尺寸不变；这里不以背球投影证明地面穿出。

## 巢 / 棋盘 / 卸货的真实连通

巢 `(345,1095)` → gateway `(467,940)` → 入口格 `(8,15)` 对应 `(484.747925,863.200012)`，前两段真实总长 276.077675 px；规则 approach distance 仍 8.25 格。

CarrierRoute 的返回终点为巢 / 卸货点，不是炮的 hopper `(452,1097)`。两者相隔 107.018690 px。此份几何检查不能证明这段球的视觉传递已经在场景中完成，必须由场景渲染 / 卸货链路另验。

## 可复跑命令

从仓库根目录执行，均仅第一关、无 GL，不改生产文件：

```sh
HOME=/tmp/ant-footpath-audit-home \
XDG_CACHE_HOME=/tmp/ant-footpath-audit-home/.cache \
XDG_DATA_HOME=/tmp/ant-footpath-audit-home/.local/share \
godot --headless --path . --script tests/audit_footpath_export.gd

OPENBLAS_NUM_THREADS=1 python tests/audit_footpath_integrated.py
OPENBLAS_NUM_THREADS=1 python tests/audit_footpath_baseline_bound.py
OPENBLAS_NUM_THREADS=1 python tests/audit_footpath_shader_bounds.py
HOME=/tmp/ant-footpath-audit-home MPLCONFIGDIR=/tmp/ant-footpath-mpl \
python tests/audit_footpath_plot.py
```

`audit_footpath_integrated.py` 检查真实导出源文件 hash、240 终点和所有逻辑路径不变。当前结果 / hash 在 `audit_footpath_integrated.json`。`--reuse-measurement` 仅在所有生产输入 hash 不变时可重算摘要，不重新计算足底扫掠。

### 发布压缩证据与解压

GitHub 仅发布以下 gzip 归档，不发布两份约 9 MB 的 raw routes JSON；raw 仍保留本地。两份 gzip 已验证解压字节与原文件完全一致，mtime 固定为 0 便于重复打包校验。

| 归档 | 压缩字节数 | SHA-256 |
| --- | ---: | --- |
| `audit_footpath_baseline_routes.json.gz` | 1,433,399 | `bfa8c3743113ba19d6311be3c5cfed29eb4fff3dd458ea7baf89a20111657bca` |
| `audit_footpath_production_routes.json.gz` | 1,602,011 | `046a4b683d4081f9b3f65bb1359a8dde0d2b8b4e948d55889829468f76d5058f` |

首次获取证据时，从仓库根目录解压。`gzip -dk` 默认拒绝覆盖已有 raw，特别是不得覆盖旧 baseline：

```sh
gzip -dk reports/first-level/batch-2/audit_footpath_baseline_routes.json.gz
gzip -dk reports/first-level/batch-2/audit_footpath_production_routes.json.gz
```

之后可直接执行上面的 Python 复验命令。如需验证当前源码，重新执行上面的 Godot production export 命令，它只写 `audit_footpath_production_routes.json`，然后执行 `audit_footpath_integrated.py`；不得用这次导出来替换 baseline。生产源码变化后的新结果需重新审阅，不能继续沿用本报告当前结论。

`audit_footpath_baseline_routes.json` 是修改前真实 Godot 生产导出，不能覆盖。`audit_footpath_baseline_bound.json` 在这份归档路线使用当前脚端 metadata，做同口径路线 A/B。

早期 `audit_footpath_geometry.json`、`audit_footpath_baseline_geometry.json` 是旧 metadata / 单参考相位证据；它们不是当前生产通过证据。最初编译失败或零路线导出不计通过，已重跑得到上述 369 条有效路线。

## 明确限制

1. 240 资源目标全部覆盖，来自既定输入序列及 8 层依次清空的几何 fixture；不等于穷举 2^240 种任意清空组合，也不把 fixture 称作真实游玩过程。
2. 可行走多边形是 layout 声明边界，不是对原背景纹理的语义分割。原先约 11.9 / 17.9 px 的八向大包络不能直接叫“已经穿到外圈龙路”。
3. 龙距只到 baked 中心线，不是完整龙 alpha 或时变碰撞体；不能把正数等同零碰撞。
4. 球 / 足 / 身体在 2D 屏幕重叠不自动说明实体碰撞，也不自动说明视觉正确。未定义 3D 体积，本报告不声称所有球与腿完全不交叠。
5. 120 Hz 加一帧距离余量针对当前基础速度、heading rate-limit / hysteresis 模型。未证明任意升级速度、低帧率跳帧、真实设备画面或自然步态。
6. `audit_footpath_geometry_overlay.png` 是分析示意图，不是游戏截图，也不是最终主图视觉确认。
