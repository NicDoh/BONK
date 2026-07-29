extends Control

var _current_screen: String = ""
var _screens: Dictionary = {}

var _expedition: ExpeditionScreen
var _character: CharacterScreen
var _tribe: TribeScreen
var _bonkery: BonkeryScreen
var _thinkery: ThinkeryScreen
var _oggsHearth: OggsHearthScreen

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var screen_container := MarginContainer.new()
	screen_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		screen_container.add_theme_constant_override("margin_" + side, 16)
	root.add_child(screen_container)

	_expedition = ExpeditionScreen.new()
	_character = CharacterScreen.new()
	_tribe = TribeScreen.new()
	_bonkery = BonkeryScreen.new()
	_thinkery = ThinkeryScreen.new()
	_oggsHearth = OggsHearthScreen.new()

	_tribe.navigate_to.connect(_navigate)
	_bonkery.navigate_to.connect(_navigate)
	_thinkery.navigate_to.connect(_navigate)
	_oggsHearth.navigate_to.connect(_navigate)

	for screen in [_expedition, _character, _tribe, _bonkery, _thinkery, _oggsHearth]:
		screen.visible = false
		screen_container.add_child(screen)

	_screens = {
		"expedition": _expedition,
		"character": _character,
		"tribe": _tribe,
		"bonkery": _bonkery,
		"thinkery": _thinkery,
		"oggsHearth": _oggsHearth,
	}

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 0)
	root.add_child(nav)

	for screen_id in ["expedition", "character", "tribe"]:
		var labels := {"expedition": "Expedition", "character": "Character", "tribe": "Tribe"}
		var btn := Button.new()
		btn.text = labels[screen_id]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_navigate.bind(screen_id))
		nav.add_child(btn)

	_navigate("expedition")

	if not GameManager.pending_offline_summary.is_empty():
		var s := GameManager.pending_offline_summary
		_expedition._on_offline_progress(s["elapsed"], s)
		GameManager.pending_offline_summary = {}

func _navigate(screen_id: String) -> void:
	if _current_screen == screen_id:
		return
	for id in _screens:
		_screens[id].visible = (id == screen_id)
	_current_screen = screen_id
	match screen_id:
		"character": _character.refresh()
		"bonkery":  _bonkery.refresh()
		"thinkery": _thinkery.refresh()
