class_name OggsHearthScreen
extends ScrollContainer

signal navigate_to(screen_id: String)

const STATS := ["strength", "defense", "constitution", "accuracy"]
const STAT_LABELS := {"strength": "Strength", "defense": "Defense", "constitution": "Constitution", "accuracy": "Accuracy"}

var _buttons: Dictionary = {}

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	add_child(inner)

	var back := Button.new()
	back.text = "← Back"
	back.pressed.connect(navigate_to.emit.bind("tribe"))
	inner.add_child(back)

	var title := Label.new()
	title.text = "Ogg's Hearth"
	title.add_theme_font_size_override("font_size", 22)
	inner.add_child(title)

	inner.add_child(HSeparator.new())

	var sub := Label.new()
	sub.text = "Training Focus"
	sub.add_theme_font_size_override("font_size", 16)
	inner.add_child(sub)

	var desc := Label.new()
	desc.text = "Choose one stat to train. All XP from combat goes to the chosen stat."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(desc)

	for stat in STATS:
		var btn := Button.new()
		btn.text = STAT_LABELS[stat]
		btn.custom_minimum_size.y = 56
		btn.toggle_mode = true
		btn.pressed.connect(_on_stat_pressed.bind(stat))
		inner.add_child(btn)
		_buttons[stat] = btn

	_refresh_buttons()
	EventBus.training_focus_changed.connect(_on_focus_changed)

func _on_stat_pressed(stat: String) -> void:
	CharacterManager.set_training(stat)

func _on_focus_changed(_stat: String) -> void:
	_refresh_buttons()

func _refresh_buttons() -> void:
	for stat in _buttons:
		_buttons[stat].button_pressed = (stat == CharacterManager.active_training)
