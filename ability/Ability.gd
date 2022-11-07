extends Spatial
class_name Ability

onready var animation_player = $AnimationPlayer
var player
var is_active:bool = false
var id

var colors = [Color.aqua, Color.coral, Color.gold]
func _init_scene(idx:int):
	id = idx
	var material = $MeshInstance.get_surface_material(0)
	material.set_albedo(colors[idx])
	$MeshInstance.set_material_override(material.duplicate())

func _ready():
	dequip()
	animation_player.connect("animation_finished", self, "_set_active")

func handle_input():
	if Input.is_action_just_pressed("click"):
		print(OS.get_ticks_msec())

func equip():
	show()
	animation_player.play("Equip")

func dequip():
	animation_player.stop()
	is_active = false
	hide()

func _set_active(_param):
	is_active = true
