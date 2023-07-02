@tool
extends EditorPlugin


func _enter_tree() -> void:
	pass


func _exit_tree() -> void:
	pass


## Add the templates to the script_templates folder
func _load_templates():
	var templates_folder: String = "res://script_templates"
