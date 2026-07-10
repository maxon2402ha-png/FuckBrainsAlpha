extends Node

var session_id: String
var log_data: Dictionary = {}
var events: Array = []
var start_time: int


var total_shots: int = 0
var total_hits: int = 0
var enemies_killed: int = 0
var items_collected: Array = []

func _ready():
	session_id = "run_" + str(Time.get_unix_time_from_system())
	start_time = Time.get_ticks_msec()

	log_data = {
		"session_id": session_id, 
		"total_time_seconds": 0.0, 
		"end_reason": "unknown", 
		"damage_taken_sources": {}, 
		"stuck_count": 0, 
		"combat_stats": {}, 
		"items_collected": items_collected, 
		"events": events
	}

func log_event(type: String, message: String, pos: Vector3 = Vector3.ZERO):
	var time_sec = (Time.get_ticks_msec() - start_time) / 1000.0
	events.append({
		"time": snapped(time_sec, 0.1), 
		"type": type, 
		"message": message, 
		"position": {"x": snapped(pos.x, 0.1), "y": snapped(pos.y, 0.1), "z": snapped(pos.z, 0.1)}
	})

func log_damage_taken(source_name: String, amount: float):
	if log_data["damage_taken_sources"].has(source_name):
		log_data["damage_taken_sources"][source_name] += amount
	else:
		log_data["damage_taken_sources"][source_name] = amount

func log_item(item_name: String):
	items_collected.append(item_name)
	log_event("item", "Picked up: " + item_name)

func log_shot(): total_shots += 1
func log_hit(): total_hits += 1
func log_kill(): enemies_killed += 1

func end_session(reason: String, death_pos: Vector3 = Vector3.ZERO):
	log_data["end_reason"] = reason
	log_data["total_time_seconds"] = (Time.get_ticks_msec() - start_time) / 1000.0


	var accuracy = 0.0
	if total_shots > 0:
		accuracy = (float(total_hits) / float(total_shots)) * 100.0

	log_data["combat_stats"] = {
		"shots_fired": total_shots, 
		"shots_hit": total_hits, 
		"accuracy_percent": snapped(accuracy, 0.1), 
		"enemies_killed": enemies_killed
	}

	if death_pos != Vector3.ZERO:
		log_data["death_position"] = {"x": snapped(death_pos.x, 0.1), "y": snapped(death_pos.y, 0.1), "z": snapped(death_pos.z, 0.1)}

	var dir = DirAccess.open("user://")
	if not dir.dir_exists("qa_logs"): dir.make_dir("qa_logs")
	var path = "user://qa_logs/" + session_id + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(log_data, "\t"))
		file.close()

	if Global.get("is_auto_test") == true:
		get_tree().quit()
