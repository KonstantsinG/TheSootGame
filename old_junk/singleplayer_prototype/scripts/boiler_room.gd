extends Node2D


var is_near_hole := false
var is_near_furnace := false
var coal_bured_count := 0

func _ready() -> void:
	_setup_holes()


func _input(event: InputEvent) -> void:
	if is_near_hole:
		if event.is_action_pressed("action"):
			$Soot.take_coal()
	
	elif is_near_furnace:
		if event.is_action_pressed("action"):
			if $Soot.drop_coal():
				coal_bured_count += 1
				$Soot/CanvasLayer/HBoxContainer/CoalLabel.text = "Coal burned: " + str(coal_bured_count) + " pcs"


func _setup_holes() -> void:
	for hole in $RightHoles/Holes.get_children():
		hole.on_hole_area_entered.connect(_in_hole_entered)
		hole.on_hole_area_exited.connect(_from_hole_exited)


func _in_hole_entered(body : Node2D, target : Node2D) -> void:
	if body is StaticBody2D: return
	
	is_near_hole = true
	target.toggle_action_key(true)
	#print("Body <" + body.name + "> entered the Hole <" + self.name + ">")


func _from_hole_exited(body : Node2D, target : Node2D) -> void:
	if body is StaticBody2D: return
	
	is_near_hole = false
	target.toggle_action_key(false)


func _on_dropping_area_body_entered(body: Node2D) -> void:
	if body is StaticBody2D: return
	
	$Trampoline/ActionKeySprite.visible = true
	is_near_furnace = true


func _on_dropping_area_body_exited(body: Node2D) -> void:
	if body is StaticBody2D: return
	
	$Trampoline/ActionKeySprite.visible = false
	is_near_furnace = false
