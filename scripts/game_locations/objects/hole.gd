extends Area2D

signal hole_entered(body : CharacterBody2D)


func _on_body_entered(body: Node2D) -> void:
	if body.get_class() != "CharacterBody2D":
		return
	else:
		hole_entered.emit(body as CharacterBody2D)
