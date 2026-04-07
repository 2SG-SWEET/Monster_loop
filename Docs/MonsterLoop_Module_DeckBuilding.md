# Monster Loop - 卡组构筑模块详细设计

> 模块版本：v1.0  
> 更新日期：2026-04-07  
> 依赖文档：[MonsterLoop_Demo_v2.md](./MonsterLoop_Demo_v2.md)

---

# 一、模块概述

## 1.1 功能定位

卡组构筑模块是玩家进入游戏前的核心准备环节，负责：
- 展示玩家已解锁的地块模块卡牌
- 允许玩家选择并配置出战卡组
- 管理出战精灵配置
- 提供进入游戏的入口

## 1.2 模块边界

| 职责范围 | 不包含 |
|---------|--------|
| 卡牌展示与选择 | 卡牌战斗逻辑 |
| 卡组配置管理 | 地块模块实例化 |
| 精灵出战配置 | 精灵养成系统 |
| 数据持久化 | 局内手牌管理 |

## 1.3 与其他模块的关系

```
┌─────────────────────────────────────────────────────────────┐
│                      卡组构筑模块                            │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  卡牌库管理   │    │  卡组配置器   │    │  精灵选择器   │  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘  │
│         │                   │                   │          │
│         └───────────────────┼───────────────────┘          │
│                             ▼                              │
│                    ┌────────────────┐                      │
│                    │  SaveManager   │                      │
│                    └────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌────────────────┐
                    │   游戏场景模块  │
                    └────────────────┘
```

---

# 二、数据结构设计

## 2.1 卡牌数据结构

### 2.1.1 TileCardData (Resource)

```gdscript
# resources/cards/TileCardData.gd
class_name TileCardData
extends Resource

@export var card_id: String
@export var module_id: String
@export var display_name: String
@export var description: String
@export_multiline var detailed_description: String
@export var icon: Texture2D
@export var rarity: Enums.CardRarity = Enums.CardRarity.COMMON
@export var initial_charge: int = 3
@export var element_types: Array[Enums.Element] = []
@export var special_effects: Array[String] = []
@export var unlock_condition: Dictionary = {}

func get_summary() -> String:
    return "%s | Charge: %d | Elements: %s" % [
        display_name, 
        initial_charge, 
        ", ".join(element_types)
    ]
```

### 2.1.2 DeckConfiguration (数据类)

```gdscript
# scripts/data/DeckConfiguration.gd
class_name DeckConfiguration
extends RefCounted

var cards: Array[DeckCardEntry] = []
var max_cards: int = 5

func add_card(module_id: String, count: int = 1) -> bool:
    if get_total_count() + count > max_cards:
        return false
    
    var existing := get_entry_by_module(module_id)
    if existing != null:
        existing.count += count
    else:
        var entry := DeckCardEntry.new()
        entry.module_id = module_id
        entry.count = count
        cards.append(entry)
    
    return true

func remove_card(module_id: String, count: int = 1) -> bool:
    var entry := get_entry_by_module(module_id)
    if entry == null or entry.count < count:
        return false
    
    entry.count -= count
    if entry.count <= 0:
        cards.erase(entry)
    
    return true

func get_total_count() -> int:
    var total := 0
    for entry in cards:
        total += entry.count
    return total

func get_entry_by_module(module_id: String) -> DeckCardEntry:
    for entry in cards:
        if entry.module_id == module_id:
            return entry
    return null

func to_dictionary() -> Dictionary:
    var result := []
    for entry in cards:
        result.append({
            "module_id": entry.module_id,
            "count": entry.count
        })
    return {"cards": result}

static func from_dictionary(data: Dictionary) -> DeckConfiguration:
    var deck := DeckConfiguration.new()
    for card_data in data.get("cards", []):
        deck.add_card(card_data.module_id, card_data.count)
    return deck

class DeckCardEntry:
    extends RefCounted
    var module_id: String = ""
    var count: int = 0
```

### 2.1.3 MonsterSlot (精灵槽位)

```gdscript
# scripts/data/MonsterSlot.gd
class_name MonsterSlot
extends RefCounted

enum SlotState { EMPTY, MONSTER, EGG }

var state: SlotState = SlotState.EMPTY
var monster_uuid: String = ""
var egg_uuid: String = ""

func is_empty() -> bool:
    return state == SlotState.EMPTY

func set_monster(uuid: String) -> void:
    state = SlotState.MONSTER
    monster_uuid = uuid
    egg_uuid = ""

func set_egg(uuid: String) -> void:
    state = SlotState.EGG
    egg_uuid = uuid
    monster_uuid = ""

func clear() -> void:
    state = SlotState.EMPTY
    monster_uuid = ""
    egg_uuid = ""

func to_dictionary() -> Dictionary:
    return {
        "state": state,
        "monster_uuid": monster_uuid,
        "egg_uuid": egg_uuid
    }

static func from_dictionary(data: Dictionary) -> MonsterSlot:
    var slot := MonsterSlot.new()
    slot.state = data.get("state", SlotState.EMPTY)
    slot.monster_uuid = data.get("monster_uuid", "")
    slot.egg_uuid = data.get("egg_uuid", "")
    return slot
```

## 2.2 枚举定义

```gdscript
# scripts/autoload/Enums.gd
extends Node

enum CardRarity { COMMON, RARE, EPIC, LEGENDARY }

enum Element { FIRE, WATER, GRASS, ELECTRIC, BUG, STEEL }

enum MonsterState { HEALTHY, INJURED, FAINTED }

static func element_to_string(element: Element) -> String:
    match element:
        Element.FIRE: return "火"
        Element.WATER: return "水"
        Element.GRASS: return "草"
        Element.ELECTRIC: return "电"
        Element.BUG: return "虫"
        Element.STEEL: return "钢"
    return "未知"

static func rarity_to_color(rarity: CardRarity) -> Color:
    match rarity:
        CardRarity.COMMON: return Color.WHITE
        CardRarity.RARE: return Color.CYAN
        CardRarity.EPIC: return Color.MAGENTA
        CardRarity.LEGENDARY: return Color.GOLD
    return Color.WHITE
```

---

# 三、场景结构设计

## 3.1 场景节点树

```
PreparationScene (Control)
├── Background (TextureRect)
├── MainContainer (HBoxContainer)
│   ├── LeftPanel (VBoxContainer)                    # 卡牌库面板
│   │   ├── PanelHeader (HBoxContainer)
│   │   │   ├── TitleLabel (Label)
│   │   │   └── FilterButton (OptionButton)
│   │   ├── CardLibrary (ScrollContainer)
│   │   │   └── CardGrid (GridContainer)
│   │   │       └── [CardSlotUI × N]
│   │   └── CardInfoPanel (PanelContainer)           # 卡牌详情
│   │       ├── CardIcon (TextureRect)
│   │       ├── CardName (Label)
│   │       ├── CardDescription (RichTextLabel)
│   │       └── CardStats (HBoxContainer)
│   │
│   ├── CenterPanel (VBoxContainer)                  # 卡组配置面板
│   │   ├── DeckTitle (Label)
│   │   ├── DeckSlots (GridContainer)                # 5个卡组槽位
│   │   │   └── [DeckSlotUI × 5]
│   │   ├── DeckStats (HBoxContainer)
│   │   │   ├── TotalChargeLabel (Label)
│   │   │   └── ElementBalance (HBoxContainer)
│   │   └── ActionButtons (HBoxContainer)
│   │       ├── ClearButton (Button)
│   │       └── PresetButton (Button)
│   │
│   └── RightPanel (VBoxContainer)                   # 精灵配置面板
│       ├── MonsterTitle (Label)
│       ├── MonsterSlots (VBoxContainer)             # 3个精灵槽位
│       │   └── [MonsterSlotUI × 3]
│       ├── MonsterInfoPanel (PanelContainer)
│       │   ├── MonsterIcon (TextureRect)
│       │   ├── MonsterStats (GridContainer)
│       │   └── MonsterSkills (VBoxContainer)
│       └── StartButton (Button)                     # 开始游戏按钮
│
├── BottomBar (HBoxContainer)
│   ├── CurrencyDisplay (HBoxContainer)
│   │   ├── CurrencyIcon (TextureRect)
│   │   └── CurrencyLabel (Label)
│   └── TierDisplay (Label)
│
└── ToastNotification (Control)
    └── ToastLabel (Label)
```

## 3.2 UI组件详细设计

### 3.2.1 CardSlotUI (卡牌槽位组件)

```gdscript
# scripts/ui/components/CardSlotUI.gd
class_name CardSlotUI
extends PanelContainer

signal clicked(card_data: TileCardData)
signal double_clicked(card_data: TileCardData)

@onready var icon_rect: TextureRect = $VBoxContainer/IconRect
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var charge_label: Label = $VBoxContainer/ChargeLabel
@onready var element_icons: HBoxContainer = $VBoxContainer/ElementIcons

var card_data: TileCardData = null
var is_selected: bool = false

func _ready():
    gui_input.connect(_on_gui_input)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

func set_card(data: TileCardData) -> void:
    card_data = data
    icon_rect.texture = data.icon
    name_label.text = data.display_name
    charge_label.text = "×%d" % data.initial_charge
    _update_element_icons()
    _update_rarity_border()

func _update_element_icons() -> void:
    for child in element_icons.get_children():
        child.queue_free()
    
    for element in card_data.element_types:
        var icon := TextureRect.new()
        icon.texture = _get_element_icon(element)
        icon.custom_minimum_size = Vector2(16, 16)
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        element_icons.add_child(icon)

func _update_rarity_border() -> void:
    var style := StyleBoxFlat.new()
    style.border_color = Enums.rarity_to_color(card_data.rarity)
    style.set_border_width_all(2)
    style.set_corner_radius_all(4)
    add_theme_stylebox_override("panel", style)

func set_selected(selected: bool) -> void:
    is_selected = selected
    modulate = Color(1.2, 1.2, 1.2) if selected else Color.WHITE

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            if event.double_click:
                double_clicked.emit(card_data)
            else:
                clicked.emit(card_data)

func _on_mouse_entered() -> void:
    if not is_selected:
        modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited() -> void:
    if not is_selected:
        modulate = Color.WHITE

func _get_element_icon(element: Enums.Element) -> Texture2D:
    return load("res://assets/icons/elements/%s.png" % Enums.element_to_string(element).to_lower())
```

### 3.2.2 DeckSlotUI (卡组槽位组件)

```gdscript
# scripts/ui/components/DeckSlotUI.gd
class_name DeckSlotUI
extends PanelContainer

signal slot_clicked(slot_index: int)
signal slot_cleared(slot_index: int)

@onready var icon_rect: TextureRect = $HBoxContainer/IconRect
@onready var info_container: VBoxContainer = $HBoxContainer/InfoContainer
@onready var name_label: Label = $HBoxContainer/InfoContainer/NameLabel
@onready var count_label: Label = $HBoxContainer/InfoContainer/CountLabel
@onready var remove_button: Button = $HBoxContainer/RemoveButton

var slot_index: int = 0
var module_id: String = ""
var count: int = 0
var card_data: TileCardData = null

func _ready():
    remove_button.pressed.connect(_on_remove_pressed)
    gui_input.connect(_on_gui_input)

func set_card(data: TileCardData, card_count: int) -> void:
    card_data = data
    module_id = data.module_id
    count = card_count
    
    icon_rect.texture = data.icon
    name_label.text = data.display_name
    count_label.text = "×%d" % count
    
    visible = true

func clear_slot() -> void:
    card_data = null
    module_id = ""
    count = 0
    
    icon_rect.texture = null
    name_label.text = "空槽位"
    count_label.text = ""
    
    visible = false

func increment() -> bool:
    if count >= 5:
        return false
    count += 1
    count_label.text = "×%d" % count
    return true

func decrement() -> bool:
    if count <= 0:
        return false
    count -= 1
    if count <= 0:
        clear_slot()
    else:
        count_label.text = "×%d" % count
    return true

func _on_remove_pressed() -> void:
    slot_cleared.emit(slot_index)

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            slot_clicked.emit(slot_index)
```

### 3.2.3 MonsterSlotUI (精灵槽位组件)

```gdscript
# scripts/ui/components/MonsterSlotUI.gd
class_name MonsterSlotUI
extends PanelContainer

signal slot_selected(slot_index: int)
signal monster_removed(slot_index: int)

@onready var icon_rect: TextureRect = $HBoxContainer/IconRect
@onready var info_container: VBoxContainer = $HBoxContainer/InfoContainer
@onready var name_label: Label = $HBoxContainer/InfoContainer/NameLabel
@onready var level_label: Label = $HBoxContainer/InfoContainer/LevelLabel
@onready var state_label: Label = $HBoxContainer/InfoContainer/StateLabel
@onready var remove_button: Button = $HBoxContainer/RemoveButton
@onready var empty_label: Label = $EmptyLabel

var slot_index: int = 0
var monster_uuid: String = ""
var is_egg: bool = false

func _ready():
    remove_button.pressed.connect(_on_remove_pressed)
    gui_input.connect(_on_gui_input)

func set_monster(monster_data: Dictionary) -> void:
    monster_uuid = monster_data.get("uuid", "")
    is_egg = false
    
    icon_rect.texture = load("res://assets/monsters/%s.png" % monster_data.get("species", "unknown"))
    name_label.text = monster_data.get("display_name", "未知精灵")
    level_label.text = "Lv.%d" % monster_data.get("level", 1)
    
    var hp_percent = float(monster_data.get("hp", 100)) / float(monster_data.get("max_hp", 100))
    if hp_percent > 0.5:
        state_label.text = "健康"
        state_label.add_theme_color_override("font_color", Color.GREEN)
    elif hp_percent > 0:
        state_label.text = "受伤"
        state_label.add_theme_color_override("font_color", Color.YELLOW)
    else:
        state_label.text = "晕倒"
        state_label.add_theme_color_override("font_color", Color.RED)
    
    empty_label.visible = false
    icon_rect.visible = true
    info_container.visible = true
    remove_button.visible = true

func set_egg(egg_data: Dictionary) -> void:
    monster_uuid = egg_data.get("uuid", "")
    is_egg = true
    
    icon_rect.texture = load("res://assets/items/egg.png")
    name_label.text = "神秘蛋"
    level_label.text = "孵化中"
    state_label.text = "%d/%d" % [egg_data.get("progress", 0), egg_data.get("required_progress", 10)]
    state_label.add_theme_color_override("font_color", Color.CYAN)
    
    empty_label.visible = false
    icon_rect.visible = true
    info_container.visible = true
    remove_button.visible = true

func clear_slot() -> void:
    monster_uuid = ""
    is_egg = false
    
    icon_rect.visible = false
    info_container.visible = false
    remove_button.visible = false
    empty_label.visible = true
    empty_label.text = "点击选择精灵"

func _on_remove_pressed() -> void:
    monster_removed.emit(slot_index)

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            slot_selected.emit(slot_index)
```

---

# 四、核心脚本实现

## 4.1 PreparationManager (准备场景管理器)

```gdscript
# scripts/scenes/PreparationManager.gd
extends Control

const DECK_SIZE := 5
const MONSTER_SLOTS := 3

@onready var card_library: GridContainer = $MainContainer/LeftPanel/CardLibrary/CardGrid
@onready var deck_slots: GridContainer = $MainContainer/CenterPanel/DeckSlots
@onready var monster_slots_container: VBoxContainer = $MainContainer/RightPanel/MonsterSlots
@onready var start_button: Button = $MainContainer/RightPanel/StartButton
@onready var total_charge_label: Label = $MainContainer/CenterPanel/DeckStats/TotalChargeLabel
@onready var toast: Control = $ToastNotification

var available_cards: Array[TileCardData] = []
var current_deck: DeckConfiguration = DeckConfiguration.new()
var selected_monsters: Array[MonsterSlot] = []
var selected_card: TileCardData = null

func _ready():
    _initialize_slots()
    _load_available_cards()
    _load_saved_deck()
    _load_saved_monsters()
    _connect_signals()
    _update_ui()

func _initialize_slots() -> void:
    for i in MONSTER_SLOTS:
        var slot := MonsterSlot.new()
        selected_monsters.append(slot)

func _load_available_cards() -> void:
    var unlocked_modules: Array = SaveManager.get_data().get("unlocked_modules", [])
    
    for module_id in unlocked_modules:
        var card_path := "res://resources/cards/%s_card.tres" % module_id
        if ResourceLoader.exists(card_path):
            var card := load(card_path) as TileCardData
            if card != null:
                available_cards.append(card)
    
    _populate_card_library()

func _populate_card_library() -> void:
    for child in card_library.get_children():
        child.queue_free()
    
    for card in available_cards:
        var slot_ui := preload("res://scenes/ui/CardSlotUI.tscn").instantiate()
        slot_ui.set_card(card)
        slot_ui.clicked.connect(_on_card_clicked)
        slot_ui.double_clicked.connect(_on_card_double_clicked)
        card_library.add_child(slot_ui)

func _load_saved_deck() -> void:
    var saved_deck: Dictionary = SaveManager.get_data().get("deck", {})
    current_deck = DeckConfiguration.from_dictionary(saved_deck)
    _update_deck_ui()

func _load_saved_monsters() -> void:
    var saved_monsters: Array = SaveManager.get_data().get("selected_monsters", [])
    for i in min(saved_monsters.size(), MONSTER_SLOTS):
        selected_monsters[i] = MonsterSlot.from_dictionary(saved_monsters[i])
    _update_monster_ui()

func _connect_signals() -> void:
    start_button.pressed.connect(_on_start_pressed)

func _on_card_clicked(card: TileCardData) -> void:
    selected_card = card
    _show_card_info(card)
    _highlight_selected_card()

func _on_card_double_clicked(card: TileCardData) -> void:
    _add_card_to_deck(card)

func _add_card_to_deck(card: TileCardData) -> void:
    if current_deck.get_total_count() >= DECK_SIZE:
        _show_toast("卡组已满！最多携带%d张卡牌" % DECK_SIZE)
        return
    
    if current_deck.add_card(card.module_id):
        _update_deck_ui()
        _update_deck_stats()
        SaveManager.mark_dirty()
        _show_toast("已添加 %s 到卡组" % card.display_name)
    else:
        _show_toast("添加失败")

func _remove_card_from_deck(module_id: String) -> void:
    if current_deck.remove_card(module_id):
        _update_deck_ui()
        _update_deck_stats()
        SaveManager.mark_dirty()

func _update_deck_ui() -> void:
    var slot_index := 0
    for child in deck_slots.get_children():
        var slot_ui := child as DeckSlotUI
        if slot_ui == null:
            continue
        
        var entries := current_deck.cards
        if slot_index < entries.size():
            var entry := entries[slot_index]
            var card := _get_card_by_module(entry.module_id)
            if card != null:
                slot_ui.set_card(card, entry.count)
            else:
                slot_ui.clear_slot()
        else:
            slot_ui.clear_slot()
        
        slot_index += 1

func _update_deck_stats() -> void:
    var total_charge := 0
    for entry in current_deck.cards:
        var card := _get_card_by_module(entry.module_id)
        if card != null:
            total_charge += card.initial_charge * entry.count
    
    total_charge_label.text = "总Charge: %d" % total_charge

func _update_monster_ui() -> void:
    var slot_index := 0
    for child in monster_slots_container.get_children():
        var slot_ui := child as MonsterSlotUI
        if slot_ui == null:
            continue
        
        var slot := selected_monsters[slot_index]
        if slot.is_empty():
            slot_ui.clear_slot()
        elif slot.state == MonsterSlot.SlotState.MONSTER:
            var monster_data := _get_monster_data(slot.monster_uuid)
            if monster_data != null:
                slot_ui.set_monster(monster_data)
            else:
                slot_ui.clear_slot()
        elif slot.state == MonsterSlot.SlotState.EGG:
            var egg_data := _get_egg_data(slot.egg_uuid)
            if egg_data != null:
                slot_ui.set_egg(egg_data)
            else:
                slot_ui.clear_slot()
        
        slot_index += 1

func _on_start_pressed() -> void:
    if not _validate_configuration():
        return
    
    _save_configuration()
    _start_game()

func _validate_configuration() -> bool:
    if current_deck.get_total_count() < DECK_SIZE:
        _show_toast("请配置完整的卡组（需要%d张卡牌）" % DECK_SIZE)
        return false
    
    var has_monster := false
    for slot in selected_monsters:
        if not slot.is_empty() and slot.state == MonsterSlot.SlotState.MONSTER:
            has_monster = true
            break
    
    if not has_monster:
        _show_toast("请至少选择1只精灵出战")
        return false
    
    return true

func _save_configuration() -> void:
    var data := SaveManager.get_data()
    data["deck"] = current_deck.to_dictionary()
    
    var monsters_data := []
    for slot in selected_monsters:
        monsters_data.append(slot.to_dictionary())
    data["selected_monsters"] = monsters_data
    
    SaveManager.mark_dirty()
    SaveManager.save_data()

func _start_game() -> void:
    GameManager.start_new_run()
    get_tree().change_scene_to_file("res://scenes/game/GameScene.tscn")

func _show_card_info(card: TileCardData) -> void:
    var info_panel := $MainContainer/LeftPanel/CardInfoPanel
    info_panel.get_node("CardIcon").texture = card.icon
    info_panel.get_node("CardName").text = card.display_name
    info_panel.get_node("CardDescription").text = card.detailed_description

func _highlight_selected_card() -> void:
    for child in card_library.get_children():
        var slot_ui := child as CardSlotUI
        if slot_ui != null:
            slot_ui.set_selected(slot_ui.card_data == selected_card)

func _show_toast(message: String) -> void:
    var toast_label := toast.get_node("ToastLabel") as Label
    toast_label.text = message
    toast.visible = true
    
    var tween := create_tween()
    tween.tween_property(toast, "modulate:a", 1.0, 0.3)
    tween.tween_interval(2.0)
    tween.tween_property(toast, "modulate:a", 0.0, 0.3)
    tween.tween_callback(func(): toast.visible = false)

func _get_card_by_module(module_id: String) -> TileCardData:
    for card in available_cards:
        if card.module_id == module_id:
            return card
    return null

func _get_monster_data(uuid: String) -> Dictionary:
    var monsters: Array = SaveManager.get_data().get("monsters", [])
    for monster in monsters:
        if monster.get("uuid") == uuid:
            return monster
    return {}

func _get_egg_data(uuid: String) -> Dictionary:
    var eggs: Array = SaveManager.get_data().get("eggs", [])
    for egg in eggs:
        if egg.get("uuid") == uuid:
            return egg
    return {}
```

## 4.2 CardLibrary (卡牌库管理器)

```gdscript
# scripts/managers/CardLibrary.gd
class_name CardLibrary
extends RefCounted

var _cards: Dictionary = {}

func _init():
    _load_all_cards()

func _load_all_cards() -> void:
    var dir := DirAccess.open("res://resources/cards/")
    if dir == null:
        return
    
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.ends_with(".tres"):
            var card := load("res://resources/cards/%s" % file_name) as TileCardData
            if card != null:
                _cards[card.module_id] = card
        file_name = dir.get_next()

func get_card(module_id: String) -> TileCardData:
    return _cards.get(module_id)

func get_all_cards() -> Array[TileCardData]:
    var result: Array[TileCardData] = []
    for card in _cards.values():
        result.append(card)
    return result

func get_cards_by_element(element: Enums.Element) -> Array[TileCardData]:
    var result: Array[TileCardData] = []
    for card in _cards.values():
        if element in card.element_types:
            result.append(card)
    return result

func get_cards_by_rarity(rarity: Enums.CardRarity) -> Array[TileCardData]:
    var result: Array[TileCardData] = []
    for card in _cards.values():
        if card.rarity == rarity:
            result.append(card)
    return result
```

---

# 五、交互流程设计

## 5.1 卡牌选择流程

```
┌─────────────────────────────────────────────────────────────┐
│                     卡牌选择流程                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 玩家点击卡牌库中的卡牌                                    │
│     │                                                       │
│     ▼                                                       │
│  2. 卡牌高亮显示，右侧展示卡牌详情                             │
│     │                                                       │
│     ├─────► 单击：选中并显示详情                              │
│     │                                                       │
│     └─────► 双击：直接添加到卡组                              │
│              │                                              │
│              ▼                                              │
│         3. 检查卡组是否已满                                   │
│              │                                              │
│              ├─ 已满 ──► 显示Toast提示                       │
│              │                                              │
│              └─ 未满 ──► 添加到卡组                           │
│                           │                                 │
│                           ▼                                 │
│                      4. 更新卡组UI                           │
│                           │                                 │
│                           ▼                                 │
│                      5. 更新统计数据                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 5.2 精灵选择流程

```
┌─────────────────────────────────────────────────────────────┐
│                     精灵选择流程                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 玩家点击精灵槽位                                          │
│     │                                                       │
│     ▼                                                       │
│  2. 打开精灵选择弹窗                                          │
│     │                                                       │
│     ├─────► 显示已孵化精灵列表                                │
│     │                                                       │
│     └─────► 显示待孵化蛋列表                                  │
│              │                                              │
│              ▼                                              │
│         3. 玩家选择精灵/蛋                                    │
│              │                                              │
│              ├─ 精灵 ──► 检查是否已在其他槽位                  │
│              │           │                                  │
│              │           ├─ 已存在 ──► 交换槽位               │
│              │           │                                  │
│              │           └─ 不存在 ──► 直接添加               │
│              │                                              │
│              └─ 蛋 ──► 直接添加到槽位                         │
│                           │                                 │
│                           ▼                                 │
│                      4. 更新精灵槽位UI                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 5.3 开始游戏流程

```
┌─────────────────────────────────────────────────────────────┐
│                     开始游戏流程                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 玩家点击"开始游戏"按钮                                    │
│     │                                                       │
│     ▼                                                       │
│  2. 验证配置                                                 │
│     │                                                       │
│     ├─ 卡组未满 ──► Toast提示，阻止开始                       │
│     │                                                       │
│     ├─ 无精灵 ──► Toast提示，阻止开始                         │
│     │                                                       │
│     └─ 验证通过 ──► 继续                                     │
│              │                                              │
│              ▼                                              │
│         3. 保存配置到SaveManager                              │
│              │                                              │
│              ▼                                              │
│         4. 调用GameManager.start_new_run()                   │
│              │                                              │
│              ▼                                              │
│         5. 切换到GameScene                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

# 六、资源文件规范

## 6.1 卡牌资源文件结构

```
resources/
├── cards/
│   ├── light_forest_card.tres
│   ├── abandoned_lab_card.tres
│   └── lava_crack_card.tres
├── monsters/
│   ├── fire_slime.tres
│   ├── grass_slime.tres
│   └── ...
└── icons/
    ├── elements/
    │   ├── fire.png
    │   ├── water.png
    │   └── ...
    └── rarity/
        ├── common.png
        ├── rare.png
        └── ...
```

## 6.2 卡牌资源示例 (light_forest_card.tres)

```gdscript
[gd_resource type="Resource" script_class="TileCardData" load_steps=3 format=3]

[ext_resource type="Script" path="res://resources/cards/TileCardData.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/icons/tiles/light_forest.png" id="2"]

[resource]
script = ExtResource("1")
card_id = "card_light_forest"
module_id = "light_forest"
display_name = "微光森林"
description = "充满生机的森林，栖息着草系和虫系精灵"
detailed_description = """
【微光森林】

初始Charge: 3
精灵系别: 草系(50%) / 虫系(50%)

特殊效果:
• 战斗胜利后30%概率掉落"果实"
• 销毁时播放"绿叶消失"粒子特效

消失奖励: 生机碎片×1
"""
icon = ExtResource("2")
rarity = 0
initial_charge = 3
element_types = [1, 4]
special_effects = ["drop_fruit_30"]
```

---

# 七、测试要点

## 7.1 功能测试

| 测试项 | 预期结果 | 验证方法 |
|--------|---------|---------|
| 卡牌加载 | 正确显示所有已解锁卡牌 | 检查卡牌库显示数量 |
| 卡牌添加 | 双击卡牌添加到卡组 | 检查卡组槽位更新 |
| 卡组上限 | 超过5张时显示提示 | 尝试添加第6张卡牌 |
| 卡牌移除 | 点击移除按钮清除卡牌 | 检查卡组槽位清空 |
| 精灵选择 | 点击槽位打开选择弹窗 | 检查弹窗显示 |
| 精灵重复 | 同一精灵不可重复选择 | 尝试选择已选精灵 |
| 开始验证 | 配置不完整时阻止开始 | 未配置完整点击开始 |
| 数据保存 | 配置正确保存到JSON | 检查save_data.json |

## 7.2 边界测试

| 测试项 | 边界条件 | 预期行为 |
|--------|---------|---------|
| 卡组为空 | 0张卡牌 | 允许，但无法开始游戏 |
| 卡组满 | 5张卡牌 | 无法继续添加 |
| 精灵为空 | 0只精灵 | 无法开始游戏 |
| 精灵满 | 3只精灵 | 无法继续添加 |
| 蛋选择 | 选择蛋 | 允许，但局内不参与战斗 |

## 7.3 性能测试

| 测试项 | 性能指标 | 预期值 |
|--------|---------|--------|
| 场景加载 | 首次加载时间 | < 1秒 |
| 卡牌渲染 | 100张卡牌渲染 | < 0.5秒 |
| UI响应 | 点击响应延迟 | < 100ms |
| 存档写入 | JSON保存时间 | < 50ms |

---

# 八、扩展预留

## 8.1 卡牌筛选系统

```gdscript
# 预留接口
func filter_cards(filter: CardFilter) -> Array[TileCardData]:
    pass

class CardFilter:
    extends RefCounted
    var elements: Array[Enums.Element] = []
    var rarities: Array[Enums.CardRarity] = []
    var min_charge: int = 0
    var max_charge: int = 999
    var search_text: String = ""
```

## 8.2 卡组预设系统

```gdscript
# 预留接口
func save_deck_preset(name: String) -> void:
    pass

func load_deck_preset(name: String) -> DeckConfiguration:
    pass

func get_deck_presets() -> Array[String]:
    pass
```

## 8.3 卡组推荐系统

```gdscript
# 预留接口
func get_recommended_decks() -> Array[DeckConfiguration]:
    pass

func analyze_deck_balance(deck: DeckConfiguration) -> Dictionary:
    pass
```

---

# 附录：相关文件清单

| 文件路径 | 说明 |
|---------|------|
| `scripts/scenes/PreparationManager.gd` | 准备场景主控制器 |
| `scripts/managers/CardLibrary.gd` | 卡牌库管理器 |
| `scripts/ui/components/CardSlotUI.gd` | 卡牌槽位UI组件 |
| `scripts/ui/components/DeckSlotUI.gd` | 卡组槽位UI组件 |
| `scripts/ui/components/MonsterSlotUI.gd` | 精灵槽位UI组件 |
| `scripts/data/DeckConfiguration.gd` | 卡组配置数据类 |
| `scripts/data/MonsterSlot.gd` | 精灵槽位数据类 |
| `resources/cards/TileCardData.gd` | 卡牌数据资源类 |
| `scenes/preparation/PreparationScene.tscn` | 准备场景文件 |
