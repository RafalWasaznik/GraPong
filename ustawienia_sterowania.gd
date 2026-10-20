extends VBoxContainer

const KOLOR_TURKUS = Color("#55e7ff")
const KOLOR_ROZ = Color("#ff5fb7")
const KOLOR_FIOLET = Color("#ad83ff")
const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")
const MAPOWANIA = [
	{"akcja": "lewy_gora", "gracz": 1, "opis": "Ruch w górę", "kolor": KOLOR_TURKUS},
	{"akcja": "lewy_dol", "gracz": 1, "opis": "Ruch w dół", "kolor": KOLOR_TURKUS},
	{"akcja": "prawy_gora", "gracz": 2, "opis": "Ruch w górę", "kolor": KOLOR_ROZ},
	{"akcja": "prawy_dol", "gracz": 2, "opis": "Ruch w dół", "kolor": KOLOR_ROZ},
	{"akcja": "pauza", "gracz": 0, "opis": "Wstrzymaj grę", "kolor": KOLOR_FIOLET}
]

@onready var gracze: HBoxContainer = $Gracze
@onready var informacja: Label = $Informacja
@onready var przywroc: Button = $Przywroc

var przyciski: Dictionary = {}
var aktywna_akcja = ""


func _ready() -> void:
	custom_minimum_size.x = 460.0
	add_theme_constant_override("separation", 6)
	gracze.add_theme_constant_override("separation", 10)
	$Gracze/Gracz1.add_theme_stylebox_override("panel", _styl_panelu(KOLOR_TURKUS))
	$Gracze/Gracz2.add_theme_stylebox_override("panel", _styl_panelu(KOLOR_ROZ))
	$Pauza.add_theme_stylebox_override("panel", _styl_panelu(KOLOR_FIOLET))
	$Pauza.custom_minimum_size.x = 190.0
	$Pauza.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	for mapowanie in MAPOWANIA:
		var akcja = str(mapowanie["akcja"])
		var kafelek = _utworz_wiersz(mapowanie)
		if int(mapowanie["gracz"]) == 1:
			$Gracze/Gracz1/Klawisze.add_child(kafelek)
		elif int(mapowanie["gracz"]) == 2:
			$Gracze/Gracz2/Klawisze.add_child(kafelek)
		else:
			$Pauza/Wiersz.add_child(kafelek)
		przyciski[akcja] = kafelek.get_node("Klawisz")

	for etykieta in [$Gracze/Gracz1/Klawisze/Tytul, $Gracze/Gracz2/Klawisze/Tytul, $Pauza/Wiersz/Tytul]:
		etykieta.add_theme_font_override("font", FONT_ARCADE)
		etykieta.add_theme_font_size_override("font_size", 18)
	$Gracze/Gracz1/Klawisze/Tytul.add_theme_color_override("font_color", KOLOR_TURKUS)
	$Gracze/Gracz2/Klawisze/Tytul.add_theme_color_override("font_color", KOLOR_ROZ)
	$Pauza/Wiersz/Tytul.add_theme_color_override("font_color", KOLOR_FIOLET)
	
	informacja.add_theme_font_size_override("font_size", 15)
	informacja.add_theme_color_override("font_color", Color("#b9cde2"))
	informacja.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	informacja.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	informacja.text = "Kliknij klawisz, aby zmienić przypisanie."
	
	przywroc.add_theme_font_size_override("font_size", 16)
	przywroc.add_theme_color_override("font_color", Color("#dceaff"))
	przywroc.add_theme_stylebox_override("normal", _styl_kafelka(Color("#72819a", 0.48)))
	przywroc.add_theme_stylebox_override("hover", _styl_kafelka(Color("#ad83ff", 0.85)))
	przywroc.pressed.connect(_przywroc_domyslne)
	_odswiez_kafelki()


func _utworz_wiersz(mapowanie: Dictionary) -> HBoxContainer:
	var wiersz = HBoxContainer.new()
	wiersz.custom_minimum_size.y = 40.0
	wiersz.add_theme_constant_override("separation", 6)
	if int(mapowanie["gracz"]) > 0:
		var opis = Label.new()
		opis.text = str(mapowanie["opis"])
		opis.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opis.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		opis.add_theme_font_size_override("font_size", 15)
		opis.add_theme_color_override("font_color", Color("#dceaff"))
		wiersz.add_child(opis)

	var kafelek = Button.new()
	kafelek.name = "Klawisz"
	kafelek.custom_minimum_size = Vector2(92.0, 38.0)
	kafelek.size_flags_horizontal = Control.SIZE_SHRINK_END
	kafelek.add_theme_font_size_override("font_size", 16)
	kafelek.add_theme_color_override("font_color", Color("#f2f7ff"))
	kafelek.add_theme_color_override("font_hover_color", Color.WHITE)
	var kolor = Color(mapowanie["kolor"])
	kafelek.add_theme_stylebox_override("normal", _styl_kafelka(kolor.darkened(0.2)))
	kafelek.add_theme_stylebox_override("hover", _styl_kafelka(kolor))
	kafelek.add_theme_stylebox_override("pressed", _styl_kafelka(kolor.lightened(0.12)))
	kafelek.add_theme_stylebox_override("focus", _styl_kafelka(kolor))
	kafelek.pressed.connect(_rozpocznij_przypisywanie.bind(str(mapowanie["akcja"])))
	wiersz.add_child(kafelek)
	return wiersz

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_anuluj_przypisywanie()


func _exit_tree() -> void:
	Ustawienia.czeka_na_klawisz = false


func _anuluj_przypisywanie() -> void:
	if aktywna_akcja.is_empty():
		return
	aktywna_akcja = ""
	Ustawienia.czeka_na_klawisz = false
	informacja.text = "Anulowano zmianę klawisza."
	_odswiez_kafelki()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or aktywna_akcja.is_empty() or not event is InputEventKey:
		return
	var klawisz := event as InputEventKey
	if not klawisz.pressed or klawisz.echo:
		return

	if klawisz.keycode == KEY_ESCAPE and aktywna_akcja != "pauza":
		aktywna_akcja = ""
		Ustawienia.czeka_na_klawisz = false
		informacja.text = "Anulowano zmianę klawisza."
		_odswiez_kafelki()
		get_viewport().set_input_as_handled()
		return

	var kod_fizyczny = klawisz.physical_keycode if klawisz.physical_keycode != KEY_NONE else klawisz.keycode
	var zamieniona_akcja = Ustawienia.ustaw_klawisz(aktywna_akcja, kod_fizyczny)
	if not zamieniona_akcja.is_empty():
		informacja.text = "Zamieniono przypisania: %s i %s." % [_nazwa_akcji(aktywna_akcja), _nazwa_akcji(zamieniona_akcja)]
	else:
		informacja.text = "Zapisano klawisz: %s." % _nazwa_akcji(aktywna_akcja)
	aktywna_akcja = ""
	Ustawienia.czeka_na_klawisz = false
	_odswiez_kafelki()
	get_viewport().set_input_as_handled()


func _rozpocznij_przypisywanie(akcja: String) -> void:
	aktywna_akcja = akcja
	Ustawienia.czeka_na_klawisz = true
	var skrot = "Esc ustawi pauzę." if akcja == "pauza" else "Esc anuluje."
	informacja.text = "Naciśnij klawisz: %s. %s" % [_nazwa_akcji(akcja), skrot]
	_odswiez_kafelki()


func _przywroc_domyslne() -> void:
	aktywna_akcja = ""
	Ustawienia.czeka_na_klawisz = false
	Ustawienia.przywroc_klawisze()
	informacja.text = "Przywrócono domyślne klawisze."
	_odswiez_kafelki()


func _odswiez_kafelki() -> void:
	for mapowanie in MAPOWANIA:
		var akcja = str(mapowanie["akcja"])
		var kafelek: Button = przyciski.get(akcja)
		if kafelek == null:
			continue
		if aktywna_akcja == akcja:
			kafelek.text = "…"
		else:
			kafelek.text = Ustawienia.tekst_klawisza(akcja)
		kafelek.disabled = not aktywna_akcja.is_empty() and aktywna_akcja != akcja


func _nazwa_akcji(akcja: String) -> String:
	for mapowanie in MAPOWANIA:
		if str(mapowanie["akcja"]) == akcja:
			var wlasciciel = "Pauza" if int(mapowanie["gracz"]) == 0 else "Gracz %d" % int(mapowanie["gracz"])
			return "%s · %s" % [wlasciciel, str(mapowanie["opis"]).to_lower()]
	return akcja


func _styl_panelu(kolor_obramowania: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color("#101d31")
	styl.border_color = Color(kolor_obramowania, 0.48)
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(10)
	styl.content_margin_left = 10.0
	styl.content_margin_right = 10.0
	styl.content_margin_top = 6.0
	styl.content_margin_bottom = 6.0
	return styl


func _styl_kafelka(kolor_obramowania: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color("#101d31")
	styl.border_color = kolor_obramowania
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(8)
	styl.content_margin_left = 8.0
	styl.content_margin_right = 8.0
	styl.content_margin_top = 4.0
	styl.content_margin_bottom = 4.0
	return styl
