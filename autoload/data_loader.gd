extends Node
## Safe, reusable JSON loader for res://data/ files.

var _cache: Dictionary = {}


func load_json(relative_path: String, required_keys: Array[String] = []) -> Variant:
	var full_path := relative_path
	if not full_path.begins_with("res://"):
		full_path = "res://data/" + relative_path.trim_prefix("/")

	if _cache.has(full_path):
		return _cache[full_path]

	if not FileAccess.file_exists(full_path):
		push_error("[DataLoader] Missing JSON file: %s" % full_path)
		return null

	var file := FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		push_error("[DataLoader] Failed to open JSON file: %s (err=%d)" % [full_path, FileAccess.get_open_error()])
		return null

	var raw := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(raw)
	if err != OK:
		push_error("[DataLoader] Malformed JSON in %s at line %d: %s" % [full_path, json.get_error_line(), json.get_error_message()])
		return null

	var data: Variant = json.data
	if required_keys.size() > 0 and data is Dictionary:
		for key in required_keys:
			if not (data as Dictionary).has(key):
				push_error("[DataLoader] Missing required field '%s' in %s" % [key, full_path])
				return null

	_cache[full_path] = data
	return data


func get_levels() -> Array:
	var data = load_json("res://data/story/levels.json", ["levels"])
	if data == null:
		return []
	return data.get("levels", [])


func clear_cache() -> void:
	_cache.clear()
