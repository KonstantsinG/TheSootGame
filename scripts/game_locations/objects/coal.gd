extends Node2D

@onready var default_view = $Type2
@onready var types = [
	$Type1, $Type2, $Type3, $Type4, $Type5
]
var type = null


func _ready() -> void:
	if type == null:
		default_view.visible = false
		_take_type()


func _preload_types() -> void:
	get_node("Type2").visible = false
	types = [get_node("Type1"), get_node("Type2"), get_node("Type3"), get_node("Type4"), get_node("Type5")]


func _take_type() -> void:
	type = types.pick_random()
	type.visible = true
	#type.get_node("CollisionPolygon2D").disabled = false


func set_type(coal_type : int) -> void:
	if types == null: _preload_types()
	
	if coal_type == -1:
		_take_type()
	else:
		if type != null:
			type.visible = false
		
		type = types[coal_type]
		type.visible = true


func get_type() -> int:
	return types.find(type)
