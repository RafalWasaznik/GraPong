extends VBoxContainer

signal back_requested

const AKCENT = Color("#55e7ff")
const TEKST = Color("#e3effa")
const TEKST_DRUGORZEDNY = Color("#91a5b8")

@onready var zakladki: TabContainer = $Zakladki
@onready var glosnosc_ogolna: HSlider = $Zakladki/Dzwiek/Margines/Zawartosc/BlokOgolny/Uklad/GlosnoscOgolna
@onready var glosnosc_muzyki: HSlider = $Zakladki/Dzwiek/Margines/Zawartosc/BlokMuzyki/Uklad/GlosnoscMuzyka
@onready var glosnosc_dzwiekow: HSlider = $Zakladki/Dzwiek/Margines/Zawartosc/BlokEfektow/Uklad/GlosnoscDzwiekow
@onready var pelny_ekran: CheckButton = $Zakladki/Ekran/Margines/Zawartosc/BlokEkranu/Uklad/PelnyEkran
@onready var kursor_neonowy: CheckButton = $Zakladki/Inne/Margines/Zawartosc/BlokKursora/Uklad/KursorNeonowy
var animacja_zakladki: Tween


func _ready() -> void:
	$WrocUstawienia.pressed.connect(_zglos_powrot)
	for suwak: HSlider in [glosnosc_ogolna, glosnosc_muzyki, glosnosc_dzwiekow]:
		suwak.min_value = 0
		suwak.max_value = 100
		suwak.step = 1
	glosnosc_ogolna.value = Ustawienia.glosnosc_ogolna
	glosnosc_muzyki.value = Ustawienia.glosnosc_muzyki
	glosnosc_dzwiekow.value = Ustawienia.glosnosc_efektow
	pelny_ekran.button_pressed = Ustawienia.pelny_ekran
	kursor_neonowy.button_pressed = Ustawienia.kursor_neonowy
	glosnosc_ogolna.value_changed.connect(_zmien_glosnosc_ogolna)
	glosnosc_muzyki.value_changed.connect(_zmien_glosnosc_muzyki)
	glosnosc_dzwiekow.value_changed.connect(_zmien_glosnosc_dzwiekow)
	pelny_ekran.toggled.connect(Ustawienia.ustaw_tryb_okna)
	kursor_neonowy.toggled.connect(Ustawienia.ustaw_kursor_neonowy)
	_ustaw_glosnosc("Master", glosnosc_ogolna.value)
	_ustaw_glosnosc("Muzyka", glosnosc_muzyki.value)
	_ustaw_glosnosc("Efekty", glosnosc_dzwiekow.value)
	_styluj()
	zakladki.tab_changed.connect(_zmien_zakladke)
	get_viewport().size_changed.connect(_dopasuj_wysokosc)
	_dopasuj_wysokosc()


func _zglos_powrot() -> void:
	back_requested.emit()


func _styluj() -> void:
	zakladki.set_tab_title(0, "Ekran")
	zakladki.set_tab_title(1, "Dźwięk")
	zakladki.set_tab_title(2, "Sterowanie")
	zakladki.set_tab_title(3, "Inne")
	var panel := _plaski_styl(Color("#101b29"))
	panel.border_color = Color(AKCENT, 0.45)
	panel.set_border_width_all(0)
	panel.content_margin_left = 1.0
	panel.content_margin_right = 1.0
	panel.content_margin_top = 12.0
	panel.content_margin_bottom = 1.0
	zakladki.add_theme_stylebox_override("panel", panel)
	zakladki.add_theme_stylebox_override("tabbar_background", StyleBoxEmpty.new())
	# TabContainer wyznacza wysokość paska z tych samych stylów, które go rysują.
	zakladki.add_theme_font_override("font", StylMenu.FONT_MENU)
	zakladki.add_theme_font_size_override("font_size", 18)
	for nazwa: String in ["font_selected_color", "font_hovered_color", "font_focus_color"]:
		zakladki.add_theme_color_override(nazwa, AKCENT)
	zakladki.add_theme_color_override("font_unselected_color", TEKST_DRUGORZEDNY)
	for nazwa: String in ["tab_unselected", "tab_hovered", "tab_selected", "tab_focus"]:
		var styl := _plaski_styl(Color.TRANSPARENT)
		styl.content_margin_left = 16.0
		styl.content_margin_right = 16.0
		styl.content_margin_top = 12.0
		styl.content_margin_bottom = 16.0
		if nazwa == "tab_selected" or nazwa == "tab_focus":
			styl.border_color = AKCENT
			styl.border_width_bottom = 2
		elif nazwa == "tab_hovered":
			styl.bg_color = Color("#172839")
		zakladki.add_theme_stylebox_override(nazwa, styl)
	for strona: ScrollContainer in zakladki.get_children():
		strona.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var przewijanie := strona.get_v_scroll_bar()
		przewijanie.custom_minimum_size.x = 8.0
		przewijanie.add_theme_stylebox_override("scroll", _plaski_styl(Color("#101b29")))
		przewijanie.add_theme_stylebox_override("grabber", _plaski_styl(Color("#344b5e")))
		przewijanie.add_theme_stylebox_override("grabber_highlight", _plaski_styl(AKCENT))
		przewijanie.add_theme_stylebox_override("grabber_pressed", _plaski_styl(AKCENT))
		strona.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		przewijanie.add_theme_stylebox_override("scroll_focus", StyleBoxEmpty.new())
	for blok: PanelContainer in [$Zakladki/Ekran/Margines/Zawartosc/BlokEkranu, $Zakladki/Dzwiek/Margines/Zawartosc/BlokOgolny, $Zakladki/Dzwiek/Margines/Zawartosc/BlokMuzyki, $Zakladki/Dzwiek/Margines/Zawartosc/BlokEfektow, $Zakladki/Inne/Margines/Zawartosc/BlokKursora]:
		blok.add_theme_stylebox_override("panel", StylMenu.styl_bloku())
	for suwak: HSlider in [glosnosc_ogolna, glosnosc_muzyki, glosnosc_dzwiekow]:
		var tor := _plaski_styl(Color("#27394a"))
		tor.content_margin_top = 2.0
		tor.content_margin_bottom = 2.0
		var wypelnienie := tor.duplicate() as StyleBoxFlat
		wypelnienie.bg_color = AKCENT
		suwak.add_theme_stylebox_override("slider", tor)
		suwak.add_theme_stylebox_override("grabber_area", wypelnienie)
		suwak.add_theme_stylebox_override("grabber_area_highlight", wypelnienie)
		var uchwyt := _tekstura_uchwytu()
		for nazwa: String in ["grabber", "grabber_highlight", "grabber_disabled"]:
			suwak.add_theme_icon_override(nazwa, uchwyt)
	for przelacznik: CheckButton in [pelny_ekran, kursor_neonowy]:
		przelacznik.add_theme_color_override("font_color", TEKST)
		przelacznik.add_theme_color_override("font_hover_color", AKCENT)
		przelacznik.add_theme_color_override("font_pressed_color", AKCENT)
		przelacznik.add_theme_icon_override("checked", _tekstura_przelacznika(true))
		przelacznik.add_theme_icon_override("unchecked", _tekstura_przelacznika(false))
	$Zakladki/Inne/Margines/Zawartosc/BlokKursora/Uklad/Opis.add_theme_color_override("font_color", TEKST_DRUGORZEDNY)
	StylMenu.styluj_przycisk($WrocUstawienia, Vector2(0, 48), AKCENT, Color("#142432"), Color("#304656"), Color("#1b3443"), Color("#10202e"), AKCENT, 18)


func _plaski_styl(kolor: Color) -> StyleBoxFlat:
	var styl := StyleBoxFlat.new()
	styl.bg_color = kolor
	styl.set_corner_radius_all(6)
	return styl


func _dopasuj_wysokosc() -> void:
	zakladki.custom_minimum_size.y = clampf(get_viewport_rect().size.y - 220.0, 160.0, 380.0)


func _zmien_zakladke(_indeks: int) -> void:
	var panel := zakladki.get_theme_stylebox("panel") as StyleBoxFlat
	panel.set_border_width_all(0)
	if is_instance_valid(animacja_zakladki):
		animacja_zakladki.kill()
	for strona: Control in zakladki.get_children():
		strona.modulate.a = 1.0
	var aktywna_strona := zakladki.get_current_tab_control()
	aktywna_strona.modulate.a = 0.0
	animacja_zakladki = create_tween()
	animacja_zakladki.tween_property(aktywna_strona, "modulate:a", 1.0, 0.16)


func _tekstura_uchwytu() -> ImageTexture:
	var obraz := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	obraz.fill(Color.TRANSPARENT)
	for y in range(16):
		for x in range(16):
			if Vector2(x - 7.5, y - 7.5).length() <= 6.0:
				obraz.set_pixel(x, y, AKCENT)
	return ImageTexture.create_from_image(obraz)


func _tekstura_przelacznika(wlaczony: bool) -> ImageTexture:
	var obraz := Image.create(40, 22, false, Image.FORMAT_RGBA8)
	obraz.fill(Color.TRANSPARENT)
	var tlo := AKCENT if wlaczony else Color("#344b5e")
	for y in range(22):
		for x in range(40):
			var srodek_x := clampf(float(x), 11.0, 29.0)
			if Vector2(float(x) - srodek_x, float(y) - 10.5).length() <= 10.0:
				obraz.set_pixel(x, y, tlo)
			if Vector2(float(x) - (29.0 if wlaczony else 11.0), float(y) - 10.5).length() <= 7.0:
				obraz.set_pixel(x, y, Color("#edfaff"))
	return ImageTexture.create_from_image(obraz)


func _zmien_glosnosc_ogolna(wartosc: float) -> void:
	Ustawienia.glosnosc_ogolna = wartosc
	_ustaw_glosnosc("Master", wartosc)
	Ustawienia.zapisz()


func _zmien_glosnosc_muzyki(wartosc: float) -> void:
	Ustawienia.glosnosc_muzyki = wartosc
	_ustaw_glosnosc("Muzyka", wartosc)
	Ustawienia.zapisz()


func _zmien_glosnosc_dzwiekow(wartosc: float) -> void:
	Ustawienia.glosnosc_efektow = wartosc
	_ustaw_glosnosc("Efekty", wartosc)
	Ustawienia.zapisz()


func _ustaw_glosnosc(nazwa_szyny: String, wartosc: float) -> void:
	var indeks = AudioServer.get_bus_index(nazwa_szyny)
	if indeks == -1:
		return
	AudioServer.set_bus_volume_db(indeks, -80.0 if wartosc <= 0 else linear_to_db(wartosc / 100.0))
