# Monster Loop - 游戏场景模块详细设计

> 模块版本：v1.0  
> 更新日期：2026-04-07  
> 依赖文档：[MonsterLoop_Demo_v2.md](./MonsterLoop_Demo_v2.md)

---

# 一、模块概述

## 1.1 功能定位

游戏场景模块是核心玩法的主战场，负责：
- 管理玩家角色的循环移动
- 处理地块模块的放置与消耗
- 监控BOSS觉醒进度
- 触发战斗与BOSS战
- 管理局内状态与数据同步

## 1.2 模块边界

| 职责范围 | 不包含 |
|---------|--------|
| 循环路径管理 | 战斗逻辑细节 |
| 地块放置系统 | 卡组构筑界面 |
| Charge消耗机制 | 精灵养成系统 |
| BOSS进度监控 | 结算界面 |
| 战斗触发判定 | 局外数据管理 |

## 1.3 系统架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                         游戏场景模块                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ PlayerSystem │  │  TileSystem  │  │  BossSystem  │              │
│  │  玩家系统     │  │  地块系统     │  │  BOSS系统    │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                 │                 │                      │
│         └────────────────┬┴─────────────────┘                      │
│                          │                                         │
│                          ▼                                         │
│                 ┌────────────────┐                                 │
│                 │  GameScene     │                                 │
│                 │  Manager       │                                 │
│                 └───────┬────────┘                                 │
│                         │                                          │
│         ┌───────────────┼───────────────┐                          │
│         │               │               │                          │
│         ▼               ▼               ▼                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                    │
│  │  EventBus  │  │SaveManager │  │GameManager │                    │
│  └────────────┘  └────────────┘  └────────────┘                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

# 二、场景结构设计

## 2.1 场景节点树

```
GameScene (Node2D)
├── YSort                                            # Y排序层
│   ├── Path2D (LoopPath)                           # 循环路径
│   │   └── PathFollow2D (PlayerFollow)             # 玩家跟随点
│   │       └── Player (CharacterBody2D)            # 玩家角色
│   │           ├── Sprite2D
│   │           ├── CollisionShape2D
│   │           └── AnimationPlayer
│   │
│   ├── TileContainer (Node2D)                      # 地块容器
│   │   └── [GridSlot × 10]                         # 10个格子节点
│   │       └── TileModuleInstance                  # 地块模块实例
│   │
│   └── BossSpawnPoint (Marker2D)                   # BOSS生成点
│
├── Background (ParallaxBackground)                  # 背景层
│   └── ParallaxLayer
│       └── Sprite2D
│
├── UI (CanvasLayer)
│   ├── TopBar (HBoxContainer)
│   │   ├── LoopCount (Label)
│   │   └── Inventory (HBoxContainer)
│   │       ├── PokeballCount (Label)
│   │       └── CurrencyCount (Label)
│   │
│   ├── BossProgress (VBoxContainer)
│   │   ├── ProgressLabel (Label)
│   │   └── ProgressBar (ProgressBar)
│   │
│   ├── HandUI (Control)
│   │   └── CardContainer (HBoxContainer)
│   │       └── [HandCardUI × 5]
│   │
│   ├── TilePlacementUI (Control)                   # 地块放置界面
│   │   ├── GridOverlay (Control)
│   │   └── PlacementPreview (Sprite2D)
│   │
│   └── PauseMenu (Control)
│       ├── PauseButton (Button)
│       └── PausePanel (Panel)
│
├── Managers (Node)
│   ├── GameSceneManager                             # 场景管理器
│   ├── PlayerController                             # 玩家控制器
│   ├── TilePlacementManager                         # 地块放置管理器
│   └── BossProgressManager                          # BOSS进度管理器
│
└── ObjectPools (Node)
    ├── TileModulePool                               # 地块模块对象池
    └── WastelandPool                                # 荒地对象池
```

## 2.2 核心节点配置

### 2.2.1 Path2D 配置

```gdscript
# Path2D 节点配置
# 名称: LoopPath
# 类型: Path2D

# 曲线设置 (Curve2D)
# 创建圆形路径，10个控制点
# 半径: 300像素
# 中心: 屏幕中心

func create_circular_path(radius: float, points: int) -> Curve2D:
    var curve := Curve2D.new()
    var center := get_viewport_rect().size / 2
    
    for i in range(points):
        var angle := TAU * i / points
        var point := center + Vector2(cos(angle), sin(angle)) * radius
        curve.add_point(point)
    
    curve.add_point(curve.get_point_position(0))
    return curve
```

### 2.2.2 PathFollow2D 配置

```gdscript
# PathFollow2D 节点配置
# 名称: PlayerFollow
# 类型: PathFollow2D

# 关键属性
rotation_mode = PathFollow2D.ROTATION_ORIENTED
uses_approximate_tangent = true
loop = true

# 移动参数
var move_speed: float = 150.0
```

### 2.2.3 碰撞层级配置

```
Collision Layer/Mask 配置:

Player (Layer 1):
  - Layer: 1 (Player)
  - Mask: 2, 3, 4 (TileModule, Enemy, Boss)

TileModule (Layer 2):
  - Layer: 2 (TileModule)
  - Mask: 1 (Player)

Enemy (Layer 3):
  - Layer: 3 (Enemy)
  - Mask: 1 (Player)

Boss (Layer 4):
  - Layer: 4 (Boss)
  - Mask: 1 (Player)
```

---

# 三、核心系统实现

## 3.1 GameSceneManager (场景管理器)

```gdscript
# scripts/scenes/GameSceneManager.gd
class_name GameSceneManager
extends Node

signal loop_completed(loop_count: int)
signal all_tiles_consumed
signal boss_spawn_requested

@export var path_radius: float = 300.0
@export var grid_count: int = 10
@export var move_speed: float = 150.0

@onready var loop_path: Path2D = $YSort/LoopPath
@onready var player_follow: PathFollow2D = $YSort/LoopPath/PlayerFollow
@onready var tile_container: Node2D = $YSort/TileContainer
@onready var boss_spawn_point: Marker2D = $YSort/BossSpawnPoint

var current_loop_count: int = 0
var is_game_active: bool = false
var is_boss_spawned: bool = false
var grid_slots: Array[GridSlot] = []

func _ready():
    _initialize_grid_slots()
    _connect_event_bus()
    _load_deck_to_hand()

func _process(delta):
    if not is_game_active or is_boss_spawned:
        return
    
    _update_player_movement(delta)
    _check_loop_completion()

func _initialize_grid_slots() -> void:
    var curve := loop_path.curve
    if curve == null:
        return
    
    var point_count := curve.point_count - 1
    
    for i in range(min(point_count, grid_count)):
        var slot := GridSlot.new()
        slot.slot_index = i
        slot.position = curve.get_point_position(i)
        slot.is_occupied = false
        grid_slots.append(slot)
        
        var marker := Marker2D.new()
        marker.position = slot.position
        marker.name = "GridSlot_%d" % i
        tile_container.add_child(marker)

func _connect_event_bus() -> void:
    EventBus.tile_placed.connect(_on_tile_placed)
    EventBus.tile_consumed.connect(_on_tile_consumed)
    EventBus.combat_triggered.connect(_on_combat_triggered)
    EventBus.boss_spawned.connect(_on_boss_spawned)

func _update_player_movement(delta: float) -> void:
    var path_length := loop_path.curve.get_baked_length()
    var move_distance := move_speed * delta
    
    player_follow.progress += move_distance
    
    if player_follow.progress >= path_length:
        player_follow.progress = 0.0
        _on_loop_completed()

func _check_loop_completion() -> void:
    if player_follow.progress_ratio >= 0.99:
        _on_loop_completed()

func _on_loop_completed() -> void:
    current_loop_count += 1
    loop_completed.emit(current_loop_count)
    EventBus.loop_completed.emit(current_loop_count)
    
    _reset_tile_triggers()
    _update_egg_progress()

func _reset_tile_triggers() -> void:
    for slot in grid_slots:
        if slot.module_instance != null:
            slot.module_instance.reset_loop_trigger()

func _update_egg_progress() -> void:
    var eggs: Array = SaveManager.get_data().get("eggs", [])
    for egg in eggs:
        egg.progress += 1
        if egg.progress >= egg.get("required_progress", 10):
            _hatch_egg(egg)
    SaveManager.mark_dirty()

func _hatch_egg(egg: Dictionary) -> void:
    var elements := [Enums.Element.FIRE, Enums.Element.WATER, Enums.Element.GRASS,
                     Enums.Element.ELECTRIC, Enums.Element.BUG]
    var random_element := elements[randi() % elements.size()]
    
    var new_monster := {
        "uuid": "monster_%s" % str(Time.get_ticks_msec()),
        "species": "%s_slime" % Enums.element_to_string(random_element).to_lower(),
        "element": random_element,
        "level": 5,
        "atk": 30,
        "def": 20,
        "hp": 100,
        "max_hp": 100,
        "skills": ["tackle", _get_element_skill(random_element)],
        "traits": []
    }
    
    var monsters: Array = SaveManager.get_data().get("monsters", [])
    monsters.append(new_monster)
    
    var eggs: Array = SaveManager.get_data().get("eggs", [])
    eggs.erase(egg)
    
    EventBus.monster_captured.emit(new_monster)
    EventBus.item_obtained.emit("new_monster", 1)

func _get_element_skill(element: Enums.Element) -> String:
    match element:
        Enums.Element.FIRE: return "flame_burst"
        Enums.Element.WATER: return "water_jet"
        Enums.Element.GRASS: return "vine_whip"
        Enums.Element.ELECTRIC: return "spark"
        Enums.Element.BUG: return "bug_bite"
    return "tackle"

func _on_tile_placed(module_id: String, grid_index: int) -> void:
    if grid_index < 0 or grid_index >= grid_slots.size():
        return
    
    var slot := grid_slots[grid_index]
    if slot.is_occupied:
        return
    
    var module_instance := TileModuleFactory.create_module(module_id)
    if module_instance == null:
        return
    
    module_instance.position = slot.position
    module_instance.grid_index = grid_index
    tile_container.add_child(module_instance)
    
    slot.module_instance = module_instance
    slot.is_occupied = true
    
    BossProgressManager.add_total_charge(module_instance.get_charge())

func _on_tile_consumed(module_id: String, grid_index: int, remaining_charge: int) -> void:
    if remaining_charge <= 0:
        var slot := grid_slots[grid_index]
        if slot.module_instance != null:
            slot.module_instance.on_disappear()
            slot.module_instance.queue_free()
            slot.module_instance = null
            slot.is_occupied = false
            
            _spawn_wasteland(slot.position)
    
    _check_all_tiles_consumed()

func _spawn_wasteland(position: Vector2) -> void:
    var wasteland := preload("res://scenes/tiles/Wasteland.tscn").instantiate()
    wasteland.position = position
    tile_container.add_child(wasteland)

func _check_all_tiles_consumed() -> void:
    for slot in grid_slots:
        if slot.module_instance != null and slot.module_instance.get_charge() > 0:
            return
    
    all_tiles_consumed.emit()
    _spawn_boss()

func _spawn_boss() -> void:
    if is_boss_spawned:
        return
    
    is_boss_spawned = true
    is_game_active = false
    
    var player_pos := player_follow.global_position
    boss_spawn_point.global_position = player_pos
    
    var boss := BossFactory.create_boss(SaveManager.get_data().player.current_tier)
    boss.position = boss_spawn_point.position
    tile_container.add_child(boss)
    
    EventBus.boss_spawned.emit(boss.get_boss_data())
    boss_spawn_requested.emit()

func _on_combat_triggered(module_id: String, enemy_data: Dictionary) -> void:
    is_game_active = false
    CombatManager.start_combat(enemy_data)

func _on_boss_spawned(boss_data: Dictionary) -> void:
    pass

func _load_deck_to_hand() -> void:
    var deck_data: Dictionary = SaveManager.get_data().get("deck", {})
    var cards: Array = deck_data.get("cards", [])
    
    var hand_cards: Array[String] = []
    for card_entry in cards:
        var module_id: String = card_entry.get("module_id", "")
        var count: int = card_entry.get("count", 1)
        for i in count:
            hand_cards.append(module_id)
    
    HandUIManager.set_hand_cards(hand_cards)

func pause_game() -> void:
    is_game_active = false
    get_tree().paused = true

func resume_game() -> void:
    is_game_active = true
    get_tree().paused = false

func get_grid_slot_at_position(position: Vector2) -> int:
    for i in range(grid_slots.size()):
        if grid_slots[i].position.distance_to(position) < 50.0:
            return i
    return -1

func get_nearest_empty_slot() -> int:
    var player_pos := player_follow.global_position
    
    var nearest_index := -1
    var nearest_distance := INF
    
    for i in range(grid_slots.size()):
        var slot := grid_slots[i]
        if not slot.is_occupied:
            var distance := slot.position.distance_to(player_pos)
            if distance < nearest_distance:
                nearest_distance = distance
                nearest_index = i
    
    return nearest_index
```

## 3.2 PlayerController (玩家控制器)

```gdscript
# scripts/scenes/PlayerController.gd
class_name PlayerController
extends CharacterBody2D

signal entered_tile(module_instance: BaseTileModule)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_module: BaseTileModule = null
var last_module_id: String = ""

func _ready():
    add_to_group("player")
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body is BaseTileModule:
        _handle_tile_collision(body)

func _handle_tile_collision(module: BaseTileModule) -> void:
    if module.has_triggered_this_loop:
        return
    
    current_module = module
    entered_tile.emit(module)
    
    _trigger_tile_effects(module)

func _trigger_tile_effects(module: BaseTileModule) -> void:
    module.on_player_enter(self)
    
    var remaining_charge := module.consume_charge()
    
    EventBus.tile_consumed.emit(
        module.get_module_id(),
        module.grid_index,
        remaining_charge
    )
    
    if remaining_charge <= 0:
        last_module_id = module.get_module_id()
    
    if _should_trigger_combat(module):
        _trigger_combat(module)

func _should_trigger_combat(module: BaseTileModule) -> bool:
    var probability := module.trigger_combat_probability()
    return randf() < probability

func _trigger_combat(module: BaseTileModule) -> void:
    var enemy_data := module.generate_monster()
    var tier: int = SaveManager.get_data().get("player", {}).get("current_tier", 0)
    
    enemy_data = _apply_tier_scaling(enemy_data, tier)
    
    EventBus.combat_triggered.emit(module.get_module_id(), enemy_data)

func _apply_tier_scaling(data: Dictionary, tier: int) -> Dictionary:
    var scaling := 1.0 + 0.2 * tier
    data["atk"] = int(data.get("atk", 30) * scaling)
    data["def"] = int(data.get("def", 20) * scaling)
    data["hp"] = int(data.get("hp", 100) * scaling)
    data["max_hp"] = data["hp"]
    return data

func play_animation(anim_name: String) -> void:
    if animation_player.has_animation(anim_name):
        animation_player.play(anim_name)

func set_visible_state(visible: bool) -> void:
    sprite.visible = visible
    collision.disabled = not visible
```

## 3.3 TilePlacementManager (地块放置管理器)

```gdscript
# scripts/scenes/TilePlacementManager.gd
class_name TilePlacementManager
extends Node

signal tile_placed(module_id: String, grid_index: int)
signal placement_cancelled

@onready var grid_overlay: Control = $"../UI/TilePlacementUI/GridOverlay"
@onready var placement_preview: Sprite2D = $"../UI/TilePlacementUI/PlacementPreview"

var is_placing: bool = false
var selected_card_index: int = -1
var selected_module_id: String = ""
var hand_cards: Array[String] = []

func _ready():
    _connect_hand_ui()
    _create_grid_overlay()

func _connect_hand_ui() -> void:
    HandUIManager.card_selected.connect(_on_card_selected)

func _create_grid_overlay() -> void:
    var grid_slots := GameSceneManager.grid_slots
    
    for i in range(grid_slots.size()):
        var slot_button := Button.new()
        slot_button.name = "SlotButton_%d" % i
        slot_button.custom_minimum_size = Vector2(64, 64)
        slot_button.pressed.connect(_on_slot_pressed.bind(i))
        
        var slot := grid_slots[i]
        var screen_pos := slot.position
        
        grid_overlay.add_child(slot_button)
        slot_button.position = screen_pos - Vector2(32, 32)

func _on_card_selected(card_index: int) -> void:
    if card_index < 0 or card_index >= hand_cards.size():
        return
    
    selected_card_index = card_index
    selected_module_id = hand_cards[card_index]
    is_placing = true
    
    _show_placement_preview()
    _highlight_available_slots()

func _show_placement_preview() -> void:
    var card_data := CardLibrary.get_card(selected_module_id)
    if card_data != null:
        placement_preview.texture = card_data.icon
        placement_preview.visible = true

func _highlight_available_slots() -> void:
    var grid_slots := GameSceneManager.grid_slots
    
    for i in range(grid_slots.size()):
        var slot_button := grid_overlay.get_node_or_null("SlotButton_%d" % i)
        if slot_button != null:
            var slot := grid_slots[i]
            if not slot.is_occupied:
                slot_button.modulate = Color(1.0, 1.0, 0.5, 0.8)
            else:
                slot_button.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _on_slot_pressed(slot_index: int) -> void:
    if not is_placing:
        return
    
    var grid_slots := GameSceneManager.grid_slots
    if slot_index < 0 or slot_index >= grid_slots.size():
        return
    
    var slot := grid_slots[slot_index]
    if slot.is_occupied:
        return
    
    _place_tile(slot_index)

func _place_tile(slot_index: int) -> void:
    tile_placed.emit(selected_module_id, slot_index)
    EventBus.tile_placed.emit(selected_module_id, slot_index)
    
    HandUIManager.remove_card(selected_card_index)
    hand_cards.remove_at(selected_card_index)
    
    _cancel_placement()

func _cancel_placement() -> void:
    is_placing = false
    selected_card_index = -1
    selected_module_id = ""
    placement_preview.visible = false
    
    _reset_slot_highlights()
    placement_cancelled.emit()

func _reset_slot_highlights() -> void:
    for child in grid_overlay.get_children():
        child.modulate = Color.WHITE

func set_hand_cards(cards: Array[String]) -> void:
    hand_cards = cards

func can_place_tile() -> bool:
    return hand_cards.size() > 0 and _has_empty_slot()

func _has_empty_slot() -> bool:
    for slot in GameSceneManager.grid_slots:
        if not slot.is_occupied:
            return true
    return false
```

## 3.4 BossProgressManager (BOSS进度管理器)

```gdscript
# scripts/scenes/BossProgressManager.gd
class_name BossProgressManager
extends Node

@onready var progress_bar: ProgressBar = $"../UI/BossProgress/ProgressBar"
@onready var progress_label: Label = $"../UI/BossProgress/ProgressLabel"

var total_charge: int = 0
var consumed_charge: int = 0

func _ready():
    _connect_event_bus()
    _update_ui()

func _connect_event_bus() -> void:
    EventBus.tile_placed.connect(_on_tile_placed)
    EventBus.tile_consumed.connect(_on_tile_consumed)

func add_total_charge(charge: int) -> void:
    total_charge += charge
    _update_ui()

func _on_tile_placed(module_id: String, grid_index: int) -> void:
    var module := TileModuleFactory.get_module_at_grid(grid_index)
    if module != null:
        add_total_charge(module.get_charge())

func _on_tile_consumed(module_id: String, grid_index: int, remaining_charge: int) -> void:
    consumed_charge += 1
    _update_ui()
    
    EventBus.boss_progress_updated.emit(consumed_charge, total_charge)
    
    if consumed_charge >= total_charge and total_charge > 0:
        _on_progress_complete()

func _on_progress_complete() -> void:
    progress_label.text = "BOSS觉醒！"
    progress_label.modulate = Color.RED

func _update_ui() -> void:
    if total_charge <= 0:
        progress_bar.value = 0
        progress_label.text = "放置地块开始游戏"
        return
    
    var progress := float(consumed_charge) / float(total_charge)
    progress_bar.value = progress * 100
    progress_label.text = "BOSS觉醒进度: %d/%d" % [consumed_charge, total_charge]

func reset() -> void:
    total_charge = 0
    consumed_charge = 0
    _update_ui()
```

---

# 四、数据结构设计

## 4.1 GridSlot (格子槽位)

```gdscript
# scripts/data/GridSlot.gd
class_name GridSlot
extends RefCounted

var slot_index: int = 0
var position: Vector2 = Vector2.ZERO
var is_occupied: bool = false
var module_instance: BaseTileModule = null

func is_empty() -> bool:
    return not is_occupied

func set_module(module: BaseTileModule) -> void:
    module_instance = module
    is_occupied = true

func clear_module() -> void:
    module_instance = null
    is_occupied = false

func get_module_id() -> String:
    if module_instance != null:
        return module_instance.get_module_id()
    return ""
```

## 4.2 RunState (局内状态)

```gdscript
# scripts/data/RunState.gd
class_name RunState
extends RefCounted

var loop_count: int = 0
var battles_won: int = 0
var monsters_captured: int = 0
var items_stolen: int = 0
var total_damage_dealt: int = 0
var total_damage_taken: int = 0
var tiles_placed: int = 0
var tiles_consumed: int = 0

func to_dictionary() -> Dictionary:
    return {
        "loop_count": loop_count,
        "battles_won": battles_won,
        "monsters_captured": monsters_captured,
        "items_stolen": items_stolen,
        "total_damage_dealt": total_damage_dealt,
        "total_damage_taken": total_damage_taken,
        "tiles_placed": tiles_placed,
        "tiles_consumed": tiles_consumed
    }

static func from_dictionary(data: Dictionary) -> RunState:
    var state := RunState.new()
    state.loop_count = data.get("loop_count", 0)
    state.battles_won = data.get("battles_won", 0)
    state.monsters_captured = data.get("monsters_captured", 0)
    state.items_stolen = data.get("items_stolen", 0)
    state.total_damage_dealt = data.get("total_damage_dealt", 0)
    state.total_damage_taken = data.get("total_damage_taken", 0)
    state.tiles_placed = data.get("tiles_placed", 0)
    state.tiles_consumed = data.get("tiles_consumed", 0)
    return state
```

---

# 五、UI组件实现

## 5.1 HandUIManager (手牌UI管理器)

```gdscript
# scripts/ui/HandUIManager.gd
class_name HandUIManager
extends Control

signal card_selected(card_index: int)

@onready var card_container: HBoxContainer = $CardContainer

var hand_cards: Array[String] = []
var selected_index: int = -1

func _ready():
    visible = true

func set_hand_cards(cards: Array[String]) -> void:
    hand_cards = cards
    _update_hand_ui()

func _update_hand_ui() -> void:
    for child in card_container.get_children():
        child.queue_free()
    
    for i in range(hand_cards.size()):
        var card_ui := _create_hand_card_ui(hand_cards[i], i)
        card_container.add_child(card_ui)

func _create_hand_card_ui(module_id: String, index: int) -> Control:
    var card_data := CardLibrary.get_card(module_id)
    if card_data == null:
        return Control.new()
    
    var card := preload("res://scenes/ui/HandCardUI.tscn").instantiate()
    card.set_card_data(card_data)
    card.card_clicked.connect(_on_card_clicked.bind(index))
    
    return card

func _on_card_clicked(card_index: int) -> void:
    selected_index = card_index
    _highlight_selected_card()
    card_selected.emit(card_index)

func _highlight_selected_card() -> void:
    for i in range(card_container.get_child_count()):
        var child := card_container.get_child(i)
        if child.has_method("set_selected"):
            child.set_selected(i == selected_index)

func remove_card(index: int) -> void:
    if index >= 0 and index < hand_cards.size():
        hand_cards.remove_at(index)
        _update_hand_ui()

func get_selected_module_id() -> String:
    if selected_index >= 0 and selected_index < hand_cards.size():
        return hand_cards[selected_index]
    return ""

func has_cards() -> bool:
    return hand_cards.size() > 0
```

## 5.2 HandCardUI (手牌卡牌UI)

```gdscript
# scripts/ui/HandCardUI.gd
class_name HandCardUI
extends PanelContainer

signal card_clicked()

@onready var icon_rect: TextureRect = $VBoxContainer/IconRect
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var charge_label: Label = $VBoxContainer/ChargeLabel

var card_data: TileCardData = null
var is_selected: bool = false

func _ready():
    gui_input.connect(_on_gui_input)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

func set_card_data(data: TileCardData) -> void:
    card_data = data
    icon_rect.texture = data.icon
    name_label.text = data.display_name
    charge_label.text = "Charge: %d" % data.initial_charge

func set_selected(selected: bool) -> void:
    is_selected = selected
    if selected:
        modulate = Color(1.2, 1.2, 1.0)
        scale = Vector2(1.1, 1.1)
    else:
        modulate = Color.WHITE
        scale = Vector2.ONE

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            card_clicked.emit()

func _on_mouse_entered() -> void:
    if not is_selected:
        modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
    if not is_selected:
        modulate = Color.WHITE
```

---

# 六、交互流程设计

## 6.1 地块放置流程

```
┌─────────────────────────────────────────────────────────────┐
│                     地块放置流程                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 玩家点击手牌中的卡牌                                      │
│     │                                                       │
│     ▼                                                       │
│  2. HandUIManager发出card_selected信号                       │
│     │                                                       │
│     ▼                                                       │
│  3. TilePlacementManager接收信号                             │
│     │                                                       │
│     ├─────► 显示放置预览                                     │
│     │                                                       │
│     └─────► 高亮可用格子                                     │
│              │                                              │
│              ▼                                              │
│         4. 玩家点击目标格子                                   │
│              │                                              │
│              ▼                                              │
│         5. 检查格子是否为空                                   │
│              │                                              │
│              ├─ 已占用 ──► 显示提示，取消放置                 │
│              │                                              │
│              └─ 空闲 ──► 执行放置                            │
│                           │                                 │
│                           ▼                                 │
│                      6. 创建模块实例                          │
│                           │                                 │
│                           ▼                                 │
│                      7. 更新格子状态                          │
│                           │                                 │
│                           ▼                                 │
│                      8. 更新BOSS进度                          │
│                           │                                 │
│                           ▼                                 │
│                      9. 从手牌移除卡牌                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 6.2 地块消耗流程

```
┌─────────────────────────────────────────────────────────────┐
│                     地块消耗流程                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 玩家经过地块模块碰撞体                                    │
│     │                                                       │
│     ▼                                                       │
│  2. PlayerController检测碰撞                                 │
│     │                                                       │
│     ▼                                                       │
│  3. 检查是否已触发过（本圈）                                   │
│     │                                                       │
│     ├─ 已触发 ──► 跳过                                       │
│     │                                                       │
│     └─ 未触发 ──► 继续                                       │
│              │                                              │
│              ▼                                              │
│         4. 调用模块consume_charge()                          │
│              │                                              │
│              ▼                                              │
│         5. 发出tile_consumed信号                             │
│              │                                              │
│              ├─────► 更新BOSS进度                            │
│              │                                              │
│              └─────► 检查Charge是否归零                       │
│                           │                                 │
│                           ├─ 未归零 ──► 继续游戏              │
│                           │                                 │
│                           └─ 归零 ──► 销毁模块                │
│                                      │                      │
│                                      ▼                      │
│                                 6. 生成荒地                  │
│                                      │                      │
│                                      ▼                      │
│                                 7. 检查是否所有模块已消耗      │
│                                      │                      │
│                                      ├─ 否 ──► 继续游戏      │
│                                      │                      │
│                                      └─ 是 ──► 生成BOSS      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 6.3 战斗触发流程

```
┌─────────────────────────────────────────────────────────────┐
│                     战斗触发流程                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 玩家经过地块模块                                          │
│     │                                                       │
│     ▼                                                       │
│  2. 调用模块trigger_combat_probability()                     │
│     │                                                       │
│     ▼                                                       │
│  3. 随机判定是否触发战斗                                      │
│     │                                                       │
│     ├─ 未触发 ──► 继续移动                                   │
│     │                                                       │
│     └─ 触发 ──► 继续                                         │
│              │                                              │
│              ▼                                              │
│         4. 调用模块generate_monster()                        │
│              │                                              │
│              ▼                                              │
│         5. 应用难度缩放                                      │
│              │                                              │
│              ▼                                              │
│         6. 发出combat_triggered信号                          │
│              │                                              │
│              ▼                                              │
│         7. 暂停游戏场景                                      │
│              │                                              │
│              ▼                                              │
│         8. 切换到战斗场景                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 6.4 循环完成流程

```
┌─────────────────────────────────────────────────────────────┐
│                     循环完成流程                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. PathFollow2D.progress_ratio达到1.0                       │
│     │                                                       │
│     ▼                                                       │
│  2. 重置progress_ratio为0.0                                  │
│     │                                                       │
│     ▼                                                       │
│  3. 增加loop_count                                           │
│     │                                                       │
│     ▼                                                       │
│  4. 发出loop_completed信号                                   │
│     │                                                       │
│     ├─────► 重置所有模块的触发状态                            │
│     │                                                       │
│     ├─────► 更新蛋的孵化进度                                 │
│     │                                                       │
│     └─────► 应用熔岩裂隙的ATK加成                            │
│              │                                              │
│              ▼                                              │
│         5. 检查蛋是否可孵化                                   │
│              │                                              │
│              └─ 可孵化 ──► 生成新精灵                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

# 七、对象池实现

## 7.1 TileModulePool (地块模块对象池)

```gdscript
# scripts/pools/TileModulePool.gd
class_name TileModulePool
extends Node

const POOL_SIZE := 5

var _pools: Dictionary = {}
var _prefabs: Dictionary = {}

func _ready():
    _preload_prefabs()
    _initialize_pools()

func _preload_prefabs() -> void:
    var module_ids := ["light_forest", "abandoned_lab", "lava_crack"]
    
    for module_id in module_ids:
        var prefab_path := "res://scenes/tiles/%s.tscn" % module_id.to_pascal_case()
        if ResourceLoader.exists(prefab_path):
            _prefabs[module_id] = load(prefab_path)

func _initialize_pools() -> void:
    for module_id in _prefabs.keys():
        _pools[module_id] = []
        
        for i in POOL_SIZE:
            var instance := _create_instance(module_id)
            instance.visible = false
            instance.process_mode = Node.PROCESS_MODE_DISABLED
            add_child(instance)
            _pools[module_id].append(instance)

func _create_instance(module_id: String) -> BaseTileModule:
    var prefab := _prefabs.get(module_id)
    if prefab == null:
        return null
    return prefab.instantiate()

func acquire(module_id: String) -> BaseTileModule:
    var pool: Array = _pools.get(module_id, [])
    
    for instance in pool:
        if not instance.visible:
            instance.visible = true
            instance.process_mode = Node.PROCESS_MODE_INHERIT
            return instance
    
    var new_instance := _create_instance(module_id)
    if new_instance != null:
        add_child(new_instance)
        pool.append(new_instance)
        return new_instance
    
    return null

func release(instance: BaseTileModule) -> void:
    if instance == null:
        return
    
    instance.visible = false
    instance.process_mode = Node.PROCESS_MODE_DISABLED
    instance.get_parent().remove_child(instance)
    add_child(instance)

func get_pool_stats() -> Dictionary:
    var stats := {}
    for module_id in _pools.keys():
        var pool: Array = _pools[module_id]
        var active := 0
        for instance in pool:
            if instance.visible:
                active += 1
        stats[module_id] = {"total": pool.size(), "active": active}
    return stats
```

---

# 八、测试要点

## 8.1 功能测试

| 测试项 | 预期结果 | 验证方法 |
|--------|---------|---------|
| 循环移动 | 玩家沿圆形路径持续移动 | 观察玩家位置变化 |
| 循环计数 | 每完成一圈计数+1 | 检查loop_count值 |
| 地块放置 | 点击手牌后可放置到空格子 | 检查格子状态 |
| 地块消耗 | 经过地块时Charge-1 | 检查模块Charge值 |
| 每圈触发 | 同一模块每圈仅触发1次 | 连续两圈观察 |
| 战斗触发 | 50%概率触发战斗 | 多次测试统计 |
| BOSS进度 | Charge消耗时进度更新 | 检查进度条 |
| BOSS生成 | 所有模块消耗完生成BOSS | 消耗所有模块 |

## 8.2 边界测试

| 测试项 | 边界条件 | 预期行为 |
|--------|---------|---------|
| 无手牌 | 手牌为空 | 无法放置地块 |
| 格子满 | 所有格子已放置 | 无法继续放置 |
| Charge为0 | 模块Charge归零 | 销毁模块，生成荒地 |
| 蛋孵化 | 进度达到上限 | 自动孵化，生成精灵 |
| BOSS生成 | 已生成BOSS | 不重复生成 |

## 8.3 性能测试

| 测试项 | 性能指标 | 预期值 |
|--------|---------|--------|
| 场景加载 | 首次加载时间 | < 2秒 |
| 对象池 | 实例化延迟 | < 10ms |
| 碰撞检测 | 每帧检测时间 | < 1ms |
| UI更新 | 进度条刷新 | < 16ms |

---

# 附录：相关文件清单

| 文件路径 | 说明 |
|---------|------|
| `scripts/scenes/GameSceneManager.gd` | 游戏场景主控制器 |
| `scripts/scenes/PlayerController.gd` | 玩家控制器 |
| `scripts/scenes/TilePlacementManager.gd` | 地块放置管理器 |
| `scripts/scenes/BossProgressManager.gd` | BOSS进度管理器 |
| `scripts/ui/HandUIManager.gd` | 手牌UI管理器 |
| `scripts/ui/HandCardUI.gd` | 手牌卡牌UI组件 |
| `scripts/data/GridSlot.gd` | 格子槽位数据类 |
| `scripts/data/RunState.gd` | 局内状态数据类 |
| `scripts/pools/TileModulePool.gd` | 地块模块对象池 |
| `scenes/game/GameScene.tscn` | 游戏场景文件 |
