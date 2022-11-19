class_name ViewComponent
extends Spatial

onready var camera = get_node("Camera")

func _update_transform(player, movement_):
    if len(movement_.states) >= 2:
        global_transform.origin = movement_.states[-2].position.linear_interpolate(
            movement_.states[-1].position, Engine.get_physics_interpolation_fraction())
    rotation_degrees.y = player.inputs[-1][Inputs.YAW]
    camera.rotation_degrees.x = player.inputs[-1][Inputs.PITCH]
