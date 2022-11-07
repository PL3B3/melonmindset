extends Spatial

var Ability = preload("res://ability/Ability.tscn")

var abilities:Dictionary = {}
var last_ability: Ability
var current_ability: Ability

func _ready():
	for i in 3:
		var ability = Ability.instance()
		ability._init_scene(i)
		add_child(ability)
		ability.dequip()
		abilities[i] = ability
	last_ability = abilities[0]
	current_ability = abilities[0]
	current_ability.equip()

func _unhandled_input(event):
	if event.is_action_pressed("ability_previous"):
		switch(last_ability)
	elif event.is_action_pressed("ability_0"):
		switch(abilities[0])
	elif event.is_action_pressed("ability_1"):
		switch(abilities[1])
	elif event.is_action_pressed("ability_2"):
		switch(abilities[2])

func switch(ability: Ability):
	if ability and ability.has_method("equip") and ability != current_ability:
		if current_ability: current_ability.dequip()
		last_ability = current_ability
		current_ability = ability
		current_ability.equip()

func _physics_process(delta):
	simulate(delta)

func simulate(delta):
	current_ability.handle_input()
