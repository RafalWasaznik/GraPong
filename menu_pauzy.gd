extends CanvasLayer

const KOLOR_TURKUS = Color("#55e7ff")
const KOLOR_FIOLET = KOLOR_TURKUS
const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")

@onready var przyciemnienie: ColorRect = $Przyciemnienie
@onready var panel_pauzy: PanelContainer = $Przyciemnienie/CenterContainer/PanelPauzy
@onready var panel_ustawien: PanelContainer = $Przyciemnienie/CenterContainer/PanelUstawien
@onready var uklad_pauzy: VBoxContainer = $Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer
@onready var tytul_pauzy: Label = $Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/TytulPauzy
@onready var guzik_wroc_do_gry: Button = $Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoGry
@onready var guzik_ustawienia: Button = $Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/OtworzUstawienia
@onready var guzik_menu: Button = $Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoMenu
@onready var ekran_ustawien = $Przyciemnienie/CenterContainer/PanelUstawien/EkranUstawien


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	przyciemnienie.hide()
	panel_ustawien.hide()

	tytul_pauzy.text = "Pauza"
	guzik_wroc_do_gry.text = "Wróć do gry"
	guzik_ustawienia.text = "Ustawienia"
	guzik_menu.text = "Menu główne"

	_styluj_interfejs()

	guzik_wroc_do_gry.pressed.connect(_wroc_do_gry)
	guzik_ustawienia.pressed.connect(_otworz_ustawienia)
	guzik_menu.pressed.connect(_wroc_do_menu)
	ekran_ustawien.back_requested.connect(_wroc_do_pauzy)


func _styluj_interfejs() -> void:
	przyciemnienie.color = Color(0.015, 0.03, 0.055, 0.66)
	_styluj_panel(panel_pauzy, KOLOR_TURKUS)
	_styluj_panel(panel_ustawien, KOLOR_FIOLET)
	panel_ustawien.custom_minimum_size = Vector2(560.0, 0.0)

	tytul_pauzy.add_theme_font_override("font", FONT_ARCADE)
	tytul_pauzy.add_theme_font_size_override("font_size", 34)
	tytul_pauzy.add_theme_color_override("font_color", KOLOR_TURKUS)
	tytul_pauzy.custom_minimum_size.y = 54.0
	uklad_pauzy.add_theme_constant_override("separation", 24)
	for dziecko in uklad_pauzy.get_children():
		if dziecko is Label:
			dziecko.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dziecko.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			dziecko.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dziecko.add_theme_font_size_override("font_size", 18)
			dziecko.add_theme_color_override("font_color", Color("#e6f2ff"))

	for guzik in [guzik_wroc_do_gry, guzik_ustawienia, guzik_menu]:
		_styluj_przycisk(guzik)
	tytul_pauzy.add_theme_font_size_override("font_size", 34)
	tytul_pauzy.add_theme_color_override("font_color", KOLOR_TURKUS)


func _styluj_panel(panel: PanelContainer, akcent: Color) -> void:
	panel.custom_minimum_size.x = 500.0
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color("#0c1628", 0.96)
	styl.set_corner_radius_all(8)
	styl.content_margin_left = 30.0
	styl.content_margin_right = 30.0
	styl.content_margin_top = 18.0
	styl.content_margin_bottom = 18.0
	styl.shadow_color = Color(akcent, 0.0)
	styl.shadow_size = 0
	styl.shadow_offset = Vector2(0.0, 8.0)
	panel.add_theme_stylebox_override("panel", styl)


func _styluj_przycisk(guzik: Button) -> void:
	StylMenu.styluj_przycisk(guzik, Vector2(420.0, 54.0), KOLOR_TURKUS, Color("#111e32"), Color("#344d64"), Color("#192d45"), Color("#102638"), KOLOR_TURKUS.darkened(0.18), 20)


func _input(event: InputEvent) -> void:
	if Ustawienia.tryb == "endless":
		var gra := get_parent() as GraPongAPI
		if gra != null and gra.przebieg().run_state != null and gra.przebieg().run_state.wybor_aktywny:
			return
	if Ustawienia.czeka_na_klawisz:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("pauza"):
		get_viewport().set_input_as_handled()
		if Ustawienia.tryb == "online":
			if not przyciemnienie.visible:
				Siec.pauza_lokalna = true
				_pokaz_pauze()
			elif panel_ustawien.visible:
				_wroc_do_pauzy()
			else:
				_wroc_do_gry()
			return

		if not get_tree().paused:
			get_tree().paused = true
			_pokaz_pauze()
		elif panel_ustawien.visible:
			_wroc_do_pauzy()
		else:
			_wroc_do_gry()


func _pokaz_pauze() -> void:
	przyciemnienie.show()
	panel_pauzy.show()
	panel_ustawien.hide()
	_animuj_wejscie(panel_pauzy)


func _wroc_do_gry() -> void:
	przyciemnienie.hide()
	if Ustawienia.tryb == "online":
		Siec.pauza_lokalna = false
	else:
		get_tree().paused = false


func _otworz_ustawienia() -> void:
	panel_pauzy.hide()
	panel_ustawien.show()
	_animuj_wejscie(panel_ustawien)


func _animuj_wejscie(panel: Control) -> void:
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.97, 0.97)
	panel.modulate.a = 0.0
	var animacja = create_tween()
	animacja.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	animacja.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacja.parallel().tween_property(panel, "scale", Vector2.ONE, 0.2)
	animacja.parallel().tween_property(panel, "modulate:a", 1.0, 0.18)


func _wroc_do_pauzy() -> void:
	panel_ustawien.hide()
	panel_pauzy.show()
	_animuj_wejscie(panel_pauzy)


func _wroc_do_menu() -> void:
	get_tree().paused = false
	if Ustawienia.tryb == "online":
		Siec.rozlacz()
	get_tree().change_scene_to_file("res://menu.tscn")
