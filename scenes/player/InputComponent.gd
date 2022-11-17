extends Node

enum Inputs {
    Z_MOTION,
    X_MOTION,
    YAW,
    PITCH,
    JUMP,
    CLICK
}

# ringbuffer of inputs
var mouse_sensitivity:float = 0.05
var yaw:float = 0.0
var pitch:float = 0.0
var z_motion:float = 0
var x_motion:float = 0
var input_frame:Dictionary = {} # command frame input

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
        Engine.time_scale = 0.2 / Engine.time_scale
    
    elif event.is_action_pressed("ability_0"):
        pass

func _simulate(player, delta):
    input_frame[Inputs.Z_MOTION] = Input.get_action_strength("move_north") - Input.get_action_strength("move_south")
    input_frame[Inputs.X_MOTION] = Input.get_action_strength("move_east") - Input.get_action_strength("move_west")
    input_frame[Inputs.YAW] = yaw
    input_frame[Inputs.PITCH] = pitch
    input_frame[Inputs.JUMP] = Input.is_action_pressed("jump")
    input_frame[Inputs.CLICK] = Input.is_action_pressed("click")