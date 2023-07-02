extends Node2D

@onready var animation : AnimationPlayer = get_node("Animation")
@onready var label : Label = get_node("ContainerLabel/Label")

var hp_value: int
var color_value: Color

func setup(hp: int = -1, color: Color = Color.WHITE):
	hp_value = hp
	color_value = color

func _ready() -> void:
	label.add_theme_color_override("font_color", color_value)
	label.text = str(hp_value)
	animation.play("rise_and_fade")

# Called in the end of show health points animation
func delete_heaalth_points():
	self.queue_free()
