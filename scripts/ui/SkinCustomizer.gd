extends Control
## Lets the player repaint the free "Recruit" skin's head / body / clothes
## colors. Only the free skin is customizable this way -- purchased skins
## keep their fixed palette, same as the real game's cosmetics.

const SAVE_KEY := "default_recruit"

var preview: SubViewport
var preview_customization: PlayerCustomization
var colors: Dictionary = {}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	colors = EconomyManager.get_recruit_colors()

	var hsplit := HSplitContainer.new()
	hsplit.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hsplit)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(320, 0)
	hsplit.add_child(left)

	var title := Label.new()
	title.text = "CUSTOMIZE RECRUIT"
	title.add_theme_font_size_override("font_size", 24)
	left.add_child(title)

	left.add_child(_color_row("Head", "head"))
	left.add_child(_color_row("Body", "body"))
	left.add_child(_color_row("Clothes", "clothes"))

	var save_btn := Button.new()
	save_btn.text = "Save & Equip"
	save_btn.pressed.connect(_save_and_equip)
	left.add_child(save_btn)

	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	left.add_child(back)

	_build_preview(hsplit)

func _color_row(label_text: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(80, 0)
	row.add_child(label)
	var picker := ColorPickerButton.new()
	picker.custom_minimum_size = Vector2(160, 32)
	picker.color = colors.get(key, Color.WHITE)
	picker.color_changed.connect(func(c): _on_color_changed(key, c))
	row.add_child(picker)
	return row

func _on_color_changed(key: String, c: Color) -> void:
	colors[key] = c
	if preview_customization:
		preview_customization.set_skin(SAVE_KEY, colors)

func _build_preview(parent: Control) -> void:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	preview = SubViewport.new()
	preview.size = Vector2i(600, 600)
	preview.own_world_3d = true
	panel.add_child(_wrap_viewport(preview))

	var world := Node3D.new()
	preview.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	world.add_child(light)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.2, 3.2)
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	world.add_child(cam)

	preview_customization = PlayerCustomization.new()
	world.add_child(preview_customization)
	preview_customization.set_skin(SAVE_KEY, colors)

func _wrap_viewport(vp: SubViewport) -> Control:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.custom_minimum_size = Vector2(500, 500)
	container.add_child(vp)
	return container

func _save_and_equip() -> void:
	EconomyManager.save_recruit_colors(colors)
	EconomyManager.equip_skin(SAVE_KEY)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
