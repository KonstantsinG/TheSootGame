extends Node2D

const MAX_COST := 10
const MIN_COST := 1

@onready var default_view = $Type2
@onready var types = [
	$Type1, $Type2, $Type3, $Type4, $Type5
]
var type = null
var id := randi_range(2, 1 << 30)

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


func start_breaking() -> void:
	$BreakingAnimationTimer.start()


func stop_breaking() -> void:
	$BreakingAnimationTimer.stop()
	$BreakingProgressBar.value = 0


func to_barricade() -> void:
	type.get_node("CollisionPolygon2D").disabled = false


func to_collectible() -> void:
	type.get_node("CollisionPolygon2D").disabled = true


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


func get_cost() -> int:
	var time_norm = $CostTimer.time_left / float(60)
	return lerp(MIN_COST, MAX_COST, time_norm)


func _on_breaking_animation_timer_timeout() -> void:
	if $BreakingProgressBar.value == $BreakingProgressBar.max_value:
		stop_breaking()
	else:
		$BreakingProgressBar.value += 1
