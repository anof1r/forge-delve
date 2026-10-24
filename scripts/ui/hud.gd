class_name Hud
extends CanvasLayer
## Минимальный интерфейс: переключатель роли ДМ/игрок (для отладки без сети).

signal role_changed(role: Permissions.Role)

var _role: Permissions.Role = Permissions.Role.DM
var _button: Button


func _ready() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 12.0
	panel.offset_top = 56.0
	panel.offset_right = -12.0
	var box := HBoxContainer.new()
	panel.add_child(box)
	_button = Button.new()
	_button.focus_mode = Control.FOCUS_NONE
	_button.pressed.connect(_toggle_role)
	box.add_child(_button)
	var hint := Label.new()
	hint.text = "ЛКМ — выбрать/идти · ПКМ/Esc — снять выбор · Space+ЛКМ — двигать сцену · СКМ — вращать · колесо — зум"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(hint)
	_refresh()


func _toggle_role() -> void:
	_role = Permissions.Role.PLAYER if _role == Permissions.Role.DM else Permissions.Role.DM
	_refresh()
	role_changed.emit(_role)


func _refresh() -> void:
	_button.text = "Роль: ДМ (мобы)" if _role == Permissions.Role.DM else "Роль: Игрок"
