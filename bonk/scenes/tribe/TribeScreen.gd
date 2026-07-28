extends ScrollContainer

signal navigate_to(screen_id: String)

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	add_child(inner)

	var title := Label.new()
	title.text = "The Tribe"
	title.add_theme_font_size_override("font_size", 22)
	inner.add_child(title)

	inner.add_child(HSeparator.new())

	for building in [["bonkery", "Bonkery"], ["thinkery", "Thinkery"]]:
		var btn := Button.new()
		btn.text = building[1]
		btn.custom_minimum_size.y = 48
		btn.pressed.connect(navigate_to.emit.bind(building[0]))
		inner.add_child(btn)
