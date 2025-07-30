extends Node

# Signals for game events
signal race_started
signal race_finished(time: float)
signal player_crashed

# Game state
var current_level: int = 1
var race_time: float = 0.0
var is_racing: bool = false

func start_race():
	is_racing = true
	race_time = 0.0
	race_started.emit()

func finish_race():
	is_racing = false
	race_finished.emit(race_time)

func _process(delta):
	if is_racing:
		race_time += delta
