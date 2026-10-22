class_name Hud
extends CanvasLayer
## Минимальный интерфейс: переключатель роли ДМ/игрок (для отладки без сети).

signal role_changed(role: Permissions.Role)

var _role: Permissions.Role = Permissions.Role.DM
var _button: Button


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	add_child(panel)
	var box := HBoxContainer.new()
	panel.add_child(box)
	_button = Button.new()
	_button.focus_mode = Control.FOCUS_NONE
	_button.pressed.connect(_toggle_role)
	box.add_child(_button)
	var hint := Label.new()
	hint.text = "ЛКМ — выбрать/идти · ПКМ/Esc — снять выбор · СКМ — вращать · Shift+СКМ — двигать · Q/E — поворот · колесо — зум"
	box.add_child(hint)
	_refresh()


func _toggle_role() -> void:
	_role = Permissions.Role.PLAYER if _role == Permissions.Role.DM else Permissions.Role.DM
	_refresh()
	role_changed.emit(_role)


func _refresh() -> void:
	_button.text = "Роль: ДМ (мобы)" if _role == Permissions.Role.DM else "Роль: Игрок"
