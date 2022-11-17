extends Spatial

onready var camera = get_node("Camera")
onready var mesh = get_node("Mesh")

func _update_transform(player):
    global_transform.origin = player.last_position.linear_interpolate(
        player.global_transform.origin, Engine.get_physics_interpolation_fraction())
    rotation_degrees.y = player.input_frame[Inputs.YAW]
    camera.rotation_degrees.x = player.input_frame[Inputs.PITCH]
    mesh.rotation_degrees.x = camera.rotation_degrees.x