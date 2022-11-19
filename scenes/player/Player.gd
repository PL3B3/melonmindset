extends Spatial

onready var movement_:MoveComponent = get_node("MoveComponent")
onready var input_:InputComponent = get_node("InputComponent")
onready var view_:ViewComponent = get_node("ViewComponent")

var inputs:Array = []
var positions:Array = []
var input:Dictionary = {}

func _ready():
    movement_.set_as_toplevel(true)

func _process(_delta):
    view_._update_transform(self, movement_)

onready var state = {
    "velocity": Vector3(), 
    "position": global_transform.origin, 
    "floor_normals": [Vector3(), Vector3(), Vector3()]
}

func _physics_process(delta):
#    var resim_state = movement_.resimulate(self, delta)
#    if resim_state: state = resim_state
    input_._update_input(self)
    state = movement_._simulate(state, inputs[-1], delta)
#    print(movement_.is_on_floor())
