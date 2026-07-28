extends ScrollContainer

signal navigate_to(screen_id: String)

var _status_label: Label
var _research_container: VBoxContainer

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	add_child(inner)

	var back := Button.new()
	back.text = "← Tribe"
	back.pressed.connect(navigate_to.emit.bind("tribe"))
	inner.add_child(back)

	var title := Label.new()
	title.text = "Thinkery"
	title.add_theme_font_size_override("font_size", 22)
	inner.add_child(title)

	inner.add_child(HSeparator.new())

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 13)
	inner.add_child(_status_label)

	_research_container = VBoxContainer.new()
	_research_container.add_theme_constant_override("separation", 8)
	inner.add_child(_research_container)

	EventBus.research_completed.connect(func(_r): refresh())
	EventBus.content_unlocked.connect(func(_id): refresh())

func _process(_delta: float) -> void:
	if ResearchManager.active_research_id != "":
		var secs := ResearchManager.time_remaining()
		_status_label.text = "Researching: %s  (%.0fs left)" % [ResearchManager.active_research_id, secs]

func refresh() -> void:
	if ResearchManager.active_research_id != "":
		var secs := ResearchManager.time_remaining()
		_status_label.text = "Researching: %s  (%.0fs left)" % [ResearchManager.active_research_id, secs]
	else:
		_status_label.text = "Idle"

	for child in _research_container.get_children():
		child.queue_free()

	var all := ResourceRegistry.get_all_research()
	for data in ResearchManager.get_available(all):
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s  (%ds)" % [data.title, int(data.duration_seconds)]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var btn := Button.new()
		btn.text = "Research"
		btn.disabled = ResearchManager.active_research_id != ""
		btn.pressed.connect(func(): ResearchManager.start(data); refresh())
		row.add_child(btn)
		_research_container.add_child(row)

	for data in all:
		if not ResearchManager.is_completed(data.id):
			continue
		var done_label := Label.new()
		done_label.text = "✓ %s" % data.title
		_research_container.add_child(done_label)
