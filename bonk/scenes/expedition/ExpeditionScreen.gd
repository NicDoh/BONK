class_name ExpeditionScreen
extends ScrollContainer

var _view: String = "world"
var _selected_zone: ZoneData = null

var _world_container: VBoxContainer
var _zone_container: VBoxContainer
var _combat_container: VBoxContainer

var _zone_title_label: Label
var _zone_desc_label: Label
var _activity_container: VBoxContainer

var _player_hp_bar: ProgressBar
var _player_hp_label: Label
var _player_stats_label: Label
var _player_panel: PanelContainer

var _monster_name_label: Label
var _monster_hp_bar: ProgressBar
var _monster_hp_label: Label
var _enemy_panel: PanelContainer

var _damage_overlay: Control
var _kills_label: Label
var _xp_label: Label
var _loot_log: RichTextLabel

var _kills_this_session: int = 0
var _xp_this_session: float = 0.0
var _loot_lines: Array[String] = []
const LOOT_MAX := 15

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 10)
	add_child(inner)

	_build_world_view(inner)
	_build_zone_view(inner)
	_build_combat_view(inner)
	_connect_signals()

	if ExpeditionManager.active and ExpeditionManager.current_monster:
		_refresh_combat_header()
		set_view("combat")
	else:
		set_view("world")

func _build_world_view(parent: VBoxContainer) -> void:
	_world_container = VBoxContainer.new()
	_world_container.add_theme_constant_override("separation", 10)
	parent.add_child(_world_container)

func _build_zone_view(parent: VBoxContainer) -> void:
	_zone_container = VBoxContainer.new()
	_zone_container.add_theme_constant_override("separation", 10)
	_zone_container.visible = false
	parent.add_child(_zone_container)

	var back := Button.new()
	back.text = "← World"
	back.pressed.connect(func(): set_view("world"))
	_zone_container.add_child(back)

	_zone_title_label = Label.new()
	_zone_title_label.add_theme_font_size_override("font_size", 22)
	_zone_container.add_child(_zone_title_label)

	_zone_desc_label = Label.new()
	_zone_desc_label.add_theme_font_size_override("font_size", 13)
	_zone_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_zone_container.add_child(_zone_desc_label)

	_zone_container.add_child(HSeparator.new())

	_activity_container = VBoxContainer.new()
	_activity_container.add_theme_constant_override("separation", 8)
	_zone_container.add_child(_activity_container)

func _build_combat_view(parent: VBoxContainer) -> void:
	_combat_container = VBoxContainer.new()
	_combat_container.add_theme_constant_override("separation", 10)
	_combat_container.visible = false
	parent.add_child(_combat_container)

	# Zone label
	var zone_lbl := Label.new()
	zone_lbl.name = "ZoneLabel"
	zone_lbl.add_theme_font_size_override("font_size", 13)
	_combat_container.add_child(zone_lbl)

	# Side-by-side panels with overlay wrapper
	var panels_wrapper := Control.new()
	panels_wrapper.custom_minimum_size.y = 180
	panels_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_combat_container.add_child(panels_wrapper)

	var panels_hbox := HBoxContainer.new()
	panels_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panels_hbox.add_theme_constant_override("separation", 8)
	panels_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panels_wrapper.add_child(panels_hbox)

	# Player panel
	_player_panel = PanelContainer.new()
	_player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panels_hbox.add_child(_player_panel)

	var player_inner := VBoxContainer.new()
	player_inner.add_theme_constant_override("separation", 6)
	_player_panel.add_child(player_inner)

	var player_title := Label.new()
	player_title.text = "You"
	player_title.add_theme_font_size_override("font_size", 18)
	player_inner.add_child(player_title)

	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.custom_minimum_size.y = 18
	_player_hp_bar.show_percentage = false
	player_inner.add_child(_player_hp_bar)

	_player_hp_label = Label.new()
	_player_hp_label.add_theme_font_size_override("font_size", 12)
	player_inner.add_child(_player_hp_label)

	_player_stats_label = Label.new()
	_player_stats_label.add_theme_font_size_override("font_size", 11)
	_player_stats_label.modulate = Color(0.8, 0.8, 0.8)
	player_inner.add_child(_player_stats_label)

	# Enemy panel
	_enemy_panel = PanelContainer.new()
	_enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panels_hbox.add_child(_enemy_panel)

	var enemy_inner := VBoxContainer.new()
	enemy_inner.add_theme_constant_override("separation", 6)
	_enemy_panel.add_child(enemy_inner)

	_monster_name_label = Label.new()
	_monster_name_label.add_theme_font_size_override("font_size", 18)
	enemy_inner.add_child(_monster_name_label)

	_monster_hp_bar = ProgressBar.new()
	_monster_hp_bar.custom_minimum_size.y = 18
	_monster_hp_bar.show_percentage = false
	enemy_inner.add_child(_monster_hp_bar)

	_monster_hp_label = Label.new()
	_monster_hp_label.add_theme_font_size_override("font_size", 12)
	enemy_inner.add_child(_monster_hp_label)

	# Floating damage overlay on top of panels
	_damage_overlay = Control.new()
	_damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panels_wrapper.add_child(_damage_overlay)

	_combat_container.add_child(HSeparator.new())

	# Session stats row
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 20)
	_combat_container.add_child(stats_row)

	_kills_label = Label.new()
	_kills_label.text = "Kills: 0"
	_kills_label.add_theme_font_size_override("font_size", 13)
	stats_row.add_child(_kills_label)

	_xp_label = Label.new()
	_xp_label.text = "XP: 0"
	_xp_label.add_theme_font_size_override("font_size", 13)
	stats_row.add_child(_xp_label)

	_combat_container.add_child(HSeparator.new())

	# Loot log
	var loot_title := Label.new()
	loot_title.text = "Loot"
	loot_title.add_theme_font_size_override("font_size", 14)
	_combat_container.add_child(loot_title)

	_loot_log = RichTextLabel.new()
	_loot_log.bbcode_enabled = true
	_loot_log.fit_content = true
	_loot_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_loot_log.custom_minimum_size.y = 80
	_combat_container.add_child(_loot_log)

	_combat_container.add_child(HSeparator.new())

	var recall_btn := Button.new()
	recall_btn.text = "Recall"
	recall_btn.custom_minimum_size.y = 44
	recall_btn.pressed.connect(func(): ExpeditionManager.recall())
	_combat_container.add_child(recall_btn)

func _connect_signals() -> void:
	EventBus.player_hit_monster.connect(_on_player_hit)
	EventBus.player_missed.connect(func(): _spawn_number("Miss", Color.GRAY, false))
	EventBus.monster_hit_player.connect(_on_monster_hit)
	EventBus.monster_missed.connect(func(): _spawn_number("Miss", Color.GRAY, true))
	EventBus.monster_died.connect(_on_monster_died)
	EventBus.monster_spawned.connect(_on_monster_spawned)
	EventBus.player_died.connect(_on_player_died)
	EventBus.item_obtained.connect(_on_item_obtained)
	EventBus.expedition_ended.connect(func(_r): set_view("world"))
	EventBus.stat_xp_gained.connect(func(_s, amount): _xp_this_session += amount; _refresh_session_stats())
	EventBus.offline_progress_applied.connect(_on_offline_progress)

func _process(_delta: float) -> void:
	if ExpeditionManager.active:
		_refresh_player_hp()
		_refresh_monster_hp()

func set_view(view: String) -> void:
	_view = view
	_world_container.visible = (view == "world")
	_zone_container.visible = (view == "zone")
	_combat_container.visible = (view == "combat")
	if view == "world":
		_refresh_zone_list()
	elif view == "zone":
		_refresh_zone_detail()

func _refresh_zone_list() -> void:
	for child in _world_container.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "Where to?"
	title.add_theme_font_size_override("font_size", 22)
	_world_container.add_child(title)
	for zone in ResourceRegistry.get_all_zones():
		var z := zone as ZoneData
		var unlocked := z.required_unlock == "" or ResearchManager.is_unlocked(z.required_unlock)
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = z.name
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 16)
		row.add_child(lbl)
		var btn := Button.new()
		btn.text = "→"
		btn.disabled = not unlocked
		btn.pressed.connect(_on_zone_selected.bind(z))
		row.add_child(btn)
		_world_container.add_child(row)

func _on_zone_selected(zone: ZoneData) -> void:
	_selected_zone = zone
	set_view("zone")

func _refresh_zone_detail() -> void:
	if not _selected_zone:
		return
	_zone_title_label.text = _selected_zone.name
	_zone_desc_label.text = _selected_zone.description
	for child in _activity_container.get_children():
		child.queue_free()
	var roam_row := HBoxContainer.new()
	var roam_lbl := Label.new()
	roam_lbl.text = "Roam"
	roam_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roam_lbl.add_theme_font_size_override("font_size", 16)
	roam_row.add_child(roam_lbl)
	var roam_btn := Button.new()
	roam_btn.text = "Start"
	roam_btn.disabled = _selected_zone.roam_monsters.is_empty() or not GameManager.is_player_free()
	roam_btn.pressed.connect(_on_start_expedition.bind(ExpeditionManager.Mode.ROAM))
	roam_row.add_child(roam_btn)
	_activity_container.add_child(roam_row)

func _on_start_expedition(mode: ExpeditionManager.Mode) -> void:
	if not _selected_zone:
		return
	_kills_this_session = 0
	_xp_this_session = 0.0
	_loot_lines.clear()
	_loot_log.text = ""
	_refresh_session_stats()
	ExpeditionManager.start(_selected_zone, mode)
	_refresh_combat_header()
	set_view("combat")

func _refresh_combat_header() -> void:
	if not ExpeditionManager.current_monster:
		return
	var zone_lbl := _combat_container.get_node("ZoneLabel") as Label
	if zone_lbl:
		zone_lbl.text = "%s — Roam" % ExpeditionManager.current_zone_id
	_refresh_player_stats()

func _refresh_player_hp() -> void:
	var hp := CharacterManager.current_hp
	var max_hp := CharacterManager.max_hp
	_player_hp_bar.max_value = max_hp
	_player_hp_bar.value = hp
	_player_hp_label.text = "%d / %d HP" % [hp, max_hp]

func _refresh_player_stats() -> void:
	var dmg := CharacterManager.get_weapon_damage()
	var acc := CharacterManager.get_total_accuracy()
	var def := CharacterManager.get_total_defense()
	_player_stats_label.text = "DMG %d  ACC %d  DEF %d" % [dmg, acc, def]

func _refresh_monster_hp() -> void:
	if not ExpeditionManager.current_monster:
		return
	var hp := ExpeditionManager._monster_hp
	var max_hp := ExpeditionManager.current_monster.hp
	_monster_hp_bar.max_value = max_hp
	_monster_hp_bar.value = maxi(0, hp)
	_monster_hp_label.text = "%d / %d HP" % [maxi(0, hp), max_hp]

func _refresh_session_stats() -> void:
	_kills_label.text = "Kills: %d" % _kills_this_session
	_xp_label.text = "XP: %d" % int(_xp_this_session)

func _on_player_hit(damage: int, _type: int, multiplier: float) -> void:
	if multiplier > 1.0:
		_spawn_number("-%d!" % damage, Color.YELLOW, false)
	else:
		_spawn_number("-%d" % damage, Color.WHITE, false)

func _on_monster_hit(damage: int) -> void:
	_spawn_number("-%d" % damage, Color(1.0, 0.35, 0.35), true)

func _on_monster_died(_monster: MonsterData) -> void:
	_kills_this_session += 1
	_refresh_session_stats()

func _on_monster_spawned(monster: MonsterData) -> void:
	_monster_name_label.text = monster.name
	_monster_hp_bar.max_value = monster.hp
	_monster_hp_bar.value = monster.hp
	_monster_hp_label.text = "%d / %d HP" % [monster.hp, monster.hp]

func _on_player_died() -> void:
	set_view("world")

func _on_item_obtained(item: ItemData, qty: int) -> void:
	if _view != "combat":
		return
	var line := "[color=gold]+ %s x%d[/color]" % [item.name, qty]
	_loot_lines.append(line)
	if _loot_lines.size() > LOOT_MAX:
		_loot_lines = _loot_lines.slice(_loot_lines.size() - LOOT_MAX)
	_loot_log.text = "\n".join(_loot_lines)

func _on_offline_progress(elapsed: float, summary: Dictionary) -> void:
	var mins := int(elapsed / 60)
	_kills_this_session += summary.get("kills", 0)
	_refresh_session_stats()
	var line := "[color=cyan]Offline %dm: %d kills[/color]" % [mins, summary.get("kills", 0)]
	_loot_lines.append(line)
	for item_name in summary.get("drops", {}):
		_loot_lines.append("[color=gold]+ %s x%d[/color]" % [item_name, summary["drops"][item_name]])
	_loot_log.text = "\n".join(_loot_lines)

func _spawn_number(text: String, color: Color, on_player: bool) -> void:
	if not _damage_overlay or not _damage_overlay.is_inside_tree():
		return

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_damage_overlay.add_child(lbl)

	# Position: left half = player (on_player=true), right half = enemy
	var overlay_size := _damage_overlay.size
	var x_center := overlay_size.x * (0.25 if on_player else 0.75)
	var y_start := overlay_size.y * 0.5
	lbl.position = Vector2(x_center - 20.0 + randf_range(-20, 20), y_start)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lbl, "position:y", y_start - 60.0, 0.9)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(lbl.queue_free)
