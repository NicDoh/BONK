extends Node

enum PlayerState { IDLE, EXPEDITION, RESEARCHING }

const MAX_OFFLINE_SECONDS := 3600.0

var player_state: PlayerState = PlayerState.IDLE
var pending_offline_summary: Dictionary = {}

func _ready() -> void:
	EventBus.expedition_started.connect(func(_z, _m): _set_state(PlayerState.EXPEDITION))
	EventBus.expedition_ended.connect(func(_r): _set_state(PlayerState.IDLE))
	EventBus.research_started.connect(func(_d): _set_state(PlayerState.RESEARCHING))
	EventBus.research_completed.connect(func(_d): _set_state(PlayerState.IDLE))
	SaveManager.load_save()
	_derive_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save()

func is_player_free() -> bool:
	return player_state == PlayerState.IDLE

func _set_state(state: PlayerState) -> void:
	player_state = state
	EventBus.player_state_changed.emit(state)

func _derive_state() -> void:
	if ExpeditionManager.active:
		player_state = PlayerState.EXPEDITION
	elif ResearchManager.active_research_id != "":
		player_state = PlayerState.RESEARCHING
	else:
		player_state = PlayerState.IDLE

func apply_offline_progress(saved_timestamp: float) -> void:
	if not ResearchManager.is_unlocked("offline_progress"):
		return
	if not ExpeditionManager.current_monster:
		return

	var elapsed := minf(Time.get_unix_time_from_system() - saved_timestamp, MAX_OFFLINE_SECONDS)
	if elapsed < 1.0:
		return

	var summary := ExpeditionManager.apply_offline_progress(elapsed)
	if not summary.is_empty():
		pending_offline_summary = summary
		EventBus.offline_progress_applied.emit(summary["elapsed"], summary)
