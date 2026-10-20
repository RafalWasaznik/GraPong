extends VBoxContainer

signal back_requested

const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")
const KOLOR_TURKUS = Color("#55e7ff")
const KOLOR_FIOLET = Color("#ad83ff")
const KOLOR_ROZ = Color("#ff5fb7")

@onready var glosnosc_ogolna: HSlider = $PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentDzwieku/UkladDzwieku/WierszOgolny/GlosnoscOgolna
@onready var glosnosc_muzyki: HSlider = $PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentDzwieku/UkladDzwieku/WierszMuzyka/GlosnoscMuzyki
@onready var glosnosc_dzwiekow: HSlider = $PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentDzwieku/UkladDzwieku/WierszDzwieki/GlosnoscDzwiekow
@onready var pelny_ekran: CheckButton = $PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentEkran/PelnyEkran


func _ready() -> void:
	$WrocUstawienia.pressed.connect(_zglos_powrot)
	$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/UstawieniaDzwieku.text = "USTAWIENIA DŹWIĘKU"
	$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/UstawieniaEkranu.text = "USTAWIENIA EKRANU"
	$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/UstawieniaSterowaniaNaglowek.text = "STEROWANIE"
	$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentDzwieku/UkladDzwieku/WierszOgolny/EtykietaOgolna.text = "Ogólne"
	$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentDzwieku/UkladDzwieku/WierszMuzyka/EtykietaMuzyka.text = "Muzyka"
	$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentDzwieku/UkladDzwieku/WierszDzwieki/EtykietaDzwieki.text = "Dźwięki"
	pelny_ekran.text = "Pełny ekran"
	$WrocUstawienia.text = "Wróć"

	for suwak in [glosnosc_ogolna, glosnosc_muzyki, glosnosc_dzwiekow]:
		suwak.min_value = 0
		suwak.max_value = 100
		suwak.step = 1
	glosnosc_ogolna.value = Ustawienia.glosnosc_ogolna
	glosnosc_muzyki.value = Ustawienia.glosnosc_muzyki
	glosnosc_dzwiekow.value = Ustawienia.glosnosc_efektow
	pelny_ekran.button_pressed = Ustawienia.pelny_ekran
	glosnosc_ogolna.value_changed.connect(_zmien_glosnosc_ogolna)
	glosnosc_muzyki.value_changed.connect(_zmien_glosnosc_muzyki)
	glosnosc_dzwiekow.value_changed.connect(_zmien_glosnosc_dzwiekow)
	pelny_ekran.toggled.connect(Ustawienia.ustaw_tryb_okna)
	_ustaw_glosnosc("Master", glosnosc_ogolna.value)
	_ustaw_glosnosc("Muzyka", glosnosc_muzyki.value)
	_ustaw_glosnosc("Efekty", glosnosc_dzwiekow.value)
	_styluj()


func _zglos_powrot() -> void:
	back_requested.emit()


func _styluj() -> void:
	add_theme_constant_override("separation", 8)
	custom_minimum_size.x = 500.0
	var etykiety = [
		$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentDzwieku/UkladDzwieku/WierszOgolny/EtykietaOgolna,
		$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentDzwieku/UkladDzwieku/WierszMuzyka/EtykietaMuzyka,
		$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentDzwieku/UkladDzwieku/WierszDzwieki/EtykietaDzwieki
	]
	for indeks in range(etykiety.size()):
		var etykieta: Label = etykiety[indeks]
		etykieta.add_theme_font_override("font", FONT_ARCADE)
		etykieta.add_theme_font_size_override("font_size", 21)
		etykieta.add_theme_color_override("font_color", [KOLOR_TURKUS, KOLOR_FIOLET, KOLOR_ROZ][indeks])
		etykieta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for nazwa in ["UstawieniaDzwieku", "UstawieniaEkranu", "UstawieniaSterowaniaNaglowek"]:
		var naglowek: Label = $PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien.get_node(nazwa)
		naglowek.add_theme_font_override("font", FONT_ARCADE)
		naglowek.add_theme_font_size_override("font_size", 24)
		naglowek.add_theme_color_override("font_color", KOLOR_TURKUS)
	$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentDzwieku.add_theme_stylebox_override("panel", _styl_sekcji(KOLOR_TURKUS))
	$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentEkran.add_theme_stylebox_override("panel", _styl_sekcji(KOLOR_FIOLET))
	$PrzewijanieUstawien/OdstepPaska/ZawartoscUstawien/SegmentSterowanie.add_theme_stylebox_override("panel", _styl_sekcji(KOLOR_TURKUS))
	_styluj_scrollbar()
	for suwak in [glosnosc_ogolna, glosnosc_muzyki, glosnosc_dzwiekow]:
		var akcent: Color = KOLOR_TURKUS if suwak == glosnosc_ogolna else KOLOR_FIOLET if suwak == glosnosc_muzyki else KOLOR_ROZ
		suwak.custom_minimum_size = Vector2(420, 42)
		suwak.add_theme_stylebox_override("slider", _styl_pola(Color("#1a2a3e"), Color("#1a2a3e")))
		suwak.add_theme_stylebox_override("grabber_area", _styl_pola(Color(akcent, 0.5), Color(akcent, 0.5)))
		suwak.add_theme_stylebox_override("grabber_area_highlight", _styl_pola(Color(akcent, 0.8), Color(akcent, 0.8)))
		var uchwyt = _tekstura_uchwytu(akcent)
		suwak.add_theme_icon_override("grabber", uchwyt)
		suwak.add_theme_icon_override("grabber_highlight", uchwyt)
		suwak.add_theme_icon_override("grabber_disabled", uchwyt)
	pelny_ekran.custom_minimum_size.y = 58
	$WrocUstawienia.custom_minimum_size = Vector2(420, 52)
	$WrocUstawienia.add_theme_font_override("font", FONT_ARCADE)
	$WrocUstawienia.add_theme_font_size_override("font_size", 21)
	$WrocUstawienia.add_theme_color_override("font_color", Color("#e8f4ff"))
	$WrocUstawienia.add_theme_stylebox_override("normal", _styl_przycisku(Color("#14243a"), Color("#31506b")))
	$WrocUstawienia.add_theme_stylebox_override("hover", _styl_przycisku(Color("#1b3049"), KOLOR_TURKUS))
	$WrocUstawienia.add_theme_stylebox_override("pressed", _styl_przycisku(Color("#102638"), KOLOR_TURKUS.darkened(0.18)))
	$PrzewijanieUstawien.custom_minimum_size = Vector2(500, 460)


func _styl_sekcji(akcent: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color("#101d31", 0.72)
	styl.border_color = Color(akcent, 0.28)
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(12)
	styl.content_margin_left = 14
	styl.content_margin_right = 14
	styl.content_margin_top = 12
	styl.content_margin_bottom = 12
	return styl


func _styl_pola(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color(tlo.r, tlo.g, tlo.b, minf(tlo.a, 0.82))
	styl.border_color = obramowanie
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(9)
	return styl


func _styl_przycisku(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var styl = _styl_pola(tlo, obramowanie)
	styl.bg_color = Color(tlo.r, tlo.g, tlo.b, minf(tlo.a, 0.78))
	styl.content_margin_left = 18
	styl.content_margin_right = 18
	styl.content_margin_top = 8
	styl.content_margin_bottom = 8
	return styl


func _styluj_scrollbar() -> void:
	var pasek: VScrollBar = $PrzewijanieUstawien.get_v_scroll_bar()
	pasek.custom_minimum_size.x = 14
	pasek.add_theme_constant_override("grabber_min_size", 52)
	var tor = StyleBoxFlat.new()
	tor.bg_color = Color("#081321", 0.9)
	tor.border_color = Color(KOLOR_TURKUS, 0.14)
	tor.set_border_width_all(1)
	tor.set_corner_radius_all(7)
	pasek.add_theme_stylebox_override("scroll", tor)
	pasek.add_theme_stylebox_override("scroll_focus", tor)
	var uchwyt = StyleBoxFlat.new()
	uchwyt.bg_color = Color("#315b70")
	uchwyt.border_color = Color(KOLOR_TURKUS, 0.62)
	uchwyt.set_border_width_all(1)
	uchwyt.set_corner_radius_all(7)
	uchwyt.shadow_color = Color(KOLOR_TURKUS, 0.12)
	uchwyt.shadow_size = 4
	pasek.add_theme_stylebox_override("grabber", uchwyt)
	var hover = uchwyt.duplicate()
	hover.bg_color = Color("#3f8298")
	hover.border_color = Color(KOLOR_TURKUS, 0.92)
	hover.shadow_color = Color(KOLOR_TURKUS, 0.28)
	hover.shadow_size = 7
	pasek.add_theme_stylebox_override("grabber_highlight", hover)


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
