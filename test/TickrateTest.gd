extends Spatial

var fixed_timer
var debug_timer
var buffer = []
func _ready():
    fixed_timer = Timer.new()
    add_child(fixed_timer)
    fixed_timer.connect("timeout", self, "_fixed_process")
    fixed_timer.start(1.0 / Engine.iterations_per_second)
    debug_timer = Timer.new()
    add_child(debug_timer)
    debug_timer.connect("timeout", self, "_debug_process")
    debug_timer.start(0.016666)

func _process(delta):
    pass

func _unhandled_input(event):
    if event.is_action_pressed("ui_left"):
        Engine.iterations_per_second -= 1
    elif event.is_action_pressed("ui_right"):
        Engine.iterations_per_second += 1

func _physics_process(delta):
    buffer.push_back(OS.get_ticks_msec())

var avg_lifetime = 0.0
var window = 5.0
func _fixed_process():
    print(Engine.iterations_per_second, ": ", buffer)
    var top = buffer.pop_front()
#	avg_lifetime = ((window - 1) * avg_lifetime + buffer.size()) / window
#	if top:
#		var lifetime = OS.get_ticks_msec() - top
#		avg_lifetime = ((window - 1) * avg_lifetime + lifetime) / window

func _debug_process():
    pass
#	print(buffer)
#	print("%s: %s" % [Engine.iterations_per_second, avg_lifetime])
