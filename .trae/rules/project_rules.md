# Monster_Loop 项目固定规则

> 基于 Godot 4.6 引擎的独立游戏项目
> 严格遵守以下规范，确保代码一致性和可维护性

---

## 1. 项目概述

- **引擎版本**: Godot 4.6
- **渲染器**: GL Compatibility (OpenGL ES 3.0)
- **物理引擎**: Jolt Physics (3D)
- **主场景**: `res://scenes/main/Main.tscn`
- **脚本语言**: GDScript

### 1.1 分辨率规范
- **设计分辨率**: 1152 × 648 (16:9 比例)
- **缩放模式**: Canvas Items (2D 拉伸)
- **拉伸模式**: Keep Aspect (保持宽高比)
- **最小分辨率**: 960 × 540
- **最大分辨率**: 1920 × 1080

### 1.2 适配原则
1. 所有 UI 使用相对布局 (Anchor/Container)
2. 避免使用绝对像素值定位
3. 使用 `get_viewport().size` 获取实际分辨率
4. 重要 UI 保持在安全区域内 (距边缘 5%)

---

## 2. 文件目录规范

### 2.1 根目录结构

```
Monster_Loop/
├── .trae/                  # AI 助手配置和规则
│   ├── rules/              # 项目固定规则
│   └── skills/             # AI 技能定义
├── Docs/                   # 项目文档
├── assets/                 # 游戏资源（图片、音频、模型等）
│   ├── images/
│   ├── audio/
│   ├── fonts/
│   └── models/
├── scenes/                 # 场景文件 (.tscn)
│   ├── main/               # 主菜单、结果等全局场景
│   ├── game/               # 游戏主场景
│   ├── combat/             # 战斗场景
│   ├── preparation/        # 准备/卡组编辑场景
│   └── ui/                 # 可复用 UI 场景
├── scripts/                # 脚本文件 (.gd)
│   ├── autoload/           # 自动加载单例脚本
│   ├── data/               # 数据结构和常量
│   ├── combat/             # 战斗系统
│   ├── modules/            # 地图模块系统
│   ├── scenes/             # 场景管理
│   └── ui/                 # UI 组件
├── resources/              # Godot 资源文件
│   ├── materials/
│   ├── shaders/
│   └── themes/
└── data/                   # 运行时数据（存档、配置等）
```

### 2.2 文件命名规范

| 类型 | 命名规则 | 示例 |
|------|----------|------|
| 场景文件 | PascalCase.tscn | `CombatScene.tscn`, `Main.tscn` |
| 脚本文件 | PascalCase.gd | `CombatManager.gd`, `GameManager.gd` |
| 资源文件 | snake_case | `player_sprite.png`, `battle_music.ogg` |
| 常量文件 | UPPER_SNAKE_CASE（内部） | `MAX_HEALTH`, `GRID_SIZE` |
| 节点名称 | PascalCase | `Player`, `HealthBar`, `GridContainer` |

---

## 3. 代码规范

### 3.1 脚本结构

```gdscript
class_name ClassName extends BaseClass
## 类功能简要说明

#region 信号
signal health_changed(new_health: int)
signal died()
#endregion

#region 常量
const MAX_HEALTH: int = 100
const DAMAGE_MULTIPLIER: float = 1.5
#endregion

#region 导出变量
@export var health: int = 100:
    set(value):
        health = clamp(value, 0, MAX_HEALTH)
        health_changed.emit(health)
        if health <= 0:
            died.emit()

@export var speed: float = 5.0
#endregion

#region 普通变量
var _is_invincible: bool = false
var _current_state: State = State.IDLE
#endregion

#region 内置虚函数
func _ready() -> void:
    _initialize()

func _process(delta: float) -> void:
    _update_logic(delta)

func _physics_process(delta: float) -> void:
    _physics_update(delta)
#endregion

#region 公共函数
func take_damage(amount: int) -> void:
    if _is_invincible:
        return
    health -= amount

func heal(amount: int) -> void:
    health += amount
#endregion

#region 私有函数
func _initialize() -> void:
    pass

func _update_logic(delta: float) -> void:
    pass

func _physics_update(delta: float) -> void:
    pass
#endregion
```

### 3.2 命名规范

| 类型 | 命名规则 | 示例 |
|------|----------|------|
| 类名 | PascalCase | `CombatManager`, `PlayerController` |
| 函数名 | snake_case | `take_damage()`, `calculate_score()` |
| 变量名 | snake_case | `current_health`, `move_speed` |
| 私有变量 | _snake_case | `_is_active`, `_target_node` |
| 常量 | UPPER_SNAKE_CASE | `MAX_LEVEL`, `GRID_WIDTH` |
| 信号 | snake_case | `health_changed`, `player_died` |
| 枚举 | PascalCase + 成员 | `enum State { IDLE, WALK, ATTACK }` |

### 3.3 类型注解

- **必须**为所有函数参数和返回值添加类型注解
- **必须**为所有变量添加类型注解
- 使用 `-> void` 明确表示无返回值

```gdscript
# 正确
func calculate_damage(base_damage: int, multiplier: float) -> int:
    return int(base_damage * multiplier)

var player_list: Array[Player] = []
var position: Vector2 = Vector2.ZERO

# 错误
func calculate_damage(base_damage, multiplier):
    return base_damage * multiplier

var player_list = []
var position = Vector2.ZERO
```

### 3.4 注释规范

```gdscript
## 类/重要函数的文档注释
## 说明功能、参数、返回值

# 普通注释，解释代码逻辑

# TODO: 待办事项
# FIXME: 需要修复的问题
# HACK: 临时解决方案
# NOTE: 重要提示
```

---

## 4. 场景组织规范

### 4.1 节点命名

- 使用 PascalCase
- 名称应清晰表达功能
- 避免无意义的名称如 `Node2D`, `Control2`

```
✓ Player
✓ HealthBar
✓ InventoryGrid
✓ SkillButton

✗ Node2D
✗ Control
✗ Button2
```

### 4.2 场景结构

```
RootNode (场景根节点)
├── Managers/           # 管理器节点（脚本挂载）
├── World/              # 游戏世界内容
│   ├── Background/
│   ├── Entities/
│   └── Foreground/
├── UI/                 # UI 层
│   ├── HUD/
│   ├── Menus/
│   └── Popups/
└── Audio/              # 音频节点
```

### 4.3 场景文件规范

- 每个场景文件只包含一个主要功能
- 复杂 UI 拆分为子场景
- 使用 `Editable Children` 谨慎修改实例化场景

---

## 5. 自动加载（Autoload）规范

当前已配置的 Autoload 单例：

| 名称 | 路径 | 职责 |
|------|------|------|
| EventBus | `scripts/autoload/EventBus.gd` | 全局事件总线 |
| SaveManager | `scripts/autoload/SaveManager.gd` | 存档管理 |
| GameManager | `scripts/autoload/GameManager.gd` | 游戏状态管理 |

### 5.1 添加新 Autoload 的规则

1. 脚本必须放在 `scripts/autoload/` 目录
2. 必须是单例模式
3. 命名以 `Manager` 或 `Bus` 结尾
4. 在 `project.godot` 的 `[autoload]` 段注册
5. 更新本文档的 Autoload 表格

---

## 6. 资源管理规范

### 6.1 导入设置

- 2D 图片：根据用途设置 Filter（像素风用 Nearest）
- 音频：设置合适的 Loop 和 Import 模式
- 所有导入资源使用 `.import` 文件跟踪

### 6.2 资源引用

```gdscript
# 推荐：使用预加载
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")

# 可接受：导出变量
@export var enemy_scene: PackedScene

# 避免：运行时字符串加载（除非必要）
load("res://scenes/enemy/" + enemy_name + ".tscn")
```

---

## 7. 信号与事件规范

### 7.1 信号定义

```gdscript
# 在信号附近添加注释说明
## 当生命值变化时触发，参数为新的生命值
signal health_changed(new_health: int)

## 当单位死亡时触发
signal died()
```

### 7.2 信号连接

```gdscript
# 在 _ready 中连接信号
func _ready() -> void:
    # 使用 Callable 连接
    health_changed.connect(_on_health_changed)
    
    # 一次性连接
    died.connect(_on_died, CONNECT_ONE_SHOT)

func _on_health_changed(new_health: int) -> void:
    pass
```

### 7.3 EventBus 使用

```gdscript
# 发布事件
EventBus.combat_started.emit(battle_id)

# 订阅事件
func _ready() -> void:
    EventBus.combat_started.connect(_on_combat_started)

func _on_combat_started(battle_id: String) -> void:
    pass
```

---

## 8. 数据管理规范

### 8.1 数据类定义

```gdscript
class_name MonsterData extends Resource
## 怪物数据资源

@export var id: String = ""
@export var name: String = ""
@export var health: int = 100
@export var attack: int = 10
@export var skills: Array[String] = []
```

### 8.2 常量定义

```gdscript
class_name GameConstants
## 游戏全局常量

#region 战斗常量
const MAX_COMBAT_UNITS: int = 6
const TURN_TIME_LIMIT: float = 30.0
#endregion

#region 地图常量
const GRID_WIDTH: int = 8
const GRID_HEIGHT: int = 8
const TILE_SIZE: int = 64
#endregion
```

### 8.3 枚举定义

```gdscript
class_name Enums
## 全局枚举定义

enum GameState {
    MAIN_MENU,
    PREPARATION,
    EXPLORATION,
    COMBAT,
    GAME_OVER
}

enum ElementType {
    FIRE,
    WATER,
    EARTH,
    WIND,
    LIGHT,
    DARK
}
```

---

## 9. UI 规范

### 9.1 UI 脚本结构

```gdscript
class_name HealthBarUI extends Control
## 生命值条 UI 组件

#region 导出引用
@export var health_bar: ProgressBar
@export var health_label: Label
#endregion

#region 公共函数
func update_health(current: int, maximum: int) -> void:
    var ratio: float = float(current) / maximum
    health_bar.value = ratio * 100
    health_label.text = "%d / %d" % [current, maximum]
#endregion
```

### 9.2 UI 场景组织

```
HealthBarUI (Control)
├── Background (ColorRect/TextureRect)
├── BarContainer (Container)
│   └── Fill (TextureProgressBar/ProgressBar)
└── LabelContainer (Container)
    └── ValueLabel (Label)
```

---

## 10. Git 规范

### 10.1 忽略文件

确保 `.gitignore` 包含：

```
# Godot
.import/
export.cfg
export_presets.cfg

# 构建输出
build/
*.tmp

# 用户特定设置
.editor_settings-4.tres
```

### 10.2 提交规范

- 使用清晰的提交信息
- 相关更改放在同一提交
- 大型重构分多个提交

```
feat: 添加新的技能系统
fix: 修复战斗回合顺序bug
docs: 更新战斗系统设计文档
refactor: 重构 CombatManager 类
```

---

## 11. 性能规范

### 11.1 一般准则

- 使用 `ObjectPool` 管理频繁创建/销毁的对象
- 避免在 `_process` 中进行复杂计算
- 使用 `await` 替代轮询
- 合理使用 `set_physics_process(false)` 暂停不需要更新的节点

### 11.2 内存管理

- 及时断开不再需要的信号连接
- 使用 `queue_free()` 而非 `free()`
- 注意循环引用导致的内存泄漏

---

## 12. 调试规范

### 12.1 日志输出

```gdscript
# 使用 print 进行简单调试
print("Player health: %d" % health)

# 使用 push_warning/push_error 输出警告/错误
push_warning("Health is low!")
push_error("Invalid state transition!")

# 使用 assert 进行开发时检查
assert(health >= 0, "Health cannot be negative!")
```

### 12.2 调试工具

- 使用 Godot 内置的 Profiler 分析性能
- 使用 Remote 场景树检查运行时节点状态
- 使用 Breakpoints 进行断点调试

---

## 13. 文档规范

### 13.1 代码文档

- 所有公共类和函数必须有文档注释
- 复杂逻辑需要行内注释
- 使用 `##` 格式（Godot 4 推荐）

### 13.2 设计文档

- 系统级设计放在 `Docs/` 目录
- 使用 Markdown 格式
- 命名规范：`MonsterLoop_Module_[模块名].md`

---

## 14. 模块特定规范

### 14.1 战斗系统 (`scripts/combat/`)

- `CombatManager`: 战斗流程总控
- `CombatUnit`: 战斗单位基类
- `TurnOrderManager`: 回合顺序管理
- `DamageCalculator`: 伤害计算
- `CommandManager`: 指令管理

### 14.2 地图模块 (`scripts/modules/`)

- `BaseTileModule`: 地图模块基类
- `TileModuleFactory`: 模块工厂
- 具体模块继承 `BaseTileModule`

### 14.3 数据管理 (`scripts/data/`)

- `CardLibrary`: 卡牌数据库
- `MonsterData`: 怪物数据定义
- `SkillData`: 技能数据定义
- `Enums`: 全局枚举
- `GameConstants`: 游戏常量

---

## 15. 检查清单

在提交代码前，确认：

- [ ] 代码遵循命名规范
- [ ] 所有函数和变量有类型注解
- [ ] 公共 API 有文档注释
- [ ] 信号正确连接和断开
- [ ] 没有未使用的变量或导入
- [ ] 场景文件组织清晰
- [ ] 资源引用路径正确
- [ ] 没有明显的性能问题

---

## 附录 A: 常用代码片段

### A.1 单例模式

```gdscript
class_name MyManager
extends Node

static var instance: MyManager

func _ready() -> void:
    if instance == null:
        instance = self
    else:
        queue_free()
```

### A.2 状态机基础

```gdscript
enum State { IDLE, WALK, ATTACK }
var _current_state: State = State.IDLE

func _change_state(new_state: State) -> void:
    _exit_state(_current_state)
    _current_state = new_state
    _enter_state(_current_state)

func _enter_state(state: State) -> void:
    match state:
        State.IDLE: pass
        State.WALK: pass
        State.ATTACK: pass

func _exit_state(state: State) -> void:
    match state:
        State.IDLE: pass
        State.WALK: pass
        State.ATTACK: pass
```

### A.3 对象池使用

```gdscript
# 获取对象
var bullet: Bullet = ObjectPool.get_bullet()
bullet.position = spawn_position

# 归还对象
ObjectPool.return_bullet(bullet)
```

---

**最后更新**: 2026-04-07  
**版本**: 1.0  
**维护者**: AI 助手
