class_name AnomalyManager
extends Node
## The rules of an anomaly game: every loop shows the place either as it should be or with exactly one anomaly.
## PSX Anomaly Horror Texture Pack - bitkiln - https://bitkiln.itch.io
##
## Put one AnomalyManager in the scene and AnomalySwap nodes on the things that can change. Then, each time the
## player starts a new loop of the corridor (or street, or store):
##
##     manager.submit_choice(turned_back)   # the player turned back (true) or went on (false): right or wrong?
##     manager.start_loop()                 # resets everything, then picks 0 or 1 anomaly for the next loop
##
## start_loop() switches every swap back to normal, then picks an anomaly with the chance anomaly_chance (never on
## the first loop of a run when first_loop_normal is on: the first start_loop() and the loop reset_run() starts).
## With no_repeats on, the anomalies come in rounds: in every round each one comes as often as its weight says
## (weight 1: once, 2: twice, 0.5: every second round, 0: never) and never twice in a row. Swaps with the same
## anomaly_id switch together. streak counts the right choices in a row (the number on the sign); a wrong choice
## sets it back to 0; at goal the run is won (goal_reached). Most anomaly games also call reset_run() after a
## wrong choice ("back to loop 0", a normal loop); the demo does.
##
## Any node in the group "anomaly_swaps" with a set_anomaly(on: bool) method and an anomaly_id works, so you can
## add your own kinds of anomalies (a moved chair, a light that is off, a sound) next to the texture swaps.
##
## Nodes can come and go: start_loop() looks for the anomaly nodes again every loop, nodes that were freed or are
## about to be (queue_free on them or on a parent) are skipped everywhere, and an AnomalySwap that leaves the scene
## tree tells the manager right away. Breakable doors, picked-up props, streamed rooms and swapping the whole level
## yourself all work; a loop keeps its anomaly id even when the changed node is freed during the loop.

## A new loop started: its number (0, 1, 2 ...) and the anomaly id ("" = nothing is wrong).
signal loop_started(loop_index: int, anomaly_id: String)
## The player chose: right or wrong, and the streak after it.
signal choice_made(correct: bool, streak: int)
## The streak reached goal.
signal goal_reached(loops: int)

## The group every AnomalyManager joins (AnomalySwap tells the managers of this group when it leaves the tree).
const MANAGER_GROUP := &"anomaly_managers"

## The group of the anomaly nodes (AnomalySwap.GROUP).
@export var group := &"anomaly_swaps"
## Chance of an anomaly in a loop.
@export_range(0.0, 1.0, 0.01) var anomaly_chance := 0.6
## The first loop of a run (the first start_loop() and the loop reset_run() starts) always shows the place as it
## should be, so the player can learn it. Loops after a wrong choice are only normal if you call reset_run() then.
@export var first_loop_normal := true
## The anomalies come in rounds: each one as often as its weight says before the next round starts, never twice
## in a row. Off: every loop picks at random by weight (repeats are possible, but never twice in a row).
@export var no_repeats := true
## Right choices in a row that win the run.
@export var goal := 8
## Seed of the random choices. 0: a new seed every run.
@export var random_seed := 0

## Number of the current loop (counts every loop since the start).
var loop_index := -1
## Right choices in a row.
var streak := 0
## The anomaly of the current loop ("" = none).
var current_id := ""

var _swaps := {}
var _bag: Array[String] = []
var _credit := {}
var _last_id := ""
var _run_start := true
var _state := 1


func _ready() -> void:
	add_to_group(MANAGER_GROUP)
	_seed_random(random_seed if random_seed != 0 else randi())
	collect.call_deferred()


## True for an anomaly node that can still be used: not freed, inside the scene tree, and neither it nor one of
## its parents is queued for deletion.
static func is_alive(node: Variant) -> bool:
	if not is_instance_valid(node):
		return false
	var n := node as Node
	if n == null or not n.is_inside_tree():
		return false
	while n != null:
		if n.is_queued_for_deletion():
			return false
		n = n.get_parent()
	return true


## Finds the anomaly nodes of the group. start_loop() calls it every loop, so nodes you add or free are picked up
## by themselves; call it yourself after changing the level in the middle of a loop. Returns the number of
## anomaly ids.
func collect() -> int:
	if not is_inside_tree():
		return _swaps.size()
	_swaps.clear()
	for node in get_tree().get_nodes_in_group(group):
		if not is_alive(node) or not node.has_method("set_anomaly"):
			continue
		if node.has_method("is_valid") and not bool(node.call("is_valid")):
			continue
		var id := str(node.get("anomaly_id"))
		if id == "":
			id = str(node.name)
		if not _swaps.has(id):
			_swaps[id] = []
		(_swaps[id] as Array).append(node)
	# the round goes on: ids that are gone leave the bag, ids that are new join it
	var kept: Array[String] = []
	for id in _bag:
		if _swaps.has(id):
			kept.append(id)
	_bag = kept
	if not _credit.is_empty():
		for id in _swaps:
			if not _credit.has(id):
				_credit[id] = 0.0
				_add_credit(str(id))
	return _swaps.size()


## Drops one anomaly node right away (AnomalySwap calls it when it leaves the scene tree).
func forget(node: Node) -> void:
	for id in _swaps.keys():
		var list: Array = _swaps[id]
		list.erase(node)
		if list.is_empty():
			_swaps.erase(id)
			_bag.erase(str(id))


## Every anomaly id, sorted.
func get_anomaly_ids() -> PackedStringArray:
	collect()
	var ids := PackedStringArray(_swaps.keys())
	ids.sort()
	return ids


## The anomaly nodes of one id (only the ones that still exist).
func get_swaps(id: String) -> Array:
	var alive: Array = []
	for node in _swaps.get(id, []):
		if is_alive(node):
			alive.append(node)
	return alive


## Starts the next loop: everything back to normal, then 0 or 1 anomaly. allow_anomaly = false forces a normal
## loop. Returns the anomaly id ("" = none).
func start_loop(allow_anomaly := true) -> String:
	collect()
	loop_index += 1
	var first := _run_start
	_run_start = false
	var id := ""
	if allow_anomaly and not _swaps.is_empty() and not (first_loop_normal and first):
		if _randf() < anomaly_chance:
			id = _pick()
	_show(id)
	loop_started.emit(loop_index, id)
	return id


## True while the current loop has an anomaly.
func is_anomaly_active() -> bool:
	return current_id != ""


## What changed in the current loop (the description of its first swap), "" without anomaly.
func get_active_description() -> String:
	return describe(current_id)


## The description of an anomaly id.
func describe(id: String) -> String:
	for node in get_swaps(id):
		var text := str(node.get("description")) if "description" in node else ""
		if text != "" and text != "<null>":
			return text
	return id.replace("_", " ")


## Judges the player's choice for the current loop: turning back is right when there is an anomaly, going on is
## right when there is none. Updates the streak and returns true for a right choice.
func submit_choice(turned_back: bool) -> bool:
	var correct := turned_back == is_anomaly_active()
	streak = streak + 1 if correct else 0
	choice_made.emit(correct, streak)
	if correct and streak >= goal:
		goal_reached.emit(streak)
	return correct


## Starts a new run: streak 0 and a normal loop. The round of anomalies goes on, so a new run does not start with
## the ones the player has just seen.
func reset_run() -> void:
	streak = 0
	_run_start = true
	start_loop(false)


## Shows one anomaly id now ("" = everything normal), without counting a loop. For tests, screenshots, debug keys.
func force_anomaly(id: String) -> void:
	collect()
	_show(id if _swaps.has(id) else "")


## Every anomaly on (true) or off (false) at once: a "show me everything" switch for demos and screenshots.
func set_all_anomalies(on: bool) -> void:
	collect()
	for id in _swaps:
		for node in get_swaps(str(id)):
			node.call("set_anomaly", on)
	current_id = ""


func _show(id: String) -> void:
	for other in _swaps:
		if other != id:
			for node in get_swaps(str(other)):
				node.call("set_anomaly", false)
	if id != "":
		for node in get_swaps(id):
			node.call("set_anomaly", true)
	current_id = id
	if id != "":
		_last_id = id


## The weight of an anomaly id: the largest weight of its nodes (1 for nodes without one). 0 or less: never picked.
func get_weight(id: String) -> float:
	var w := 0.0
	var found := false
	for node in get_swaps(id):
		var value: Variant = node.get("weight")
		var nw := float(value) if value != null else 1.0
		w = nw if not found else maxf(w, nw)
		found = true
	return w


## Picks the anomaly of a loop ("" when every anomaly has weight 0).
func _pick() -> String:
	var ids: Array[String] = []
	for id in _swaps:
		if get_weight(str(id)) > 0.0:
			ids.append(str(id))
	if ids.is_empty():
		return ""
	var chosen := ""
	if no_repeats:
		# rounds: every id gets its weight as credit per round and enters the bag once per whole credit
		for _round in 64:
			var pool: Array[String] = []
			for id in _bag:
				if ids.has(id) and (id != _last_id or ids.size() == 1):
					pool.append(id)
			if not pool.is_empty():
				chosen = pool[mini(int(_randf() * pool.size()), pool.size() - 1)]
				break
			_new_round(ids)
		if chosen == "":
			chosen = ids[0]
		_bag.erase(chosen)
	else:
		if ids.size() > 1:
			ids.erase(_last_id)
		var total := 0.0
		for id in ids:
			total += get_weight(id)
		chosen = ids[ids.size() - 1]
		var r := _randf() * total
		for id in ids:
			r -= get_weight(id)
			if r <= 0.0:
				chosen = id
				break
	return chosen


func _new_round(ids: Array[String]) -> void:
	for id in ids:
		if not _credit.has(id):
			_credit[id] = 0.0
		_add_credit(id)


func _add_credit(id: String) -> void:
	var c := float(_credit.get(id, 0.0)) + maxf(get_weight(id), 0.0)
	while c >= 1.0 - 0.0001:
		_bag.append(id)
		c -= 1.0
	_credit[id] = maxf(c, 0.0)


# a small seeded random source of its own (the same seed gives the same run)
func _seed_random(value: int) -> void:
	_state = value & 0x7fffffff
	if _state == 0:
		_state = 1


func _randf() -> float:
	_state = (_state * 1103515245 + 12345) & 0x7fffffff
	return float(_state) / 2147483648.0
