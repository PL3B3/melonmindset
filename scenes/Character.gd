extends RigidBody

const SHAPECAST_DISTANCE:float = 0.1
const SHAPECAST_TOLERANCE:float = 0.04
const TOLERANCE:float = 0.01
const FLOOR_ANGLE:float = deg2rad(45)
const STEP_HEIGHT:float = 0.5
const SNAP_LENGTH:float = 0.25
onready var camera = $VisualRoot/Camera
onready var mesh = $MeshInstance
onready var visual_root = $VisualRoot
onready var delta = 1.0 / Engine.iterations_per_second
var speed:float = 10.0
var max_speed_ratio:float = 1.5
var accel_gnd:float = 12.0
var accel_air:float = 5.0
var jump_height:float = 3.5
var jump_duration:float = 0.35
var gravity:float = (2.0 * jump_height) / (pow(jump_duration, 2))
var jump_force:float = gravity * jump_duration
var velocity:Vector3 = Vector3()
var position:Vector3
var floor_normal:Vector3 = Vector3()
var last_position = Vector3()

var mouse_sensitivity:float = 0.1
var yaw:float = 0.0
var pitch:float = 0.0

var query_shape := CylinderShape.new()

func _ready():
	query_shape.height = 1.0
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
	visual_root.rotation_degrees.y = yaw
	camera.rotation_degrees.x = pitch
	mesh.rotation_degrees.y = yaw
	mesh.rotation_degrees.x = pitch
	
var simulating = false
func _physics_process(delta):
	for i in 24:
		simulating = true
#        PhysicsServer.simulate(1.0 / 60.0)
		simulating = false
#	if Input.is_action_pressed("click"):
##        print("simulating")
#		simulating = true
#		for i in 24:
#			PhysicsServer.simulate(1.0 / 60.0)
#		simulating = false
	if Input.is_action_just_pressed("alt_click"):
		sleeping = false
#    print(linear_velocity)
	last_position = global_transform.origin
	
"""
NOTE: 0.25 is used everywhere, but nothing special about it, tune if needed

down_dist = how far you can cast_motion down
[makes floor check more precise on stairs/ledges]

if down_dist < FLOOR_CHECK_DIST:
	do floor check @ down_dist + TOLERANCE

if floor below:
	snap to floor
	friction / speed limit
	lerp velocity towards input direction
	for i in 2: # in case wall immediately after step up/down (may be too edgy of an edge case)
		check if walking into wall
		if wall:
			if stair step:
				step up
			else:
				wall slide
	do jump
else:
	air strafing
	gravity

"""
# TODO: wall sliding in flat corner...seems like velocity has a downwards y component, always .25
# regardless of the wall slide down force (unless it's 0)
# lowering the wall check distance seems to work...
func _integrate_forces(state):
	velocity = linear_velocity
	position = state.transform.origin
	var direction = direction()
	var h_velocity = Vector3(velocity.x, 0, velocity.z)
	floor_normal = collide_floor(position + Vector3.DOWN * 0.25)
#	pvecs([floor_normal])
	if floor_normal and is_floor(floor_normal):
		snap_to_floor(state)
		position = state.transform.origin
#		pvecs([position])
		var speed_ratio = h_velocity.length() / speed
		if speed_ratio > max_speed_ratio:
			velocity.x *= max_speed_ratio / speed_ratio
			velocity.z *= max_speed_ratio / speed_ratio
		# maintain horizontal velocity (x and z) on slopes
		var target_vel = Math.get_slope_velocity(direction * speed, floor_normal)
		velocity = velocity.linear_interpolate(target_vel, clamp(accel_gnd * delta, 0.0, 1.0))
		# slide along obstructions, instead of pushing into them (jiggly)
		h_velocity = Vector3(velocity.x, 0, velocity.z)
		var wall_normal:Vector3 = collide(position + h_velocity.normalized() * 0.005)
		pvecs([wall_normal, velocity])
#		print("%.2f" % wall_normal.dot(Vector3.UP))
#		collide(position + direction * SHAPECAST_DISTANCE)
#		collide_lower(position + direction * SHAPECAST_DISTANCE)
		if should_wall_slide(velocity, wall_normal):
#			print("wall slide")
			var slide_direction = wall_normal.slide(floor_normal).normalized()
			velocity = velocity.slide(slide_direction)
			velocity -= floor_normal * 0.25
#		else:
#			print("not")
		if Input.is_action_pressed("jump"):
			velocity.y = jump_force
	else:
#		print('air %s' % OS.get_ticks_msec())
		if h_velocity.dot(direction) <= speed:
			velocity += direction * (speed - h_velocity.dot(direction)) * accel_air * delta
		velocity.y -= gravity * delta
	linear_velocity = velocity

func cast_motion(position, motion):
	var space_state = get_world().direct_space_state
	var shape_query = PhysicsShapeQueryParameters.new()
	shape_query.exclude = [self]
	shape_query.set_shape(query_shape)
	shape_query.transform.origin = position + Vector3(0, -0.5, 0)
	return space_state.cast_motion(shape_query, motion)

func snap_to_floor(state:PhysicsDirectBodyState):
	var result := PhysicsTestMotionResult.new()
	if test_motion(state.transform.origin, Vector3.DOWN * SNAP_LENGTH, result) and is_floor(result.collision_normal):
		state.transform.origin += result.motion.project(result.collision_normal)
#		print("snapped", OS.get_ticks_msec())

func detect_down_slope(position, velocity):
	var space_state = get_world().direct_space_state
	var ray_body = Vector3.DOWN * 2.0
	var result_near = space_state.intersect_ray(position, position + ray_body, [self])
	var result_far = space_state.intersect_ray(position + velocity * delta, position + velocity * delta + ray_body, [self])
	if result_near and result_far:
		var slope_dir = (result_far.position - result_near.position).normalized()
		if slope_dir.dot(Vector3.UP) < -TOLERANCE:
			return slope_dir
	return Vector3()

func snap(position):
	var result := PhysicsTestMotionResult.new()
	if test_motion(position, floor_normal * SNAP_LENGTH, result):
		return result.motion
	else:
		return Vector3()

func step():
	var result := PhysicsTestMotionResult.new()
	var sweep_start := position
	# up
	if test_motion(sweep_start, Vector3.UP * STEP_HEIGHT, result):
		pass
	# forward
	
	# down
	

func test_motion(position:Vector3, motion:Vector3, result:PhysicsTestMotionResult) -> bool:
	return PhysicsServer.body_test_motion(get_rid(), Transform(Basis.IDENTITY, position), motion, false, result)

func direction():
	var forward = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	var right = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	return Vector3(right, 0, -forward).normalized().rotated(Vector3.UP, deg2rad(yaw))

func raycast():
	var space_state = get_world().direct_space_state
	var ray_start = camera.global_transform.origin
	var ray_vec = -200 * camera.global_transform.basis.z
	var ray_end = ray_start + ray_vec
	var result = space_state.intersect_ray(ray_start, ray_end, [self])
	if result and is_instance_valid(result.collider):
		print("Hit ", result.collider)


# TODO exclude specific collision shapes, not whole colliders
func collide_shape(position:Vector3, shape:Shape=query_shape, iters:int=1):
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
func collide_head(position:Vector3) -> Vector3:
	var results = collide_shape(position + Vector3(0, 0.5, 0), query_shape, 1)
	return results[0].normal if results else Vector3()

func collide_feet(position:Vector3) -> Vector3:
	var results = collide_shape(position - Vector3(0, 0.5 - SHAPECAST_TOLERANCE, 0), query_shape, 1)
	return results[0].normal if results else Vector3()

# using near full-height collider for cases where the wall is at head height
# tradeoff: leads to some jitter when pushing into two sloped ceiling walls
# if that's more important, use a shorter collider @ feet
func collide(position:Vector3) -> Vector3:
	var shape = CylinderShape.new()
	shape.height = $CollisionShape.shape.height # - TOLERANCE
	var results = collide_shape(position, shape, 1)
	return results[0].normal if results else Vector3()

func collide_floor(position:Vector3) -> Vector3:
	var results = collide_shape(position - Vector3(0, 0.5, 0), query_shape, 4)
	var floor_normal = Vector3()
	for result in results:
		if is_floor(result.normal):
			floor_normal += result.normal
	return floor_normal.normalized()

func collide_lower(position:Vector3) -> Vector3:
	var results = collide_shape(position - Vector3(0, 0.5, 0), query_shape, 4)
	var normal = Vector3()
	for result in results:
		if not is_floor(result.normal) and result.normal.dot(Vector3.UP) > -TOLERANCE:
			normal += result.normal
	return normal.normalized()

func collide_upper(position:Vector3) -> Vector3:
	var results = collide_shape(position, query_shape, 4)
	var upper_normal = Vector3()
	for result in results:
		if not is_floor(result.normal):
			upper_normal += result.normal
	return upper_normal.normalized()

func vsum(vectors:Array) -> Vector3:
	var sum := Vector3()
	for vector in vectors: sum += vector
	return sum

func vtos(vector:Vector3):
	return "(%+.3f, %+.3f, %+.3f)" % [vector.x, vector.y, vector.z]

func is_floor(normal:Vector3) -> bool:
	return normal.angle_to(Vector3.UP) <= FLOOR_ANGLE + TOLERANCE

func should_wall_slide(motion:Vector3, wall_normal:Vector3) -> bool:
	return (
		not is_floor(wall_normal) 
		and abs(motion.slide(wall_normal).dot(Vector3.UP)) > TOLERANCE # will slide vertically
		and wall_normal.dot(Vector3.UP) > -0.25 # isn't a ceiling
		and wall_normal.dot(motion) < TOLERANCE # motion is pushing into wall
	)

func pvecs(vecs):
	var vec_str = ""
	for vec in vecs:
		vec_str += vtos(vec) + " - "
	print(vec_str)

func phvel():
	var h_vel = Vector3(velocity.x, 0, velocity.z)
	print("%.2f" % h_vel.length())
