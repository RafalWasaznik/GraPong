extends Control

const CHARAKTERY_BOTA = ["defensywny", "ofensywny", "agresywny", "nieprzewidywalny"]
const KOLOR_TLA_NEON = Color("#070b16")
const KOLOR_TURKUS_NEON = Color("#55e7ff")
const KOLOR_FIOLET_NEON = Color("#ad83ff")
const KOLOR_ROZ_NEON = Color("#ff5fb7")
const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")

@onready var ekran_glowny = $CenterContainer/EkranGlowny
@onready var center_container = $CenterContainer
@onready var wybor_trybu = $CenterContainer/WyborTrybu
@onready var opcje_jeden_gracz = $CenterContainer/OpcjeJedenGracz
@onready var opcje_dwoch_graczy = $CenterContainer/OpcjeDwochGraczy
@onready var ekran_ustawien = $CenterContainer/EkranUstawien

var wybor_gier_jeden: VBoxContainer
var wybor_gier_dwoch: VBoxContainer
var aktywne_ustawienia_bota = "klasyczna"

@onready var trudnosc = $CenterContainer/OpcjeJedenGracz/Trudnosc
@onready var limit_jeden = $CenterContainer/OpcjeJedenGracz/LimitJeden
@onready var limit_dwoch = $CenterContainer/OpcjeDwochGraczy/LimitDwoch

@onready var rozmiar_jeden = $CenterContainer/OpcjeJedenGracz/RozmiarPlanszyJeden
@onready var rozmiar_dwoch = $CenterContainer/OpcjeDwochGraczy/RozmiarPlanszyDwoch

@onready var glosnosc_ogolna = $CenterContainer/EkranUstawien/GlosnoscOgolna
@onready var glosnosc_muzyki = $CenterContainer/EkranUstawien/GlosnoscMuzyki
@onready var glosnosc_dzwiekow = $CenterContainer/EkranUstawien/GlosnoscDzwiekow

var demo_pilka = Vector2.ZERO
var demo_predkosc = Vector2(255.0, 145.0)
var demo_slady: Array[Vector2] = []
var demo_lewa_y = 0.0
var demo_prawa_y = 0.0
var demo_gotowy = false
var przyciemnienie_tla = 0.0
var docelowe_przyciemnienie = 0.0


func _ready():
	Ustawienia.wczytaj()
	_utworz_ekrany_wyboru_gier()
	_styluj_menu()

	$CenterContainer/EkranGlowny/Graj.pressed.connect(_pokaz_wybor_trybu)
	$CenterContainer/EkranGlowny/Ustawienia.pressed.connect(_pokaz_ustawienia)

	$CenterContainer/WyborTrybu/JedenGracz.pressed.connect(_pokaz_wybor_gier_jeden)
	$CenterContainer/WyborTrybu/DwochGraczy.pressed.connect(_pokaz_wybor_gier_dwoch)
	$CenterContainer/WyborTrybu/Wroc.pressed.connect(_pokaz_ekran_glowny)

	$CenterContainer/OpcjeJedenGracz/StartJeden.pressed.connect(_start_jeden_gracz)
	$CenterContainer/OpcjeJedenGracz/WrocJeden.pressed.connect(_pokaz_wybor_gier_jeden)

	$CenterContainer/OpcjeDwochGraczy/StartDwoch.pressed.connect(_start_dwoch_graczy)
	$CenterContainer/OpcjeDwochGraczy/WrocDwoch.pressed.connect(_pokaz_wybor_gier_dwoch)

	$CenterContainer/EkranUstawien/WrocUstawienia.pressed.connect(_pokaz_ekran_glowny)

	trudnosc.add_item("Bot Jawor (Łatwy)", 0)
	trudnosc.add_item("Bot Rafał (Średni)", 1)
	trudnosc.add_item("Bot Jakub (Trudny)", 2)
	trudnosc.add_item("Bot Damian (Niemożliwy)", 3)

	_ustaw_wybor_trudnosci(Ustawienia.trudnosc_klasyczna)

	rozmiar_jeden.add_item("Mała", 0)
	rozmiar_jeden.add_item("Standardowa", 1)
	rozmiar_jeden.add_item("Duża", 2)

	rozmiar_dwoch.add_item("Mała", 0)
	rozmiar_dwoch.add_item("Standardowa", 1)
	rozmiar_dwoch.add_item("Duża", 2)

	_wybierz_rozmiar_na_liscie(rozmiar_jeden)
	_wybierz_rozmiar_na_liscie(rozmiar_dwoch)

	limit_jeden.placeholder_text = "Wpisz limit punktów"
	limit_dwoch.placeholder_text = "Wpisz limit punktów"
	limit_jeden.text = str(Ustawienia.limit_punktow)
	limit_dwoch.text = str(Ustawienia.limit_punktow)

	$CenterContainer/OpcjeJedenGracz/EtykietaRozmiaruJeden.text = "Wielkość planszy"
	$CenterContainer/OpcjeDwochGraczy/EtykietaRozmiaruDwoch.text = "Wielkość planszy"

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

	$CenterContainer/EkranGlowny/Tytuł.text = "PONG"
	$CenterContainer/EkranGlowny/Graj.text = "Graj"
	$CenterContainer/EkranGlowny/Ustawienia.text = "Ustawienia"

	$CenterContainer/WyborTrybu/TytulTrybu.text = "Wybierz tryb"
	$CenterContainer/WyborTrybu/JedenGracz.text = "1 gracz"
	$CenterContainer/WyborTrybu/DwochGraczy.text = "2 graczy"
	_dodaj_opis_trybu($CenterContainer/WyborTrybu/JedenGracz, "1 GRACZ", "Zagraj przeciwko botowi", KOLOR_TURKUS_NEON)
	_dodaj_opis_trybu($CenterContainer/WyborTrybu/DwochGraczy, "2 GRACZY", "Mecz dla dwóch osób przy jednej klawiaturze", KOLOR_ROZ_NEON)
	$CenterContainer/WyborTrybu/Wroc.text = "Wróć"

	$CenterContainer/OpcjeJedenGracz/TytulOpcjiJeden.text = "Gra z botem"
	$CenterContainer/OpcjeJedenGracz/EtykietaLimituJeden.text = "Limit punktów"
	$CenterContainer/OpcjeJedenGracz/StartJeden.text = "Graj"
	$CenterContainer/OpcjeJedenGracz/WrocJeden.text = "Wróć"

	$CenterContainer/OpcjeDwochGraczy/EtykietaLimituDwoch.text = "Limit punktów"
	$CenterContainer/OpcjeDwochGraczy/StartDwoch.text = "Graj"
	$CenterContainer/OpcjeDwochGraczy/WrocDwoch.text = "Wróć"

	$CenterContainer/EkranUstawien/EtykietaOgolna.text = "Głośność ogólna"
	$CenterContainer/EkranUstawien/EtykietaMuzyka.text = "Głośność muzyki"
	$CenterContainer/EkranUstawien/EtykietaDzwieki.text = "Głośność dźwięków"

	_pokaz_ekran_glowny()
	_ustaw_glosnosc("Master", glosnosc_ogolna.value)
	_ustaw_glosnosc("Muzyka", glosnosc_muzyki.value)
	_ustaw_glosnosc("Efekty", glosnosc_dzwiekow.value)
	queue_redraw()


func _process(delta):
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if not demo_gotowy:
		var boisko = _prostokat_boisko()
		demo_pilka = boisko.get_center()
		demo_lewa_y = demo_pilka.y
		demo_prawa_y = demo_pilka.y
		demo_gotowy = true
	przyciemnienie_tla = move_toward(przyciemnienie_tla, docelowe_przyciemnienie, delta * 1.8)
	_symuluj_tlo(delta)
	queue_redraw()


func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), KOLOR_TLA_NEON, true)
	draw_circle(Vector2(size.x * 0.12, size.y * 0.18), size.y * 0.42, Color(0.08, 0.72, 0.93, 0.035))
	draw_circle(Vector2(size.x * 0.88, size.y * 0.82), size.y * 0.48, Color(0.55, 0.22, 0.94, 0.04))
	var boisko = _prostokat_boisko()
	draw_rect(boisko, Color("#0b1728", 0.62), true)
	draw_rect(boisko, Color(KOLOR_TURKUS_NEON, 0.43), false, 2.0)
	draw_rect(boisko.grow(-10.0), Color(KOLOR_FIOLET_NEON, 0.13), false, 1.0)
	draw_circle(boisko.get_center(), minf(boisko.size.y * 0.15, 78.0), Color(KOLOR_TURKUS_NEON, 0.2), false, 2.0)
	var y = boisko.position.y + 16.0
	while y < boisko.end.y - 16.0:
		var kolor_linii = Color(KOLOR_TURKUS_NEON, 0.48) if int(y / 28.0) % 2 == 0 else Color(KOLOR_FIOLET_NEON, 0.48)
		draw_line(Vector2(boisko.get_center().x, y), Vector2(boisko.get_center().x, minf(y + 14.0, boisko.end.y - 16.0)), kolor_linii, 3.0)
		y += 28.0
	var paletka_w = clampf(boisko.size.x * 0.012, 12.0, 20.0)
	var paletka_h = clampf(boisko.size.y * 0.22, 66.0, 116.0)
	var lewa = Rect2(Vector2(boisko.position.x + 14.0, demo_lewa_y - paletka_h * 0.5), Vector2(paletka_w, paletka_h))
	var prawa = Rect2(Vector2(boisko.end.x - 14.0 - paletka_w, demo_prawa_y - paletka_h * 0.5), Vector2(paletka_w, paletka_h))
	draw_rect(lewa.grow(5.0), Color(KOLOR_TURKUS_NEON, 0.1), true)
	draw_rect(lewa, Color("#40dff5"), true)
	draw_rect(lewa, Color("#c7faff"), false, 2.0)
	draw_rect(prawa.grow(5.0), Color(KOLOR_ROZ_NEON, 0.11), true)
	draw_rect(prawa, Color("#ff4fa3"), true)
	draw_rect(prawa, Color("#ffe0f1"), false, 2.0)
	for i in range(demo_slady.size()):
		var udzial = float(i + 1) / float(demo_slady.size() + 1)
		draw_circle(demo_slady[i], lerpf(2.0, 6.0, udzial), Color(KOLOR_TURKUS_NEON, udzial * 0.3))
	draw_circle(demo_pilka, 13.0, Color(KOLOR_TURKUS_NEON, 0.13))
	draw_circle(demo_pilka, 8.0, KOLOR_TURKUS_NEON)
	draw_circle(demo_pilka, 4.5, Color("#ffffff"))
	if przyciemnienie_tla > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.03, 0.055, przyciemnienie_tla), true)


func _prostokat_boisko() -> Rect2:
	var margines_x = size.x * 0.095
	var margines_y = size.y * 0.15
	return Rect2(Vector2(margines_x, margines_y), Vector2(maxf(size.x - margines_x * 2.0, 1.0), maxf(size.y - margines_y * 2.0, 1.0)))


func _symuluj_tlo(delta):
	var boisko = _prostokat_boisko()
	var paletka_h = clampf(boisko.size.y * 0.22, 66.0, 116.0)
	var paletka_w = clampf(boisko.size.x * 0.012, 12.0, 20.0)
	var stara_pozycja = demo_pilka
	var nowa_pozycja = demo_pilka + demo_predkosc * delta
	var gora = boisko.position.y + 12.0
	var dol = boisko.end.y - 12.0
	if nowa_pozycja.y < gora or nowa_pozycja.y > dol:
		demo_predkosc.y *= -1.0
		nowa_pozycja.y = clampf(nowa_pozycja.y, gora, dol)
	var x_lewej = boisko.position.x + 14.0 + paletka_w
	var x_prawej = boisko.end.x - 14.0 - paletka_w
	if demo_predkosc.x < 0.0 and nowa_pozycja.x - 6.0 <= x_lewej and absf(nowa_pozycja.y - demo_lewa_y) <= paletka_h * 0.5 + 8.0:
		demo_predkosc.x = absf(demo_predkosc.x)
		demo_predkosc.y += (nowa_pozycja.y - demo_lewa_y) * 1.2
	elif demo_predkosc.x > 0.0 and nowa_pozycja.x + 6.0 >= x_prawej and absf(nowa_pozycja.y - demo_prawa_y) <= paletka_h * 0.5 + 8.0:
		demo_predkosc.x = -absf(demo_predkosc.x)
		demo_predkosc.y += (nowa_pozycja.y - demo_prawa_y) * 1.2
	if nowa_pozycja.x < boisko.position.x + 5.0 or nowa_pozycja.x > boisko.end.x - 5.0:
		demo_predkosc.x *= -1.0
		nowa_pozycja.x = clampf(nowa_pozycja.x, boisko.position.x + 5.0, boisko.end.x - 5.0)
	demo_predkosc = demo_predkosc.normalized() * 255.0
	if demo_slady.is_empty() or demo_pilka.distance_to(demo_slady.back()) > 4.0:
		demo_slady.append(stara_pozycja)
		if demo_slady.size() > 10:
			demo_slady.pop_front()
	demo_pilka = nowa_pozycja
	var cel_lewej = demo_pilka.y if demo_predkosc.x < 0.0 else boisko.get_center().y
	var cel_prawej = demo_pilka.y if demo_predkosc.x > 0.0 else boisko.get_center().y
	demo_lewa_y = move_toward(demo_lewa_y, cel_lewej, 155.0 * delta)
	demo_prawa_y = move_toward(demo_prawa_y, cel_prawej, 155.0 * delta)
	demo_lewa_y = clampf(demo_lewa_y, boisko.position.y + paletka_h * 0.5, boisko.end.y - paletka_h * 0.5)
	demo_prawa_y = clampf(demo_prawa_y, boisko.position.y + paletka_h * 0.5, boisko.end.y - paletka_h * 0.5)


func _styluj_menu():
	var karta = Panel.new()
	karta.name = "KartaMenu"
	karta.custom_minimum_size = Vector2(600.0, 620.0)
	karta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var styl_karty = StyleBoxFlat.new()
	styl_karty.bg_color = Color("#0c1628", 0.96)
	styl_karty.border_color = Color("#28627a")
	styl_karty.set_border_width_all(2)
	styl_karty.set_corner_radius_all(22)
	styl_karty.shadow_color = Color(KOLOR_TURKUS_NEON, 0.12)
	styl_karty.shadow_size = 25
	styl_karty.shadow_offset = Vector2.ZERO
	karta.add_theme_stylebox_override("panel", styl_karty)
	center_container.add_child(karta)
	center_container.move_child(karta, 0)

	for ekran in [ekran_glowny, wybor_trybu, wybor_gier_jeden, wybor_gier_dwoch, opcje_jeden_gracz, opcje_dwoch_graczy, ekran_ustawien]:
		ekran.custom_minimum_size = Vector2(420.0, 0.0)
		ekran.add_theme_constant_override("separation", 14)
		_wycentruj_teksty(ekran)
		for dziecko in ekran.get_children():
			if dziecko is Control:
				dziecko.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if dziecko is Label:
				dziecko.add_theme_font_size_override("font_size", 21)
				dziecko.add_theme_color_override("font_color", Color("#e8f4ff"))

	ekran_ustawien.add_theme_constant_override("separation", 8)

	var tytul = $CenterContainer/EkranGlowny/Tytuł
	tytul.add_theme_font_override("font", FONT_ARCADE)
	tytul.add_theme_font_size_override("font_size", 68)
	tytul.add_theme_color_override("font_color", Color("#69edff"))
	tytul.custom_minimum_size.y = 92.0

	var tytul_trybu = $CenterContainer/WyborTrybu/TytulTrybu
	tytul_trybu.add_theme_font_override("font", FONT_ARCADE)
	tytul_trybu.add_theme_font_size_override("font_size", 28)
	tytul_trybu.add_theme_color_override("font_color", Color("#69edff"))
	$CenterContainer/OpcjeJedenGracz/TytulOpcjiJeden.add_theme_font_size_override("font_size", 28)
	$CenterContainer/OpcjeJedenGracz/TytulOpcjiJeden.add_theme_font_override("font", FONT_ARCADE)
	$CenterContainer/OpcjeJedenGracz/TytulOpcjiJeden.add_theme_color_override("font_color", Color("#69edff"))
	$CenterContainer/EkranUstawien/EtykietaOgolna.add_theme_color_override("font_color", KOLOR_TURKUS_NEON)
	$CenterContainer/EkranUstawien/EtykietaMuzyka.add_theme_color_override("font_color", KOLOR_FIOLET_NEON)
	$CenterContainer/EkranUstawien/EtykietaDzwieki.add_theme_color_override("font_color", KOLOR_ROZ_NEON)
	for ekran_wyboru in [wybor_gier_jeden, wybor_gier_dwoch]:
		ekran_wyboru.get_node("Tytul").add_theme_font_size_override("font_size", 28)
		ekran_wyboru.get_node("Tytul").add_theme_font_override("font", FONT_ARCADE)
		ekran_wyboru.get_node("Tytul").add_theme_color_override("font_color", KOLOR_TURKUS_NEON)

	for guzik in [
		$CenterContainer/EkranGlowny/Graj,
		$CenterContainer/EkranGlowny/Ustawienia,
		$CenterContainer/WyborTrybu/JedenGracz,
		$CenterContainer/WyborTrybu/DwochGraczy,
		$CenterContainer/WyborTrybu/Wroc,
		$CenterContainer/OpcjeJedenGracz/StartJeden,
		$CenterContainer/OpcjeJedenGracz/WrocJeden,
		$CenterContainer/OpcjeDwochGraczy/StartDwoch,
		$CenterContainer/OpcjeDwochGraczy/WrocDwoch,
		$CenterContainer/EkranUstawien/WrocUstawienia
	]:
		_styluj_przycisk(guzik)

	var guzik_graj = $CenterContainer/EkranGlowny/Graj
	guzik_graj.add_theme_color_override("font_color", Color("#eaffff"))
	guzik_graj.add_theme_color_override("font_hover_color", Color.WHITE)
	var styl_graj = _nowy_styl_przycisku(Color("#123b4a"), KOLOR_TURKUS_NEON)
	styl_graj.set_border_width_all(2)
	styl_graj.shadow_color = Color(KOLOR_TURKUS_NEON, 0.18)
	styl_graj.shadow_size = 10
	guzik_graj.add_theme_stylebox_override("normal", styl_graj)
	var styl_graj_hover = _nowy_styl_przycisku(Color("#18536a"), Color("#b4f8ff"))
	styl_graj_hover.set_border_width_all(2)
	styl_graj_hover.shadow_color = Color(KOLOR_TURKUS_NEON, 0.42)
	styl_graj_hover.shadow_size = 17
	guzik_graj.add_theme_stylebox_override("hover", styl_graj_hover)
	$CenterContainer/EkranGlowny/Ustawienia.set_meta("neon_akcent", KOLOR_FIOLET_NEON)
	for guzik_powrotu in [
		$CenterContainer/WyborTrybu/Wroc,
		$CenterContainer/OpcjeJedenGracz/WrocJeden,
		$CenterContainer/OpcjeDwochGraczy/WrocDwoch,
		$CenterContainer/EkranUstawien/WrocUstawienia
	]:
		guzik_powrotu.set_meta("neon_akcent", KOLOR_FIOLET_NEON)

	for lista in [trudnosc, rozmiar_jeden, rozmiar_dwoch]:
		_styluj_przycisk(lista)
		lista.custom_minimum_size = Vector2(420.0, 50.0)
		var popup = lista.get_popup()
		var styl_popup = StyleBoxFlat.new()
		styl_popup.bg_color = Color("#111c2b")
		styl_popup.border_color = Color("#3b5a73")
		styl_popup.set_border_width_all(1)
		styl_popup.set_corner_radius_all(10)
		popup.add_theme_stylebox_override("panel", styl_popup)
		popup.add_theme_color_override("font_color", Color("#e8f4ff"))
		popup.add_theme_color_override("font_hover_color", Color.WHITE)
		popup.add_theme_color_override("font_selected_color", KOLOR_TURKUS_NEON)
		var styl_najechania = StyleBoxFlat.new()
		styl_najechania.bg_color = Color("#1b304a")
		styl_najechania.border_color = KOLOR_TURKUS_NEON
		styl_najechania.set_border_width_all(1)
		styl_najechania.set_corner_radius_all(6)
		popup.add_theme_stylebox_override("hover", styl_najechania)

	for pole in [limit_jeden, limit_dwoch]:
		pole.custom_minimum_size = Vector2(420.0, 50.0)
		pole.add_theme_font_size_override("font_size", 21)
		pole.add_theme_color_override("font_color", Color("#f0f6fc"))
		pole.add_theme_color_override("font_placeholder_color", Color("#93a9c2"))
		pole.add_theme_color_override("caret_color", KOLOR_TURKUS_NEON)
		pole.add_theme_stylebox_override("normal", _nowy_styl_pola(Color("#0a1323"), Color("#304b68")))
		pole.add_theme_stylebox_override("focus", _nowy_styl_pola(Color("#0a1323"), KOLOR_TURKUS_NEON))

	var akcenty_suwakow = [KOLOR_TURKUS_NEON, KOLOR_FIOLET_NEON, KOLOR_ROZ_NEON]
	var suwaki = [glosnosc_ogolna, glosnosc_muzyki, glosnosc_dzwiekow]
	for i in range(suwaki.size()):
		var suwak = suwaki[i]
		var akcent: Color = akcenty_suwakow[i]
		suwak.custom_minimum_size = Vector2(420.0, 42.0)
		suwak.add_theme_stylebox_override("slider", _nowy_styl_pola(Color("#1a2a3e"), Color("#1a2a3e")))
		suwak.add_theme_stylebox_override("grabber_area", _nowy_styl_pola(Color(akcent, 0.5), Color(akcent, 0.5)))
		suwak.add_theme_stylebox_override("grabber_area_highlight", _nowy_styl_pola(Color(akcent, 0.8), Color(akcent, 0.8)))
		var uchwyt = _stworz_teksture_uchwytu(akcent)
		suwak.add_theme_icon_override("grabber", uchwyt)
		suwak.add_theme_icon_override("grabber_highlight", uchwyt)
		suwak.add_theme_icon_override("grabber_disabled", uchwyt)


func _styluj_przycisk(guzik: Button):
	guzik.custom_minimum_size = Vector2(420.0, 52.0)
	guzik.add_theme_font_size_override("font_size", 21)
	guzik.add_theme_color_override("font_color", Color("#e8f4ff"))
	guzik.add_theme_color_override("font_hover_color", Color.WHITE)
	guzik.add_theme_color_override("font_pressed_color", Color("#b8f5ff"))
	guzik.add_theme_color_override("font_focus_color", Color.WHITE)
	guzik.add_theme_stylebox_override("normal", _nowy_styl_przycisku(Color("#14243a"), Color("#31506b")))
	guzik.add_theme_stylebox_override("hover", _nowy_styl_przycisku(Color("#1b3049"), KOLOR_TURKUS_NEON))
	guzik.add_theme_stylebox_override("pressed", _nowy_styl_przycisku(Color("#102638"), Color("#35bcd5")))
	guzik.add_theme_stylebox_override("focus", _nowy_styl_przycisku(Color("#14243a"), KOLOR_TURKUS_NEON))
	guzik.add_theme_stylebox_override("disabled", _nowy_styl_przycisku(Color("#151d2b"), Color("#293a4e")))
	guzik.pivot_offset = guzik.custom_minimum_size * 0.5
	guzik.resized.connect(func(): guzik.pivot_offset = guzik.size * 0.5)
	guzik.mouse_entered.connect(_animuj_najechanie.bind(guzik, true))
	guzik.mouse_exited.connect(_animuj_najechanie.bind(guzik, false))


func _animuj_najechanie(guzik: Control, aktywne: bool):
	if aktywne and guzik.has_meta("neon_akcent"):
		var akcent: Color = guzik.get_meta("neon_akcent")
		var styl_hover = _nowy_styl_przycisku(Color("#1a2d47"), akcent)
		styl_hover.set_border_width_all(2)
		styl_hover.shadow_color = Color(akcent, 0.38)
		styl_hover.shadow_size = 15
		styl_hover.shadow_offset = Vector2.ZERO
		guzik.add_theme_stylebox_override("hover", styl_hover)
	if guzik.has_meta("animacja_najechania"):
		var stara_animacja = guzik.get_meta("animacja_najechania")
		if is_instance_valid(stara_animacja):
			stara_animacja.kill()
	var animacja = create_tween()
	guzik.set_meta("animacja_najechania", animacja)
	animacja.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacja.tween_property(guzik, "scale", Vector2(1.035, 1.035) if aktywne else Vector2.ONE, 0.14)


func _dodaj_opis_trybu(przycisk: Button, tytul: String, opis: String, akcent: Color):
	przycisk.text = ""
	przycisk.custom_minimum_size = Vector2(420.0, 88.0)
	przycisk.tooltip_text = opis
	przycisk.set_meta("neon_akcent", akcent)
	var styl_karty = _nowy_styl_przycisku(Color("#101d31"), Color(akcent, 0.42))
	styl_karty.set_border_width_all(1)
	przycisk.add_theme_stylebox_override("normal", styl_karty)
	var styl_karty_hover = _nowy_styl_przycisku(Color("#1a2d47"), akcent)
	styl_karty_hover.set_border_width_all(2)
	styl_karty_hover.shadow_color = Color(akcent, 0.38)
	styl_karty_hover.shadow_size = 15
	styl_karty_hover.shadow_offset = Vector2.ZERO
	przycisk.add_theme_stylebox_override("hover", styl_karty_hover)
	var pasek = ColorRect.new()
	pasek.color = akcent
	pasek.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pasek.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	pasek.offset_left = 0.0
	pasek.offset_right = 5.0
	przycisk.add_child(pasek)
	var uklad = VBoxContainer.new()
	uklad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	uklad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	uklad.offset_left = 22.0
	uklad.offset_right = -12.0
	uklad.offset_top = 11.0
	uklad.offset_bottom = -9.0
	uklad.add_theme_constant_override("separation", 2)
	przycisk.add_child(uklad)
	var etykieta_tytulu = Label.new()
	etykieta_tytulu.text = tytul
	etykieta_tytulu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_tytulu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etykieta_tytulu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etykieta_tytulu.add_theme_font_size_override("font_size", 22)
	etykieta_tytulu.add_theme_color_override("font_color", Color("#f2f8ff"))
	uklad.add_child(etykieta_tytulu)
	var etykieta_opisu = Label.new()
	etykieta_opisu.text = opis
	etykieta_opisu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_opisu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etykieta_opisu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etykieta_opisu.add_theme_font_size_override("font_size", 15)
	etykieta_opisu.add_theme_color_override("font_color", Color("#b9cde2"))
	uklad.add_child(etykieta_opisu)


func _utworz_ekrany_wyboru_gier():
	wybor_gier_jeden = VBoxContainer.new()
	wybor_gier_jeden.name = "WyborGierJedenGracz"
	wybor_gier_jeden.alignment = BoxContainer.ALIGNMENT_CENTER
	center_container.add_child(wybor_gier_jeden)
	wybor_gier_jeden.hide()
	_dodaj_ekran_wyboru_gier(wybor_gier_jeden, "Tryb dla jednego gracza")
	_dodaj_karte_wyboru(wybor_gier_jeden, "KLASYCZNY", "Klasyczny mecz przeciwko botowi", KOLOR_TURKUS_NEON, _pokaz_opcje_jednego_gracza)
	_dodaj_karte_wyboru(wybor_gier_jeden, "ENDLESS RALLY", "Jedna paletka, seria i rosnące wyzwanie", KOLOR_FIOLET_NEON, _start_endless_rally)
	_dodaj_karte_wyboru(wybor_gier_jeden, "ARENA", "Mecz z botem i losowymi modyfikacjami planszy", Color("#ffb454"), _pokaz_opcje_areny)
	_dodaj_karte_wyboru(wybor_gier_jeden, "Wróć", "", Color("#7892ad"), _pokaz_wybor_trybu, true)

	wybor_gier_dwoch = VBoxContainer.new()
	wybor_gier_dwoch.name = "WyborGierDwochGraczy"
	wybor_gier_dwoch.alignment = BoxContainer.ALIGNMENT_CENTER
	center_container.add_child(wybor_gier_dwoch)
	wybor_gier_dwoch.hide()
	_dodaj_ekran_wyboru_gier(wybor_gier_dwoch, "Tryb dla dwóch graczy")
	_dodaj_karte_wyboru(wybor_gier_dwoch, "KLASYCZNY POJEDYNEK", "Zagrajcie przeciwko sobie przy jednej klawiaturze", KOLOR_ROZ_NEON, _pokaz_opcje_dwoch_graczy)
	_dodaj_karte_wyboru(wybor_gier_dwoch, "ARENA", "Pojedynek na planszy z losowymi modyfikacjami", Color("#ffb454"), _start_arena.bind(true))
	_dodaj_karte_wyboru(wybor_gier_dwoch, "Wróć", "", Color("#7892ad"), _pokaz_wybor_trybu, true)


func _dodaj_ekran_wyboru_gier(ekran: VBoxContainer, tekst_tytulu: String):
	var tytul = Label.new()
	tytul.name = "Tytul"
	tytul.text = tekst_tytulu
	tytul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ekran.add_child(tytul)


func _dodaj_karte_wyboru(ekran: VBoxContainer, tytul: String, opis: String, akcent: Color, akcja: Callable, tylko_przycisk: bool = false):
	var przycisk = Button.new()
	przycisk.name = "Wybor" + str(ekran.get_child_count())
	przycisk.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ekran.add_child(przycisk)
	_styluj_przycisk(przycisk)
	if tylko_przycisk:
		przycisk.text = tytul
	else:
		_dodaj_opis_trybu(przycisk, tytul, opis, akcent)
	przycisk.pressed.connect(akcja)


func _wycentruj_teksty(wezel: Node) -> void:
	if wezel is Label:
		wezel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wezel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		wezel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elif wezel is Button:
		wezel.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for dziecko in wezel.get_children():
		_wycentruj_teksty(dziecko)


func _nowy_styl_przycisku(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = tlo
	styl.border_color = obramowanie
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(10)
	styl.content_margin_left = 18.0
	styl.content_margin_right = 18.0
	styl.content_margin_top = 8.0
	styl.content_margin_bottom = 8.0
	styl.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	styl.shadow_size = 5
	styl.shadow_offset = Vector2(0.0, 2.0)
	return styl


func _nowy_styl_pola(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = tlo
	styl.border_color = obramowanie
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(9)
	styl.content_margin_left = 14.0
	styl.content_margin_right = 14.0
	styl.content_margin_top = 8.0
	styl.content_margin_bottom = 8.0
	return styl


func _stworz_teksture_uchwytu(akcent: Color) -> ImageTexture:
	var obraz = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	obraz.fill(Color.TRANSPARENT)

	for y in range(24):
		for x in range(24):
			var odleglosc = Vector2(x - 11.5, y - 11.5).length()
			if odleglosc <= 10.5:
				obraz.set_pixel(x, y, akcent)
			elif odleglosc <= 11.5:
				obraz.set_pixel(x, y, Color("#d9fbff"))

	return ImageTexture.create_from_image(obraz)


func _wybierz_rozmiar_na_liscie(lista):
	match Ustawienia.rozmiar_planszy:
		"mala":
			lista.select(0)
		"duza":
			lista.select(2)
		_:
			lista.select(1)


func _zapisz_wybor_rozmiaru(lista):
	match lista.selected:
		0:
			Ustawienia.rozmiar_planszy = "mala"
		1:
			Ustawienia.rozmiar_planszy = "standardowa"
		2:
			Ustawienia.rozmiar_planszy = "duza"

	Ustawienia.ustaw_geometrie_planszy()


func _pokaz_ekran(ekran):
	docelowe_przyciemnienie = 0.0 if ekran == ekran_glowny else 0.42
	ekran_glowny.hide()
	wybor_trybu.hide()
	wybor_gier_jeden.hide()
	wybor_gier_dwoch.hide()
	opcje_jeden_gracz.hide()
	opcje_dwoch_graczy.hide()
	ekran_ustawien.hide()
	ekran.show()
	ekran.modulate.a = 0.0
	var animacja = create_tween()
	animacja.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacja.tween_property(ekran, "modulate:a", 1.0, 0.18)


func _pokaz_ekran_glowny():
	_pokaz_ekran(ekran_glowny)


func _pokaz_wybor_trybu():
	_pokaz_ekran(wybor_trybu)


func _pokaz_wybor_gier_jeden():
	_pokaz_ekran(wybor_gier_jeden)


func _pokaz_wybor_gier_dwoch():
	_pokaz_ekran(wybor_gier_dwoch)


func _pokaz_opcje_jednego_gracza():
	aktywne_ustawienia_bota = "klasyczna"
	$CenterContainer/OpcjeJedenGracz/TytulOpcjiJeden.text = "Gra klasyczna z botem"
	$CenterContainer/OpcjeJedenGracz/EtykietaRozmiaruJeden.show()
	rozmiar_jeden.show()
	limit_jeden.text = str(Ustawienia.limit_punktow_klasyczny)
	_ustaw_wybor_trudnosci(Ustawienia.trudnosc_klasyczna)
	_pokaz_ekran(opcje_jeden_gracz)


func _pokaz_opcje_areny():
	aktywne_ustawienia_bota = "arena"
	$CenterContainer/OpcjeJedenGracz/TytulOpcjiJeden.text = "Arena z botem"
	$CenterContainer/OpcjeJedenGracz/EtykietaRozmiaruJeden.hide()
	rozmiar_jeden.hide()
	limit_jeden.text = str(Ustawienia.limit_punktow_areny)
	_ustaw_wybor_trudnosci(Ustawienia.trudnosc_areny)
	_pokaz_ekran(opcje_jeden_gracz)


func _ustaw_wybor_trudnosci(wartosc: String) -> void:
	match wartosc:
		"latwy":
			trudnosc.select(0)
		"sredni":
			trudnosc.select(1)
		"trudny":
			trudnosc.select(2)
		"niemozliwy":
			trudnosc.select(3)
		_:
			trudnosc.select(1)


func _trudnosc_z_wyboru() -> String:
	match trudnosc.selected:
		0:
			return "latwy"
		1:
			return "sredni"
		2:
			return "trudny"
		3:
			return "niemozliwy"
	return "sredni"


func _pokaz_opcje_dwoch_graczy():
	_pokaz_ekran(opcje_dwoch_graczy)


func _pokaz_ustawienia():
	_pokaz_ekran(ekran_ustawien)


func _start_jeden_gracz():
	if not limit_jeden.text.is_valid_int() or limit_jeden.text.to_int() < 1:
		limit_jeden.placeholder_text = "Wpisz liczbę większą od 0"
		limit_jeden.grab_focus()
		return

	var wybrana_trudnosc = _trudnosc_z_wyboru()
	var wybrany_limit = limit_jeden.text.to_int()
	if aktywne_ustawienia_bota == "arena":
		Ustawienia.trudnosc_areny = wybrana_trudnosc
		Ustawienia.limit_punktow_areny = wybrany_limit
		Ustawienia.tryb = "arena"
		Ustawienia.rozmiar_planszy = "standardowa"
		Ustawienia.ustaw_geometrie_planszy()
	else:
		Ustawienia.trudnosc_klasyczna = wybrana_trudnosc
		Ustawienia.limit_punktow_klasyczny = wybrany_limit
		Ustawienia.tryb = "bot"
		_zapisz_wybor_rozmiaru(rozmiar_jeden)

	Ustawienia.arena_dwoch_graczy = false
	Ustawienia.limit_punktow = wybrany_limit
	Ustawienia.trudnosc = wybrana_trudnosc

	Ustawienia.charakter_bota = CHARAKTERY_BOTA.pick_random()

	Ustawienia.zapisz()
	get_tree().change_scene_to_file("res://scena_główna.tscn")


func _start_dwoch_graczy():
	if not limit_dwoch.text.is_valid_int() or limit_dwoch.text.to_int() < 1:
		limit_dwoch.placeholder_text = "Wpisz liczbę większą od 0"
		limit_dwoch.grab_focus()
		return

	Ustawienia.tryb = "2graczy"
	Ustawienia.arena_dwoch_graczy = false
	Ustawienia.limit_punktow = limit_dwoch.text.to_int()
	_zapisz_wybor_rozmiaru(rozmiar_dwoch)

	Ustawienia.zapisz()
	get_tree().change_scene_to_file("res://scena_główna.tscn")


func _start_endless_rally():
	Ustawienia.tryb = "endless"
	Ustawienia.arena_dwoch_graczy = false
	Ustawienia.rozmiar_planszy = "standardowa"
	Ustawienia.ustaw_geometrie_planszy()
	Ustawienia.zapisz()
	get_tree().change_scene_to_file("res://scena_główna.tscn")


func _start_arena(dwoch_graczy: bool = false):
	Ustawienia.tryb = "arena"
	Ustawienia.arena_dwoch_graczy = dwoch_graczy
	Ustawienia.rozmiar_planszy = "standardowa"
	Ustawienia.ustaw_geometrie_planszy()
	Ustawienia.charakter_bota = CHARAKTERY_BOTA.pick_random()
	Ustawienia.zapisz()
	get_tree().change_scene_to_file("res://scena_główna.tscn")


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
