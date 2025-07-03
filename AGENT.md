# Agent Guidelines for Orb Protector Godot Project

## Build/Test Commands
- **Run Project**: Open in Godot editor and press F5, or use `godot --path . --main-pack` from command line
- **Export**: Use Godot editor Project > Export menu
- **Debug**: Use Godot editor's debugger (F6 for quick debug)

## Architecture & Structure
- **Main Scene**: orb_protector.tscn (entry point with GameController.gd)
- **Core Scripts**: logic/ directory contains all GDScript files
- **Scene Files**: ball.tscn, walls.tscn for reusable components
- **Resources**: PNG assets with corresponding .import files

## Code Style Guidelines
- **Naming**: snake_case for variables/functions, PascalCase for classes
- **Structure**: extends first, signals, @export vars, @onready vars, regular vars, functions
- **Signal Handlers**: Use `_on_[signal_name]` pattern 
- **Node References**: Use @onready for scene tree nodes
- **Private Variables**: Prefix with underscore (_private_var)
- **Built-in Functions**: _ready(), _input(), _process() - underscore prefix

## Project Structure
- Main scenes are in root, logic scripts in logic/ folder
- Uses Area2D for collision detection, RigidBody2D for physics
- Signal-based communication between nodes
