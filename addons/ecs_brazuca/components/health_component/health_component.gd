@icon("health_component_icon.svg")
extends BaseComponent

## HealthComponent are a component who deal with health every entity who can receive damage must own at least one
## This component is able to emit a health_points node (who have a short life, just to spam the actual health)
class_name HealthComponent

## Emited when the health reach to 0 for the first time, this means when the entity become dead (in other words).
signal health_depleted

## Emitted when the health increase from 0 to any value, this means when the entity revive (in other words).
signal health_recovered

## Emited every call of update_health(), so does not change the property health directly, use the method update_health().
signal health_changed(old_health: float, new_health: float)

## Emited when the resistance_ratio was changed
signal resistance_ratio_changed(old_resistance_ratio: float, new_resistance_ratio: float)

const health_points_path: PackedScene = preload("health_points.tscn")

@export_group("Health")

## The max_health value, during runtime change this value using the method change_max_health()
@export var max_health: float:
	set(new_max_health):
		if new_max_health < 0:
			max_health = 0
		else:
			max_health = new_max_health

## The initial value for the entity, clamped to be at max the max_health
@export var initial_health: float:
	set(new_initial_health):
		initial_health = clamp(new_initial_health, 0, max_health)

## The ratio of the resistance based always on the max_health, high numbers means more resistance.
## Utilized by the systems
@export_range(0.001, 1000) var resistance_ratio: float = 1

@export_group("Health Point Colors")

## Display the actual health everytime update_health() are called, its just a visual number.
@export var visible_health_points: bool = true

## Its the color who appear when the health is not changed, for example, when it takes a damage equal to 0
## Only used when visible_health_points are true
@export var color_nothing_changed: Color = Color.WHITE

## Its the color who appear when the health is damaged
## Only used when visible_health_points are true
@export var color_damaged: Color = Color.RED

## Its the color who appear when the health is healed, if visible_health_points be true
## Only used when visible_health_points are true
@export var color_healed: Color = Color.GREEN

## Does NOT change health directly, utilize update_health.
var health: float

func _init():
	super()
	add_to_group("HealthComponentGroup", true)

func get_health() -> float:
	return health

func get_resistance_ratio() -> float:
	return resistance_ratio

func _ready() -> void:
	super()
	
	health = initial_health

# Verify if the necessary connections was made, can be by editor or before the call for verify_connections in _ready()
func verify_connections() -> void:
	super()
	if len(health_depleted.get_connections()) == 0:
		push_warning(COMPONENT_WARNINGS["COMPONENT WARNING 1"].format([health_depleted.get_name(), self.get_name()]))
	
	if len(health_recovered.get_connections()) == 0:
		push_warning(COMPONENT_WARNINGS["COMPONENT WARNING 1"].format([health_recovered.get_name(), self.get_name()]))
	
	if len(health_changed.get_connections()) == 0:
		push_warning(COMPONENT_WARNINGS["COMPONENT WARNING 1"].format([health_changed.get_name(), self.get_name()]))
		
	if len(resistance_ratio_changed.get_connections()) == 0:
		push_warning(COMPONENT_WARNINGS["COMPONENT WARNING 1"].format([resistance_ratio_changed.get_name(), self.get_name()]))

func update_health(damage: float) -> void:
	
	var new_health = clamp(health - damage, 0, max_health)
	var delta_health: float = new_health - health
	
	# If the new_health be 0 and the previous health was different than 0, this means the entity just died
	if new_health == 0 and health != 0:
		health_depleted.emit()
	
	elif new_health > 0 and health == 0:
		health_recovered.emit()
	
	health_changed.emit(health, new_health)
	update_property("health", new_health)
	
	if visible_health_points == true:
		show_health_points(delta_health)

func show_health_points(health_variation: float) -> void:
	
	var health_points: Node2D = health_points_path.instantiate()
	# If its equal than self, means there is not a parent who inherits from Node2D
	# So the transform is not visible, meaning there is not a position to display the health points
	if _entity != self:
		var health_points_color: Color
		# The color of health_points will be defined according the health_behaviour
		if health_variation > 0:
			health_points_color = color_healed
		elif health_variation == 0:
			health_points_color = color_nothing_changed
		else:
			health_points_color = color_damaged
		
		health_points.setup(health, health_points_color)
		_entity.add_child(health_points)
	else:
		push_warning("The component {0} doesn't have an ancetor who inherits from Node2D, so the health points cannot be visible. Consider setting visible_health_points to false".format(self.get_name()))
