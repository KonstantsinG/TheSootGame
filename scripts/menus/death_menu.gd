extends Control

signal timeout

@onready var title = $TimeLabel
var time_left = 20


func _on_global_timer_timeout() -> void:
	timeout.emit()


func _on_update_title_timer_timeout() -> void:
	time_left -= 1
	title.text = str(time_left) + " sec"
