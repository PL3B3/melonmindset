extends Node

enum Inputs {
    Z_MOTION,
    X_MOTION,
    YAW,
    PITCH,
    JUMP,
    L_CLICK,
    R_CLICK
}

# ringbuffer of inputs
var mouse_sensitivity:float = 0.05
var yaw:float = 0.0
var pitch:float = 0.0

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
    var input_z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
    var input_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")