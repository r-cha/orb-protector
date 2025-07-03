"""
Pickup represents power-ups that can be collected by balls.
Handles different pickup types and their effects.
"""
extends Area2D
class_name Pickup

signal pickup_collected(pickup_type)

@export var pickup_type: String = "minus"  # "minus" or "double_damage"
@onready var _label = $Label
@onready var _color_rect = $ColorRect
@onready var _collision = $CollisionShape2D

var _pickup_size = Vector2(120, 60)

func _ready():
	# Set pickup collision layer to layer 5 for ball collision detection
	collision_layer = 16  # Layer 5
	collision_mask = 1    # Only detect balls (layer 1)
	
	# Add to pickups group for easy access
	add_to_group("pickups")
	
	# Connect area entered signal for collision detection
	body_entered.connect(_on_body_entered)
	
	_update_display()

func _on_body_entered(body):
	if body.has_method("get_speed"):  # Check if it's a ball
		print("Pickup collected: ", pickup_type)
		emit_signal("pickup_collected", pickup_type)
		queue_free()

func _update_display():
	if pickup_type == "minus":
		_label.text = "-"
		_color_rect.color = Color.RED
	elif pickup_type == "double_damage":
		_label.text = "2×"
		_color_rect.color = Color.ORANGE
	else:
		_label.text = "?"
		_color_rect.color = Color.WHITE

func set_pickup_type(type: String):
	pickup_type = type
	_update_display()
