class_name MoveComponent
extends KinematicBody

var scale_multiple:float = 0.25
# -- Movement Settings --
var velocity = Vector3()
var speed: float = 10.0 * scale_multiple
var max_ground_speed:float = speed * 1.2
var accel_air:float = 5.0
var accel_ground:float= 12.0
var jump_height:float = 3.5 * scale_multiple
var jump_duration:float = 0.35
var gravity:float = (2.0 * jump_height) / (pow(jump_duration, 2))
var jump_force:float = gravity * jump_duration
var snap_distance:float = 0.5

var states:Array = []
var resim_frames:int = 15

var update_internals = false
func resimulate(player, delta):
    if len(states) > resim_frames:
        var original_position = global_transform.origin
        # reset state
#        velocity = states[-resim_frames].velocity
#        global_transform.origin = states[-resim_frames].position
        var state = states[-resim_frames]
        # erase recorded states
        var old_states = []
        for i in resim_frames:
            old_states.push_back(states.pop_back())
        old_states.invert()
        # replay inputs
        update_internals = true
        for i in range(len(player.inputs) - resim_frames, len(player.inputs)):
            var input = player.inputs[i]
            state = _simulate(state, input, delta)
        var diff = (global_transform.origin - original_position).length()
        if diff > 0.0:
            print(diff)
#            print("old: %s" % states[-(resim_frames + 1)])
#            for i in len(old_states):
#                print("old: %s\nnew: %s" % [old_states[i], states[i - resim_frames]])
        return state
        
var reset_step = false
onready var raycast = $RayCast
func _simulate(state, input, delta):
    print(is_on_floor())
    velocity = state.velocity
    global_transform.origin = state.position
#    move_and_slide(Vector3(), Vector3.UP)
#    force_update_transform()
    states.push_back(state)
    var snap = Vector3.DOWN * snap_distance
    var direction = input[Inputs.Z_MOTION] * Vector3.FORWARD + input[Inputs.X_MOTION] * Vector3.RIGHT
    direction = direction.rotated(Vector3.UP, deg2rad(input[Inputs.YAW])).normalized()
    var h_velocity = Vector3(velocity.x, 0, velocity.z)
    var floor_normal = Vector3()
    for normal in state.floor_normals:
        if normal: floor_normal = normal
    if floor_normal:
        var target_vel = Math.get_slope_velocity(direction * speed, floor_normal)
        velocity = velocity.linear_interpolate(target_vel, clamp(accel_ground * delta, 0.0, 1.0))
        if h_velocity.length() > max_ground_speed:
            velocity.x *= max_ground_speed / h_velocity.length()
            velocity.z *= max_ground_speed / h_velocity.length()
        if input[Inputs.JUMP]:
            velocity.y = jump_force
            snap = Vector3()
        else:
            velocity -= floor_normal * delta * 8 #* gravity * 1.5
    else:
        if h_velocity.dot(direction) <= speed:
            velocity += direction * (speed - h_velocity.dot(direction)) * accel_air * delta
        velocity.y -= gravity * delta
#    velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)
    velocity = move_and_slide(velocity, Vector3.UP)
    return {
        "velocity": velocity, 
        "position": global_transform.origin, 
#        "floor_normal": get_floor_normal(),
        "floor_normals": [state.floor_normals[1], state.floor_normals[2], get_floor_normal()],
        "input": input
    }
