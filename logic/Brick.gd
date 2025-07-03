"""
Brick represents an individual brick that can be destroyed by balls.
Handles damage, special effects, and visual representation.
"""
extends StaticBody2D
class_name Brick

signal brick_destroyed(brick)
signal ball_bounced(ball)

@export var hp: int = 1
@export var is_special_block: bool = false
@export var special_type: String = "" # "add", "multiply"

@onready var _label = $Label
@onready var _color_rect = $ColorRect
@onready var _collision = $CollisionShape2D

var _brick_size = Vector2(120, 60)

func _ready():
	# Set brick collision layer to layer 3 for ball collision detection
	collision_layer = 4
	collision_mask = 0  # Bricks don't need to detect anything
	_update_display()

func take_damage_from_ball():
	if is_special_block:
		_handle_special_block()
	else:
		_take_damage()

func _take_damage():
	var damage = 1
	
	# Check if double damage is active
	var game_controller = get_tree().get_first_node_in_group("game_controller")
	if game_controller and game_controller.has_method("is_double_damage_active"):
		if game_controller.is_double_damage_active():
			damage = 2
	
	hp -= damage
	if hp <= 0:
		emit_signal("brick_destroyed", self)
		queue_free()
	else:
		_update_display()

func _handle_special_block():
	# Signal will be caught by GameController to add/multiply balls
	emit_signal("brick_destroyed", self)
	queue_free()

func _update_display():
	if is_special_block:
		_label.text = "+" if special_type == "add" else "×"
		_color_rect.color = Color.GREEN if special_type == "add" else Color.YELLOW
	else:
		_label.text = str(hp)
		# Color based on HP: blue for low HP, red for high HP
		var color_intensity = min(hp / 10.0, 1.0)
		_color_rect.color = Color(0.5 + color_intensity * 0.5, 0.3, 1.0 - color_intensity * 0.3, 1.0)

func set_hp(new_hp: int):
	hp = new_hp
	_update_display()

func set_special(type: String):
	is_special_block = true
	special_type = type
	_update_display()
