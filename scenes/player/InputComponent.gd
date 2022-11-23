class_name InputComponent
extends Node

# ringbuffer of inputs
var mouse_sensitivity:float = 0.05
var yaw:float = 0.0
var pitch:float = 0.0

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
    
    elif event.is_action_pressed("walk"):
        Engine.time_scale = 10.0 / Engine.time_scale
    
    elif event.is_action_pressed("ability_0"):
        pass

func _update_input(player):
    var input:Dictionary = {}
    input[Inputs.Z_MOTION] = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
    input[Inputs.X_MOTION] = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    input[Inputs.YAW] = yaw
    input[Inputs.PITCH] = pitch
    input[Inputs.JUMP] = Input.is_action_pressed("jump")
    input[Inputs.CLICK] = Input.is_action_pressed("click")
    input["id"] = OS.get_ticks_msec()
    player.inputs.push_back(input)
