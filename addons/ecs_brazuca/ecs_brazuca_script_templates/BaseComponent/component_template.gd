# meta-name: Brazuca Component
# meta-description: Utilized as template to new nodes who extends from BaseComponent
# meta-default: true

extends BaseComponent

#class_name MyComponent

## Do NOT override _init, utilize super() at beggin
func _init() -> void:
	super()

	#add_to_group("MyComponentGroup", true)


## Do NOT override _ready, utilize super() at beggin
func _ready() -> void:
	super()
	
	
## Do NOT override _exit_tree(), utilize super() at beggin
func _exit_tree() -> void:
	super()

