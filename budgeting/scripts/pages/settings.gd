extends ColorRect
@onready var cp1 = $Color1
@onready var cp2 = $Color2
@onready var cp3 = $Color3
@onready var cp4 = $Color4

@onready var Example = $Example

func _ready() -> void:
	for i in get_children():
		if i is ColorPickerButton:
			var picker = i.get_picker()
			picker.picker_shape = 2
			picker.color_modes_visible = false
			picker.sliders_visible = false
			picker.presets_visible = false
	changed_color()		

func changed_color():
	ColorScheme.system_gradient.colors = PackedColorArray([Color(0, 0, 0), cp1.color, cp2.color, cp3.color, cp4.color, Color(1, 1, 1)])
	ColorScheme.system_gradient.offsets = PackedFloat32Array([0, 0.2, 0.4, 0.6, 0.8, 1])
	var idx = 6
	for i in Example.get_children():
		i.color = ColorScheme.get_color(idx, 6, ColorScheme.system_gradient)
		idx -= 1

func _on_color_1_color_changed(color: Color) -> void: changed_color()

func _on_color_2_color_changed(color: Color) -> void: changed_color()

func _on_color_3_color_changed(color: Color) -> void: changed_color()

func _on_color_4_color_changed(color: Color) -> void: changed_color()
