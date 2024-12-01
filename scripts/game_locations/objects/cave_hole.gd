extends Area2D

signal hole_entered(boody : CharacterBody2D, hole : Area2D)
signal hole_exited(body : CharacterBody2D, hole : Area2D)


func _on_body_entered(body: Node2D) -> void:
	if body.get_class() != "CharacterBody2D":
		return
	else:
		if not body.controlable: return
		
		$KeyPanel.visible = true
		hole_entered.emit(body as CharacterBody2D, self)


func _on_body_exited(body: Node2D) -> void:
	if body.get_class() != "CharacterBody2D":
		return
	else:
		if not body.controlable: return
		
		$KeyPanel.visible = false
		hole_exited.emit(body as CharacterBody2D, self)
