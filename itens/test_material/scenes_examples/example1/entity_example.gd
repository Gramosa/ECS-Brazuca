extends Node2D

# Called when the node enters the scene tree for the first time.
#@onready var damage_system: DamageSystem = get_node("../Systems/DamageSystem")
@onready var damage_system: DamageSystem =  get_node("%DamageSystem")
@onready var effect_system: AbilitySystem = get_node("%AbilitySystem")
@onready var aura: Sprite2D = get_node("Aura")

var actual_health_component: String = "Shield"

func _input(event):
	"""Mudar no futuro a maneira de chamar a função do_damage, provavelmente usando sinais"""
	# The own DamageComponent will damage the HealthComponent, just for test purpose of the system
	if event.is_action_pressed("esquerda"):
		damage_system.do_damage(self, self, false, false, "", actual_health_component)
	
	elif event.is_action_pressed("direita"):
		damage_system.do_damage(self, self, true, true, "", actual_health_component)
	
	elif event.is_action_pressed("testar"):
		var start = Time.get_ticks_msec()
		#effect_system.test()
		#effect_system.test2()
		#effect_system.test3()
		#effect_system.test4()
		var end = Time.get_ticks_msec() - start
		print("tempo passado= ", end)
	
# Called by both HealthComponent
# Maybe pass the component name with signal???
func _on_health_component_health_changed(old_health: float, new_health: float):
	if new_health < old_health:
		"""Lembrando que o sistema de efeito ainda nao foi totalmente implementado"""
		effect_system.apply_effect(self, self, "Endurance", "", "PrimaryHealth")
		print("levou dano")
	
	elif new_health > old_health:
		print("Curou")
	
	elif new_health == old_health:
		# In that case the health will health will be the same only if its 0 or max_health
		"""Uma maneira meio porca de fazer isso, mudar no futuro"""
		if new_health != 0:
			actual_health_component = "Shield"
		print("nada muda")
	
	print("vida atual: " + str(new_health))

func _on_primary_health_depleted():
	self.hide()
	print("morreu")

func _on_primary_health_recovered():
	self.show()
	print("reviveu")

func _on_shield_health_depleted() -> void:
	aura.hide()
	actual_health_component = "PrimaryHealth"
	print("escudo desativado")

func _on_shield_health_recovered() -> void:
	aura.show()
	actual_health_component = "Shield"
	print("escudo ativado novamente")
