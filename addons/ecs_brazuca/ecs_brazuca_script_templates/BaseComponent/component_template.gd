# meta-name: Brazuca Component
# meta-description: Utilized as template to new nodes who extends from BaseComponent
# meta-default: true

extends BaseComponent

#class_name MyComponent

## Do NOT override _init, utilize super() at beggin
func _init() -> void:
	super()
	
	#_target_entity_type = "Node2D"
	#add_to_group("MyComponentGroup", true)


## Do NOT override _enter_tree(), utilize super() at beggin
func _enter_tree() -> void:
	super()


## Do NOT override _exit_tree(), utilize super() at beggin
func _exit_tree() -> void:
	super()


## Not obligated, in really, i may remove this in future
#func get_class_name():
#	return "MyComponent"
