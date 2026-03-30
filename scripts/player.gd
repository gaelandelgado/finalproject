extends CharacterBody2D

const WALK_SPEED = 100.0
const RUN_SPEED = 160.0
const ATTACK_FRICTION = 0.94

@onready var anim = $AnimatedSprite2D
@onready var footsteps = [$Footstep1, $Footstep2]
@onready var footstep_timer = $FootstepTimer
@onready var hurt_sounds = [$HurtSound1, $HurtSound2]
@onready var walk_attack_sound = $WalkAttackSound
@onready var run_attack_sound = $RunAttackSound

var direction = Vector2.ZERO
var is_attacking = false
var is_hurt = false
var is_dead = false
var is_running = false
var was_running_when_attacked = false
var footstep_index = 0
var last_hurt_sound = 0
var max_health = 10
var health = 10
var damage = 2

func _physics_process(_delta):
	if is_dead:
		update_animation()
		return
	
	if not is_attacking and not is_hurt:
		var input = Vector2.ZERO
		input.x = Input.get_axis("ui_left", "ui_right")
		input.y = Input.get_axis("ui_up", "ui_down")
		
		is_running = Input.is_action_pressed("sprint")
		var speed = RUN_SPEED if is_running else WALK_SPEED
		
		if input != Vector2.ZERO:
			input = input.normalized()
			direction = input
			velocity = input * speed
		else:
			velocity = Vector2.ZERO
		
		if Input.is_action_just_pressed("attack"):
			is_attacking = true
			was_running_when_attacked = is_running
			if is_running:
				run_attack_sound.play()
			else:
				walk_attack_sound.play()
	else:
		velocity *= ATTACK_FRICTION
	
	move_and_slide()
	update_animation()
	update_footsteps()

func update_animation():
	if is_dead:
		if anim.animation != "death_" + get_direction_name():
			anim.play("death_" + get_direction_name())
		return
	if is_hurt:
		anim.play("hurt_" + get_direction_name())
		return
	if is_attacking:
		if was_running_when_attacked:
			anim.play("run_attack_" + get_direction_name())
		else:
			anim.play("walk_attack_" + get_direction_name())
		return
	
	if velocity == Vector2.ZERO:
		anim.play("idle_" + get_direction_name())
	elif is_running:
		anim.play("run_" + get_direction_name())
	else:
		anim.play("walk_" + get_direction_name())

func get_direction_name() -> String:
	if abs(direction.y) > abs(direction.x):
		return "down" if direction.y > 0 else "up"
	else:
		return "right" if direction.x > 0 else "left"

func update_footsteps():
	if velocity != Vector2.ZERO and not is_attacking and not is_hurt and not is_dead:
		if footstep_timer.is_stopped():
			play_footstep()
	else:
		footstep_timer.stop()

func play_footstep():
	footsteps[footstep_index].play()
	footstep_index = (footstep_index + 1) % 2
	footstep_timer.wait_time = 0.36 if is_running else 0.33
	footstep_timer.start()

func _on_footstep_timer_timeout():
	if velocity != Vector2.ZERO and not is_attacking and not is_hurt and not is_dead:
		play_footstep()

func _on_animated_sprite_2d_animation_finished():
	if is_attacking:
		is_attacking = false
	if is_hurt:
		is_hurt = false

func _on_attack_hitbox_area_entered(area):
	if area.name == "Hurtbox":
		var parent = area.get_parent()
		if parent.has_method("take_damage"):
			parent.take_damage(damage)

func take_damage(amount):
	if is_dead or is_hurt:
		return
	is_hurt = true
	health -= amount
	last_hurt_sound = (last_hurt_sound + 1) % 2
	hurt_sounds[last_hurt_sound].play()
	if health <= 0:
		is_dead = true
		print("dead")
