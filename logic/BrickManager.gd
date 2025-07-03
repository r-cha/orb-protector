"""
BrickManager handles the creation, positioning, and management of bricks in the game.
Manages brick spawning, destruction, special brick effects, and game progression.
"""
extends Node2D

signal game_over
signal special_block_hit(type)

@onready var _brick_scene = preload("res://brick.tscn")

var _grid_width = 10
var _grid_height = 12
var _brick_size = Vector2(120, 60)
var _brick_spacing = Vector2(128, 64)  # 8px gap between bricks
var _start_position = Vector2(64, 100)
var current_round = 1  # Keep public for GameController access
var _bricks = []
var _base_spawn_probability = 0.6  # Base 60% chance for brick to spawn
var _base_special_probability = 0.15

func _ready():
	_spawn_new_row()

func _spawn_new_row():
	var new_row = []
	
	# Calculate dynamic spawn probability based on brick count
	var total_bricks = _get_total_brick_count()
	var spawn_probability = _base_spawn_probability
	if total_bricks > 50:
		spawn_probability = max(0.3, _base_spawn_probability - (total_bricks - 50) * 0.01)
	
	for x in _grid_width:
		# Random chance to spawn brick (creates gaps)
		if randf() > spawn_probability:
			new_row.append(null)
			continue
			
		var brick = _brick_scene.instantiate()
		add_child(brick)
		
		var pos = _start_position + Vector2(x * _brick_spacing.x, 0)
		brick.position = pos
		
		# Implement variable brick toughness with higher variance
		var hp = _get_varied_brick_hp()
		brick.set_hp(hp)
		
		if randf() < _base_special_probability:
			var special_type = "add" if randf() < 0.9 else "multiply"
			brick.set_special(special_type)
		
		brick.brick_destroyed.connect(_on_brick_destroyed)
		new_row.append(brick)
	
	_bricks.insert(0, new_row)
	current_round += 1

func _on_brick_destroyed(brick):
	if brick.is_special_block:
		emit_signal("special_block_hit", brick.special_type)
	
	# Remove from grid tracking
	for row in _bricks:
		var index = row.find(brick)
		if index != -1:
			row[index] = null
			break

func descend_bricks():
	# Move all bricks down one row
	for row in _bricks:
		for brick in row:
			if is_instance_valid(brick):
				brick.position.y += _brick_spacing.y
				
				# Check if any brick reached bottom (y > 700 for 4x scale)
				if brick.position.y > 700:
					emit_signal("game_over")
					return
	
	# Spawn new row at top
	_spawn_new_row()

func _get_total_brick_count() -> int:
	var count = 0
	for row in _bricks:
		for brick in row:
			if is_instance_valid(brick):
				count += 1
	return count

func _get_varied_brick_hp() -> int:
	# Create high variance in brick HP based on game progress
	var variance_factor = min(current_round / 10.0, 2.0)  # Max 2x variance multiplier
	
	# Base HP ranges
	var base_min = 1 if current_round <= 3 else min(current_round - 2, 10)
	var base_max = 5 if current_round <= 5 else min(current_round + 3, 99)
	
	# Roll for brick type with increasing variance
	var roll = randf()
	var hp = 1  # Default to 1 HP minimum
	
	if roll < 0.5:  # 50% easy bricks
		hp = randi_range(base_min, max(base_min + 2, base_max / 3))
	elif roll < 0.8:  # 30% medium bricks  
		hp = randi_range(max(1, base_max / 3), max(1, base_max * 2 / 3))
	elif roll < 0.98:  # 18% hard bricks
		hp = randi_range(max(1, base_max * 2 / 3), base_max)
	else:  # 2% super tough bricks with extreme variance
		var super_tough_min = max(1, int(base_max * variance_factor))
		var super_tough_max = max(1, int(base_max * variance_factor * 1.5))
		hp = min(randi_range(super_tough_min, super_tough_max), 99)
	
	return max(1, hp)  # Ensure HP is never 0

func clear_all_bricks():
	for row in _bricks:
		for brick in row:
			if is_instance_valid(brick):
				brick.queue_free()
	_bricks.clear()

func spawn_new_row():
	"""Public wrapper for spawning new rows (used by GameController)"""
	_spawn_new_row()
