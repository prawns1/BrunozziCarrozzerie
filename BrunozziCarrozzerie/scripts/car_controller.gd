extends VehicleBody

############################################################
# behaviour values

export var MAX_ENGINE_FORCE = 200.0
export var MAX_BRAKE_FORCE = 5.0
export var MAX_STEER_ANGLE = 0.5

export var steer_speed = 5.0

var steer_target = 0.0
var steer_angle = 0.0

var x = 0.0
var incrementConst = 5

############################################################
# Input

export var joy_steering = JOY_ANALOG_LX
export var steering_mult = -1.0
export var joy_throttle = JOY_ANALOG_R2
export var throttle_mult = 1.0
export var joy_brake = JOY_ANALOG_L2
export var brake_mult = 1.0

func _physics_process(delta):
	var steer_val = steering_mult * Input.get_joy_axis(0, joy_steering)
	var throttle_val = throttle_mult * Input.get_joy_axis(0, joy_throttle)
	var brake_val = brake_mult * Input.get_joy_axis(0, joy_brake)
	
	# overrules for keyboard
	if Input.is_action_pressed("ui_up"):
		#up is pressed, X_GRAPH_COORDINATE increases
		x = increaseX(x,delta)
		throttle_val = 1.0
	if Input.is_action_pressed("ui_down"):
		#down is pressed, X_GRAPH_COORDINATE decreases
		x = decreaseX(x,delta)
		brake_val = 1.0
	if Input.is_action_pressed("ui_left"):
		steer_val = 1.0
	elif Input.is_action_pressed("ui_right"):
		steer_val = -1.0
	
	engine_force = throttle_val * getSpeed(x)
	brake = brake_val * MAX_BRAKE_FORCE
	
	steer_target = steer_val * MAX_STEER_ANGLE
	if (steer_target < steer_angle):
		steer_angle -= steer_speed * delta
		if (steer_target > steer_angle):
			steer_angle = steer_target
	elif (steer_target > steer_angle):
		steer_angle += steer_speed * delta
		if (steer_target < steer_angle):
			steer_angle = steer_target
	
	steering = steer_angle

func increaseX(x, delta):
	x = x + delta*incrementConst
	print(x)
	return x
	
func decreaseX(x, delta):
	x = x - delta*incrementConst*30
	if(x < 0):
		x = 0
	print(x)
	return x

func getSpeed(x):
	if(x <= 25):
		return 1.24*x
	else:
		return log(x)*52
