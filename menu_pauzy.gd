extends CanvasLayer

const KOLOR_TURKUS = Color("#55e7ff")
const KOLOR_FIOLET = Color("#ad83ff")

@onready var przyciemnienie = $Przyciemnienie
@onready var panel_pauzy = $Przyciemnienie/CenterContainer/PanelPauzy
@onready var panel_ustawien = $Przyciemnienie/CenterContainer/PanelUstawien



func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	przyciemnienie.hide()
	panel_ustawien.hide()

	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/TytulPauzy.text = "Pauza"
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoGry.text = "Wróć do gry"
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/OtworzUstawienia.text = "Ustawienia"
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoMenu.text = "Menu główne"

	_styluj_interfejs()

	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoGry.pressed.connect(_wroc_do_gry)
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/OtworzUstawienia.pressed.connect(_otworz_ustawienia)
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoMenu.pressed.connect(_wroc_do_menu)
	$Przyciemnienie/CenterContainer/PanelUstawien/EkranUstawien.back_requested.connect(_wroc_do_pauzy)


func _styluj_interfejs():
	przyciemnienie.color = Color(0.015, 0.03, 0.055, 0.66)
	_styluj_panel(panel_pauzy, KOLOR_TURKUS)
	_styluj_panel(panel_ustawien, KOLOR_FIOLET)
	panel_ustawien.custom_minimum_size = Vector2(560.0, 0.0)

	var tytul_pauzy = $Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/TytulPauzy
	tytul_pauzy.add_theme_font_override("font", load("res://assets/fonts/Oxanium.ttf"))
	tytul_pauzy.add_theme_font_size_override("font_size", 34)
	tytul_pauzy.add_theme_color_override("font_color", KOLOR_TURKUS)
	tytul_pauzy.custom_minimum_size.y = 54.0
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer.add_theme_constant_override("separation", 12)
	for dziecko in $Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer.get_children():
		if dziecko is Label:
			dziecko.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dziecko.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			dziecko.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dziecko.add_theme_font_size_override("font_size", 18)
			dziecko.add_theme_color_override("font_color", Color("#e6f2ff"))

	for guzik in [
		$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoGry,
		$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/OtworzUstawienia,
		$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoMenu
	]:
		_styluj_przycisk(guzik)


func _styluj_panel(panel: PanelContainer, akcent: Color):
	panel.custom_minimum_size.x = 500.0
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color("#0c1628f7")
	styl.border_color = Color(akcent, 0.68)
	styl.set_border_width_all(2)
	styl.set_corner_radius_all(22)
	styl.content_margin_left = 30.0
	styl.content_margin_right = 30.0
	styl.content_margin_top = 18.0
	styl.content_margin_bottom = 18.0
	styl.shadow_color = Color(akcent, 0.12)
	styl.shadow_size = 22
	styl.shadow_offset = Vector2(0.0, 8.0)
	panel.add_theme_stylebox_override("panel", styl)


func _styluj_przycisk(guzik: Button):
	guzik.custom_minimum_size = Vector2(420.0, 54.0)
	guzik.alignment = HORIZONTAL_ALIGNMENT_CENTER
	guzik.add_theme_font_size_override("font_size", 20)
	guzik.add_theme_color_override("font_color", Color("#e8f4ff"))
	guzik.add_theme_color_override("font_hover_color", Color.WHITE)
	guzik.add_theme_color_override("font_pressed_color", Color("#b8f5ff"))
	var akcent = KOLOR_TURKUS
	guzik.add_theme_stylebox_override("normal", _styl_przycisku(Color("#111e32"), Color("#344d64")))
	guzik.add_theme_stylebox_override("hover", _styl_przycisku(Color("#192d45"), akcent))
	guzik.add_theme_stylebox_override("pressed", _styl_przycisku(Color("#102638"), akcent.darkened(0.18)))
	guzik.add_theme_stylebox_override("focus", _styl_przycisku(Color("#111e32"), akcent))
	guzik.pivot_offset = guzik.custom_minimum_size * 0.5
	guzik.resized.connect(func(): guzik.pivot_offset = guzik.size * 0.5)
	guzik.mouse_entered.connect(_animuj_najechanie.bind(guzik, true))
	guzik.mouse_exited.connect(_animuj_najechanie.bind(guzik, false))


func _animuj_najechanie(guzik: Control, aktywne: bool):
	if guzik.has_meta("animacja_najechania"):
		var poprzednia = guzik.get_meta("animacja_najechania")
		if is_instance_valid(poprzednia):
			poprzednia.kill()
	var animacja = create_tween()
	guzik.set_meta("animacja_najechania", animacja)
	animacja.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacja.tween_property(guzik, "scale", Vector2(1.035, 1.035) if aktywne else Vector2.ONE, 0.14)


func _styl_przycisku(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = tlo
	styl.border_color = obramowanie
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(10)
	styl.content_margin_left = 18.0
	styl.content_margin_right = 18.0
	styl.content_margin_top = 8.0
	styl.content_margin_bottom = 8.0
	return styl


func _styl_pola(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = tlo
	styl.border_color = obramowanie
	styl.draw_center = true
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(8)
	# Wysokość stylu wyznacza grubość prowadnicy HSlidera.
	styl.content_margin_left = 2.0
	styl.content_margin_right = 2.0
	styl.content_margin_top = 4.0
	styl.content_margin_bottom = 4.0
	return styl


func _tekstura_uchwytu(kolor: Color) -> ImageTexture:
	var obraz = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	obraz.fill(Color.TRANSPARENT)
	for y in range(24):
		for x in range(24):
			var odleglosc = Vector2(x - 11.5, y - 11.5).length()
			if odleglosc <= 10.5:
				obraz.set_pixel(x, y, kolor)
			elif odleglosc <= 11.5:
				obraz.set_pixel(x, y, Color("#d9fbff"))
	return ImageTexture.create_from_image(obraz)


func _input(event):
	if Ustawienia.czeka_na_klawisz:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("pauza"):
		get_viewport().set_input_as_handled()

		if not get_tree().paused:
			get_tree().paused = true
			przyciemnienie.show()
			panel_pauzy.show()
			panel_ustawien.hide()
			_animuj_wejscie(panel_pauzy)
		elif panel_ustawien.visible:
			_wroc_do_pauzy()
		else:
			_wroc_do_gry()


func _wroc_do_gry():
	przyciemnienie.hide()
	get_tree().paused = false


func _otworz_ustawienia():
	panel_pauzy.hide()
	panel_ustawien.show()
	_animuj_wejscie(panel_ustawien)


func _animuj_wejscie(panel: Control):
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.97, 0.97)
	panel.modulate.a = 0.0
	var animacja = create_tween()
	animacja.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	animacja.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacja.parallel().tween_property(panel, "scale", Vector2.ONE, 0.2)
	animacja.parallel().tween_property(panel, "modulate:a", 1.0, 0.18)


func _wroc_do_pauzy():
	panel_ustawien.hide()
	panel_pauzy.show()
	_animuj_wejscie(panel_pauzy)


func _wroc_do_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")
