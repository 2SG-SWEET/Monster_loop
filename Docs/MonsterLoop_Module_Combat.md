# Monster Loop - 战斗模块详细设计

> 模块版本：v2.0  
> 更新日期：2026-04-07  
> 依赖文档：[MonsterLoop_Demo_v2.md](./MonsterLoop_Demo_v2.md)

---

# 一、模块概述

## 1.1 功能定位

战斗模块是核心玩法的核心交互环节，负责：
- 管理**多V多回合制战斗流程**（玩家队伍 vs 敌方队伍）
- 处理伤害计算与属性克制
- 实现捕获与偷窃机制
- 管理破绽（虚弱）系统
- **基于速度属性的行动顺序排序**
- **每回合玩家为所有存活单位设定行动指令**
- 处理战斗结算与奖励

## 1.2 核心设计理念

### 多V多战斗机制
- 玩家可携带最多 **3只精灵** 参战
- 敌方队伍可包含 **1-5只精灵**（根据关卡配置）
- 每只精灵拥有独立的**速度属性(SPD)**

### 速度行动系统
- 每回合开始时，根据**所有存活单位的速度值**排序
- 速度高者优先行动
- 速度相同时随机决定顺序

### 指令预输入系统
- 玩家在回合开始时为**所有存活单位**设定行动指令
- 敌方AI同时设定行动指令
- 系统按速度顺序依次执行所有单位的行动

## 1.3 模块边界

| 职责范围 | 不包含 |
|---------|--------|
| 战斗场景管理 | 游戏场景循环移动 |
| 回合制逻辑 | 地块放置系统 |
| 伤害计算 | 精灵养成系统 |
| 捕获/偷窃判定 | BOSS进度管理 |
| 战斗UI交互 | 局外数据管理 |
| 速度排序系统 | 队伍编辑系统 |

## 1.4 系统架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                         战斗模块 v2.0                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │CombatManager │  │TurnOrderMgr  │  │ DamageSystem │              │
│  │  战斗管理器   │  │ 行动顺序管理  │  │  伤害系统     │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                 │                 │                      │
│         └────────────────┬┴─────────────────┘                      │
│                          │                                         │
│         ┌────────────────┼────────────────┐                        │
│         │                │                │                        │
│         ▼                ▼                ▼                        │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                    │
│  │CaptureSystem│  │StealSystem │  │ CommandMgr │                    │
│  │  捕获系统   │  │  偷窃系统   │  │  指令管理器  │                    │
│  └────────────┘  └────────────┘  └────────────┘                    │
│                                                                     │
│         ┌────────────────┬────────────────┐                        │
│         │                │                │                        │
│         ▼                ▼                ▼                        │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                    │
│  │BreakSystem │  │ CombatAI   │  │ CombatUI   │                    │
│  │  破绽系统   │  │  战斗AI    │  │  战斗UI    │                    │
│  └────────────┘  └────────────┘  └────────────┘                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

# 二、场景结构设计

## 2.1 场景节点树

```
CombatScene (CanvasLayer)
├── Background (TextureRect)                        # 战斗背景
│   └── ShaderMaterial (转场效果)
│
├── BattleField (Control)                           # 战斗区域
│   ├── EnemySide (HBoxContainer)                   # 敌方区域（多单位）
│   │   ├── EnemySlot1 (VBoxContainer)
│   │   │   ├── EnemySprite (AnimatedSprite2D)
│   │   │   ├── EnemyStatus (VBoxContainer)
│   │   │   │   ├── EnemyName (Label)
│   │   │   │   ├── EnemyLevel (Label)
│   │   │   │   ├── EnemyHPBar (ProgressBar)
│   │   │   │   ├── EnemySPD (Label)               # 速度显示
│   │   │   │   └── EnemyStatusEffects (HBoxContainer)
│   │   │   └── EnemyElement (TextureRect)
│   │   ├── EnemySlot2 (VBoxContainer)
│   │   ├── EnemySlot3 (VBoxContainer)
│   │   ├── EnemySlot4 (VBoxContainer)
│   │   └── EnemySlot5 (VBoxContainer)
│   │
│   └── PlayerSide (HBoxContainer)                  # 玩家区域（多单位）
│       ├── PlayerSlot1 (VBoxContainer)
│       │   ├── PlayerSprite (AnimatedSprite2D)
│       │   ├── PlayerStatus (VBoxContainer)
│       │   │   ├── PlayerName (Label)
│       │   │   ├── PlayerLevel (Label)
│       │   │   ├── PlayerHPBar (ProgressBar)
│       │   │   ├── PlayerSPD (Label)              # 速度显示
│       │   │   └── PlayerStatusEffects (HBoxContainer)
│       │   └── PlayerElement (TextureRect)
│       ├── PlayerSlot2 (VBoxContainer)
│       └── PlayerSlot3 (VBoxContainer)
│
├── TurnOrderPanel (HBoxContainer)                  # 行动顺序面板
│   ├── TurnOrderLabel (Label)
│   └── TurnOrderIcons (HBoxContainer)              # 显示行动顺序图标
│       └── [UnitIcon × N]                          # 按速度排序的单位图标
│
├── CommandPanel (PanelContainer)                   # 指令面板（多单位）
│   ├── UnitSelector (TabContainer)                 # 单位选择标签
│   │   ├── UnitTab1 (VBoxContainer)
│   │   │   ├── UnitName (Label)
│   │   │   └── ActionButtons (GridContainer)
│   │   │       ├── AttackButton (Button)
│   │   │       ├── SkillButton (Button)
│   │   │       ├── CaptureButton (Button)
│   │   │       ├── StealButton (Button)
│   │   │       └── DefendButton (Button)          # 新增：防御
│   │   ├── UnitTab2 (VBoxContainer)
│   │   └── UnitTab3 (VBoxContainer)
│   │
│   ├── SkillPanel (VBoxContainer)                  # 技能面板
│   │   ├── SkillList (VBoxContainer)
│   │   │   └── [SkillButton × N]
│   │   └── BackButton (Button)
│   │
│   ├── TargetSelectPanel (VBoxContainer)           # 目标选择面板
│   │   ├── TargetList (VBoxContainer)
│   │   │   └── [TargetButton × N]
│   │   └── BackButton (Button)
│   │
│   └── ConfirmButton (Button)                      # 确认所有指令
│
├── CombatLog (ScrollContainer)                     # 战斗日志
│   └── LogContainer (VBoxContainer)
│       └── [LogEntry × N]
│
├── TurnIndicator (Control)                         # 回合指示器
│   ├── TurnLabel (Label)
│   ├── PhaseLabel (Label)                          # 阶段标签（指令/执行）
│   └── TimerBar (ProgressBar)
│
├── ResultPanel (Control)                           # 结果面板
│   ├── VictoryPanel (PanelContainer)
│   │   ├── ResultTitle (Label)
│   │   ├── RewardsContainer (VBoxContainer)
│   │   └── ContinueButton (Button)
│   │
│   └── DefeatPanel (PanelContainer)
│       ├── ResultTitle (Label)
│       └── RetryButton (Button)
│
└── Managers (Node)
    ├── CombatManager                                # 战斗管理器
    ├── TurnOrderManager                             # 行动顺序管理器
    ├── CommandManager                               # 指令管理器
    ├── DamageCalculator                             # 伤害计算器
    ├── CaptureManager                               # 捕获管理器
    └── StealManager                                 # 偷窃管理器
```

## 2.2 UI布局示意

```
┌─────────────────────────────────────────────────────────────────────┐
│  [回合: 1/10]  [阶段: 指令输入]           [计时: ████████░░] 8s     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ 行动顺序: [火史]→[草龟]→[水蛇]→[敌方A]→[敌方B]               │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                    敌方队伍 (3只)                              │ │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐                       │ │
│  │  │火焰史莱姆│  │ 水蛇    │  │ 草精    │                       │ │
│  │  │ Lv.5    │  │ Lv.4    │  │ Lv.6    │                       │ │
│  │  │HP:80%   │  │HP:100%  │  │HP:60%   │                       │ │
│  │  │SPD:25   │  │SPD:30   │  │SPD:18   │                       │ │
│  │  └─────────┘  └─────────┘  └─────────┘                       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                    玩家队伍 (3只)                              │ │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐                       │ │
│  │  │ 草苗龟  │  │ 火精灵  │  │ 电鼠    │                       │ │
│  │  │ Lv.5    │  │ Lv.5    │  │ Lv.4    │                       │ │
│  │  │HP:100%  │  │HP:85%   │  │HP:100%  │                       │ │
│  │  │SPD:20   │  │SPD:35   │  │SPD:28   │                       │ │
│  │  │[已设定] │  │[待设定] │  │[待设定] │                       │ │
│  │  └─────────┘  └─────────┘  └─────────┘                       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ [草苗龟] [火精灵] [电鼠]    ← 单位切换标签                     │  │
│  ├──────────────────────────────────────────────────────────────┤  │
│  │  [攻击]  [技能]  [捕获(8)]  [偷窃]  [防御]                    │  │
│  │                                                              │  │
│  │  当前单位: 草苗龟 | 已设定指令: 攻击→火焰史莱姆               │  │
│  └──────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ [确认所有指令]                                                │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ > 第1回合开始！                                               │  │
│  │ > 请为所有存活单位设定行动指令                                 │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

# 三、核心数据结构

## 3.1 CombatUnit (战斗单位)

```gdscript
# scripts/combat/CombatUnit.gd
class_name CombatUnit
extends RefCounted

enum UnitType { PLAYER, ENEMY, BOSS }
enum UnitState { ACTIVE, DEFENDING, FAINTED }

var unit_type: UnitType = UnitType.ENEMY
var uuid: String = ""
var display_name: String = ""
var level: int = 1
var element: Enums.Element = Enums.Element.FIRE

var base_atk: int = 30
var base_def: int = 20
var base_hp: int = 100
var base_spd: int = 20

var current_hp: int = 100
var max_hp: int = 100

var skills: Array[SkillData] = []
var traits: Array[String] = []

var status_effects: Dictionary = {}
var attack_count: int = 0
var last_action: String = ""

var is_weakened: bool = false
var weaken_turns_remaining: int = 0

var unit_state: UnitState = UnitState.ACTIVE
var slot_index: int = 0

func _init(data: Dictionary = {}):
    if data.is_empty():
        return
    
    uuid = data.get("uuid", "")
    display_name = data.get("display_name", "未知")
    level = data.get("level", 1)
    element = data.get("element", Enums.Element.FIRE)
    base_atk = data.get("atk", 30)
    base_def = data.get("def", 20)
    base_hp = data.get("hp", 100)
    base_spd = data.get("spd", 20)
    max_hp = base_hp
    current_hp = base_hp
    
    for skill_id in data.get("skills", []):
        var skill := SkillDatabase.get_skill(skill_id)
        if skill != null:
            skills.append(skill)
    
    traits = data.get("traits", [])

func get_effective_atk() -> int:
    var atk := base_atk
    
    if is_weakened:
        atk = int(atk * 0.8)
    
    if unit_state == UnitState.DEFENDING:
        atk = int(atk * 0.5)
    
    for effect_name in status_effects:
        var effect := status_effects[effect_name]
        if effect.has("atk_modifier"):
            atk = int(atk * effect.atk_modifier)
    
    return atk

func get_effective_def() -> int:
    var def := base_def
    
    if is_weakened:
        def = int(def * 0.8)
    
    if unit_state == UnitState.DEFENDING:
        def = int(def * 2.0)
    
    for effect_name in status_effects:
        var effect := status_effects[effect_name]
        if effect.has("def_modifier"):
            def = int(def * effect.def_modifier)
    
    return def

func get_effective_spd() -> int:
    var spd := base_spd
    
    if is_weakened:
        spd = int(spd * 0.9)
    
    for effect_name in status_effects:
        var effect := status_effects[effect_name]
        if effect.has("spd_modifier"):
            spd = int(spd * effect.spd_modifier)
    
    return spd

func take_damage(amount: int) -> int:
    var actual_damage := mini(amount, current_hp)
    current_hp -= actual_damage
    
    if current_hp <= 0:
        unit_state = UnitState.FAINTED
    
    return actual_damage

func heal(amount: int) -> int:
    var actual_heal := mini(amount, max_hp - current_hp)
    current_hp += actual_heal
    return actual_heal

func is_fainted() -> bool:
    return unit_state == UnitState.FAINTED or current_hp <= 0

func is_active() -> bool:
    return unit_state == UnitState.ACTIVE and current_hp > 0

func set_defending(is_defending: bool) -> void:
    if is_defending:
        unit_state = UnitState.DEFENDING
    else:
        unit_state = UnitState.ACTIVE

func apply_weaken(duration: int = 1) -> void:
    is_weakened = true
    weaken_turns_remaining = duration

func tick_weaken() -> void:
    if is_weakened:
        weaken_turns_remaining -= 1
        if weaken_turns_remaining <= 0:
            is_weakened = false

func tick_status_effects() -> void:
    var expired: Array[String] = []
    
    for effect_name in status_effects:
        var effect := status_effects[effect_name]
        if effect.has("duration"):
            effect.duration -= 1
            if effect.duration <= 0:
                expired.append(effect_name)
    
    for effect_name in expired:
        status_effects.erase(effect_name)

func reset_turn_state() -> void:
    if unit_state == UnitState.DEFENDING:
        unit_state = UnitState.ACTIVE

func get_hp_percent() -> float:
    return float(current_hp) / float(max_hp)

func to_dictionary() -> Dictionary:
    return {
        "uuid": uuid,
        "display_name": display_name,
        "level": level,
        "element": element,
        "atk": base_atk,
        "def": base_def,
        "hp": current_hp,
        "max_hp": max_hp,
        "spd": base_spd,
        "skills": skills.map(func(s): return s.skill_id),
        "traits": traits,
        "is_weakened": is_weakened,
        "unit_state": unit_state
    }
```

## 3.2 CombatCommand (战斗指令)

```gdscript
# scripts/combat/CombatCommand.gd
class_name CombatCommand
extends RefCounted

enum CommandType { 
    ATTACK, 
    SKILL, 
    CAPTURE, 
    STEAL, 
    DEFEND,
    SWITCH,
    ITEM
}

var actor: CombatUnit = null
var command_type: CommandType = CommandType.ATTACK
var target: CombatUnit = null
var skill_index: int = -1
var item_id: String = ""
var priority: int = 0

func _init(p_actor: CombatUnit, p_type: CommandType, p_target: CombatUnit = null):
    actor = p_actor
    command_type = p_type
    target = p_target
    priority = actor.get_effective_spd() if actor != null else 0

func execute() -> CommandResult:
    var result := CommandResult.new()
    result.command = self
    result.actor = actor
    
    if actor == null or actor.is_fainted():
        result.success = false
        result.message = "行动者已倒下"
        return result
    
    match command_type:
        CommandType.ATTACK:
            _execute_attack(result)
        CommandType.SKILL:
            _execute_skill(result)
        CommandType.CAPTURE:
            _execute_capture(result)
        CommandType.STEAL:
            _execute_steal(result)
        CommandType.DEFEND:
            _execute_defend(result)
        _:
            result.success = false
            result.message = "未知指令类型"
    
    return result

func _execute_attack(result: CommandResult) -> void:
    if target == null or target.is_fainted():
        result.success = false
        result.message = "目标无效"
        return
    
    var skill := _get_basic_attack()
    var damage_result := DamageCalculator.calculate_damage(actor, target, skill)
    
    var actual_damage := target.take_damage(damage_result.final_damage)
    
    result.success = true
    result.damage_dealt = actual_damage
    result.target = target
    result.message = "%s 使用了 %s！" % [actor.display_name, skill.display_name]
    
    if damage_result.is_critical:
        result.message += "\n击中了要害！"
    
    if damage_result.element_modifier > 1.0:
        result.message += "\n效果拔群！"
    elif damage_result.element_modifier < 1.0:
        result.message += "\n效果不佳..."
    
    result.message += "\n%s 受到了 %d 点伤害！" % [target.display_name, actual_damage]
    
    actor.last_action = "attack"
    actor.attack_count += 1

func _execute_skill(result: CommandResult) -> void:
    if skill_index < 0 or skill_index >= actor.skills.size():
        result.success = false
        result.message = "无效的技能选择"
        return
    
    var skill := actor.skills[skill_index]
    
    if not skill.can_use():
        result.success = false
        result.message = "技能PP已耗尽"
        return
    
    if target == null or target.is_fainted():
        result.success = false
        result.message = "目标无效"
        return
    
    var damage_result := DamageCalculator.calculate_damage(actor, target, skill)
    var actual_damage := target.take_damage(damage_result.final_damage)
    
    skill.use()
    
    result.success = true
    result.damage_dealt = actual_damage
    result.target = target
    result.skill_used = skill
    result.message = "%s 使用了 %s！" % [actor.display_name, skill.display_name]
    
    if damage_result.is_critical:
        result.message += "\n击中了要害！"
    
    if damage_result.element_modifier > 1.0:
        result.message += "\n效果拔群！"
    elif damage_result.element_modifier < 1.0:
        result.message += "\n效果不佳..."
    
    result.message += "\n%s 受到了 %d 点伤害！" % [target.display_name, actual_damage]
    
    actor.last_action = "skill"

func _execute_capture(result: CommandResult) -> void:
    var pokeballs: int = SaveManager.get_data().get("inventory", {}).get("pokeballs", 0)
    
    if pokeballs <= 0:
        result.success = false
        result.message = "没有精灵球了！"
        return
    
    if target == null or target.is_fainted():
        result.success = false
        result.message = "目标无效"
        return
    
    SaveManager.get_data()["inventory"]["pokeballs"] = pokeballs - 1
    SaveManager.mark_dirty()
    
    var capture_result := CaptureManager.attempt_capture(target)
    
    result.message = "使用了精灵球！"
    
    if capture_result.success:
        result.success = true
        result.captured = true
        result.captured_data = capture_result.captured_data
        result.message += "\n捕获成功！"
    else:
        result.success = true
        result.captured = false
        result.message += "\n捕获失败..."

func _execute_steal(result: CommandResult) -> void:
    if target == null or target.is_fainted():
        result.success = false
        result.message = "目标无效"
        return
    
    var steal_result := StealManager.attempt_steal(target)
    
    result.message = "尝试偷窃..."
    
    if steal_result.success:
        result.success = true
        result.stolen_item = steal_result
        result.message += "\n偷窃成功！获得了 %s！" % steal_result.item_name
    else:
        result.success = false
        result.message += "\n偷窃失败！"

func _execute_defend(result: CommandResult) -> void:
    actor.set_defending(true)
    result.success = true
    result.message = "%s 进入防御姿态！" % actor.display_name

func _get_basic_attack() -> SkillData:
    var attack := SkillData.new()
    attack.skill_id = "basic_attack"
    attack.display_name = "撞击"
    attack.power = 10
    attack.skill_type = SkillData.SkillType.PHYSICAL
    attack.element = actor.element
    return attack

class CommandResult:
    extends RefCounted
    
    var command: CombatCommand = null
    var actor: CombatUnit = null
    var target: CombatUnit = null
    var success: bool = false
    var message: String = ""
    var damage_dealt: int = 0
    var skill_used: SkillData = null
    var captured: bool = false
    var captured_data: Dictionary = {}
    var stolen_item: Dictionary = {}
```

## 3.3 TurnOrderManager (行动顺序管理器)

```gdscript
# scripts/combat/TurnOrderManager.gd
class_name TurnOrderManager
extends RefCounted

signal turn_order_changed(order: Array[CombatUnit])
signal current_unit_changed(unit: CombatUnit)

var _turn_order: Array[CombatUnit] = []
var _current_index: int = 0

func calculate_turn_order(all_units: Array[CombatUnit]) -> Array[CombatUnit]:
    var active_units := all_units.filter(func(u): return not u.is_fainted())
    
    active_units.sort_custom(_compare_by_speed)
    
    _turn_order = active_units
    _current_index = 0
    
    turn_order_changed.emit(_turn_order)
    
    return _turn_order

func _compare_by_speed(a: CombatUnit, b: CombatUnit) -> bool:
    var spd_a := a.get_effective_spd()
    var spd_b := b.get_effective_spd()
    
    if spd_a != spd_b:
        return spd_a > spd_b
    
    return randf() > 0.5

func get_current_unit() -> CombatUnit:
    if _current_index >= 0 and _current_index < _turn_order.size():
        return _turn_order[_current_index]
    return null

func advance_to_next() -> CombatUnit:
    _current_index += 1
    
    while _current_index < _turn_order.size():
        var unit := _turn_order[_current_index]
        if not unit.is_fainted():
            current_unit_changed.emit(unit)
            return unit
        _current_index += 1
    
    return null

func has_more_units() -> bool:
    for i in range(_current_index + 1, _turn_order.size()):
        if not _turn_order[i].is_fainted():
            return true
    return false

func get_turn_order() -> Array[CombatUnit]:
    return _turn_order

func get_remaining_units() -> Array[CombatUnit]:
    var remaining: Array[CombatUnit] = []
    for i in range(_current_index, _turn_order.size()):
        var unit := _turn_order[i]
        if not unit.is_fainted():
            remaining.append(unit)
    return remaining

func reset() -> void:
    _turn_order.clear()
    _current_index = 0

func get_unit_position(unit: CombatUnit) -> int:
    for i in range(_turn_order.size()):
        if _turn_order[i].uuid == unit.uuid:
            return i
    return -1
```

## 3.4 SkillData (技能数据)

```gdscript
# scripts/combat/SkillData.gd
class_name SkillData
extends Resource

enum SkillType { PHYSICAL, SPECIAL, STATUS }
enum TargetType { SINGLE_ENEMY, ALL_ENEMY, SELF, ALLY }

@export var skill_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var skill_type: SkillType = SkillType.PHYSICAL
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var power: int = 10
@export var element: Enums.Element = Enums.Element.FIRE
@export var accuracy: int = 100
@export var pp: int = 10
@export var current_pp: int = 10
@export var priority: int = 0
@export var effect: Dictionary = {}

func can_use() -> bool:
    return current_pp > 0

func use() -> void:
    if current_pp > 0:
        current_pp -= 1

func restore_pp(amount: int = -1) -> void:
    if amount < 0:
        current_pp = pp
    else:
        current_pp = mini(pp, current_pp + amount)
```

## 3.5 CombatResult (战斗结果)

```gdscript
# scripts/combat/CombatResult.gd
class_name CombatResult
extends RefCounted

enum ResultType { VICTORY, DEFEAT, CAPTURED, FLED }

var result_type: ResultType = ResultType.VICTORY
var captured_monsters: Array[Dictionary] = []
var stolen_items: Array[Dictionary] = []
var experience_gained: int = 0
var damage_dealt: int = 0
var damage_taken: int = 0
var turns_elapsed: int = 0
var units_defeated: int = 0

func to_dictionary() -> Dictionary:
    return {
        "result_type": result_type,
        "captured_monsters": captured_monsters,
        "stolen_items": stolen_items,
        "experience_gained": experience_gained,
        "damage_dealt": damage_dealt,
        "damage_taken": damage_taken,
        "turns_elapsed": turns_elapsed,
        "units_defeated": units_defeated
    }
```

---

# 四、核心系统实现

## 4.1 CombatManager (战斗管理器)

```gdscript
# scripts/combat/CombatManager.gd
class_name CombatManager
extends Node

signal combat_started(enemy_units: Array[Dictionary])
signal turn_phase_changed(phase: String)
signal command_phase_started(player_units: Array[CombatUnit])
signal execution_phase_started(turn_order: Array[CombatUnit])
signal command_executed(command: CombatCommand, result: CommandResult.CommandResult)
signal combat_ended(result: CombatResult)
signal hp_changed(unit: CombatUnit, old_hp: int, new_hp: int)
signal status_applied(unit: CombatUnit, status: String)
signal log_message(message: String)
signal unit_fainted(unit: CombatUnit)

const COMMAND_TIME_LIMIT := 30.0
const MAX_TURNS := 50
const MAX_PLAYER_UNITS := 3
const MAX_ENEMY_UNITS := 5

enum CombatPhase { 
    INIT, 
    COMMAND_INPUT, 
    EXECUTION, 
    TURN_END, 
    COMBAT_END 
}

@onready var phase_timer: Timer = $PhaseTimer

var player_units: Array[CombatUnit] = []
var enemy_units: Array[CombatUnit] = []
var turn_order_manager: TurnOrderManager = null
var command_manager: CommandManager = null

var current_turn: int = 0
var current_phase: CombatPhase = CombatPhase.INIT
var is_combat_active: bool = false
var phase_time_remaining: float = COMMAND_TIME_LIMIT
var current_module_id: String = ""

var pending_commands: Array[CombatCommand] = []
var executed_commands_this_turn: Array[CombatCommand] = []

func _ready():
    turn_order_manager = TurnOrderManager.new()
    command_manager = CommandManager.new()
    phase_timer.wait_time = 0.1
    phase_timer.timeout.connect(_on_phase_timer_tick)

func start_combat(enemy_data_list: Array[Dictionary], module_id: String = "") -> void:
    current_module_id = module_id
    _initialize_units(enemy_data_list)
    _reset_combat_state()
    
    is_combat_active = true
    combat_started.emit(enemy_data_list)
    
    _start_new_turn()

func _initialize_units(enemy_data_list: Array[Dictionary]) -> void:
    player_units.clear()
    enemy_units.clear()
    
    var player_monsters: Array = SaveManager.get_data().get("selected_monsters", [])
    var slot_index := 0
    
    for slot_data in player_monsters:
        if slot_data.get("state", 0) == MonsterSlot.SlotState.MONSTER:
            var monster_uuid := slot_data.get("monster_uuid", "")
            if not monster_uuid.is_empty():
                var monster_data := _get_monster_by_uuid(monster_uuid)
                if not monster_data.is_empty():
                    var unit := CombatUnit.new(monster_data)
                    unit.unit_type = CombatUnit.UnitType.PLAYER
                    unit.slot_index = slot_index
                    player_units.append(unit)
                    slot_index += 1
                    
                    if player_units.size() >= MAX_PLAYER_UNITS:
                        break
    
    if player_units.is_empty():
        var monsters: Array = SaveManager.get_data().get("monsters", [])
        if monsters.size() > 0:
            var unit := CombatUnit.new(monsters[0])
            unit.unit_type = CombatUnit.UnitType.PLAYER
            unit.slot_index = 0
            player_units.append(unit)
    
    for i in range(mini(enemy_data_list.size(), MAX_ENEMY_UNITS)):
        var enemy_unit := CombatUnit.new(enemy_data_list[i])
        enemy_unit.unit_type = CombatUnit.UnitType.ENEMY
        enemy_unit.slot_index = i
        enemy_units.append(enemy_unit)

func _get_monster_by_uuid(uuid: String) -> Dictionary:
    var monsters: Array = SaveManager.get_data().get("monsters", [])
    for monster in monsters:
        if monster.get("uuid") == uuid:
            return monster
    return {}

func _reset_combat_state() -> void:
    current_turn = 0
    current_phase = CombatPhase.INIT
    pending_commands.clear()
    executed_commands_this_turn.clear()
    phase_time_remaining = COMMAND_TIME_LIMIT

func _start_new_turn() -> void:
    current_turn += 1
    
    if current_turn > MAX_TURNS:
        _end_combat(CombatResult.ResultType.DEFEAT)
        return
    
    _add_log("═══ 第 %d 回合开始！ ═══" % current_turn)
    
    for unit in player_units:
        unit.reset_turn_state()
        unit.tick_weaken()
        unit.tick_status_effects()
    
    for unit in enemy_units:
        unit.reset_turn_state()
        unit.tick_weaken()
        unit.tick_status_effects()
    
    _start_command_phase()

func _start_command_phase() -> void:
    current_phase = CombatPhase.COMMAND_INPUT
    phase_time_remaining = COMMAND_TIME_LIMIT
    pending_commands.clear()
    executed_commands_this_turn.clear()
    
    phase_timer.start()
    
    turn_phase_changed.emit("command_input")
    command_phase_started.emit(_get_active_player_units())
    
    _add_log("请为所有存活单位设定行动指令")

func _on_phase_timer_tick() -> void:
    if not is_combat_active:
        phase_timer.stop()
        return
    
    phase_time_remaining -= 0.1
    
    if phase_time_remaining <= 0:
        _on_phase_timeout()

func _on_phase_timeout() -> void:
    if current_phase == CombatPhase.COMMAND_INPUT:
        _auto_fill_pending_commands()
        _start_execution_phase()

func _auto_fill_pending_commands() -> void:
    var active_players := _get_active_player_units()
    
    for unit in active_players:
        var has_command := false
        for cmd in pending_commands:
            if cmd.actor.uuid == unit.uuid:
                has_command = true
                break
        
        if not has_command:
            var alive_enemies := _get_active_enemy_units()
            if alive_enemies.size() > 0:
                var target := alive_enemies[randi() % alive_enemies.size()]
                var cmd := CombatCommand.new(unit, CombatCommand.CommandType.ATTACK, target)
                pending_commands.append(cmd)
                _add_log("%s 自动选择攻击 %s" % [unit.display_name, target.display_name])

func set_unit_command(unit_uuid: String, command_type: CombatCommand.CommandType, 
                       target_uuid: String = "", skill_index: int = -1) -> bool:
    if current_phase != CombatPhase.COMMAND_INPUT:
        return false
    
    var actor: CombatUnit = null
    for unit in player_units:
        if unit.uuid == unit_uuid and not unit.is_fainted():
            actor = unit
            break
    
    if actor == null:
        return false
    
    var target: CombatUnit = null
    if not target_uuid.is_empty():
        for unit in enemy_units:
            if unit.uuid == target_uuid and not unit.is_fainted():
                target = unit
                break
    
    var existing_index := -1
    for i in range(pending_commands.size()):
        if pending_commands[i].actor.uuid == unit_uuid:
            existing_index = i
            break
    
    var cmd := CombatCommand.new(actor, command_type, target)
    cmd.skill_index = skill_index
    
    if existing_index >= 0:
        pending_commands[existing_index] = cmd
    else:
        pending_commands.append(cmd)
    
    return true

func confirm_all_commands() -> void:
    if current_phase != CombatPhase.COMMAND_INPUT:
        return
    
    _auto_fill_pending_commands()
    _start_execution_phase()

func _start_execution_phase() -> void:
    current_phase = CombatPhase.EXECUTION
    phase_timer.stop()
    
    _generate_enemy_commands()
    
    var all_commands := pending_commands.duplicate()
    all_commands.sort_custom(_compare_command_priority)
    
    var all_units: Array[CombatUnit] = []
    all_units.append_array(player_units)
    all_units.append_array(enemy_units)
    
    var turn_order := turn_order_manager.calculate_turn_order(all_units)
    
    turn_phase_changed.emit("execution")
    execution_phase_started.emit(turn_order)
    
    _add_log("═══ 执行阶段 ═══")
    
    _execute_commands_sequentially(all_commands)

func _generate_enemy_commands() -> void:
    var active_enemies := _get_active_enemy_units()
    var active_players := _get_active_player_units()
    
    for enemy in active_enemies:
        if active_players.is_empty():
            continue
        
        var ai_decision := CombatAI.select_action(enemy, active_players, active_enemies)
        var cmd := CombatCommand.new(enemy, ai_decision.command_type, ai_decision.target)
        cmd.skill_index = ai_decision.skill_index
        pending_commands.append(cmd)

func _compare_command_priority(a: CombatCommand, b: CombatCommand) -> bool:
    var spd_a := a.actor.get_effective_spd() if a.actor != null else 0
    var spd_b := b.actor.get_effective_spd() if b.actor != null else 0
    
    if spd_a != spd_b:
        return spd_a > spd_b
    
    return randf() > 0.5

func _execute_commands_sequentially(commands: Array[CombatCommand]) -> void:
    for cmd in commands:
        if cmd.actor.is_fainted():
            continue
        
        if cmd.target != null and cmd.target.is_fainted():
            var new_target := _find_new_target(cmd)
            if new_target == null:
                continue
            cmd.target = new_target
        
        var result := cmd.execute()
        executed_commands_this_turn.append(cmd)
        
        command_executed.emit(cmd, result)
        
        if not result.message.is_empty():
            _add_log(result.message)
        
        if cmd.target != null:
            hp_changed.emit(cmd.target, cmd.target.current_hp + result.damage_dealt, cmd.target.current_hp)
        
        if result.captured:
            _handle_capture(cmd.target, result.captured_data)
        
        if result.stolen_item.has("item_id"):
            _apply_stolen_item(result.stolen_item)
        
        _check_break_trigger(cmd.actor, cmd.target)
        
        if _check_combat_end():
            return
        
        await get_tree().create_timer(0.3).timeout
    
    _end_turn()

func _find_new_target(cmd: CombatCommand) -> CombatUnit:
    if cmd.actor.unit_type == CombatUnit.UnitType.PLAYER:
        var active_enemies := _get_active_enemy_units()
        if active_enemies.size() > 0:
            return active_enemies[randi() % active_enemies.size()]
    else:
        var active_players := _get_active_player_units()
        if active_players.size() > 0:
            return active_players[randi() % active_players.size()]
    return null

func _check_break_trigger(attacker: CombatUnit, target: CombatUnit) -> void:
    if target == null:
        return
    
    var consecutive := 0
    for cmd in executed_commands_this_turn:
        if cmd.target != null and cmd.target.uuid == target.uuid:
            if cmd.command_type == CombatCommand.CommandType.ATTACK or cmd.command_type == CombatCommand.CommandType.SKILL:
                consecutive += 1
    
    if consecutive >= 2 and not target.is_weakened:
        target.apply_weaken(1)
        status_applied.emit(target, "weaken")
        _add_log("%s 进入了虚弱状态！" % target.display_name)

func _handle_capture(target: CombatUnit, captured_data: Dictionary) -> void:
    _save_captured_monster(captured_data)
    
    for i in range(enemy_units.size()):
        if enemy_units[i].uuid == target.uuid:
            enemy_units[i].unit_state = CombatUnit.UnitState.FAINTED
            break

func _end_turn() -> void:
    current_phase = CombatPhase.TURN_END
    
    _check_fainted_units()
    
    if _check_combat_end():
        return
    
    await get_tree().create_timer(0.5).timeout
    
    _start_new_turn()

func _check_fainted_units() -> void:
    for unit in player_units:
        if unit.is_fainted():
            unit_fainted.emit(unit)
    
    for unit in enemy_units:
        if unit.is_fainted():
            unit_fainted.emit(unit)

func _check_combat_end() -> bool:
    var active_players := _get_active_player_units()
    var active_enemies := _get_active_enemy_units()
    
    if active_players.is_empty():
        _end_combat(CombatResult.ResultType.DEFEAT)
        return true
    
    if active_enemies.is_empty():
        _end_combat(CombatResult.ResultType.VICTORY)
        return true
    
    return false

func _end_combat(result_type: CombatResult.ResultType) -> void:
    is_combat_active = false
    current_phase = CombatPhase.COMBAT_END
    phase_timer.stop()
    
    var result := CombatResult.new()
    result.result_type = result_type
    result.turns_elapsed = current_turn
    
    if result_type == CombatResult.ResultType.VICTORY:
        for enemy in enemy_units:
            result.experience_gained += enemy.level * 10
            result.units_defeated += 1
        _add_log("战斗胜利！获得 %d 经验！" % result.experience_gained)
    elif result_type == CombatResult.ResultType.DEFEAT:
        _add_log("战斗失败...")
    
    await get_tree().create_timer(1.0).timeout
    
    combat_ended.emit(result)

func _save_captured_monster(monster_data: Dictionary) -> void:
    var monsters: Array = SaveManager.get_data().get("monsters", [])
    monsters.append(monster_data)
    SaveManager.mark_dirty()
    
    EventBus.monster_captured.emit(monster_data)

func _apply_stolen_item(steal_result: Dictionary) -> void:
    var item_id: String = steal_result.get("item_id", "")
    var item_count: int = steal_result.get("count", 1)
    
    var inventory: Dictionary = SaveManager.get_data().get("inventory", {})
    var current_count: int = inventory.get(item_id, 0)
    inventory[item_id] = current_count + item_count
    SaveManager.mark_dirty()
    
    EventBus.item_obtained.emit(item_id, item_count)

func _add_log(message: String) -> void:
    log_message.emit(message)

func _get_active_player_units() -> Array[CombatUnit]:
    var active: Array[CombatUnit] = []
    for unit in player_units:
        if not unit.is_fainted():
            active.append(unit)
    return active

func _get_active_enemy_units() -> Array[CombatUnit] =:
    var active: Array[CombatUnit] = []
    for unit in enemy_units:
        if not unit.is_fainted():
            active.append(unit)
    return active

func get_phase_time_remaining() -> float:
    return phase_time_remaining

func get_player_units() -> Array[CombatUnit]:
    return player_units

func get_enemy_units() -> Array[CombatUnit]:
    return enemy_units

func is_active() -> bool:
    return is_combat_active

func get_current_phase() -> CombatPhase:
    return current_phase

func get_pending_commands() -> Array[CombatCommand]:
    return pending_commands

func has_unit_command(unit_uuid: String) -> bool:
    for cmd in pending_commands:
        if cmd.actor.uuid == unit_uuid:
            return true
    return false
```

## 4.2 CommandManager (指令管理器)

```gdscript
# scripts/combat/CommandManager.gd
class_name CommandManager
extends RefCounted

var _commands: Dictionary = {}

func set_command(unit_uuid: String, command: CombatCommand) -> void:
    _commands[unit_uuid] = command

func get_command(unit_uuid: String) -> CombatCommand:
    return _commands.get(unit_uuid, null)

func has_command(unit_uuid: String) -> bool:
    return _commands.has(unit_uuid)

func clear_commands() -> void:
    _commands.clear()

func get_all_commands() -> Array[CombatCommand]:
    var result: Array[CombatCommand] = []
    for cmd in _commands.values():
        result.append(cmd)
    return result

func get_commands_by_type(type: CombatCommand.CommandType) -> Array[CombatCommand]:
    var result: Array[CombatCommand] = []
    for cmd in _commands.values():
        if cmd.command_type == type:
            result.append(cmd)
    return result

func is_all_units_commanded(units: Array[CombatUnit]) -> bool:
    for unit in units:
        if not unit.is_fainted() and not _commands.has(unit.uuid):
            return false
    return true
```

## 4.3 DamageCalculator (伤害计算器)

```gdscript
# scripts/combat/DamageCalculator.gd
class_name DamageCalculator
extends RefCounted

static var element_chart: Dictionary = {
    Enums.Element.FIRE: {
        "strong_against": [Enums.Element.GRASS, Enums.Element.BUG],
        "weak_against": [Enums.Element.WATER],
        "immune_to": []
    },
    Enums.Element.WATER: {
        "strong_against": [Enums.Element.FIRE],
        "weak_against": [Enums.Element.GRASS, Enums.Element.ELECTRIC],
        "immune_to": []
    },
    Enums.Element.GRASS: {
        "strong_against": [Enums.Element.WATER],
        "weak_against": [Enums.Element.FIRE, Enums.Element.BUG],
        "immune_to": []
    },
    Enums.Element.ELECTRIC: {
        "strong_against": [Enums.Element.WATER],
        "weak_against": [],
        "immune_to": []
    },
    Enums.Element.BUG: {
        "strong_against": [Enums.Element.GRASS],
        "weak_against": [Enums.Element.FIRE],
        "immune_to": []
    },
    Enums.Element.STEEL: {
        "strong_against": [],
        "weak_against": [Enums.Element.FIRE],
        "immune_to": []
    }
}

static func calculate_damage(attacker: CombatUnit, defender: CombatUnit, skill: SkillData) -> DamageResult:
    var result := DamageResult.new()
    
    result.attacker = attacker
    result.defender = defender
    result.skill = skill
    
    result.element_modifier = get_element_modifier(skill.element, defender.element)
    result.is_critical = _check_critical()
    
    var level := float(attacker.level)
    var power := float(skill.power)
    var atk := float(attacker.get_effective_atk())
    var def := float(defender.get_effective_def())
    
    var base_damage := (level / 5.0 + 1.0) * (power * atk) / (def * 2.0)
    
    var final_damage := base_damage * result.element_modifier
    
    if result.is_critical:
        final_damage *= 1.5
    
    result.base_damage = int(base_damage)
    result.final_damage = maxi(1, int(final_damage))
    
    return result

static func get_element_modifier(attack_element: Enums.Element, defense_element: Enums.Element) -> float:
    var chart := element_chart.get(attack_element, {})
    
    var strong_against: Array = chart.get("strong_against", [])
    var weak_against: Array = chart.get("weak_against", [])
    
    if defense_element in strong_against:
        return 2.0
    elif defense_element in weak_against:
        return 0.5
    
    return 1.0

static func _check_critical() -> bool:
    return randf() < 0.0625

static func get_element_relationship_text(attack_element: Enums.Element, defense_element: Enums.Element) -> String:
    var modifier := get_element_modifier(attack_element, defense_element)
    
    if modifier > 1.0:
        return "效果拔群！"
    elif modifier < 1.0:
        return "效果不佳..."
    
    return ""

class DamageResult:
    extends RefCounted
    
    var attacker: CombatUnit = null
    var defender: CombatUnit = null
    var skill: SkillData = null
    var base_damage: int = 0
    var final_damage: int = 0
    var element_modifier: float = 1.0
    var is_critical: bool = false
```

## 4.4 CaptureManager (捕获管理器)

```gdscript
# scripts/combat/CaptureManager.gd
class_name CaptureManager
extends RefCounted

const BASE_CAPTURE_RATE := 0.40
const WEAKEN_BONUS := 0.20
const LOW_HP_BONUS := 0.15

static func attempt_capture(target: CombatUnit, module_id: String = "") -> CaptureResult:
    var result := CaptureResult.new()
    result.target = target
    
    var capture_rate := BASE_CAPTURE_RATE
    
    if target.is_weakened:
        capture_rate += WEAKEN_BONUS
        result.modifiers.append("虚弱状态: +20%")
    
    var hp_percent := target.get_hp_percent()
    if hp_percent < 0.3:
        capture_rate += LOW_HP_BONUS * (1.0 - hp_percent / 0.3)
        result.modifiers.append("低血量: +%.0f%%" % (LOW_HP_BONUS * 100 * (1.0 - hp_percent / 0.3)))
    
    capture_rate = mini(capture_rate, 0.95)
    result.final_rate = capture_rate
    
    var roll := randf()
    result.roll_value = roll
    result.success = roll < capture_rate
    
    if result.success:
        result.captured_data = _create_captured_monster_data(target)
    
    return result

static func _create_captured_monster_data(target: CombatUnit) -> Dictionary:
    return {
        "uuid": "monster_%s" % str(Time.get_ticks_msec()),
        "species": _get_species_from_element(target.element),
        "display_name": target.display_name,
        "element": target.element,
        "level": target.level,
        "atk": target.base_atk,
        "def": target.base_def,
        "hp": target.current_hp,
        "max_hp": target.max_hp,
        "spd": target.base_spd,
        "skills": target.skills.map(func(s): return s.skill_id),
        "traits": target.traits.duplicate(),
        "captured_at": Time.get_datetime_string_from_system()
    }

static func _get_species_from_element(element: Enums.Element) -> String:
    match element:
        Enums.Element.FIRE: return "fire_slime"
        Enums.Element.WATER: return "water_slime"
        Enums.Element.GRASS: return "grass_slime"
        Enums.Element.ELECTRIC: return "electric_slime"
        Enums.Element.BUG: return "bug_slime"
        Enums.Element.STEEL: return "steel_slime"
    return "unknown_slime"

class CaptureResult:
    extends RefCounted
    
    var target: CombatUnit = null
    var success: bool = false
    var final_rate: float = 0.0
    var roll_value: float = 0.0
    var modifiers: Array[String] = []
    var captured_data: Dictionary = {}
```

## 4.5 StealManager (偷窃管理器)

```gdscript
# scripts/combat/StealManager.gd
class_name StealManager
extends RefCounted

const BASE_STEAL_RATE := 0.20
const ABANDONED_LAB_BONUS := 0.20
const WEAKEN_BONUS := 0.50
const MAX_STEAL_RATE := 0.90

const LOOT_TABLE: Array[Dictionary] = [
    {"item_id": "evolution_stone", "name": "进化石", "weight": 70},
    {"item_id": "gene_fragment", "name": "稀有基因碎片", "weight": 30}
]

static func attempt_steal(target: CombatUnit, module_id: String = "") -> StealResult:
    var result := StealResult.new()
    result.target = target
    
    var steal_rate := BASE_STEAL_RATE
    
    if module_id == "abandoned_lab":
        steal_rate += ABANDONED_LAB_BONUS
        result.modifiers.append("废弃研究所: +20%")
    
    if target.is_weakened:
        steal_rate += WEAKEN_BONUS
        result.modifiers.append("虚弱状态: +50%")
    
    steal_rate = mini(steal_rate, MAX_STEAL_RATE)
    result.final_rate = steal_rate
    
    var roll := randf()
    result.roll_value = roll
    result.success = roll < steal_rate
    
    if result.success:
        var loot := _select_loot()
        result.item_id = loot.item_id
        result.item_name = loot.name
        result.count = 1
    
    return result

static func _select_loot() -> Dictionary:
    var total_weight := 0
    for item in LOOT_TABLE:
        total_weight += item.weight
    
    var roll := randi() % total_weight
    var current_weight := 0
    
    for item in LOOT_TABLE:
        current_weight += item.weight
        if roll < current_weight:
            return item
    
    return LOOT_TABLE[0]

class StealResult:
    extends RefCounted
    
    var target: CombatUnit = null
    var success: bool = false
    var final_rate: float = 0.0
    var roll_value: float = 0.0
    var modifiers: Array[String] = []
    var item_id: String = ""
    var item_name: String = ""
    var count: int = 0
```

## 4.6 CombatAI (战斗AI)

```gdscript
# scripts/combat/CombatAI.gd
class_name CombatAI
extends RefCounted

enum Difficulty { EASY, NORMAL, HARD }

static func select_action(enemy: CombatUnit, player_units: Array[CombatUnit], 
                          enemy_units: Array[CombatUnit]) -> Dictionary:
    var difficulty := _get_difficulty_for_enemy(enemy)
    
    match difficulty:
        Difficulty.EASY:
            return _easy_ai(enemy, player_units)
        Difficulty.NORMAL:
            return _normal_ai(enemy, player_units)
        Difficulty.HARD:
            return _hard_ai(enemy, player_units, enemy_units)
    
    return {"command_type": CombatCommand.CommandType.ATTACK, "target": player_units[0] if player_units.size() > 0 else null}

static func _get_difficulty_for_enemy(enemy: CombatUnit) -> Difficulty:
    if enemy.level >= 8:
        return Difficulty.HARD
    elif enemy.level >= 5:
        return Difficulty.NORMAL
    return Difficulty.EASY

static func _easy_ai(enemy: CombatUnit, player_units: Array[CombatUnit]) -> Dictionary:
    var target := _select_random_target(player_units)
    return {
        "command_type": CombatCommand.CommandType.ATTACK,
        "target": target,
        "skill_index": -1
    }

static func _normal_ai(enemy: CombatUnit, player_units: Array[CombatUnit]) -> Dictionary:
    var target := _select_lowest_hp_target(player_units)
    
    if enemy.skills.size() > 0 and randf() < 0.4:
        var usable_skills := enemy.skills.filter(func(s): return s.can_use())
        if usable_skills.size() > 0:
            return {
                "command_type": CombatCommand.CommandType.SKILL,
                "target": target,
                "skill_index": enemy.skills.find(usable_skills[randi() % usable_skills.size()])
            }
    
    return {
        "command_type": CombatCommand.CommandType.ATTACK,
        "target": target,
        "skill_index": -1
    }

static func _hard_ai(enemy: CombatUnit, player_units: Array[CombatUnit], 
                     enemy_units: Array[CombatUnit]) -> Dictionary:
    var best_target: CombatUnit = null
    var best_score: float = -1.0
    
    for player in player_units:
        if player.is_fainted():
            continue
        
        var score := _calculate_target_score(enemy, player)
        if score > best_score:
            best_score = score
            best_target = player
    
    if best_target == null:
        best_target = player_units[0]
    
    var best_skill_index := -1
    var best_damage := 0
    
    for i in range(enemy.skills.size()):
        var skill := enemy.skills[i]
        if skill.can_use():
            var damage_result := DamageCalculator.calculate_damage(enemy, best_target, skill)
            var effective_damage := damage_result.final_damage * damage_result.element_modifier
            if effective_damage > best_damage:
                best_damage = effective_damage
                best_skill_index = i
    
    if best_skill_index >= 0 and best_damage > enemy.get_effective_atk():
        return {
            "command_type": CombatCommand.CommandType.SKILL,
            "target": best_target,
            "skill_index": best_skill_index
        }
    
    return {
        "command_type": CombatCommand.CommandType.ATTACK,
        "target": best_target,
        "skill_index": -1
    }

static func _calculate_target_score(attacker: CombatUnit, target: CombatUnit) -> float:
    var score := 0.0
    
    score += (1.0 - target.get_hp_percent()) * 100
    
    var element_modifier := DamageCalculator.get_element_modifier(attacker.element, target.element)
    score += element_modifier * 50
    
    if target.get_effective_spd() > attacker.get_effective_spd():
        score += 20
    
    return score

static func _select_random_target(units: Array[CombatUnit]) -> CombatUnit:
    var active := units.filter(func(u): return not u.is_fainted())
    if active.is_empty():
        return null
    return active[randi() % active.size()]

static func _select_lowest_hp_target(units: Array[CombatUnit]) -> CombatUnit:
    var active := units.filter(func(u): return not u.is_fainted())
    if active.is_empty():
        return null
    
    var lowest: CombatUnit = active[0]
    for unit in active:
        if unit.current_hp < lowest.current_hp:
            lowest = unit
    return lowest
```

---

# 五、战斗UI实现

## 5.1 CombatUIManager (战斗UI管理器)

```gdscript
# scripts/ui/CombatUIManager.gd
class_name CombatUIManager
extends Control

signal command_set(unit_uuid: String, command_type: int, target_uuid: String, skill_index: int)
signal all_commands_confirmed

@onready var enemy_slots: Array[Node] = [
    $BattleField/EnemySide/EnemySlot1,
    $BattleField/EnemySide/EnemySlot2,
    $BattleField/EnemySide/EnemySlot3,
    $BattleField/EnemySide/EnemySlot4,
    $BattleField/EnemySide/EnemySlot5
]

@onready var player_slots: Array[Node] = [
    $BattleField/PlayerSide/PlayerSlot1,
    $BattleField/PlayerSide/PlayerSlot2,
    $BattleField/PlayerSide/PlayerSlot3
]

@onready var turn_order_icons: HBoxContainer = $TurnOrderPanel/TurnOrderIcons
@onready var unit_selector: TabContainer = $CommandPanel/UnitSelector
@onready var skill_panel: VBoxContainer = $CommandPanel/SkillPanel
@onready var target_select_panel: VBoxContainer = $CommandPanel/TargetSelectPanel
@onready var confirm_button: Button = $CommandPanel/ConfirmButton

@onready var turn_label: Label = $TurnIndicator/TurnLabel
@onready var phase_label: Label = $TurnIndicator/PhaseLabel
@onready var timer_bar: ProgressBar = $TurnIndicator/TimerBar
@onready var log_container: VBoxContainer = $CombatLog/LogContainer
@onready var result_panel: Control = $ResultPanel

var combat_manager: CombatManager = null
var current_selected_unit: CombatUnit = null
var current_command_type: CombatCommand.CommandType = CombatCommand.CommandType.ATTACK
var pending_skill_index: int = -1

func _ready():
    _connect_signals()

func initialize(manager: CombatManager) -> void:
    combat_manager = manager
    
    combat_manager.combat_started.connect(_on_combat_started)
    combat_manager.turn_phase_changed.connect(_on_turn_phase_changed)
    combat_manager.command_phase_started.connect(_on_command_phase_started)
    combat_manager.execution_phase_started.connect(_on_execution_phase_started)
    combat_manager.command_executed.connect(_on_command_executed)
    combat_manager.hp_changed.connect(_on_hp_changed)
    combat_manager.status_applied.connect(_on_status_applied)
    combat_manager.log_message.connect(_on_log_message)
    combat_manager.combat_ended.connect(_on_combat_ended)
    combat_manager.unit_fainted.connect(_on_unit_fainted)

func _connect_signals() -> void:
    confirm_button.pressed.connect(_on_confirm_pressed)

func _on_combat_started(enemy_data_list: Array[Dictionary]) -> void:
    _initialize_unit_slots()
    _update_all_unit_displays()
    
    result_panel.visible = false

func _initialize_unit_slots() -> void:
    var player_units := combat_manager.get_player_units()
    var enemy_units := combat_manager.get_enemy_units()
    
    for i in range(player_slots.size()):
        if i < player_units.size():
            _setup_player_slot(player_slots[i], player_units[i])
        else:
            player_slots[i].visible = false
    
    for i in range(enemy_slots.size()):
        if i < enemy_units.size():
            _setup_enemy_slot(enemy_slots[i], enemy_units[i])
        else:
            enemy_slots[i].visible = false
    
    _setup_unit_selector_tabs(player_units)

func _setup_player_slot(slot: Node, unit: CombatUnit) -> void:
    slot.visible = true
    slot.set_meta("unit_uuid", unit.uuid)
    
    var name_label: Label = slot.get_node("PlayerStatus/PlayerName")
    var level_label: Label = slot.get_node("PlayerStatus/PlayerLevel")
    var hp_bar: ProgressBar = slot.get_node("PlayerStatus/PlayerHPBar")
    var spd_label: Label = slot.get_node("PlayerStatus/PlayerSPD")
    
    name_label.text = unit.display_name
    level_label.text = "Lv.%d" % unit.level
    hp_bar.value = unit.get_hp_percent() * 100
    spd_label.text = "SPD:%d" % unit.base_spd

func _setup_enemy_slot(slot: Node, unit: CombatUnit) -> void:
    slot.visible = true
    slot.set_meta("unit_uuid", unit.uuid)
    
    var name_label: Label = slot.get_node("EnemyStatus/EnemyName")
    var level_label: Label = slot.get_node("EnemyStatus/EnemyLevel")
    var hp_bar: ProgressBar = slot.get_node("EnemyStatus/EnemyHPBar")
    var spd_label: Label = slot.get_node("EnemyStatus/EnemySPD")
    
    name_label.text = unit.display_name
    level_label.text = "Lv.%d" % unit.level
    hp_bar.value = unit.get_hp_percent() * 100
    spd_label.text = "SPD:%d" % unit.base_spd

func _setup_unit_selector_tabs(player_units: Array[CombatUnit]) -> void:
    for child in unit_selector.get_children():
        child.queue_free()
    
    for i in range(player_units.size()):
        var unit := player_units[i]
        var tab := _create_unit_tab(unit, i)
        unit_selector.add_child(tab)
        unit_selector.set_tab_title(i, unit.display_name)

func _create_unit_tab(unit: CombatUnit, index: int) -> VBoxContainer:
    var tab := VBoxContainer.new()
    tab.set_meta("unit_uuid", unit.uuid)
    
    var status_label := Label.new()
    status_label.text = "HP: %d/%d | SPD: %d" % [unit.current_hp, unit.max_hp, unit.base_spd]
    tab.add_child(status_label)
    
    var buttons := GridContainer.new()
    buttons.columns = 3
    
    var attack_btn := Button.new()
    attack_btn.text = "攻击"
    attack_btn.pressed.connect(_on_attack_button_pressed.bind(unit.uuid))
    buttons.add_child(attack_btn)
    
    var skill_btn := Button.new()
    skill_btn.text = "技能"
    skill_btn.pressed.connect(_on_skill_button_pressed.bind(unit.uuid))
    buttons.add_child(skill_btn)
    
    var defend_btn := Button.new()
    defend_btn.text = "防御"
    defend_btn.pressed.connect(_on_defend_button_pressed.bind(unit.uuid))
    buttons.add_child(defend_btn)
    
    var capture_btn := Button.new()
    capture_btn.text = "捕获"
    capture_btn.pressed.connect(_on_capture_button_pressed.bind(unit.uuid))
    buttons.add_child(capture_btn)
    
    var steal_btn := Button.new()
    steal_btn.text = "偷窃"
    steal_btn.pressed.connect(_on_steal_button_pressed.bind(unit.uuid))
    buttons.add_child(steal_btn)
    
    tab.add_child(buttons)
    
    var command_status := Label.new()
    command_status.name = "CommandStatus"
    command_status.text = "[待设定]"
    tab.add_child(command_status)
    
    return tab

func _on_turn_phase_changed(phase: String) -> void:
    match phase:
        "command_input":
            phase_label.text = "指令输入阶段"
            _set_command_panel_enabled(true)
        "execution":
            phase_label.text = "执行阶段"
            _set_command_panel_enabled(false)
        _:
            phase_label.text = phase

func _on_command_phase_started(player_units: Array[CombatUnit]) -> void:
    turn_label.text = "回合 %d" % combat_manager.current_turn
    
    _update_all_unit_displays()
    _update_turn_order_display()
    _reset_command_status()

func _on_execution_phase_started(turn_order: Array[CombatUnit]) -> void:
    _update_turn_order_display()
    _highlight_current_unit(null)

func _on_command_executed(command: CombatCommand, result: CommandResult) -> void:
    _update_all_unit_displays()
    _highlight_current_unit(command.actor)

func _on_hp_changed(unit: CombatUnit, old_hp: int, new_hp: int) -> void:
    _update_unit_display(unit)

func _on_status_applied(unit: CombatUnit, status: String) -> void:
    _update_unit_display(unit)

func _on_log_message(message: String) -> void:
    var log_entry := Label.new()
    log_entry.text = "> " + message
    log_entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    log_container.add_child(log_entry)
    
    await get_tree().process_frame
    var scroll := log_container.get_parent() as ScrollContainer
    scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _on_combat_ended(result: CombatResult) -> void:
    _set_command_panel_enabled(false)
    
    await get_tree().create_timer(0.5).timeout
    
    match result.result_type:
        CombatResult.ResultType.VICTORY, CombatResult.ResultType.CAPTURED:
            _show_victory_panel(result)
        CombatResult.ResultType.DEFEAT:
            _show_defeat_panel()

func _on_unit_fainted(unit: CombatUnit) -> void:
    _update_unit_display(unit)
    _animate_faint(unit)

func _on_attack_button_pressed(unit_uuid: String) -> void:
    current_selected_unit = _find_unit_by_uuid(unit_uuid)
    current_command_type = CombatCommand.CommandType.ATTACK
    _show_target_selection()

func _on_skill_button_pressed(unit_uuid: String) -> void:
    current_selected_unit = _find_unit_by_uuid(unit_uuid)
    _show_skill_selection(unit_uuid)

func _on_defend_button_pressed(unit_uuid: String) -> void:
    combat_manager.set_unit_command(unit_uuid, CombatCommand.CommandType.DEFEND)
    _update_command_status(unit_uuid, "防御")

func _on_capture_button_pressed(unit_uuid: String) -> void:
    current_selected_unit = _find_unit_by_uuid(unit_uuid)
    current_command_type = CombatCommand.CommandType.CAPTURE
    _show_target_selection()

func _on_steal_button_pressed(unit_uuid: String) -> void:
    current_selected_unit = _find_unit_by_uuid(unit_uuid)
    current_command_type = CombatCommand.CommandType.STEAL
    _show_target_selection()

func _show_target_selection() -> void:
    target_select_panel.visible = true
    skill_panel.visible = false
    
    for child in target_select_panel.get_node("TargetList").get_children():
        child.queue_free()
    
    var enemy_units := combat_manager.get_enemy_units()
    var target_list := target_select_panel.get_node("TargetList")
    
    for enemy in enemy_units:
        if not enemy.is_fainted():
            var btn := Button.new()
            btn.text = "%s (HP:%d%%)" % [enemy.display_name, int(enemy.get_hp_percent() * 100)]
            btn.pressed.connect(_on_target_selected.bind(enemy.uuid))
            target_list.add_child(btn)

func _on_target_selected(target_uuid: String) -> void:
    target_select_panel.visible = false
    
    if current_selected_unit != null:
        combat_manager.set_unit_command(
            current_selected_unit.uuid, 
            current_command_type, 
            target_uuid, 
            pending_skill_index
        )
        _update_command_status(current_selected_unit.uuid, _get_command_name(current_command_type))
        pending_skill_index = -1

func _show_skill_selection(unit_uuid: String) -> void:
    skill_panel.visible = true
    target_select_panel.visible = false
    
    var unit := _find_unit_by_uuid(unit_uuid)
    if unit == null:
        return
    
    for child in skill_panel.get_node("SkillList").get_children():
        child.queue_free()
    
    var skill_list := skill_panel.get_node("SkillList")
    
    for i in range(unit.skills.size()):
        var skill := unit.skills[i]
        var btn := Button.new()
        btn.text = "%s (PP:%d/%d)" % [skill.display_name, skill.current_pp, skill.pp]
        btn.disabled = not skill.can_use()
        btn.pressed.connect(_on_skill_selected.bind(i))
        skill_list.add_child(btn)

func _on_skill_selected(skill_index: int) -> void:
    skill_panel.visible = false
    pending_skill_index = skill_index
    current_command_type = CombatCommand.CommandType.SKILL
    _show_target_selection()

func _on_confirm_pressed() -> void:
    combat_manager.confirm_all_commands()

func _update_all_unit_displays() -> void:
    for unit in combat_manager.get_player_units():
        _update_unit_display(unit)
    for unit in combat_manager.get_enemy_units():
        _update_unit_display(unit)

func _update_unit_display(unit: CombatUnit) -> void:
    var slot: Node = null
    
    if unit.unit_type == CombatUnit.UnitType.PLAYER:
        var idx := unit.slot_index
        if idx >= 0 and idx < player_slots.size():
            slot = player_slots[idx]
    else:
        var idx := unit.slot_index
        if idx >= 0 and idx < enemy_slots.size():
            slot = enemy_slots[idx]
    
    if slot == null:
        return
    
    var hp_bar: ProgressBar
    if unit.unit_type == CombatUnit.UnitType.PLAYER:
        hp_bar = slot.get_node("PlayerStatus/PlayerHPBar")
    else:
        hp_bar = slot.get_node("EnemyStatus/EnemyHPBar")
    
    hp_bar.value = unit.get_hp_percent() * 100
    
    if unit.is_fainted():
        slot.modulate = Color(0.5, 0.5, 0.5, 1.0)

func _update_turn_order_display() -> void:
    for child in turn_order_icons.get_children():
        child.queue_free()
    
    var all_units: Array[CombatUnit] = []
    all_units.append_array(combat_manager.get_player_units())
    all_units.append_array(combat_manager.get_enemy_units())
    
    var active := all_units.filter(func(u): return not u.is_fainted())
    active.sort_custom(func(a, b): return a.get_effective_spd() > b.get_effective_spd())
    
    for unit in active:
        var icon := TextureRect.new()
        icon.custom_minimum_size = Vector2(32, 32)
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.tooltip_text = "%s (SPD:%d)" % [unit.display_name, unit.get_effective_spd()]
        turn_order_icons.add_child(icon)

func _reset_command_status() -> void:
    for tab in unit_selector.get_children():
        var status_label: Label = tab.get_node_or_null("CommandStatus")
        if status_label:
            status_label.text = "[待设定]"

func _update_command_status(unit_uuid: String, command_name: String) -> void:
    for tab in unit_selector.get_children():
        if tab.get_meta("unit_uuid", "") == unit_uuid:
            var status_label: Label = tab.get_node_or_null("CommandStatus")
            if status_label:
                status_label.text = "[已设定: %s]" % command_name
            break

func _highlight_current_unit(unit: CombatUnit) -> void:
    pass

func _set_command_panel_enabled(enabled: bool) -> void:
    confirm_button.disabled = not enabled

func _find_unit_by_uuid(uuid: String) -> CombatUnit:
    for unit in combat_manager.get_player_units():
        if unit.uuid == uuid:
            return unit
    for unit in combat_manager.get_enemy_units():
        if unit.uuid == uuid:
            return unit
    return null

func _get_command_name(cmd_type: CombatCommand.CommandType) -> String:
    match cmd_type:
        CombatCommand.CommandType.ATTACK: return "攻击"
        CombatCommand.CommandType.SKILL: return "技能"
        CombatCommand.CommandType.CAPTURE: return "捕获"
        CombatCommand.CommandType.STEAL: return "偷窃"
        CombatCommand.CommandType.DEFEND: return "防御"
    return "未知"

func _animate_faint(unit: CombatUnit) -> void:
    pass

func _show_victory_panel(result: CombatResult) -> void:
    result_panel.visible = true

func _show_defeat_panel() -> void:
    result_panel.visible = true

func _process(delta):
    if combat_manager != null and combat_manager.is_active():
        timer_bar.value = combat_manager.get_phase_time_remaining() / CombatManager.COMMAND_TIME_LIMIT * 100
```

---

# 六、战斗流程设计

## 6.1 完整多V多战斗流程

```
┌─────────────────────────────────────────────────────────────┐
│                   多V多战斗流程 v2.0                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 战斗触发                                                 │
│     │                                                       │
│     ▼                                                       │
│  2. 初始化战斗单位                                           │
│     │                                                       │
│     ├─────► 加载玩家队伍（最多3只精灵）                       │
│     │                                                       │
│     └─────► 生成敌方队伍（1-5只精灵）                        │
│              │                                              │
│              ▼                                              │
│         3. 战斗开始                                          │
│              │                                              │
│              ▼                                              │
│    ┌─────────────────────────────────┐                      │
│    │         回合循环                 │                      │
│    │  ┌─────────────────────────────┐│                      │
│    │  │ 4. 回合开始                  ││                      │
│    │  │    ├─ 重置单位状态           ││                      │
│    │  │    ├─ 处理持续效果           ││                      │
│    │  │    └─ 进入指令输入阶段       ││                      │
│    │  └─────────────────────────────┘│                      │
│    │                │                │                      │
│    │                ▼                │                      │
│    │  ┌─────────────────────────────┐│                      │
│    │  │ 5. 指令输入阶段              ││                      │
│    │  │    ├─ 玩家为所有存活单位     ││                      │
│    │  │    │   设定行动指令          ││                      │
│    │  │    │   ├─ 攻击+目标         ││                      │
│    │  │    │   ├─ 技能+目标         ││                      │
│    │  │    │   ├─ 捕获+目标         ││                      │
│    │  │    │   ├─ 偷窃+目标         ││                      │
│    │  │    │   └─ 防御              ││                      │
│    │  │    ├─ 敌方AI设定指令        ││                      │
│    │  │    └─ 确认所有指令          ││                      │
│    │  └─────────────────────────────┘│                      │
│    │                │                │                      │
│    │                ▼                │                      │
│    │  ┌─────────────────────────────┐│                      │
│    │  │ 6. 执行阶段                  ││                      │
│    │  │    ├─ 按速度排序所有单位     ││                      │
│    │  │    ├─ 依次执行指令           ││                      │
│    │  │    │   ├─ 检查行动者存活     ││                      │
│    │  │    │   ├─ 检查目标有效       ││                      │
│    │  │    │   ├─ 执行行动           ││                      │
│    │  │    │   ├─ 检查破绽触发       ││                      │
│    │  │    │   └─ 检查战斗结束       ││                      │
│    │  │    └─ 所有指令执行完毕       ││                      │
│    │  └─────────────────────────────┘│                      │
│    │                │                │                      │
│    │                ▼                │                      │
│    │  ┌─────────────────────────────┐│                      │
│    │  │ 7. 回合结束                  ││                      │
│    │  │    ├─ 检查倒下单位           ││                      │
│    │  │    └─ 检查战斗结束条件       ││                      │
│    │  └─────────────────────────────┘│                      │
│    └────────────────┼────────────────┘                      │
│                     │                                       │
│                     ▼                                       │
│              6. 战斗结束                                     │
│                     │                                       │
│                     ├─ 胜利 ──► 发放奖励                     │
│                     │                                       │
│                     ├─ 捕获 ──► 保存精灵                     │
│                     │                                       │
│                     └─ 失败 ──► 返回准备界面                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 6.2 速度排序行动顺序

```
┌─────────────────────────────────────────────────────────────┐
│                   速度排序行动顺序                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  输入: 所有存活单位列表                                      │
│     │                                                       │
│     ▼                                                       │
│  1. 过滤存活单位                                             │
│     │                                                       │
│     │  active_units = units.filter(u => !u.is_fainted())   │
│     │                                                       │
│     ▼                                                       │
│  2. 计算有效速度                                             │
│     │                                                       │
│     │  effective_spd = base_spd × 状态修正                  │
│     │  - 虚弱状态: SPD × 0.9                                │
│     │  - 其他状态效果...                                    │
│     │                                                       │
│     ▼                                                       │
│  3. 按速度降序排序                                           │
│     │                                                       │
│     │  sort_custom((a, b) => a.spd > b.spd)                │
│     │                                                       │
│     ├─ 速度相同 ──► 随机决定顺序                            │
│     │                                                       │
│     ▼                                                       │
│  4. 生成行动顺序列表                                         │
│     │                                                       │
│     │  turn_order = [UnitA, UnitB, UnitC, ...]             │
│     │                                                       │
│     ▼                                                       │
│  输出: 按速度排序的行动顺序                                  │
│                                                             │
│  示例:                                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 火精灵 (SPD:35) → 电鼠 (SPD:28) → 水蛇 (SPD:30)      │   │
│  │ → 草苗龟 (SPD:20) → 敌方A (SPD:25)                   │   │
│  │                                                      │   │
│  │ 行动顺序: 火精灵 → 水蛇 → 敌方A → 电鼠 → 草苗龟      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 6.3 指令输入流程

```
┌─────────────────────────────────────────────────────────────┐
│                   指令输入流程                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 进入指令输入阶段                                         │
│     │                                                       │
│     ▼                                                       │
│  2. 显示所有存活玩家单位                                     │
│     │                                                       │
│     │  ┌─────────┐  ┌─────────┐  ┌─────────┐              │
│     │  │ 单位A   │  │ 单位B   │  │ 单位C   │              │
│     │  │ [待设定]│  │ [待设定]│  │ [待设定]│              │
│     │  └─────────┘  └─────────┘  └─────────┘              │
│     │                                                       │
│     ▼                                                       │
│  3. 玩家选择单位并设定指令                                   │
│     │                                                       │
│     ├─ 选择单位A ──► 选择行动类型 ──► 选择目标              │
│     │                    │                                  │
│     │                    ├─ 攻击 ──► 选择敌方目标           │
│     │                    ├─ 技能 ──► 选择技能 → 选择目标    │
│     │                    ├─ 捕获 ──► 选择敌方目标           │
│     │                    ├─ 偷窃 ──► 选择敌方目标           │
│     │                    └─ 防御 ──► 无需目标               │
│     │                                                       │
│     ▼                                                       │
│  4. 更新单位状态显示                                         │
│     │                                                       │
│     │  ┌─────────┐  ┌─────────┐  ┌─────────┐              │
│     │  │ 单位A   │  │ 单位B   │  │ 单位C   │              │
│     │  │[攻击→敌1]│  │ [待设定]│  │ [待设定]│              │
│     │  └─────────┘  └─────────┘  └─────────┘              │
│     │                                                       │
│     ▼                                                       │
│  5. 重复步骤3直到所有单位设定完毕                            │
│     │                                                       │
│     ▼                                                       │
│  6. 玩家点击"确认所有指令"                                   │
│     │                                                       │
│     ├─ 有未设定单位 ──► 自动填充（随机攻击）                 │
│     │                                                       │
│     ▼                                                       │
│  7. 进入执行阶段                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 6.4 伤害计算流程

```
┌─────────────────────────────────────────────────────────────┐
│                     伤害计算流程                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  输入: 攻击方、防御方、技能                                   │
│     │                                                       │
│     ▼                                                       │
│  1. 计算属性克制倍率                                         │
│     │                                                       │
│     ├─ 克制 ──► Modifiers = 2.0                             │
│     │                                                       │
│     ├─ 被克制 ──► Modifiers = 0.5                           │
│     │                                                       │
│     └─ 无克制 ──► Modifiers = 1.0                           │
│              │                                              │
│              ▼                                              │
│         2. 计算基础伤害                                      │
│              │                                              │
│              │  Damage = (Level/5 + 1) × (Power×ATK)/(DEF×2)│
│              │                                              │
│              ▼                                              │
│         3. 应用属性克制                                      │
│              │                                              │
│              │  Damage = Damage × Modifiers                 │
│              │                                              │
│              ▼                                              │
│         4. 检查暴击                                          │
│              │                                              │
│              ├─ 暴击(6.25%) ──► Damage × 1.5                │
│              │                                              │
│              └─ 未暴击 ──► 不变                              │
│                       │                                     │
│                       ▼                                     │
│                  5. 取整并确保最小值为1                       │
│                       │                                     │
│                       ▼                                     │
│                  输出: 最终伤害值                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

# 七、技能数据库

## 7.1 SkillDatabase (技能数据库)

```gdscript
# scripts/combat/SkillDatabase.gd
class_name SkillDatabase
extends RefCounted

static var _skills: Dictionary = {}
static var _initialized: bool = false

static func initialize() -> void:
    if _initialized:
        return
    
    _register_basic_skills()
    _register_elemental_skills()
    _register_status_skills()
    _initialized = true

static func _register_basic_skills() -> void:
    _register_skill({
        "skill_id": "tackle",
        "display_name": "撞击",
        "description": "用身体撞击敌人",
        "skill_type": SkillData.SkillType.PHYSICAL,
        "target_type": SkillData.TargetType.SINGLE_ENEMY,
        "power": 10,
        "element": Enums.Element.FIRE,
        "accuracy": 100,
        "pp": 35
    })
    
    _register_skill({
        "skill_id": "defend",
        "display_name": "防御",
        "description": "进入防御姿态，本回合防御力翻倍",
        "skill_type": SkillData.SkillType.STATUS,
        "target_type": SkillData.TargetType.SELF,
        "power": 0,
        "element": Enums.Element.FIRE,
        "accuracy": 100,
        "pp": 10
    })

static func _register_elemental_skills() -> void:
    _register_skill({
        "skill_id": "fireball",
        "display_name": "火球",
        "description": "发射火球攻击敌人",
        "skill_type": SkillData.SkillType.SPECIAL,
        "target_type": SkillData.TargetType.SINGLE_ENEMY,
        "power": 25,
        "element": Enums.Element.FIRE,
        "accuracy": 100,
        "pp": 15
    })
    
    _register_skill({
        "skill_id": "water_jet",
        "display_name": "水流喷射",
        "description": "喷射水流攻击敌人",
        "skill_type": SkillData.SkillType.SPECIAL,
        "target_type": SkillData.TargetType.SINGLE_ENEMY,
        "power": 25,
        "element": Enums.Element.WATER,
        "accuracy": 100,
        "pp": 15
    })
    
    _register_skill({
        "skill_id": "vine_whip",
        "display_name": "藤鞭",
        "description": "用藤鞭抽打敌人",
        "skill_type": SkillData.SkillType.PHYSICAL,
        "target_type": SkillData.TargetType.SINGLE_ENEMY,
        "power": 25,
        "element": Enums.Element.GRASS,
        "accuracy": 100,
        "pp": 15
    })
    
    _register_skill({
        "skill_id": "thunder_shock",
        "display_name": "电击",
        "description": "释放电流攻击敌人",
        "skill_type": SkillData.SkillType.SPECIAL,
        "target_type": SkillData.TargetType.SINGLE_ENEMY,
        "power": 25,
        "element": Enums.Element.ELECTRIC,
        "accuracy": 100,
        "pp": 15
    })

static func _register_status_skills() -> void:
    _register_skill({
        "skill_id": "quick_attack",
        "display_name": "先制攻击",
        "description": "速度优先的攻击",
        "skill_type": SkillData.SkillType.PHYSICAL,
        "target_type": SkillData.TargetType.SINGLE_ENEMY,
        "power": 15,
        "element": Enums.Element.FIRE,
        "accuracy": 100,
        "pp": 20,
        "priority": 1
    })

static func _register_skill(data: Dictionary) -> void:
    var skill := SkillData.new()
    skill.skill_id = data.get("skill_id", "")
    skill.display_name = data.get("display_name", "")
    skill.description = data.get("description", "")
    skill.skill_type = data.get("skill_type", SkillData.SkillType.PHYSICAL)
    skill.target_type = data.get("target_type", SkillData.TargetType.SINGLE_ENEMY)
    skill.power = data.get("power", 10)
    skill.element = data.get("element", Enums.Element.FIRE)
    skill.accuracy = data.get("accuracy", 100)
    skill.pp = data.get("pp", 10)
    skill.current_pp = skill.pp
    skill.priority = data.get("priority", 0)
    
    _skills[skill.skill_id] = skill

static func get_skill(skill_id: String) -> SkillData:
    if not _initialized:
        initialize()
    
    var skill := _skills.get(skill_id, null)
    if skill != null:
        return skill.duplicate()
    return null

static func get_all_skills() -> Array[SkillData]:
    if not _initialized:
        initialize()
    
    var result: Array[SkillData] = []
    for skill in _skills.values():
        result.append(skill.duplicate())
    return result
```

---

# 八、扩展预留

## 8.1 状态效果系统

```gdscript
# scripts/combat/StatusEffect.gd
class_name StatusEffect
extends RefCounted

enum EffectType { POISON, BURN, PARALYZE, FREEZE, SLEEP, SPEED_UP, SPEED_DOWN }

var effect_type: EffectType
var duration: int = 0
var damage_per_turn: int = 0
var stat_modifiers: Dictionary = {}

func _init(type: EffectType, dur: int = 3):
    effect_type = type
    duration = dur
    _setup_effect()

func _setup_effect() -> void:
    match effect_type:
        EffectType.POISON:
            damage_per_turn = 10
        EffectType.BURN:
            damage_per_turn = 5
            stat_modifiers["atk_modifier"] = 0.9
        EffectType.PARALYZE:
            stat_modifiers["spd_modifier"] = 0.5
        EffectType.SPEED_UP:
            stat_modifiers["spd_modifier"] = 1.5
        EffectType.SPEED_DOWN:
            stat_modifiers["spd_modifier"] = 0.7

func apply(unit: CombatUnit) -> void:
    for stat in stat_modifiers:
        unit.status_effects[effect_type_to_string()] = {
            "duration": duration,
            stat: stat_modifiers[stat]
        }

func tick(unit: CombatUnit) -> int:
    if damage_per_turn > 0:
        unit.take_damage(damage_per_turn)
    
    duration -= 1
    return duration

func is_expired() -> bool:
    return duration <= 0

func effect_type_to_string() -> String:
    match effect_type:
        EffectType.POISON: return "poison"
        EffectType.BURN: return "burn"
        EffectType.PARALYZE: return "paralyze"
        EffectType.FREEZE: return "freeze"
        EffectType.SLEEP: return "sleep"
        EffectType.SPEED_UP: return "speed_up"
        EffectType.SPEED_DOWN: return "speed_down"
    return "unknown"
```

## 8.2 战斗AI扩展

```gdscript
# 预留: 更智能的AI决策
class_name CombatAIAdvanced
extends RefCounted

static func select_action_with_strategy(enemy: CombatUnit, 
                                        player_units: Array[CombatUnit],
                                        enemy_units: Array[CombatUnit],
                                        turn_history: Array) -> Dictionary:
    var strategy := _determine_strategy(enemy, player_units, enemy_units)
    
    match strategy:
        "aggressive":
            return _aggressive_strategy(enemy, player_units)
        "defensive":
            return _defensive_strategy(enemy, player_units, enemy_units)
        "support":
            return _support_strategy(enemy, player_units, enemy_units)
        _:
            return CombatAI.select_action(enemy, player_units, enemy_units)

static func _determine_strategy(enemy: CombatUnit, 
                                player_units: Array[CombatUnit],
                                enemy_units: Array[CombatUnit]) -> String:
    var enemy_team_hp := 0.0
    var player_team_hp := 0.0
    
    for e in enemy_units:
        if not e.is_fainted():
            enemy_team_hp += e.get_hp_percent()
    
    for p in player_units:
        if not p.is_fainted():
            player_team_hp += p.get_hp_percent()
    
    if enemy_team_hp > player_team_hp * 1.5:
        return "aggressive"
    elif enemy_team_hp < player_team_hp * 0.7:
        return "defensive"
    
    return "balanced"

static func _aggressive_strategy(enemy: CombatUnit, player_units: Array[CombatUnit]) -> Dictionary:
    var lowest_hp_target: CombatUnit = null
    var lowest_hp := 999999
    
    for p in player_units:
        if not p.is_fainted() and p.current_hp < lowest_hp:
            lowest_hp = p.current_hp
            lowest_hp_target = p
    
    return {
        "command_type": CombatCommand.CommandType.ATTACK,
        "target": lowest_hp_target,
        "skill_index": -1
    }

static func _defensive_strategy(enemy: CombatUnit, 
                                player_units: Array[CombatUnit],
                                enemy_units: Array[CombatUnit]) -> Dictionary:
    if enemy.get_hp_percent() < 0.3:
        return {
            "command_type": CombatCommand.CommandType.DEFEND,
            "target": null,
            "skill_index": -1
        }
    
    return CombatAI.select_action(enemy, player_units, enemy_units)

static func _support_strategy(enemy: CombatUnit, 
                              player_units: Array[CombatUnit],
                              enemy_units: Array[CombatUnit]) -> Dictionary:
    return CombatAI.select_action(enemy, player_units, enemy_units)
```

---

# 附录：相关文件清单

| 文件路径 | 说明 |
|---------|------|
| `scripts/combat/CombatManager.gd` | 战斗管理器（多V多支持） |
| `scripts/combat/CombatUnit.gd` | 战斗单位数据类（含速度属性） |
| `scripts/combat/TurnOrderManager.gd` | 行动顺序管理器 |
| `scripts/combat/CommandManager.gd` | 指令管理器 |
| `scripts/combat/CombatCommand.gd` | 战斗指令类 |
| `scripts/combat/DamageCalculator.gd` | 伤害计算器 |
| `scripts/combat/CaptureManager.gd` | 捕获管理器 |
| `scripts/combat/StealManager.gd` | 偷窃管理器 |
| `scripts/combat/CombatAI.gd` | 战斗AI |
| `scripts/combat/SkillData.gd` | 技能数据类 |
| `scripts/combat/CombatResult.gd` | 战斗结果数据类 |
| `scripts/combat/SkillDatabase.gd` | 技能数据库 |
| `scripts/combat/StatusEffect.gd` | 状态效果类 |
| `scripts/ui/CombatUIManager.gd` | 战斗UI管理器 |
| `scenes/combat/CombatScene.tscn` | 战斗场景文件 |
| `resources/skills/*.tres` | 技能资源文件 |

---

# 附录：属性克制速查表

```
                    克制关系图
                    
         ┌─────────────────────────────┐
         │                             │
         ▼                             │
       ┌───┐                         ┌───┐
       │ 火 │ ──────────────────────►│ 草 │
       └───┘                         └───┘
         │                             │
         │                             ▼
         │                           ┌───┐
         │                           │ 虫 │
         │                           └───┘
         │                             │
         ▼                             │
       ┌───┐                         ┌───┐
       │ 水 │ ◄─────────────────────│ 电 │
       └───┘                         └───┘
         │                             │
         │                             │
         ▼                             │
       ┌───┐                           │
       │ 钢 │ ◄─────────────────────────┘
       └───┘
         
    克制倍率: 2.0x
    被克制倍率: 0.5x
    无克制关系: 1.0x
```

---

# 附录：版本更新日志

## v2.0 (2026-04-07)
- **重大更新**: 从1V1改为多V多战斗系统
- 新增速度属性(SPD)系统
- 新增TurnOrderManager行动顺序管理器
- 新增CommandManager指令管理器
- 新增CombatCommand战斗指令类
- 重构CombatManager支持多单位战斗
- 新增指令预输入系统
- 新增防御指令
- 更新UI支持多单位选择
- 新增行动顺序显示面板
- 更新战斗流程图

## v1.0 (初始版本)
- 基础1V1回合制战斗
- 伤害计算系统
- 捕获与偷窃机制
- 破绽（虚弱）系统