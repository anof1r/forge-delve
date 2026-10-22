extends CharacterBody2D

# Скорость движения игрока (пикселей в секунду)
var speed: float = 300.0

# Переменная для хранения точки, куда кликнул игрок
var target_position: Vector2

# Флаг: движется ли сейчас игрок
var is_moving: bool = false

func _ready():
	# При старте игры точка назначения равна текущей позиции игрока
	target_position = global_position
	is_moving = false

# Эта функция ловит клики мыши


# Эта функция выполняется каждый кадр
func _physics_process(delta):
	# Если игрок должен двигаться
	# ... (нажмите Enter и Tab, чтобы Copilot дописал проверку if is_moving: ...)
	
		# Вычисляем направление от игрока к точке клика
		# ... (Copilot допишет var direction = target_position - global_position ...)
		
		# Если до цели осталось меньше 5 пикселей, останавливаемся
		# ... (Copilot допишет if direction.length() < 5: ...)
		
		# Иначе двигаемся в сторону цели
		# ... (Copilot допишет velocity = direction.normalized() * speed ...)
	
	# Двигаем персонажа с учетом столкновений
	move_and_slide()
