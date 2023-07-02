extends Node2D

# Called when the node enters the scene tree for the first time.
#@onready var damage_system: DamageSystem = get_node("../Systems/DamageSystem")
@onready var damage_system: DamageSystem =  get_node("%DamageSystem")

func _input(event):
	"""Mudar no futuro a maneira de chamar a função do_damage, provavelmente usando sinais"""
	# The own DamageComponent will damage the HealthComponent, just for test purpose of the system
	if event.is_action_pressed("esquerda"):
		damage_system.do_damage(self, self)
	
	elif event.is_action_pressed("direita"):
		damage_system.do_damage(self, self, true)
	
	elif event.is_action_pressed("pular"):
		print(ClassDB.class_exists("HealthComponent"))
		print(damage_system.entities)
		

func _on_health_component_health_changed(_new_health: int, behaviour: HealthComponent.HealthChangeBehaviour):
	if behaviour == HealthComponent.HealthChangeBehaviour.DAMAGED:
		print("Levou Dano")
	
	elif behaviour == HealthComponent.HealthChangeBehaviour.HEALED:
		print("Curou")
	
	elif behaviour == HealthComponent.HealthChangeBehaviour.HEALTH_NOT_CHANGED:
		print("Just want to see, nothing changed")

func _on_health_component_health_depleted():
	self.hide()
	print("morreu")


func _on_health_component_health_recovered():
	self.show()
	print("reviveu")
