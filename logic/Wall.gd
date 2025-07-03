"""
Wall represents static boundaries that balls bounce off of.
"""
extends StaticBody2D

func _ready():
	# Set wall collision layer to layer 2 for ball collision detection
	collision_layer = 2
	collision_mask = 0  # Walls don't need to detect anything
