# Monster Loop (生态环) —— Demo 设计文档 v2.0

> 文档版本：v2.0  
> 更新日期：2026-04-07  
> 变更说明：整合审查优化建议，修正数值公式，完善技术细节

---

# 一、核心设计理念 (Core Design)

## 1.1 核心逻辑

玩家作为"生态塑造者"，通过放置可消耗的"栖息地卡牌"构建路径生态，诱导精灵生成并完成捕获/偷窃，所有栖息地消耗完毕后触发BOSS战。

## 1.2 关键判定

| 判定条件 | 触发结果 |
|---------|---------|
| 生态位消耗殆尽 | 所有已放置的栖息地地块Charge属性均为0 |
| BOSS降临触发 | 最后一个栖息地地块Charge变为0时，在玩家当前位置生成BOSS预制体 |

## 1.3 游戏循环概览

```
局外准备 → 局内探索 → 战斗捕获 → BOSS战 → 结算 → 局外养成
    ↑                                                        ↓
    └──────────────────── 难度递增 ←─────────────────────────┘
```

---

# 二、核心玩法循环 (The Loop)

## 2.1 局外准备 (Preparation)

### 2.1.1 地图库配置

- **初始解锁地块模块**：微光森林、废弃研究所、熔岩裂隙（3种独立模块）
- **卡包配置规则**：固定选择N=5张卡牌（可配置参数），可重复选择同一种栖息地模块
- **卡牌存储**：选中的卡牌存入"手牌列表"，每张卡牌绑定对应地块模块的唯一标识

### 2.1.2 出战配置

- **精灵携带数量**：1-3只（最少1只，最多3只）
- **精灵状态判定**：可携带已孵化精灵、待孵化蛋
- **数据传递**：从局外精灵档案读取等级、ATK、DEF、技能、特性等数据

## 2.2 局内探索 (The Exploration)

### 2.2.1 自动循环移动

- **位移控制**：Path2D绘制固定圆形路径（半径300像素，可配置）
- **移动速度**：150像素/秒（可调节参数）
- **循环判定**：PathFollow2D的 `progress_ratio` 达到1.0时，重置为0.0

### 2.2.2 生态位放置

- **放置区域**：Path2D路径上的"格子节点"（预设10个均匀分布）
- **放置规则**：每个格子仅可放置1个栖息地模块，不可叠加
- **手牌显示**：左侧侧边栏UI，显示5张手牌，点击选中

### 2.2.3 次数消耗机制（核心逻辑）

| 机制 | 说明 |
|------|------|
| Charge属性 | 每个栖息地模块实例挂载独立的Charge值 |
| 消耗触发 | 玩家与模块碰撞体碰撞时，Charge减1（每圈仅触发1次） |
| 地块状态切换 | Charge归0时，销毁模块，生成"荒地"预制体 |
| BOSS觉醒进度 | 每消耗1点Charge，进度条增加（1/总初始Charge） |

### 2.2.4 一圈触发重置机制（v2.0新增）

```gdscript
# 在 BaseTileModule 中增加
var has_triggered_this_loop: bool = false

func reset_loop_trigger():
    has_triggered_this_loop = false

func on_player_enter(player: Node2D):
    if has_triggered_this_loop:
        return
    has_triggered_this_loop = true
    consume_charge()
```

玩家完成一圈时（PathFollow2D progress_ratio 从接近1.0重置为0.0时），全局调用所有模块的 `reset_loop_trigger()`。

## 2.3 战斗与捕获 (Combat & Capture)

### 2.3.1 战斗风格

- **模式**：1v1 快节奏回合制（Demo阶段）
- **战斗触发**：经过非荒地地块模块时，50%概率触发
- **回合规则**：玩家先行动，单次回合时间限制10秒

### 2.3.2 核心动作

| 动作 | 说明 |
|------|------|
| 攻击/技能 | 使用技能造成伤害 |
| 捕获 | 消耗精灵球，概率捕获敌方精灵 |
| 偷窃 | 特定条件下偷取道具 |

### 2.3.3 破绽系统 (Breaking)

- **触发条件**：玩家连续2次使用攻击（不限制是否克制）
- **状态维持**：虚弱状态持续1回合
- **数值加成**：虚弱状态下，捕获率、偷窃成功率提升50%，敌方DEF降低20%

---

# 三、系统模块详解

## 3.1 地块模块设计 (The Tiles)

### 3.1.1 基础地块接口（BaseTileModule）

所有地块模块必须继承该基础接口：

```gdscript
class_name BaseTileModule
extends Area2D

signal tile_disappear(module_id: String, grid_index: int)
signal special_effect_trigger(effect_data: Dictionary)

# 核心方法
func get_charge() -> int:
    pass

func consume_charge() -> int:
    pass

func trigger_combat_probability() -> float:
    pass

func generate_monster() -> Dictionary:
    pass

func get_special_effect() -> Dictionary:
    pass

func on_disappear() -> void:
    pass

func get_module_id() -> String:
    pass

# v2.0 新增方法
func get_display_name() -> String:
    pass

func get_icon_texture() -> Texture2D:
    pass

func get_description() -> String:
    pass

func can_place_on_tile(grid_index: int) -> bool:
    return true

func get_adjacent_synergy_bonus(adjacent_modules: Array) -> Dictionary:
    return {}

func reset_loop_trigger() -> void:
    has_triggered_this_loop = false
```

### 3.1.2 现有地块模块实现

| 模块名称 | 唯一标识 | 初始Charge | 精灵系别 | 特殊效果 | 消失奖励 |
|---------|---------|-----------|---------|---------|---------|
| 微光森林 | light_forest | 3 | 草/虫系（各50%） | 战斗胜利30%掉落果实 | 生机碎片×1 |
| 废弃研究所 | abandoned_lab | 2 | 电/钢系（各50%） | 偷窃成功率+20% | 科技模组×1 |
| 熔岩裂隙 | lava_crack | 5 | 火系（100%） | 每圈敌我ATK+5 | 核心火种×1 |

## 3.2 战斗系统

### 3.2.1 伤害公式（v2.0修正）

$$Damage = \left( \frac{Level}{5} + 1 \right) \times \frac{Power \times ATK}{DEF \times 2} \times Modifiers$$

**参数说明**：
- Level：攻击方精灵等级（1-10级）
- Power：技能威力（普通攻击=10，属性技能=15）
- ATK/DEF：攻击方/防御方基础属性
- Modifiers：属性克制倍率

**计算示例**（5级精灵，ATK=30，DEF=20，Power=15，克制2.0x）：
$$Damage = (1+1) \times \frac{15 \times 30}{20 \times 2} \times 2.0 = 2 \times 11.25 \times 2 = 45$$

### 3.2.2 属性克制表（v2.0完善）

| 攻击属性 | 克制(2.0x) | 被克制(0.5x) | 无效果(1.0x) |
|---------|-----------|-------------|-------------|
| 火 | 草、虫 | 水 | 电、钢 |
| 水 | 火 | 草、电 | 虫、钢 |
| 草 | 水 | 火、虫 | 电、钢 |
| 电 | 水 | - | 火、草、虫、钢 |
| 虫 | 草 | 火 | 水、电、钢 |
| 钢 | - | 火 | 水、草、电、虫 |

### 3.2.3 捕获系统（v2.0调整）

| 状态 | 捕获率 |
|------|--------|
| 基础捕获率 | 40% |
| 虚弱状态 | 60% |
| 初始精灵球数量 | 8个 |

### 3.2.4 偷窃系统

| 条件 | 成功率加成 |
|------|-----------|
| 基础偷窃率 | 20% |
| 废弃研究所模块 | +20% |
| 敌方虚弱状态 | +50% |
| 最高上限 | 90% |

**奖励概率**：
- 进化石：70%
- 稀有基因碎片：30%

## 3.3 局外养成

### 3.3.1 孵化器系统

- **进度计算**：每完成1圈循环，蛋进度+1
- **孵化条件**：进度达到10时自动孵化
- **孵化结果**：随机系别精灵（草/虫/电/钢/火系，各20%概率）

### 3.3.2 基因洗炼系统

- **消耗**：1个稀有基因碎片
- **效果**：精灵获得"攻击力+10"特性

---

# 四、关卡迭代与难度曲线

## 4.1 结算逻辑

1. **判定触发**：所有模块Charge均为0时，触发BOSS战
2. **BOSS生成**：在玩家当前位置生成BOSS预制体
3. **战斗结算**：
   - 胜利：弹出结算界面，难度+1
   - 失败：可选择重新开始或退出

## 4.2 难度扩展

**敌方属性修正公式**：
$$Enemy\_Stat_{new} = Enemy\_Stat_{base} \times (1 + 0.2 \times Tier)$$

| Tier | 属性提升 |
|------|---------|
| 0 | 0% |
| 1 | 20% |
| 2 | 40% |

---

# 五、Godot 4 技术方案实现

## 5.1 项目结构

```
monster-loop/
├── scenes/
│   ├── main.tscn
│   ├── preparation/
│   │   └── PreparationScene.tscn
│   ├── game/
│   │   └── GameScene.tscn
│   └── combat/
│       └── CombatScene.tscn
├── scripts/
│   ├── autoload/
│   │   ├── EventBus.gd
│   │   ├── GameManager.gd
│   │   └── SaveManager.gd
│   ├── modules/
│   │   ├── BaseTileModule.gd
│   │   ├── LightForestModule.gd
│   │   ├── AbandonedLabModule.gd
│   │   └── LavaCrackModule.gd
│   ├── combat/
│   │   ├── CombatManager.gd
│   │   └── CombatUnit.gd
│   └── ui/
│       ├── HandUI.gd
│       └── BossProgressUI.gd
├── resources/
│   ├── monsters/
│   │   └── MonsterData.tres
│   └── tiles/
│       └── TileModuleData.tres
└── data/
    └── save_data.json
```

## 5.2 全局事件总线（v2.0新增）

```gdscript
# scripts/autoload/EventBus.gd
extends Node

signal boss_progress_updated(current: int, total: int)
signal combat_triggered(module_id: String, enemy_data: Dictionary)
signal monster_captured(monster_data: Dictionary)
signal item_obtained(item_id: String, count: int)
signal loop_completed(loop_count: int)
signal tile_placed(module_id: String, grid_index: int)
signal tile_consumed(module_id: String, grid_index: int, remaining_charge: int)
signal boss_spawned(boss_data: Dictionary)
signal game_over(is_victory: bool)
```

## 5.3 数据存储（v2.0完善）

### 5.3.1 存档结构

```json
{
  "version": "1.0.0",
  "player": {
    "current_tier": 0,
    "currency": 0
  },
  "monsters": [
    {
      "uuid": "monster_001",
      "species": "fire_slime",
      "element": "fire",
      "level": 5,
      "atk": 30,
      "def": 20,
      "hp": 100,
      "max_hp": 100,
      "skills": ["tackle", "flame_burst"],
      "traits": []
    }
  ],
  "eggs": [
    {
      "uuid": "egg_001",
      "progress": 0,
      "required_progress": 10
    }
  ],
  "inventory": {
    "pokeballs": 8,
    "gene_fragments": 0,
    "evolution_stones": 0
  },
  "deck": {
    "cards": [
      {"module_id": "light_forest", "count": 2},
      {"module_id": "abandoned_lab", "count": 1},
      {"module_id": "lava_crack", "count": 2}
    ]
  },
  "unlocked_modules": ["light_forest", "abandoned_lab", "lava_crack"]
}
```

### 5.3.2 存档管理

```gdscript
# scripts/autoload/SaveManager.gd
extends Node

const SAVE_PATH := "user://save_data.json"
const BACKUP_PATH := "user://save_data_backup.json"
const CURRENT_VERSION := "1.0.0"

var _data: Dictionary = {}
var _is_dirty: bool = false

func _ready():
    load_save_data()

func load_save_data() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        _data = get_default_data()
        return _data
    
    var json := JSON.new()
    var error := json.parse(FileAccess.get_file_as_string(SAVE_PATH))
    
    if error != OK:
        if FileAccess.file_exists(BACKUP_PATH):
            json.parse(FileAccess.get_file_as_string(BACKUP_PATH))
        else:
            _data = get_default_data()
            return _data
    
    _data = validate_and_migrate(json.data)
    return _data

func save_data() -> void:
    if not _is_dirty:
        return
    
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(_data, "  "))
    
    # 创建备份
    var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
    backup.store_string(JSON.stringify(_data, "  "))
    
    _is_dirty = false

func mark_dirty() -> void:
    _is_dirty = true

func get_default_data() -> Dictionary:
    return {
        "version": CURRENT_VERSION,
        "player": {"current_tier": 0, "currency": 0},
        "monsters": [],
        "eggs": [],
        "inventory": {"pokeballs": 8, "gene_fragments": 0, "evolution_stones": 0},
        "deck": {"cards": []},
        "unlocked_modules": ["light_forest", "abandoned_lab", "lava_crack"]
    }

func validate_and_migrate(data: Dictionary) -> Dictionary:
    # 版本迁移逻辑
    if not data.has("version"):
        data["version"] = CURRENT_VERSION
    return data
```

## 5.4 碰撞层级定义（v2.0新增）

| Layer | 名称 | 说明 |
|-------|------|------|
| 1 | Player | 玩家角色 |
| 2 | TileModule | 地块模块 |
| 3 | Enemy | 敌方精灵 |
| 4 | Boss | BOSS |

**碰撞掩码配置**：
- Player: mask = Layer 2, 3, 4
- TileModule: mask = Layer 1
- Enemy: mask = Layer 1
- Boss: mask = Layer 1

---

# 六、详细模块设计文档索引

以下模块的详细设计请参阅独立文档：

1. **[卡组构筑模块](./MonsterLoop_Module_DeckBuilding.md)** - 卡牌系统、卡组配置、手牌管理
2. **[游戏场景模块](./MonsterLoop_Module_GameScene.md)** - 地图系统、循环移动、地块放置
3. **[战斗模块](./MonsterLoop_Module_Combat.md)** - 战斗流程、伤害计算、捕获偷窃

---

# 七、开发优先级建议

## Phase 1 - 核心框架（第1-2周）
- [ ] 全局事件总线 (EventBus.gd)
- [ ] 存档管理器 (SaveManager.gd)
- [ ] 游戏管理器 (GameManager.gd)
- [ ] 基础地块接口 (BaseTileModule.gd)

## Phase 2 - 卡组构筑（第3周）
- [ ] 卡牌数据结构
- [ ] 卡组配置界面
- [ ] 手牌UI系统

## Phase 3 - 游戏场景（第4-5周）
- [ ] Path2D循环路径
- [ ] 地块放置系统
- [ ] Charge消耗机制
- [ ] BOSS进度条

## Phase 4 - 战斗系统（第6-7周）
- [ ] 战斗场景与转场
- [ ] 伤害计算系统
- [ ] 属性克制系统
- [ ] 捕获与偷窃机制

## Phase 5 - 养成与完善（第8周）
- [ ] 孵化器系统
- [ ] 基因洗炼
- [ ] 数值平衡调整
- [ ] Bug修复

---

# 附录：变更日志

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| v1.0 | - | 初始设计文档 |
| v2.0 | 2026-04-07 | 整合审查建议，修正伤害公式，完善属性克制表，增加事件总线，完善数据存储 |
