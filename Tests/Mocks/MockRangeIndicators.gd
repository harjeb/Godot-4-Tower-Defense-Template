extends Node
class_name MockRangeIndicators

## Mock Range Indicators System for testing
## Simulates visual range indicators functionality

signal indicator_created(indicator_type: String, target: Node)
signal indicator_updated(indicator: Node)
signal indicator_hidden(indicator: Node)

var active_indicators: Dictionary = {}  # target_id -> [indicators]
var indicator_pool: Array = []  # Object pool for indicators
var update_timer: Timer

func _ready():
	# Initialize mock indicators
	initialize_indicators()
	
	# Setup update timer
	update_timer = Timer.new()
	update_timer.wait_time = 0.2
	update_timer.timeout.connect(_on_update_timer)
	add_child(update_timer)
	update_timer.start()

func initialize_indicators():
	"""Initialize mock indicator system"""
	# Create indicator pool
	for i in range(20):
		var indicator = create_mock_indicator()
		indicator_pool.append(indicator)

func create_mock_indicator() -> Node:
	"""Create a mock indicator"""
	var indicator = Node2D.new()
	indicator.name = "MockIndicator"
	indicator.visible = false
	return indicator

func show_attack_range(target: Node) -> bool:
	"""Show attack range indicator for target"""
	if not target:
		return false
	
	var indicator = get_pooled_indicator()
	if not indicator:
		return false
	
	setup_attack_range_indicator(indicator, target)
	indicator.visible = true
	
	var target_id = target.get_instance_id()
	if not active_indicators.has(target_id):
		active_indicators[target_id] = []
	
	active_indicators[target_id].append(indicator)
	indicator_created.emit("attack_range", target)
	
	return true

func hide_attack_range(target: Node) -> bool:
	"""Hide attack range indicator for target"""
	if not target:
		return false
	
	var target_id = target.get_instance_id()
	if not active_indicators.has(target_id):
		return false
	
	var indicators_to_remove = []
	for indicator in active_indicators[target_id]:
		if is_attack_range_indicator(indicator):
			indicators_to_remove.append(indicator)
	
	for indicator in indicators_to_remove:
		hide_indicator(indicator, target)
	
	return true

func show_hero_aura(target: Node) -> bool:
	"""Show hero aura indicator for target"""
	if not target:
		return false
	
	var indicator = get_pooled_indicator()
	if not indicator:
		return false
	
	setup_aura_indicator(indicator, target)
	indicator.visible = true
	
	var target_id = target.get_instance_id()
	if not active_indicators.has(target_id):
		active_indicators[target_id] = []
	
	active_indicators[target_id].append(indicator)
	indicator_created.emit("aura", target)
	
	return true

func show_skill_range(target: Node, skill_index: int) -> bool:
	"""Show skill range indicator for target"""
	if not target or skill_index < 0:
		return false
	
	var indicator = get_pooled_indicator()
	if not indicator:
		return false
	
	setup_skill_range_indicator(indicator, target, skill_index)
	indicator.visible = true
	
	var target_id = target.get_instance_id()
	if not active_indicators.has(target_id):
		active_indicators[target_id] = []
	
	active_indicators[target_id].append(indicator)
	indicator_created.emit("skill_range", target)
	
	return true

func hide_all_skill_ranges(target: Node) -> bool:
	"""Hide all skill range indicators for target"""
	if not target:
		return false
	
	var target_id = target.get_instance_id()
	if not active_indicators.has(target_id):
		return true
	
	var indicators_to_remove = []
	for indicator in active_indicators[target_id]:
		if is_skill_range_indicator(indicator):
			indicators_to_remove.append(indicator)
	
	for indicator in indicators_to_remove:
		hide_indicator(indicator, target)
	
	return true

func get_pooled_indicator() -> Node:
	"""Get indicator from pool"""
	for indicator in indicator_pool:
		if not indicator.visible:
			return indicator
	
	# Create new indicator if pool is empty
	var new_indicator = create_mock_indicator()
	indicator_pool.append(new_indicator)
	return new_indicator

func setup_attack_range_indicator(indicator: Node, target: Node):
	"""Setup attack range indicator"""
	indicator.set_meta("type", "attack_range")
	indicator.set_meta("target", target)
	
	# Set size based on target attack range
	if target.has_method("get_attack_range"):
		var range = target.get_attack_range()
		indicator.set_meta("range", range)

func setup_aura_indicator(indicator: Node, target: Node):
	"""Setup aura indicator"""
	indicator.set_meta("type", "aura")
	indicator.set_meta("target", target)
	
	# Set aura properties
	if target.has_method("get_aura_range"):
		var range = target.get_aura_range()
		indicator.set_meta("range", range)

func setup_skill_range_indicator(indicator: Node, target: Node, skill_index: int):
	"""Setup skill range indicator"""
	indicator.set_meta("type", "skill_range")
	indicator.set_meta("target", target)
	indicator.set_meta("skill_index", skill_index)
	
	# Set skill range properties
	if target.has_method("get_skill_range"):
		var range = target.get_skill_range(skill_index)
		indicator.set_meta("range", range)

func hide_indicator(indicator: Node, target: Node):
	"""Hide and return indicator to pool"""
	indicator.visible = false
	indicator.clear_meta()
	
	var target_id = target.get_instance_id()
	if active_indicators.has(target_id):
		var index = active_indicators[target_id].find(indicator)
		if index >= 0:
			active_indicators[target_id].remove_at(index)
	
	indicator_hidden.emit(indicator)

func is_attack_range_indicator(indicator: Node) -> bool:
	"""Check if indicator is attack range type"""
	return indicator.get_meta("type") == "attack_range"

func is_skill_range_indicator(indicator: Node) -> bool:
	"""Check if indicator is skill range type"""
	return indicator.get_meta("type") == "skill_range"

func cleanup_indicators():
	"""Clean up all indicators"""
	for target_id in active_indicators:
		for indicator in active_indicators[target_id]:
			hide_indicator(indicator, indicator.get_meta("target"))
	
	active_indicators.clear()

func batch_update_indicators():
	"""Update all indicators in batch"""
	for target_id in active_indicators:
		for indicator in active_indicators[target_id]:
			update_indicator(indicator)

func update_indicator(indicator: Node):
	"""Update single indicator"""
	var target = indicator.get_meta("target")
	if target and is_instance_valid(target):
		# Update position to follow target
		if target.has_method("get_global_position"):
			indicator.global_position = target.get_global_position()
		
		# Update size based on target stats
		if indicator.get_meta("type") == "attack_range" and target.has_method("get_attack_range"):
			var range = target.get_attack_range()
			indicator.set_meta("range", range)
		
		indicator_updated.emit(indicator)

func _on_update_timer():
	"""Handle update timer timeout"""
	batch_update_indicators()

func get_indicator_count() -> int:
	"""Get total number of active indicators"""
	var count = 0
	for target_id in active_indicators:
		count += active_indicators[target_id].size()
	return count

func get_indicators_for_target(target: Node) -> Array:
	"""Get all indicators for specific target"""
	var target_id = target.get_instance_id()
	return active_indicators.get(target_id, [])

func is_indicator_visible_for_target(target: Node, indicator_type: String) -> bool:
	"""Check if specific indicator type is visible for target"""
	var indicators = get_indicators_for_target(target)
	for indicator in indicators:
		if indicator.get_meta("type") == indicator_type and indicator.visible:
			return true
	return false

func set_indicator_color(indicator_type: String, color: Color):
	"""Set color for indicator type"""
	# This would update the visual appearance
	pass

func set_indicator_opacity(indicator_type: String, opacity: float):
	"""Set opacity for indicator type"""
	# This would update the visual appearance
	pass

func set_indicator_line_width(indicator_type: String, width: float):
	"""Set line width for indicator type"""
	# This would update the visual appearance
	pass

func debug_print_indicator_info():
	"""Print debug information about indicators"""
	print("Active Indicators: %d" % get_indicator_count())
	print("Pool Size: %d" % indicator_pool.size())
	print("Active Targets: %d" % active_indicators.size())