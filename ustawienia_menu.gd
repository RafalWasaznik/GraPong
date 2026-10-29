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
var intensywnosc_efektow: HSlider
var etykieta_efektow: Label
var wybor_tla: OptionButton
var jakosc_tla: OptionButton


func _ready() -> void:
	$WrocUstawienia.pressed.connect(_zglos_powrot)
	_dodaj_regulacje_efektow()
	_dodaj_ustawienia_tla()
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
	var autorzy := Label.new()
	autorzy.text = "VFX 2D Free - heyheythere | CC BY 4.0"
	autorzy.tooltip_text = "https://heyheythere.itch.io/vfx-2d-free\nhttps://creativecommons.org/licenses/by/4.0/"
	autorzy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	autorzy.add_theme_font_size_override("font_size", 12)
	autorzy.add_theme_color_override("font_color", TEKST_DRUGORZEDNY)
	$Zakladki/Inne/Margines/Zawartosc.add_child(autorzy)
	zakladki.tab_changed.connect(_zmien_zakladke)
	get_viewport().size_changed.connect(_dopasuj_wysokosc)
	_dopasuj_wysokosc()


func _dodaj_regulacje_efektow() -> void:
	var blok := PanelContainer.new()
	blok.name = "BlokEfektowWizualnych"
	blok.add_theme_stylebox_override("panel", StylMenu.styl_bloku())
	$Zakladki/Ekran/Margines/Zawartosc.add_child(blok)
	var uklad := VBoxContainer.new()
	uklad.add_theme_constant_override("separation", 16)
	blok.add_child(uklad)
	etykieta_efektow = Label.new()
	etykieta_efektow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_efektow.add_theme_color_override("font_color", TEKST)
	uklad.add_child(etykieta_efektow)
	intensywnosc_efektow = HSlider.new()
	intensywnosc_efektow.name = "IntensywnoscEfektow"
	intensywnosc_efektow.custom_minimum_size.y = 32.0
	intensywnosc_efektow.min_value = 0.0
	intensywnosc_efektow.max_value = 100.0
	intensywnosc_efektow.step = 1.0
	intensywnosc_efektow.accessibility_name = "Intensywność efektów"
	uklad.add_child(intensywnosc_efektow)
	_odswiez_intensywnosc_efektow()
	intensywnosc_efektow.value_changed.connect(_zmien_intensywnosc_efektow)
	visibility_changed.connect(_odswiez_intensywnosc_efektow)


func _odswiez_intensywnosc_efektow() -> void:
	intensywnosc_efektow.set_value_no_signal(Ustawienia.intensywnosc_efektow)
	etykieta_efektow.text = "Intensywność efektów - %d%%" % roundi(Ustawienia.intensywnosc_efektow)


func _zmien_intensywnosc_efektow(wartosc: float) -> void:
	Ustawienia.ustaw_intensywnosc_efektow(wartosc)
	etykieta_efektow.text = "Intensywność efektów - %d%%" % roundi(wartosc)


func _dodaj_ustawienia_tla() -> void:
	var blok := PanelContainer.new()
	blok.name = "BlokTla"
	blok.add_theme_stylebox_override("panel", StylMenu.styl_bloku())
	$Zakladki/Ekran/Margines/Zawartosc.add_child(blok)
	var uklad := VBoxContainer.new()
	uklad.add_theme_constant_override("separation", 12)
	blok.add_child(uklad)
	_dodaj_opis_tla(uklad, "Tło meczu")
	wybor_tla = OptionButton.new()
	wybor_tla.name = "MotywTla"
	wybor_tla.allow_reselect = true
	wybor_tla.accessibility_name = "Motyw tła meczu"
	for nazwa: String in Ustawienia.MOTYWY_TLA:
		wybor_tla.add_item(nazwa)
	uklad.add_child(wybor_tla)
	_dodaj_opis_tla(uklad, "Efekty tła")
	jakosc_tla = OptionButton.new()
	jakosc_tla.name = "JakoscTla"
	jakosc_tla.accessibility_name = "Jakość tła meczu"
	for nazwa: String in Ustawienia.JAKOSCI_TLA:
		jakosc_tla.add_item(nazwa)
	uklad.add_child(jakosc_tla)
	for pole: Control in [wybor_tla, jakosc_tla]:
		pole.custom_minimum_size.y = 42
		pole.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_odswiez_tlo()
	wybor_tla.item_selected.connect(Ustawienia.ustaw_motyw_tla)
	jakosc_tla.item_selected.connect(Ustawienia.ustaw_jakosc_tla)
	visibility_changed.connect(_odswiez_tlo)


func _dodaj_opis_tla(rodzic: Control, tekst: String) -> void:
	var opis := Label.new()
	opis.text = tekst
	opis.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opis.add_theme_color_override("font_color", TEKST_DRUGORZEDNY)
	rodzic.add_child(opis)


func _odswiez_tlo() -> void:
	wybor_tla.select(Ustawienia.motyw_tla)
	jakosc_tla.select(Ustawienia.jakosc_tla)


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
		strona.get_v_scroll_bar().custom_minimum_size.x = 10.0
	for blok: PanelContainer in [$Zakladki/Ekran/Margines/Zawartosc/BlokEkranu, $Zakladki/Dzwiek/Margines/Zawartosc/BlokOgolny, $Zakladki/Dzwiek/Margines/Zawartosc/BlokMuzyki, $Zakladki/Dzwiek/Margines/Zawartosc/BlokEfektow, $Zakladki/Inne/Margines/Zawartosc/BlokKursora]:
		blok.add_theme_stylebox_override("panel", StylMenu.styl_bloku())
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
