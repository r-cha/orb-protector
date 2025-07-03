extends StaticBody2D
class_name Brick

signal brick_destroyed(brick)
signal ball_bounced(ball)

@export var hp: int = 1
@export var is_special_block: bool = false
@export var special_type: String = "" # "add", "multiply"

@onready var label = $Label
@onready var color_rect = $ColorRect
@onready var collision = $CollisionShape2D

var brick_size = Vector2(120, 60)

func _ready():
	# Set brick collision layer to layer 3 for ball collision detection
	collision_layer = 4
	collision_mask = 0  # Bricks don't need to detect anything
	update_display()

func take_damage_from_ball():
	if is_special_block:
		handle_special_block()
	else:
		take_damage()

func take_damage():
	hp -= 1
	if hp <= 0:
		emit_signal("brick_destroyed", self)
		queue_free()
	else:
		update_display()

func handle_special_block():
	# Signal will be caught by GameController to add/multiply balls
	emit_signal("brick_destroyed", self)
	queue_free()

func update_display():
	if is_special_block:
		label.text = "+" if special_type == "add" else "×"
		color_rect.color = Color.GREEN if special_type == "add" else Color.YELLOW
	else:
		label.text = str(hp)
		# Color based on HP: blue for low HP, red for high HP
		var color_intensity = min(hp / 10.0, 1.0)
		color_rect.color = Color(0.5 + color_intensity * 0.5, 0.3, 1.0 - color_intensity * 0.3, 1.0)

func set_hp(new_hp: int):
	hp = new_hp
	update_display()

func set_special(type: String):
	is_special_block = true
	special_type = type
	update_display()
