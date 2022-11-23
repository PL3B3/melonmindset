extends RigidBody

onready var camera = $VisualRoot/Camera
onready var mesh = $MeshInstance
onready var visual_root = $VisualRoot
var speed:float = 7.5
var acceleration:float = 10.0
var velocity:Vector3 = Vector3()
var last_position = Vector3()
var jump_height:float = 3.5
var jump_duration:float = 0.35
var gravity:float = (2.0 * jump_height) / (pow(jump_duration, 2))
var jump_force:float = gravity * jump_duration

var mouse_sensitivity:float = 0.05
var yaw:float = 0.0
var pitch:float = 0.0

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    visual_root.set_as_toplevel(true)

func _unhandled_input(event):
    if (event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
        yaw = fmod(yaw - event.relative.x * mouse_sensitivity, 360.0)
        if yaw < -180.0: yaw += 360.0
        elif yaw > 180.0: yaw -= 360.0
        pitch = clamp(pitch - (event.relative.y * mouse_sensitivity), -90.0, 90.0)
    elif event.is_action_pressed("toggle_mouse_mode"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        elif Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta):
    visual_root.global_transform.origin = last_position.linear_interpolate(
        global_transform.origin, Engine.get_physics_interpolation_fraction()
    )
#    print((global_transform.origin - get_global_transform_interpolated().origin).length())
    visual_root.rotation_degrees.y = yaw
    camera.rotation_degrees.x = pitch
    mesh.rotation_degrees.y = yaw
    mesh.rotation_degrees.x = pitch
    
var simulating = false
func _physics_process(delta):
#    for i in 5:
#        simulating = true
#        PhysicsServer.simulate(1.0 / 60.0)
#        simulating = false
    if Input.is_action_pressed("click"):
#        print("simulating")
        simulating = true
        for i in 10:
            PhysicsServer.simulate(1.0 / 60.0)
        simulating = false
    if Input.is_action_just_pressed("alt_click"):
        sleeping = false
#    print(linear_velocity)
    last_position = global_transform.origin
    
var grounded = false
func _integrate_forces(state):
    var delta:float = 1.0 / Engine.iterations_per_second
    var forward = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
    var right = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    var dir := Vector3(right, 0, -forward).normalized()
    dir = dir.rotated(Vector3.UP, deg2rad(yaw))
    var y_tmp = velocity.y
    velocity = velocity.linear_interpolate(dir * speed, delta * acceleration)
    velocity.y = y_tmp
    var floor_normals:Array = []
#    var floor_normal = Vector3()
    for i in state.get_contact_count():
        var normal: Vector3 = state.get_contact_local_normal(i)
        if normal.angle_to(Vector3.UP) <= (PI / 4) + 0.01:
            floor_normals.push_back(normal)
    var floor_normal = sum_vectors(floor_normals).normalized()
#    var floor_normal = shapecast(state.transform.origin + Vector3.DOWN * 0.1, Vector3.DOWN * 0.1)
#    print(state.get_contact_count(), " ", floor_normal)
    
    print(vtos(floor_normal))
    if floor_normal and floor_normal.angle_to(Vector3.UP) <= (PI / 4) + 0.01:
        velocity = Math.get_slope_velocity(velocity, floor_normal)
        if Input.is_action_pressed("jump"):
            velocity.y = jump_force
#        velocity = velocity.slide(floor_normal)
    else:
        velocity.y -= gravity * delta
    state.linear_velocity = velocity

    var contacts = []
    for i in state.get_contact_count():
        contacts.push_back(vtos(state.get_contact_local_normal(i)))
#    print("%s: %7d -- %s" % [int(simulating), OS.get_ticks_msec(), contacts])

    

func sum_vectors(vectors):
    var sum = Vector3()
    for vector in vectors: sum += vector
    return sum



func vtos(vector:Vector3):
    return "(%+.2f, %+.2f, %+.2f)" % [vector.x, vector.y, vector.z]

func raycast():
    var space_state = get_world().direct_space_state
    var ray_start = camera.global_transform.origin
    var ray_vec = -200 * camera.global_transform.basis.z
    var ray_end = ray_start + ray_vec
    var result = space_state.intersect_ray(ray_start, ray_end, [self])
    if result and is_instance_valid(result.collider):
        print("Hit ", result.collider)

onready var sweep_shape:CylinderShape = CylinderShape.new()
func shapecast(origin, motion):
    var space_state = get_world().direct_space_state
    var shape_query = PhysicsShapeQueryParameters.new()
    shape_query.exclude = [self]
    shape_query.margin = 0.05
    shape_query.set_shape(sweep_shape)
    shape_query.transform.origin = origin
    var cast_result = space_state.cast_motion(shape_query, motion)
    var result = space_state.get_rest_info(shape_query)
    return result.normal if result else Vector3()
