class_name ZoneData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var roam_monsters: Array[ZoneMonsterEntry] = []
@export var boss: MonsterData = null
@export var required_unlock: String = ""
