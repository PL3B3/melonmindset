extends KinematicBody

# -- Movement Settings --
var velocity = Vector3()
var floor_normal = Vector3()
var speed: float = 15.0
var max_ground_speed:float = speed * 1.2
var accel_air:float = 5.0
var accel_ground:float= 12.0
var jump_height:float = 3.5
var jump_duration:float = 0.35
var gravity:float = (2.0 * jump_height) / (pow(jump_duration, 2))
var jump_force:float = gravity * jump_duration
var snap_distance:float = 0.1

onready var start = {
    "velocity": Vector3(), 
    "position": global_transform.origin, 
    "floor_normal": Vector3()
}
onready var state = start.duplicate()
var states:Array = []
var inputs:Array = [
    {0:1, 1:0, 2:0, 3:0, 4:false, 5:false},
    {0:1, 1:0, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:0, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:0, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:0, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:0, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:0, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:0, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:0, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:0, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:true, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false},
#    {0:1, 1:1, 2:0, 3:0, 4:false, 5:false} 
]

var unique_states = {}
var errors = []
var iters = 500

func _physics_process(delta):
    play_inputs(delta)
    unique_states[statetos(state)] = true
    if Input.is_action_just_pressed("click"):
        print(unique_states)
    if not iters:
#        errors.sort()
        print(errors)
        queue_free()
    iters -= 1
#    print("Final state: %s" % statetos(state))

var end = Vector3()
func play_inputs(delta):
    state = start.duplicate()
    var old_states = states.duplicate()
    states = []
    global_transform.origin = start.position
    force_update_transform()
    for i in 20:
#        state = _simulate(state, input, delta)
        move_and_slide(Vector3(10, -2, 0), Vector3.UP)
    if end:
        print((global_transform.origin - end).length())
    end = global_transform.origin
#    if old_states and (statetos(states[-1]) != statetos(old_states[-1])):
#        var error = (old_states[-1].position - states[-1].position).length()
#        errors.push_back(error)
#        print("off: %s" % (old_states[-1].position - states[-1].position).length())
#        for i in len(old_states):
#            print("old: %s" % statetos(old_states[i]))
#            print("new: %s" % statetos(states[i]))

func statetos(state):
    return "{vel: %s, pos: %s, flr %s}" % [
        vtos(state.velocity), 
        vtos(state.position), 
        vtos(state.floor_normal)
    ]

func _simulate(state, input, delta):
    velocity = state.velocity
    floor_normal = state.floor_normal
    global_transform.origin = state.position
    states.push_back(state)
    var direction = Vector3(input[Inputs.X_MOTION], 0, -input[Inputs.Z_MOTION])
    direction = direction.rotated(Vector3.UP, deg2rad(input[Inputs.YAW])).normalized()
#    velocity = velocity.linear_interpolate(direction * speed, delta * accel_ground)
    var h_velocity = Vector3(velocity.x, 0, velocity.z)
    if floor_normal and floor_normal.angle_to(Vector3.UP) <= PI / 4 + 0.001:
        var target_vel = Math.get_slope_velocity(direction * speed, floor_normal)
        velocity = velocity.linear_interpolate(target_vel, clamp(accel_ground * delta, 0.0, 1.0))
        if h_velocity.length() > max_ground_speed:
            velocity.x *= max_ground_speed / h_velocity.length()
            velocity.z *= max_ground_speed / h_velocity.length()
        if input[Inputs.JUMP]:
            velocity.y = jump_force
        else:
            velocity -= floor_normal * 0.01
    else:
        if h_velocity.dot(direction) <= speed:
            velocity += direction * (speed - h_velocity.dot(direction)) * accel_air * delta
        velocity.y -= gravity * delta
    velocity = move_and_slide(Vector3(10, -2, 3), Vector3.UP)
    return {
        "velocity": velocity, 
        "position": global_transform.origin, 
        "floor_normal": check_floor(global_transform.origin)
    }

func check_floor(position):
    var space_state = get_world().direct_space_state
    var shape_query = PhysicsShapeQueryParameters.new()
    shape_query.exclude = [self]
    shape_query.set_shape($CollisionShape.shape)
    shape_query.transform.origin = position + Vector3.DOWN * 0.1
    var result = space_state.get_rest_info(shape_query)
    return result.normal if result else Vector3()

func vtos(vector:Vector3):
    return "(%+.3f, %+.3f, %+.3f)" % [vector.x, vector.y, vector.z]
