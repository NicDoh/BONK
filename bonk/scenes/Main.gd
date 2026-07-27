extends Control

var monster_name_label: Label
var monster_hp_label: Label
var monster_hp_bar: ProgressBar

var player_hp_label: Label
var player_hp_bar: ProgressBar

var combat_log: RichTextLabel
var action_button: Button
var stats_label: Label

var _log_lines: Array[String] = []
const LOG_MAX := 8

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 16)
	margin.add_child(inner)

	# Monster section
	var monster_section := VBoxContainer.new()
	inner.add_child(monster_section)

	monster_name_label = Label.new()
	monster_name_label.text = "No monster"
	monster_name_label.add_theme_font_size_override("font_size", 22)
	monster_section.add_child(monster_name_label)

	monster_hp_bar = ProgressBar.new()
	monster_hp_bar.min_value = 0
	monster_hp_bar.value = 0
	monster_hp_bar.custom_minimum_size.y = 24
	monster_section.add_child(monster_hp_bar)

	monster_hp_label = Label.new()
	monster_hp_label.text = ""
	monster_section.add_child(monster_hp_label)

	inner.add_child(HSeparator.new())

	# Player section
	var player_section := VBoxContainer.new()
	inner.add_child(player_section)

	var player_title := Label.new()
	player_title.text = "You"
	player_title.add_theme_font_size_override("font_size", 22)
	player_section.add_child(player_title)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.min_value = 0
	player_hp_bar.custom_minimum_size.y = 24
	player_section.add_child(player_hp_bar)

	player_hp_label = Label.new()
	player_section.add_child(player_hp_label)

	inner.add_child(HSeparator.new())

	# Stats panel
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 13)
	inner.add_child(stats_label)
	_refresh_stats()

	inner.add_child(HSeparator.new())

	# Combat log
	combat_log = RichTextLabel.new()
	combat_log.bbcode_enabled = true
	combat_log.fit_content = false
	combat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_log.custom_minimum_size.y = 160
	inner.add_child(combat_log)

	# Button
	action_button = Button.new()
	action_button.text = "Start Expedition"
	action_button.custom_minimum_size.y = 48
	action_button.pressed.connect(_on_action_pressed)
	inner.add_child(action_button)

	# Connect EventBus signals
	EventBus.player_hit_monster.connect(_on_player_hit)
	EventBus.player_missed.connect(_on_player_missed)
	EventBus.monster_hit_player.connect(_on_monster_hit)
	EventBus.player_blocked.connect(_on_player_blocked)
	EventBus.monster_missed.connect(_on_monster_missed)
	EventBus.monster_died.connect(_on_monster_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.item_obtained.connect(_on_item_obtained)
	EventBus.expedition_ended.connect(_on_expedition_ended)
	EventBus.stat_leveled_up.connect(_on_stat_leveled_up)
	EventBus.stat_xp_gained.connect(func(_s, _a): _refresh_stats())

	_refresh_player_hp()

func _process(_delta: float) -> void:
	if ExpeditionManager.active:
		_refresh_player_hp()
		_refresh_monster_hp()

func _on_action_pressed() -> void:
	if ExpeditionManager.active:
		ExpeditionManager.recall()
		action_button.text = "Start Expedition"
	else:
		var monster := load("res://data/test_monster.tres") as MonsterData
		ExpeditionManager.start("test_zone", monster)
		monster_name_label.text = monster.name
		monster_hp_bar.max_value = monster.hp
		monster_hp_bar.value = monster.hp
		monster_hp_label.text = "%d / %d" % [monster.hp, monster.hp]
		action_button.text = "Recall"
		_log("--- Expedition started ---")

func _refresh_player_hp() -> void:
	var hp := CharacterManager.current_hp
	var max_hp := CharacterManager.max_hp
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = hp
	player_hp_label.text = "%d / %d HP" % [hp, max_hp]

func _refresh_monster_hp() -> void:
	var hp := ExpeditionManager._monster_hp
	var max_hp := ExpeditionManager.current_monster.hp if ExpeditionManager.current_monster else 1
	monster_hp_bar.value = maxi(0, hp)
	monster_hp_label.text = "%d / %d" % [maxi(0, hp), max_hp]

func _on_player_hit(damage: int, _type: int, multiplier: float) -> void:
	if multiplier > 1.0:
		_log("[color=yellow]You hit for %d (WEAK!)[/color]" % damage)
	elif multiplier < 1.0:
		_log("[color=gray]You hit for %d (resisted)[/color]" % damage)
	else:
		_log("You hit for %d" % damage)

func _on_player_missed() -> void:
	_log("[color=gray]You missed.[/color]")

func _on_monster_hit(damage: int) -> void:
	_log("[color=red]Monster hits you for %d[/color]" % damage)

func _on_player_blocked(_damage: int) -> void:
	_log("[color=cyan]You blocked![/color]")

func _on_monster_missed() -> void:
	_log("[color=gray]Monster missed.[/color]")

func _on_monster_died(_monster: MonsterData) -> void:
	_log("[color=green]Monster defeated![/color]")

func _on_player_died() -> void:
	_log("[color=red]You died.[/color]")
	action_button.text = "Start Expedition"

func _on_item_obtained(item: ItemData, quantity: int) -> void:
	_log("[color=gold]Drop: %s x%d[/color]" % [item.name, quantity])

func _on_expedition_ended(_result: Dictionary) -> void:
	action_button.text = "Start Expedition"

func _on_stat_leveled_up(stat_name: String, new_level: int) -> void:
	_log("[color=cyan]%s leveled up to %d![/color]" % [stat_name.capitalize(), new_level])
	_refresh_stats()

func _refresh_stats() -> void:
	var lines := []
	for stat in ["hp", "strength", "defense", "speed", "accuracy"]:
		var level := CharacterManager.get_level(stat)
		var xp: float = CharacterManager.stats[stat]["xp"]
		var needed := CharacterManager.xp_for_level(level + 1)
		lines.append("%s: %d  (%.0f / %.0f xp)" % [stat.capitalize(), level, xp, needed])
	stats_label.text = "\n".join(lines)

func _log(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > LOG_MAX:
		_log_lines = _log_lines.slice(_log_lines.size() - LOG_MAX)
	combat_log.text = "\n".join(_log_lines)
