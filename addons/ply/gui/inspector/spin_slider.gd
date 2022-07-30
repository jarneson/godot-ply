@tool
extends Control

signal edit_started
signal value_changed(value)
signal edit_committed(value)

var value: float :
	get:
		return value # TODOConverter40 Non existent get function 
	set(v):
		value = v
		update()

var label: String
var min_value: float
var max_value: float
var step: float
var allow_greater: bool
var allow_lesser: bool

var value_input_popup: Popup
var value_input: LineEdit
var value_input_just_closed: bool


func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	value_input_popup = Popup.new()
	value_input_popup.name = "spinner_popup_%s" % [label]
	
	value_input = LineEdit.new()
	value_input.name = "spinner_line_edit_%s" % [label]
	value_input_popup.add_child(value_input)
	value_input_popup.wrap_controls = true
	value_input.set_anchors_and_offsets_preset(Control.PRESET_WIDE)
	
	value_input_popup.popup_hide.connect(_on_value_input_closed)
	value_input.text_submitted.connect(_on_value_input_entered)
	value_input.focus_exited.connect(_on_value_input_focus_exited)
	
	add_child(value_input_popup)
	focus_mode = FOCUS_ALL


func get_text_value() -> String:
	return str(snapped(value, step))


func _on_value_input_entered(_text) -> void:
	value_input_popup.hide()


func _evaluate_input_text(and_hide: bool) -> void:
	if value_input_just_closed:
		return
	value_input_just_closed = true
	var text = value_input.text
	text.replace(",", ".")
	var expr = Expression.new()
	var err = expr.parse(text)
	if err != OK:
		return
	var val = expr.execute(Array(), null, false)
	if val == null:
		return
	value = val
	emit_signal("value_changed", value)
	emit_signal("edit_committed", value)
	if and_hide:
		value_input_popup.hide()


func _on_value_input_focus_exited() -> void:
	if value_input.get_menu().visible:
		return
	_evaluate_input_text(true)


func _on_value_input_closed() -> void:
	_evaluate_input_text(false)


func _on_focus_entered() -> void:
	if (
		(Input.is_action_pressed("ui_focus_next") || Input.is_action_pressed("ui_focus_prev"))
		&& not value_input_just_closed
	):
		_handle_focus()
	value_input_just_closed = false


func _handle_focus() -> void:
	var gr = get_global_rect()
	value_input.set_text(get_text_value())
	value_input_popup.set_position(get_screen_position())
	value_input_popup.set_size(gr.size)
	value_input_popup.call_deferred("popup")
	value_input.call_deferred("grab_focus")
	value_input.call_deferred("select_all")
	value_input.focus_next = find_next_valid_focus().get_path()
	value_input.focus_previous = find_prev_valid_focus().get_path()
	value_input_just_closed = false
	emit_signal("edit_started")


func _draw() -> void:
	var sb = get_theme_stylebox("normal", "LineEdit")
	draw_style_box(sb, Rect2(Vector2(), size))
	var font = get_theme_font("font", "LineEdit")
	var sep_base = 4
	var sep = sep_base + sb.get_offset().x
	var string_width = font.get_string_size(label).x
	var number_width = size.x - sb.get_minimum_size().x - string_width - sep
	var vofs = (size.y - font.get_height()) / 2 + font.get_ascent()
	var fc = get_theme_color("font_color", "LineEdit")
	var numstr = get_text_value()
	draw_string(
		font,
		Vector2(round(sb.get_offset().x), vofs),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16, fc * Color(1, 1, 1, 0.5)
	)
	draw_string(
		font,
		Vector2(round(sb.get_offset().x + string_width + sep), vofs),
		numstr,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		fc
	)

var grabbing_spinner_mouse_pos: Vector2
var grabbing_spinner_attempt: bool
var grabbing_spinner_dist_cache: float
var grabbing_spinner: bool
var pre_grab_value: float


func _gui_input(evt) -> void:
	if evt is InputEventMouseButton:
		if evt.button_index == MOUSE_BUTTON_LEFT:
			if evt.pressed:
				grabbing_spinner_attempt = true
				grabbing_spinner_dist_cache = 0
				pre_grab_value = value
				grabbing_spinner_mouse_pos = get_viewport().get_mouse_position()
			else:
				if grabbing_spinner_attempt:
					if grabbing_spinner:
						Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
						Input.warp_mouse(grabbing_spinner_mouse_pos)
						emit_signal("edit_committed", value)
					else:
						_handle_focus()
					grabbing_spinner = false
					grabbing_spinner_attempt = false
	if evt is InputEventMouseMotion:
		if grabbing_spinner_attempt:
			var diff_x = evt.relative.x
			grabbing_spinner_dist_cache += diff_x
			if not grabbing_spinner and abs(grabbing_spinner_dist_cache) > 4:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				grabbing_spinner = true
				emit_signal("edit_started")
			if grabbing_spinner:
				value = pre_grab_value + step * grabbing_spinner_dist_cache
				emit_signal("value_changed", value)
				update()
