extends Node2D

@onready var shadow = $ShadowSprite
@onready var rock = $RockSprite
@onready var explosion = $ExplosionSprite
@onready var dead_shape = $DeadArea/CollisionShape2D

var exploded = false


func _physics_process(delta: float) -> void:
	if rock.position != Vector2(0, -35):
		rock.position = rock.position.move_toward(Vector2(0, -35), 190 * delta)
	elif not exploded:
		explode_rock()
		exploded = true


func resume_falling(offset : float, index : int, max_index : int = 6) -> void:
	var st = max_index - index
	var time = st + offset
	var dist = time * 200
	rock.position.y = -35.0 if -1000 + dist > -35 else float(-1000 + dist)


func explode_rock() -> void:
	shadow.visible = false
	rock.visible = false
	explosion.visible = true
	dead_shape.disabled = false
	
	if get_tree() != null:
		var tween = get_tree().create_tween()
		tween.tween_property(explosion, "modulate", Color.TRANSPARENT, 1)
		tween.tween_callback(queue_free)


func _on_dead_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if body.controlable:
			body.kill()
