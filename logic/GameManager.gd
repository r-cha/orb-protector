extends Node

@onready var title_screen = preload("res://title_screen.tscn")
@onready var game_scene = preload("res://orb_protector.tscn")

var current_scene = null

func _ready():
	_show_title_screen()

func _show_title_screen():
	# Remove current scene if it exists
	if current_scene:
		current_scene.queue_free()
	
	# Create and add title screen
	current_scene = title_screen.instantiate()
	add_child(current_scene)
	
	# Connect the start game signal
	current_scene.start_game.connect(_start_game)

func _start_game():
	# Remove title screen
	if current_scene:
		current_scene.queue_free()
	
	# Create and add game scene
	current_scene = game_scene.instantiate()
	add_child(current_scene)
	
	# Connect game over signal to show title screen again
	if current_scene.has_signal("game_over"):
		current_scene.game_over.connect(_show_title_screen)
