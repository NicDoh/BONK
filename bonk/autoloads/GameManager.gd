extends Node

const MAX_OFFLINE_SECONDS := 3600.0

var pending_offline_summary: Dictionary = {}

func _ready() -> void:
	SaveManager.load_save()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save()

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
