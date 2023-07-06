extends Node2D

const enemy = preload("enemy_test.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn"):
		var location_y = randi_range(75, 275)
		var enemy_instance = enemy.instantiate()
		enemy_instance.position.y = location_y
		enemy_instance.position.x = 50
		add_child(enemy_instance)
