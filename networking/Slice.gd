extends Reference

class_name Slice

class Move:
	var x_dir := 0
	var z_dir := 0
	var jump := 0
	var look := Vector2()

class PlayerState:
	var position := Vector3()
	var velocity := Vector3()
	var health := 0
	var sig_recharge_tracker := 0
	var ult_charge := 0
	var active_slot := 0

class WeaponState:
	var equipped := false
	var loaded := 0
	var ammo := 0
	var fire_again_tracker := 0
