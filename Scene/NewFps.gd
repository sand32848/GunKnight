extends KinematicBody


var full_contact = false
var shotOnCooldown = false
var interacting = false
var interactOnCooldown = false

var speed = 20
var h_acceleration = 6
var gravity = 20
var jump = 10
var air_acceleration = 1
var normal_acceleration = 6

var damage = 10

var mouse_Sensitivity = 0.3

var direction = Vector3()
var h_velocity = Vector3()
var movement = Vector3()
var gravity_vec = Vector3()

onready var aimCast = $Head/Camera/AimCast
onready var interactCast = $Head/Camera/InteractCast
onready var head = $Head
onready var ground_Check = $GroundCheck
onready var muzzle = $Head/Gun/Muzzle
onready var animationPlayer = $AnimationPlayer
onready var interactUI = $CanvasLayer/Control/Label
onready var InteractTimer = $InteractCooldown


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion and !interacting:
		rotate_y(deg2rad(-event.relative.x * mouse_Sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_Sensitivity))
		head.rotation.x  = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

func _physics_process(delta):
	direction = Vector3()
	
	if ground_Check.is_colliding():
		full_contact = true
	else:
		full_contact = false
		
	if interactCast.is_colliding():
		var target = interactCast.get_collider()
		if target.is_in_group("Interactable")and !interacting:
			interactUI.visible = true
			if Input.is_action_just_pressed("Interact") and interactOnCooldown == false:
				interacting = true
				var new_dialog = Dialogic.start('First')
				add_child(new_dialog)
				new_dialog.connect("dialogic_signal", self, 'dialogic_signal')
		else:
			interactUI.visible = false
	else:
		interactUI.visible = false
	
	if Input.is_action_just_pressed("Fire") and shotOnCooldown == false:
			if aimCast.is_colliding():
				var target = aimCast.get_collider()
				if target.is_in_group("Enemy"):
					print("hit enemy")
			shotOnCooldown = true
			animationPlayer.play("GunFire")
	
	#Gravity Controller
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
		h_acceleration = air_acceleration
	elif is_on_floor() and full_contact:
		gravity_vec = -get_floor_normal()* gravity
		h_acceleration = normal_acceleration
	else:
		gravity_vec = -get_floor_normal()
		h_acceleration = normal_acceleration
		
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or ground_Check.is_colliding()):
		gravity_vec = Vector3.UP * jump
	
	#movement Controler
	if !interacting:
		if Input.is_action_pressed("Move_Forward"):
			direction -= transform.basis.z
		elif Input.is_action_pressed("Move_Backward"):
			direction += transform.basis.z
		if Input.is_action_pressed("Move_Left"):
			direction -= transform.basis.x
		elif Input.is_action_pressed("Move_Right"):
			direction += transform.basis.x
	
	direction = direction.normalized()
	h_velocity = h_velocity.linear_interpolate(direction * speed, h_acceleration * delta)
	movement.z = h_velocity.z + gravity_vec.z
	movement.x = h_velocity.x  + gravity_vec.x
	movement.y = gravity_vec.y
	
	move_and_slide(movement, Vector3.UP)

func _return():
	shotOnCooldown = false
	animationPlayer.play("Idle")
	
func dialogic_signal(value):
	interacting = false
	interactOnCooldown = true
	InteractTimer.start()

func _on_InteractCooldown_timeout():
	interactOnCooldown = false 
