extends Node2D

signal on_hole_area_entered(body : Node2D, target : Node2D)
signal on_hole_area_exited(body : Node2D, target : Node2D)


func _on_enter_area_body_entered(body: Node2D) -> void:
	on_hole_area_entered.emit(body, self)


func _on_enter_area_body_exited(body: Node2D) -> void:
	on_hole_area_exited.emit(body, self)


func toggle_action_key(enabled : bool) -> void:
	$"E-KeySprite".visible = enabled
