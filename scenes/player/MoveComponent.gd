class_name MoveComponent
extends KinematicBody

const EPSILON:float = 0.001
const FLOOR_ANGLE:float = deg2rad(45)
var scale_multiple:float = 1.0
# -- Movement Settings --
var velocity = Vector3()
var floor_normal = Vector3()
var speed: float = 10.0 * scale_multiple
var max_ground_speed:float = speed * 1.3
var accel_air:float = 4.0
var accel_ground:float= 12.0
var jump_height:float = 3.5 * scale_multiple
var jump_duration:float = 0.35
var gravity:float = (2.0 * jump_height) / (pow(jump_duration, 2))
var jump_force:float = gravity * jump_duration
var snap_distance:float = 0.1

var states:Array = []
var resim_frames:int = 12

var query_shape := CylinderShape.new()

func _ready():
    query_shape.height = 1.0

func resimulate(player, delta):
    if len(states) > resim_frames:
        var original_position = global_transform.origin
        var state = states[-resim_frames]
        # erase recorded states
        var old_states = []
        for i in resim_frames:
            old_states.push_back(states.pop_back())
        old_states.invert()
        # replay inputs
        for i in range(len(player.inputs) - resim_frames, len(player.inputs)):
            var input = player.inputs[i]
            state = _simulate(state, input, delta)
        var diff = (global_transform.origin - original_position).length()
        if diff > 0.0:
            print(diff)
#            print("old: %s" % states[-(resim_frames + 1)])
#            for i in len(old_states):
#                print("old: %s\nnew: %s" % [statetos(old_states[i]), statetos(states[i - resim_frames])])
        return state

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
#    force_update_transform()
#    move_and_slide(Vector3(), Vector3.UP)
    states.push_back(state)
    var snap = Vector3.DOWN * snap_distance
    var direction = Vector3(input[Inputs.X_MOTION], 0, -input[Inputs.Z_MOTION])
    direction = direction.rotated(Vector3.UP, deg2rad(input[Inputs.YAW])).normalized()
    var h_velocity = Vector3(velocity.x, 0, velocity.z)
#    var floor_normal = state.floor_normals[2]
#    for normal in state.floor_normals:
#        if normal: floor_normal = normal
#    print(vtos(floor_normal))
    if floor_normal and floor_normal.angle_to(Vector3.UP) <= FLOOR_ANGLE + EPSILON:
        # maintain horizontal velocity (x and z) on slopes
        var target_vel = Math.get_slope_velocity(direction * speed, floor_normal)
        velocity = velocity.linear_interpolate(target_vel, clamp(accel_ground * delta, 0.0, 1.0))
        if h_velocity.length() > max_ground_speed:
            velocity.x *= max_ground_speed / h_velocity.length()
            velocity.z *= max_ground_speed / h_velocity.length()
        var wall_normal:Vector3 = collide_feet(global_transform.origin + direction * 0.1 + Vector3.UP * 0.1) 
#        Vector3()
#        shapecast(global_transform.origin + direction * 0.1)
#        check_wall(global_transform.origin, direction)
#        var wall_normal = check_floor(global_transform.origin + direction * 0.1)
#        print(vtos(global_transform.origin), " ", vtos(wall_normal), " ", velocity.dot(wall_normal))
        var ceil_normal:Vector3 = collide_head(global_transform.origin + Vector3.UP * 0.1)  
#        Vector3()
#        check_floor(global_transform.origin + Vector3.UP * 0.1)
        # reduces shaking when pushing into sloped ceilings by canceling forward velocity
        # ceil_normal.angle_to(Vector3.DOWN) <= FLOOR_ANGLE + EPSILON and 
        if ceil_normal and velocity.dot(ceil_normal) < 0:
            var corner_direction = ceil_normal.slide(floor_normal) 
            if corner_direction.length() > EPSILON:
                velocity = velocity.slide(corner_direction.normalized())
#                velocity = velocity.slide((ceil_normal + floor_normal).normalized())
#            else:
#                velocity = velocity.slide(ceil_normal)
            # increased "gravity" further reduces shaking
#            print("balling", OS.get_ticks_msec())
#            velocity -= floor_normal * 0.5
        # reduces up/down shaking when pushing into sloped walls; makes velocity parallel to floor
        if wall_normal and wall_normal.angle_to(Vector3.UP) >= FLOOR_ANGLE + EPSILON and velocity.dot(wall_normal) < 0:
#            var up_c = (velocity.slide(wall_normal)).project(floor_normal)
#            print(up_c.length())
#            if up_c.dot(floor_normal) > 0:
#                velocity -= 2 * up_c
#            print("wallin", OS.get_ticks_msec())
            var slide_normal = wall_normal.slide(floor_normal).normalized() 
            velocity = velocity.slide(slide_normal)
            velocity -= floor_normal * 0.75
        if input[Inputs.JUMP]:
            velocity.y = jump_force
            snap = Vector3()
        else:
            velocity -= floor_normal * 0.01 #* gravity * 1.5
    else:
#        print("air")
#        if state.floor_normals[1]:
#            velocity += state.floor_normals[1] * 4.5
        if h_velocity.dot(direction) <= speed:
            velocity += direction * (speed - h_velocity.dot(direction)) * accel_air * delta
        velocity.y -= gravity * delta
#    print(h_velocity.dot(check_floor(global_transform.origin + Vector3.UP * 0.1)))
#    velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP)
#    print(shapecast(state.position, Vector3.DOWN * 0.1))
#    print(vtos(check_floor(global_transform.origin)))
#    print(vtos(velocity))
#    print(h_velocity.length())
    velocity = move() # move_and_slide(velocity, Vector3.UP, false, 2, FLOOR_ANGLE)
    return {
        "velocity": velocity, 
        "position": global_transform.origin, 
        "floor_normal": collide_floor(global_transform.origin + Vector3.DOWN * 0.1)
#            collide_feet(global_transform.origin + Vector3.DOWN * 0.1),
#            get_floor_normal()
#        "floor_normal": shapecast(global_transform.origin + Vector3.DOWN * 0.1, Vector3.DOWN * 0.1),
#        "grounded": shapecast(state.position, Vector3.DOWN * 0.1)[0] != 1,
#        "floor_normals": [state.floor_normals[1], state.floor_normals[2], get_floor_normal()]
    }

func move():
    return move_and_slide(velocity, Vector3.UP, false, 2, FLOOR_ANGLE, false)

func collide_shape(position:Vector3, shape:Shape, iters:int):
    var space_state = get_world().direct_space_state
    var shape_query = PhysicsShapeQueryParameters.new()
    shape_query.exclude = [self]
    shape_query.set_shape(shape)
    shape_query.transform.origin = position
    var results = []
    var normal = Vector3()
    for i in iters:
        var result = space_state.get_rest_info(shape_query)
        if result: 
            results.push_back(result)
            shape_query.exclude = shape_query.exclude + [result.rid]
    return results

# position of player
func collide_head(position:Vector3):
    var results = collide_shape(position + Vector3(0, 0.5, 0), query_shape, 1)
    return results[0].normal if results else Vector3()

func collide_feet(position):
    var results = collide_shape(position - Vector3(0, 0.5, 0), query_shape, 1)
    return results[0].normal if results else Vector3()

func collide_floor(position):
    var results = collide_shape(position - Vector3(0, 0.5, 0), query_shape, 4)
    var floor_normal = Vector3()
    for result in results:
        floor_normal += result.normal
    return floor_normal.normalized()

func shapecast(position):
    var space_state = get_world().direct_space_state
    var shape_query = PhysicsShapeQueryParameters.new()
    var feet_shape = CylinderShape.new()
    feet_shape.height = 1.0
    shape_query.exclude = [self]
    shape_query.set_shape(feet_shape)
    shape_query.transform.origin = position - Vector3(0, 0.5, 0)
    print("querying shape")
    var normal = Vector3()
    for i in 4:
        var result = space_state.get_rest_info(shape_query)
        if result:
            shape_query.exclude = shape_query.exclude + [result.rid]
            normal += result.normal
            print(result.normal)
        else:
            break
#    print(normal.normalized())
    return normal.normalized()

func vtos(vector:Vector3):
    return "(%+.3f, %+.3f, %+.3f)" % [vector.x, vector.y, vector.z]
