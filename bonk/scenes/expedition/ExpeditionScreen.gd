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

var _combat_zone_label: Label
var _monster_name_label: Label
var _monster_hp_label: Label
var _monster_hp_bar: ProgressBar
var _player_hp_label: Label
var _player_hp_bar: ProgressBar
var _combat_log: RichTextLabel

var _log_lines: Array[String] = []
const LOG_MAX := 8

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	add_child(inner)

	_world_container = VBoxContainer.new()
	_world_container.add_theme_constant_override("separation", 12)
	inner.add_child(_world_container)

	_zone_container = VBoxContainer.new()
	_zone_container.add_theme_constant_override("separation", 12)
	_zone_container.visible = false
	inner.add_child(_zone_container)

	var zone_back := Button.new()
	zone_back.text = "← World"
	zone_back.pressed.connect(func(): set_view("world"))
	_zone_container.add_child(zone_back)

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

	_combat_container = VBoxContainer.new()
	_combat_container.add_theme_constant_override("separation", 12)
	_combat_container.visible = false
	inner.add_child(_combat_container)

	_combat_zone_label = Label.new()
	_combat_zone_label.add_theme_font_size_override("font_size", 13)
	_combat_container.add_child(_combat_zone_label)

	_monster_name_label = Label.new()
	_monster_name_label.add_theme_font_size_override("font_size", 22)
	_combat_container.add_child(_monster_name_label)

	_monster_hp_bar = ProgressBar.new()
	_monster_hp_bar.min_value = 0
	_monster_hp_bar.custom_minimum_size.y = 20
	_combat_container.add_child(_monster_hp_bar)

	_monster_hp_label = Label.new()
	_combat_container.add_child(_monster_hp_label)

	_combat_container.add_child(HSeparator.new())

	var player_title := Label.new()
	player_title.text = "You"
	player_title.add_theme_font_size_override("font_size", 22)
	_combat_container.add_child(player_title)

	_player_hp_bar = ProgressBar.new()
	_player_hp_bar.min_value = 0
	_player_hp_bar.custom_minimum_size.y = 20
	_combat_container.add_child(_player_hp_bar)

	_player_hp_label = Label.new()
	_combat_container.add_child(_player_hp_label)

	_combat_container.add_child(HSeparator.new())

	_combat_log = RichTextLabel.new()
	_combat_log.bbcode_enabled = true
	_combat_log.fit_content = true
	_combat_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_combat_container.add_child(_combat_log)

	_combat_container.add_child(HSeparator.new())

	var recall_btn := Button.new()
	recall_btn.text = "Recall"
	recall_btn.custom_minimum_size.y = 48
	recall_btn.pressed.connect(_on_recall_pressed)
	_combat_container.add_child(recall_btn)

	EventBus.player_hit_monster.connect(_on_player_hit)
	EventBus.player_missed.connect(func(): log_line("[color=gray]You missed.[/color]"))
	EventBus.monster_hit_player.connect(func(d): log_line("[color=red]Monster hits you for %d[/color]" % d))
	EventBus.player_blocked.connect(func(_d): log_line("[color=cyan]You blocked![/color]"))
	EventBus.monster_missed.connect(func(): log_line("[color=gray]Monster missed.[/color]"))
	EventBus.monster_died.connect(func(_m): log_line("[color=green]Monster defeated![/color]"))
	EventBus.monster_spawned.connect(_on_monster_spawned)
	EventBus.player_died.connect(_on_player_died)
	EventBus.item_obtained.connect(func(item, qty): log_line("[color=gold]Drop: %s x%d[/color]" % [item.name, qty]))
	EventBus.expedition_ended.connect(func(_r): set_view("world"))
	EventBus.offline_progress_applied.connect(_on_offline_progress)

	if ExpeditionManager.active and ExpeditionManager.current_monster:
		_refresh_combat_header()
		set_view("combat")
	else:
		set_view("world")

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
	roam_btn.disabled = _selected_zone.roam_monsters.is_empty()
	roam_btn.pressed.connect(_on_start_expedition.bind(ExpeditionManager.Mode.ROAM))
	roam_row.add_child(roam_btn)
	_activity_container.add_child(roam_row)
	var boss_row := HBoxContainer.new()
	var boss_lbl := Label.new()
	boss_lbl.text = "Boss Run"
	boss_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_lbl.add_theme_font_size_override("font_size", 16)
	boss_row.add_child(boss_lbl)
	var boss_btn := Button.new()
	boss_btn.text = "Start"
	boss_btn.disabled = true
	boss_row.add_child(boss_btn)
	_activity_container.add_child(boss_row)

func _on_start_expedition(mode: ExpeditionManager.Mode) -> void:
	if not _selected_zone:
		return
	ExpeditionManager.start(_selected_zone, mode)
	_refresh_combat_header()
	set_view("combat")
	log_line("--- %s — Roam ---" % _selected_zone.name)

func _refresh_combat_header() -> void:
	if not ExpeditionManager.current_monster:
		return
	var monster := ExpeditionManager.current_monster
	_combat_zone_label.text = "%s — Roam" % ExpeditionManager.current_zone_id
	_monster_name_label.text = monster.name
	_monster_hp_bar.max_value = monster.hp
	_monster_hp_bar.value = ExpeditionManager._monster_hp

func _on_recall_pressed() -> void:
	ExpeditionManager.recall()

func _refresh_player_hp() -> void:
	var hp := CharacterManager.current_hp
	var max_hp := CharacterManager.max_hp
	_player_hp_bar.max_value = max_hp
	_player_hp_bar.value = hp
	_player_hp_label.text = "%d / %d HP" % [hp, max_hp]

func _refresh_monster_hp() -> void:
	var hp := ExpeditionManager._monster_hp
	var max_hp := ExpeditionManager.current_monster.hp if ExpeditionManager.current_monster else 1
	_monster_hp_bar.value = maxi(0, hp)
	_monster_hp_label.text = "%d / %d" % [maxi(0, hp), max_hp]

func _on_player_hit(damage: int, _type: int, multiplier: float) -> void:
	if multiplier > 1.0:
		log_line("[color=yellow]You hit for %d (WEAK!)[/color]" % damage)
	elif multiplier < 1.0:
		log_line("[color=gray]You hit for %d (resisted)[/color]" % damage)
	else:
		log_line("You hit for %d" % damage)

func _on_monster_spawned(monster: MonsterData) -> void:
	_monster_name_label.text = monster.name
	_monster_hp_bar.max_value = monster.hp
	_monster_hp_bar.value = monster.hp
	_monster_hp_label.text = "%d / %d" % [monster.hp, monster.hp]

func _on_player_died() -> void:
	log_line("[color=red]You died.[/color]")
	set_view("world")

func _on_offline_progress(elapsed: float, summary: Dictionary) -> void:
	var mins := int(elapsed / 60)
	log_line("[color=gold]--- Offline: %dm, %d kills ---[/color]" % [mins, summary["kills"]])
	for item_name in summary["drops"]:
		log_line("[color=gold]  %s x%d[/color]" % [item_name, summary["drops"][item_name]])

func log_line(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > LOG_MAX:
		_log_lines = _log_lines.slice(_log_lines.size() - LOG_MAX)
	_combat_log.text = "\n".join(_log_lines)
