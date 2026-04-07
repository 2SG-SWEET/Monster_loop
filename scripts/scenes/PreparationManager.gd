class_name PreparationManager
extends Control

const DECK_SIZE := 5
const MONSTER_SLOTS := 3

@onready var card_library_container: GridContainer = $MainContainer/LeftPanel/CardLibrary/CardGrid
@onready var deck_slots_container: GridContainer = $MainContainer/CenterPanel/DeckSlots
@onready var monster_slots_container: VBoxContainer = $MainContainer/RightPanel/MonsterSlots
@onready var start_button: Button = $MainContainer/RightPanel/StartButton
@onready var total_charge_label: Label = $MainContainer/CenterPanel/DeckStats/TotalChargeLabel
@onready var card_info_panel: PanelContainer = $MainContainer/LeftPanel/CardInfoPanel
@onready var card_info_icon: TextureRect = $MainContainer/LeftPanel/CardInfoPanel/VBox/CardIcon
@onready var card_info_name: Label = $MainContainer/LeftPanel/CardInfoPanel/VBox/CardName
@onready var card_info_desc: RichTextLabel = $MainContainer/LeftPanel/CardInfoPanel/VBox/CardDescription
@onready var toast_label: Label = $ToastNotification/ToastLabel

var available_cards: Array = []
var current_deck: DeckConfiguration = DeckConfiguration.new()
var selected_monster_slots: Array = []
var selected_card: TileCardData = null
var card_slot_uis: Array = []
var deck_slot_uis: Array = []
var monster_slot_uis: Array = []

func _ready():
	CardLibrary.initialize()
	_initialize_monster_slots()
	_load_available_cards()
	_load_saved_deck()
	_load_saved_monsters()
	_connect_signals()
	_update_ui()

func _initialize_monster_slots() -> void:
	for i in MONSTER_SLOTS:
		var slot := MonsterSlot.new()
		selected_monster_slots.append(slot)

func _load_available_cards() -> void:
	var unlocked_modules: Array = SaveManager.get_data().get("unlocked_modules", [])
	available_cards = CardLibrary.get_unlocked_cards(unlocked_modules)
	_populate_card_library()

func _populate_card_library() -> void:
	if card_library_container == null:
		return
	
	for child in card_library_container.get_children():
		child.queue_free()
	card_slot_uis.clear()
	
	for card in available_cards:
		var slot_ui := _create_card_slot_ui(card)
		card_library_container.add_child(slot_ui)
		card_slot_uis.append(slot_ui)

func _create_card_slot_ui(card: TileCardData) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(100, 120)
	
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if card.icon:
		icon.texture = card.icon
	vbox.add_child(icon)
	
	var name_lbl := Label.new()
	name_lbl.text = card.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)
	
	var charge_lbl := Label.new()
	charge_lbl.text = "×%d" % card.initial_charge
	charge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(charge_lbl)
	
	var style := StyleBoxFlat.new()
	style.border_color = card.get_rarity_color()
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
	panel.add_theme_stylebox_override("panel", style)
	
	panel.set_meta("card_data", card)
	panel.gui_input.connect(_on_card_slot_gui_input.bind(panel, card))
	panel.mouse_entered.connect(_on_card_slot_mouse_entered.bind(card))
	panel.mouse_exited.connect(_on_card_slot_mouse_exited.bind(panel))
	
	return panel

func _load_saved_deck() -> void:
	var saved_deck: Dictionary = SaveManager.get_data().get("deck", {})
	current_deck = DeckConfiguration.from_dictionary(saved_deck)

func _load_saved_monsters() -> void:
	var saved_monsters: Array = SaveManager.get_data().get("selected_monsters", [])
	for i in range(min(saved_monsters.size(), MONSTER_SLOTS)):
		selected_monster_slots[i] = MonsterSlot.from_dictionary(saved_monsters[i])

func _connect_signals() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)

func _on_card_slot_gui_input(event: InputEvent, panel: Control, card: TileCardData) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_add_card_to_deck(card)

func _on_card_slot_mouse_entered(card: TileCardData) -> void:
	_show_card_info(card)

func _on_card_slot_mouse_exited(panel: Control) -> void:
	pass

func _show_card_info(card: TileCardData) -> void:
	if card_info_panel == null:
		return
	
	if card_info_name:
		card_info_name.text = card.display_name
	if card_info_desc:
		card_info_desc.text = card.detailed_description
	if card_info_icon and card.icon:
		card_info_icon.texture = card.icon
	
	card_info_panel.visible = true

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
	if deck_slots_container == null:
		return
	
	for child in deck_slots_container.get_children():
		child.queue_free()
	deck_slot_uis.clear()
	
	var entries := current_deck.cards
	for i in range(DECK_SIZE):
		var slot_ui := _create_deck_slot_ui(i)
		deck_slots_container.add_child(slot_ui)
		deck_slot_uis.append(slot_ui)
		
		if i < entries.size():
			var entry: Dictionary = entries[i]
			var card := CardLibrary.get_card(entry.module_id)
			if card != null:
				_set_deck_slot_data(slot_ui, card, entry.count)

func _create_deck_slot_ui(index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 60)
	
	var hbox := HBoxContainer.new()
	panel.add_child(hbox)
	
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	
	var info_vbox := VBoxContainer.new()
	hbox.add_child(info_vbox)
	
	var name_lbl := Label.new()
	name_lbl.text = "空槽位"
	info_vbox.add_child(name_lbl)
	
	var count_lbl := Label.new()
	count_lbl.text = ""
	info_vbox.add_child(count_lbl)
	
	var remove_btn := Button.new()
	remove_btn.text = "×"
	remove_btn.custom_minimum_size = Vector2(24, 24)
	hbox.add_child(remove_btn)
	
	panel.set_meta("slot_index", index)
	panel.set_meta("icon", icon)
	panel.set_meta("name_label", name_lbl)
	panel.set_meta("count_label", count_lbl)
	panel.set_meta("remove_button", remove_btn)
	
	remove_btn.pressed.connect(_on_deck_remove_pressed.bind(index))
	
	return panel

func _set_deck_slot_data(slot_ui: Control, card: TileCardData, count: int) -> void:
	var icon: TextureRect = slot_ui.get_meta("icon")
	var name_lbl: Label = slot_ui.get_meta("name_label")
	var count_lbl: Label = slot_ui.get_meta("count_label")
	
	if icon and card.icon:
		icon.texture = card.icon
	if name_lbl:
		name_lbl.text = card.display_name
	if count_lbl:
		count_lbl.text = "×%d" % count

func _on_deck_remove_pressed(slot_index: int) -> void:
	var entries := current_deck.cards
	if slot_index < entries.size():
		var entry: Dictionary = entries[slot_index]
		_remove_card_from_deck(entry.module_id)

func _update_deck_stats() -> void:
	var total_charge := 0
	for entry in current_deck.cards:
		var card := CardLibrary.get_card(entry.module_id)
		if card != null:
			total_charge += card.initial_charge * entry.count
	
	if total_charge_label:
		total_charge_label.text = "总Charge: %d" % total_charge

func _update_monster_ui() -> void:
	if monster_slots_container == null:
		return
	
	for child in monster_slots_container.get_children():
		child.queue_free()
	monster_slot_uis.clear()
	
	var monsters: Array = SaveManager.get_player_monsters()
	
	for i in range(MONSTER_SLOTS):
		var slot_ui := _create_monster_slot_ui(i)
		monster_slots_container.add_child(slot_ui)
		monster_slot_uis.append(slot_ui)
		
		var slot: MonsterSlot = selected_monster_slots[i]
		if not slot.is_empty():
			var uuid := slot.get_uuid()
			var monster_data := _find_monster_by_uuid(monsters, uuid)
			if not monster_data.is_empty():
				_set_monster_slot_data(slot_ui, monster_data, slot.state == MonsterSlot.SlotState.EGG)

func _create_monster_slot_ui(index: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 80)
	
	var hbox := HBoxContainer.new()
	panel.add_child(hbox)
	
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.visible = false
	hbox.add_child(icon)
	
	var info_vbox := VBoxContainer.new()
	info_vbox.visible = false
	hbox.add_child(info_vbox)
	
	var name_lbl := Label.new()
	info_vbox.add_child(name_lbl)
	
	var level_lbl := Label.new()
	info_vbox.add_child(level_lbl)
	
	var state_lbl := Label.new()
	info_vbox.add_child(state_lbl)
	
	var remove_btn := Button.new()
	remove_btn.text = "×"
	remove_btn.visible = false
	hbox.add_child(remove_btn)
	
	var empty_lbl := Label.new()
	empty_lbl.text = "点击选择精灵"
	empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(empty_lbl)
	
	panel.set_meta("slot_index", index)
	panel.set_meta("icon", icon)
	panel.set_meta("info_vbox", info_vbox)
	panel.set_meta("name_label", name_lbl)
	panel.set_meta("level_label", level_lbl)
	panel.set_meta("state_label", state_lbl)
	panel.set_meta("remove_button", remove_btn)
	panel.set_meta("empty_label", empty_lbl)
	
	remove_btn.pressed.connect(_on_monster_remove_pressed.bind(index))
	panel.gui_input.connect(_on_monster_slot_clicked.bind(index))
	
	return panel

func _set_monster_slot_data(slot_ui: Control, data: Dictionary, is_egg: bool) -> void:
	var icon: TextureRect = slot_ui.get_meta("icon")
	var info_vbox: VBoxContainer = slot_ui.get_meta("info_vbox")
	var name_lbl: Label = slot_ui.get_meta("name_label")
	var level_lbl: Label = slot_ui.get_meta("level_label")
	var state_lbl: Label = slot_ui.get_meta("state_label")
	var remove_btn: Button = slot_ui.get_meta("remove_button")
	var empty_lbl: Label = slot_ui.get_meta("empty_label")
	
	if is_egg:
		if name_lbl:
			name_lbl.text = "神秘蛋"
		if level_lbl:
			level_lbl.text = "孵化中"
		if state_lbl:
			state_lbl.text = "%d/%d" % [data.get("progress", 0), data.get("required_progress", 10)]
	else:
		if name_lbl:
			name_lbl.text = data.get("display_name", "未知精灵")
		if level_lbl:
			level_lbl.text = "Lv.%d" % data.get("level", 1)
		if state_lbl:
			state_lbl.text = "健康"
	
	icon.visible = true
	info_vbox.visible = true
	remove_btn.visible = true
	empty_lbl.visible = false

func _on_monster_slot_clicked(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_monster_for_slot(slot_index)

func _on_monster_remove_pressed(slot_index: int) -> void:
	selected_monster_slots[slot_index].clear()
	_update_monster_ui()
	SaveManager.mark_dirty()

func _select_monster_for_slot(slot_index: int) -> void:
	var monsters: Array = SaveManager.get_player_monsters()
	if monsters.is_empty():
		_show_toast("没有可用的精灵")
		return
	
	var slot: MonsterSlot = selected_monster_slots[slot_index]
	if slot.is_empty():
		for monster in monsters:
			var uuid: String = monster.get("uuid", "")
			var already_selected := false
			for s in selected_monster_slots:
				if s.get_uuid() == uuid:
					already_selected = true
					break
			
			if not already_selected:
				slot.set_monster(uuid)
				_update_monster_ui()
				SaveManager.mark_dirty()
				return
		
		_show_toast("所有精灵都已选中")

func _find_monster_by_uuid(monsters: Array, uuid: String) -> Dictionary:
	for monster in monsters:
		if monster.get("uuid", "") == uuid:
			return monster
	return {}

func _update_ui() -> void:
	_update_deck_ui()
	_update_deck_stats()
	_update_monster_ui()

func _on_start_pressed() -> void:
	if current_deck.get_total_count() == 0:
		_show_toast("请至少选择一张卡牌")
		return
	
	var has_monster := false
	for slot in selected_monster_slots:
		if not slot.is_empty():
			has_monster = true
			break
	
	if not has_monster:
		_show_toast("请至少选择一只精灵")
		return
	
	_save_selection()
	SaveManager.save_data()
	GameManager.set_phase(Enums.GamePhase.EXPLORATION)

func _save_selection() -> void:
	var deck_dict := current_deck.to_dictionary()
	SaveManager.get_data()["deck"] = deck_dict
	
	var selected_monsters_data: Array = []
	for slot in selected_monster_slots:
		selected_monsters_data.append(slot.to_dictionary())
	SaveManager.get_data()["selected_monsters"] = selected_monsters_data
	
	var selected_uuids: Array = []
	for slot in selected_monster_slots:
		if slot.state == MonsterSlot.SlotState.MONSTER:
			selected_uuids.append(slot.monster_uuid)
	SaveManager.get_data()["selected_monsters"] = selected_uuids

func _show_toast(message: String) -> void:
	if toast_label:
		toast_label.text = message
		toast_label.visible = true
		
		var tween := create_tween()
		tween.tween_property(toast_label, "modulate:a", 1.0, 0.2)
		tween.tween_interval(2.0)
		tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): toast_label.visible = false)
