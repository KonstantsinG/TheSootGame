extends Control

@onready var time_left_label = $Panel2/Panel/HBoxContainer/TimeLabel

@onready var red_score_label = $Panel2/Panel/HBoxContainer/RedScoreLabel
@onready var blue_score_label = $Panel2/Panel/HBoxContainer/BlueScoreLabel
@onready var green_score_label = $Panel2/Panel/HBoxContainer/GreenScoreLabel
@onready var yellow_score_label = $Panel2/Panel/HBoxContainer/YellowScoreLabel


func update_time_left(sec_left : int) -> void:
	var mins = int(sec_left / float(60)) #warning-ignore:integer_division
	var secs = sec_left % 60
	
	var mins_str = str(mins) if mins >= 10 else "0" + str(mins)
	var secs_str = str(secs) if secs >= 10 else "0" + str(secs)
	
	time_left_label.text = "Time left: " + mins_str + ":" + secs_str


func update_score(team : GameParams.TeamTypes, score : int) -> void:
	match team:
		GameParams.TeamTypes.RED:
			red_score_label.text = str(score)
		
		GameParams.TeamTypes.BLUE:
			blue_score_label.text = str(score)
		
		GameParams.TeamTypes.GREEN:
			green_score_label.text = str(score)
		
		GameParams.TeamTypes.YELLOW:
			yellow_score_label.text = str(score)
