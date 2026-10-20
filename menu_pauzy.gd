extends CanvasLayer

const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")
const KOLOR_TURKUS = Color("#55e7ff")
const KOLOR_FIOLET = Color("#ad83ff")

@onready var przyciemnienie = $Przyciemnienie
@onready var panel_pauzy = $Przyciemnienie/CenterContainer/PanelPauzy
@onready var panel_ustawien = $Przyciemnienie/CenterContainer/PanelUstawien

@onready var glosnosc_ogolna = $Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/GlosnoscOgolna
@onready var glosnosc_muzyki = $Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/GlosnoscMuzyki
@onready var glosnosc_dzwiekow = $Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/GlosnoscDzwiekow


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	Ustawienia.wczytaj()

	przyciemnienie.hide()
	panel_ustawien.hide()

	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/TytulPauzy.text = "Pauza"
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoGry.text = "Wróć do gry"
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/OtworzUstawienia.text = "Ustawienia"
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoMenu.text = "Menu główne"
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/PodpowiedzSterowania.text = Ustawienia.tekst_podpowiedzi()

	$Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/TytulUstawien.text = "Ustawienia"
	$Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/EtykietaOgolna.text = "Głośność ogólna"
	$Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/EtykietaMuzyka.text = "Głośność muzyki"
	$Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/EtykietaDzwieki.text = "Głośność dźwięków"
	$Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/WrocDoPauzy.text = "Wróć"
	_styluj_interfejs()
	var podpowiedz_sterowania = $Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/PodpowiedzSterowania
	podpowiedz_sterowania.add_theme_font_size_override("font_size", 15)
	podpowiedz_sterowania.add_theme_color_override("font_color", Color("#b9cde2"))

	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoGry.pressed.connect(_wroc_do_gry)
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/OtworzUstawienia.pressed.connect(_otworz_ustawienia)
	$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoMenu.pressed.connect(_wroc_do_menu)
	$Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/WrocDoPauzy.pressed.connect(_wroc_do_pauzy)

	glosnosc_ogolna.min_value = 0
	glosnosc_ogolna.max_value = 100
	glosnosc_ogolna.step = 1
	glosnosc_ogolna.value = Ustawienia.glosnosc_ogolna

	glosnosc_muzyki.min_value = 0
	glosnosc_muzyki.max_value = 100
	glosnosc_muzyki.step = 1
	glosnosc_muzyki.value = Ustawienia.glosnosc_muzyki

	glosnosc_dzwiekow.min_value = 0
	glosnosc_dzwiekow.max_value = 100
	glosnosc_dzwiekow.step = 1
	glosnosc_dzwiekow.value = Ustawienia.glosnosc_efektow

	glosnosc_ogolna.value_changed.connect(_zmien_glosnosc_ogolna)
	glosnosc_muzyki.value_changed.connect(_zmien_glosnosc_muzyki)
	glosnosc_dzwiekow.value_changed.connect(_zmien_glosnosc_dzwiekow)

	_ustaw_glosnosc("Master", glosnosc_ogolna.value)
	_ustaw_glosnosc("Muzyka", glosnosc_muzyki.value)
	_ustaw_glosnosc("Efekty", glosnosc_dzwiekow.value)


func _styluj_interfejs():
	przyciemnienie.color = Color(0.015, 0.03, 0.055, 0.66)
	_styluj_panel(panel_pauzy, KOLOR_TURKUS)
	_styluj_panel(panel_ustawien, KOLOR_FIOLET)

	var styl_ustawien = panel_ustawien.get_theme_stylebox("panel") as StyleBoxFlat
	styl_ustawien.content_margin_top = 5.0
	styl_ustawien.content_margin_bottom = 5.0
	panel_ustawien.custom_minimum_size.y = 616.0

	var tytul_pauzy = $Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/TytulPauzy
	var tytul_ustawien = $Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/TytulUstawien
	for tytul in [tytul_pauzy, tytul_ustawien]:
		tytul.add_theme_font_override("font", FONT_ARCADE)
		tytul.add_theme_font_size_override("font_size", 34)
		tytul.add_theme_color_override("font_color", KOLOR_TURKUS if tytul == tytul_pauzy else KOLOR_FIOLET)
		tytul.custom_minimum_size.y = 54.0
		tytul_ustawien.custom_minimum_size.y = 42.0

	for panel in [panel_pauzy, panel_ustawien]:
		var uklad = panel.get_child(0)
		uklad.add_theme_constant_override("separation", 12 if panel == panel_pauzy else 5)
		for dziecko in uklad.get_children():
			if dziecko is Label:
				dziecko.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				dziecko.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				dziecko.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				if dziecko != tytul_pauzy and dziecko != tytul_ustawien:
					dziecko.add_theme_font_size_override("font_size", 18)
					dziecko.add_theme_color_override("font_color", Color("#e6f2ff"))

	for guzik in [
		$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoGry,
		$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/OtworzUstawienia,
		$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/WrocDoMenu,
		$Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/WrocDoPauzy
	]:
		_styluj_przycisk(guzik)

	for suwak in [glosnosc_ogolna, glosnosc_muzyki, glosnosc_dzwiekow]:
		suwak.custom_minimum_size = Vector2(420.0, 32.0)
		var akcent = KOLOR_TURKUS if suwak == glosnosc_ogolna else KOLOR_FIOLET if suwak == glosnosc_muzyki else Color("#ff5fb7")
		suwak.add_theme_stylebox_override("slider", _styl_pola(Color("#17263b"), Color("#17263b")))
		suwak.add_theme_stylebox_override("grabber_area", _styl_pola(Color(akcent, 0.4), Color(akcent, 0.4)))
		suwak.add_theme_stylebox_override("grabber_area_highlight", _styl_pola(Color(akcent, 0.75), Color(akcent, 0.75)))
		var uchwyt = _tekstura_uchwytu(akcent)
		suwak.add_theme_icon_override("grabber", uchwyt)
		suwak.add_theme_icon_override("grabber_highlight", uchwyt)
		suwak.add_theme_icon_override("grabber_disabled", uchwyt)


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
	var akcent = KOLOR_FIOLET if guzik == $Przyciemnienie/CenterContainer/PanelUstawien/VBoxContainer/WrocDoPauzy else KOLOR_TURKUS
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
			$Przyciemnienie/CenterContainer/PanelPauzy/VBoxContainer/PodpowiedzSterowania.text = Ustawienia.tekst_podpowiedzi()
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


func _zmien_glosnosc_ogolna(wartosc):
	Ustawienia.glosnosc_ogolna = wartosc
	_ustaw_glosnosc("Master", wartosc)
	Ustawienia.zapisz()


func _zmien_glosnosc_muzyki(wartosc):
	Ustawienia.glosnosc_muzyki = wartosc
	_ustaw_glosnosc("Muzyka", wartosc)
	Ustawienia.zapisz()


func _zmien_glosnosc_dzwiekow(wartosc):
	Ustawienia.glosnosc_efektow = wartosc
	_ustaw_glosnosc("Efekty", wartosc)
	Ustawienia.zapisz()


func _ustaw_glosnosc(nazwa_szyny, wartosc):
	var indeks = AudioServer.get_bus_index(nazwa_szyny)

	if indeks == -1:
		return

	if wartosc <= 0:
		AudioServer.set_bus_volume_db(indeks, -80.0)
	else:
		AudioServer.set_bus_volume_db(indeks, linear_to_db(wartosc / 100.0))
