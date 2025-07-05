extends Control

signal start_game

func _ready():
	# Connect input handler
	pass

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		_start_game()
	elif event is InputEventKey and event.pressed:
		_start_game()

func _start_game():
	start_game.emit()
