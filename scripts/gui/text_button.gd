@tool
extends Control

signal button_pressed

@export var text : String = "Button"

@onready var label = $Panel/Label

var default_text := "Button"


func _ready() -> void:
	if label.text != text:
		label.text = text


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if label.text != text:
			label.text = text


func change_text(new_text : String):
	label.text = new_text


func _on_panel_mouse_entered() -> void:
	material.set_shader_parameter("highlighted", true)


func _on_panel_mouse_exited() -> void:
	material.set_shader_parameter("highlighted", false)


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			button_pressed.emit()
