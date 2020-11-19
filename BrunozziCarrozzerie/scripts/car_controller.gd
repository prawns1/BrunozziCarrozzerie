extends VehicleBody

############################################################
# behaviour values

export var MAX_ENGINE_FORCE = 200.0
export var MAX_BRAKE_FORCE = 5.0
export var MAX_STEER_ANGLE = 0.25

export var steer_speed = 5.0

var steer_target = 0.0
var steer_angle = 0.0

var x = 0.0
var incrementConst = 5

var rpm

#moduloLimite da l'idea di aver raggiunto il limite, la barretta non rimane ferma di getto
var moduloLimite = 5 
#(N.B: la rotazione della stanghetta varia da 10.0 a 250.0 MASSIMO TEORICO)
#leggere github: "Contagiri e tachimetro scalabili" per più informazioni sulle variabili qua sotto
var contagiriBound = 200
var contagiriScale = 10
var tachimetroBound = 220
var tachimetroScale = 15

var minimoRotazione = 10.0
var massimoRotazione = 250.0
var massimoTestoTachimetro = 220.0

var respawnPosition = Vector3(0,0,0)
var justRespawned = false

############################################################
# Input

export var joy_steering = JOY_ANALOG_LX
export var steering_mult = -1.0
export var joy_throttle = JOY_ANALOG_R2
export var throttle_mult = 1.0
export var joy_brake = JOY_ANALOG_L2
export var brake_mult = 1.0

############################################################
# AUDIO CONTROL
export(String, FILE, "*.wav") onready var engine_audio_path
export(float) var a_pitch_offset
export(float) var a_pitch_scale
export(float) var max_wheel_rpm
export(int) var n_gears

var pitch_constant
var pb_speed = 1

func _ready():
	$AudioStreamPlayer.stream = load(engine_audio_path)
	$AudioStreamPlayer.play()
	pitch_constant = max_wheel_rpm/n_gears

func _physics_process(delta):
	var steer_val = steering_mult * Input.get_joy_axis(0, joy_steering)
	var throttle_val = throttle_mult * Input.get_joy_axis(0, joy_throttle)
	var brake_val = brake_mult * Input.get_joy_axis(0, joy_brake)
	
	rpm = $wheel_front_l.get_rpm()
	
	# overrules for keyboard
	if Input.is_action_pressed("ui_up"):
		throttle_val = 1.0
	if Input.is_action_pressed("ui_down"):
		brake_val = 1.0
	if Input.is_action_pressed("ui_left"):
		steer_val = 2.0
	elif Input.is_action_pressed("ui_right"):
		steer_val = -2.0
		
	#ignorare rpm < 50 e rpm > 37
	#se freno ed rpm<50, allora vado in retro a -5 costante
	if(brake_val == 1 && rpm<50):
		engine_force = - MAX_ENGINE_FORCE / 4
	else:
		#se ho premuto su (throttle_val ==1) accelero
		engine_force = throttle_val * MAX_ENGINE_FORCE / 4
		#sennò sto frenando perchè rpm è ancora alto e deve scendere
		if(rpm > 37):#si
			brake = brake_val * 2.0/3.0
		
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
	
	#sta funzione è una merda ma fa il suo lavoro
	pb_speed = ((fmod(abs(rpm/contagiriScale),pitch_constant)/pitch_constant) * a_pitch_scale + a_pitch_offset)
	$AudioStreamPlayer.pitch_scale = pb_speed

func _process(delta):
	setContagiri()
	setTachimetro()
	checkRaycast()
	pass

func setContagiri():
	#pb_speed [1.0, 2) (valore suono giri)
	#rot [10.0, 250] (angolo)
	#la funzione rimappa pb_speed in modo da farlo entrare nel range rot
	#fx1 = x*250 - 250 = (x-1) * 250 
	var rot = (pb_speed-1) * 250;
	$Control/ContagiriBarretta.rect_rotation = rot

func setTachimetro():
	var rot
	rot = min(abs(rpm/tachimetroScale), tachimetroBound + randi() % moduloLimite)
	$Control/TachimetroBarretta.rect_rotation = rot
	#rot : rotMax = speedAttuale : speedMassima
	#rot : 250 = speedAttuale : 220
	$Control/TachimetroText.bbcode_text = str("[center] ", int(rot * massimoTestoTachimetro / massimoRotazione)) 

func checkRaycast():
	var timer = get_node("Timer")
	var ray = get_node("RayCast")
	
	if(timer.is_stopped() == false):
		return
		
	if(ray.is_colliding() == false && justRespawned == false):
		#FARE PARTIRE L'AUDIO DI GIGI: PORCODDIO SIAMO NEL FOSSO
		timer.start() #see _on_Timer_timeout()
		pass
	else:
		justRespawned = false
		respawnPosition = translation


func _on_Timer_timeout():
	#respawning con reset rotazione
	#translation e' da sostituire con un punto di respawn
	translation = respawnPosition
	rotation_degrees = Vector3(0,0,0)
	translation = Vector3(0,0,0)
	sleeping = true
	justRespawned = true
	get_node("Timer").stop()
