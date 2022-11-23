extends KinematicBody

var test_iterations:int = 200
var speed:float = 15
var moves = []
var moves_idx = 0
var moves_count = 1
var repeat_count = 2
var last_moves = moves
var rng = RandomNumberGenerator.new()
var results = []
onready var default_phys_ticks = Engine.iterations_per_second
onready var pos_at_begin = global_transform.origin

func _ready():
    rng.seed = hash("consistency")
    moves = get_moves()

func get_moves():
    var result = []
    for i in range(0, moves_count):
        var random_move = Vector3(
            rng.randf_range(-speed, speed), 
            rng.randf_range(-speed, speed * 0.5),
            rng.randf_range(-speed, speed)
        )
        for j in repeat_count:
            result.append(Vector3(10, 0, 0))
    return result

var press_time = 0
func _unhandled_input(event):
    if event.is_action_pressed("ability_0"):
        press_time = OS.get_ticks_usec()

func _physics_process(delta):
#    if moves:
#        move_and_slide(moves.pop_back(), Vector3.UP)
#    else:
#        moves = get_moves()
#	for move in moves:
#		move_and_slide(move, Vector3.UP)
#	if press_time:
#		print(OS.get_ticks_usec() - press_time)
#		press_time = 0
    test_reconciliation_resim()
#	test_delta_compensation()

var p0 = Vector3()
var phase = 0
func test_delta_compensation():
    if moves_idx < moves.size():
        var delta_compensation = Engine.iterations_per_second / float(default_phys_ticks)
        var move = moves[moves_idx]
        move_and_slide_with_snap(move * delta_compensation, Vector3.DOWN)
        moves_idx += 1
        if moves_idx == moves.size():
            print("Move position at rate %s: %s" % [Engine.iterations_per_second, global_transform.origin])
            if phase == 0:
                Engine.iterations_per_second = 60
                p0 = global_transform.origin
                global_transform.origin = pos_at_begin
                force_update_transform()
                moves_idx = 0
                phase = 1
            else:
                print("Discrepancy: %s" % [(global_transform.origin - p0).length()])
                Engine.iterations_per_second = 100
                pos_at_begin = global_transform.origin
                moves = get_moves()
                moves_idx = 0
                phase = 0

func simulate_move():
    if moves_idx < moves.size():
        var move = moves[moves_idx]
        moves_idx += 1

func test_reconciliation():
    if moves_idx < moves.size():
        move_and_slide(moves[moves_idx], Vector3.UP)
#		move_and_slide_with_snap(moves[moves_idx], Vector3.DOWN, Vector3.UP)
        moves_idx += 1
        if moves_idx == moves.size():
            var final_position = global_transform.origin
#			print("Move position: %s" % global_transform.origin)
            global_transform.origin = pos_at_begin
            force_update_transform()
#			for i in 100:
#				var a = 3 + 2
            for move in moves:
                move_and_slide(move, Vector3.UP)
#				move_and_slide_with_snap(move, Vector3.DOWN, Vector3.UP)
#			print("Calc position: %s" % global_transform.origin)
            results.push_back((global_transform.origin - final_position).length())
            results.sort()
            results.invert()
            if test_iterations == 0:
                print(results)
                queue_free()
            pos_at_begin = global_transform.origin
            moves = get_moves()
            moves_idx = 0
            test_iterations -= 1
            if test_iterations % 10 == 0: print(test_iterations, ": ", results)

func test_reconciliation_resim():
    if moves_idx < moves.size():
        move_and_slide(moves[moves_idx], Vector3.UP)
#		move_and_slide_with_snap(moves[moves_idx], Vector3.DOWN, Vector3.UP)
        moves_idx += 1
        if moves_idx == moves.size():
            var final_position = global_transform.origin
#			print("Move position: %s" % global_transform.origin)
            var new_pos = Vector3()
            for i in 2:
                global_transform.origin = pos_at_begin
                force_update_transform()
                for j in 2:
                    move_and_slide(Vector3(10, 0, 0), Vector3.UP)
                if new_pos:
                    results.push_back((global_transform.origin - new_pos).length())
                new_pos = global_transform.origin
            results.sort()
            results.invert()
            if test_iterations == 0:
                print(results)
                queue_free()
            pos_at_begin = global_transform.origin
            moves = get_moves()
            moves_idx = 0
            test_iterations -= 1
            if test_iterations % 10 == 0: print(test_iterations, ": ", results)
