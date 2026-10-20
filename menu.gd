extends Control

const CHARAKTERY_BOTA = ["defensywny", "ofensywny", "agresywny", "nieprzewidywalny"]
const KOLOR_TLA_NEON = Color("#070b16")
const KOLOR_TURKUS_NEON = Color("#55e7ff")
const KOLOR_FIOLET_NEON = Color("#ad83ff")
const KOLOR_ROZ_NEON = Color("#ff5fb7")
const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")
const DZWIEK_MENU_GENERATOR = preload("res://dzwiek_menu.gd")

@onready var ekran_glowny = $CenterContainer/EkranGlowny
@onready var center_container = $CenterContainer
@onready var wybor_trybu = $CenterContainer/WyborTrybu
@onready var opcje_jeden_gracz = $CenterContainer/OpcjeJedenGracz
@onready var opcje_dwoch_graczy = $CenterContainer/OpcjeDwochGraczy
@onready var ekran_ustawien = $CenterContainer/EkranUstawien

var wybor_gier_jeden: VBoxContainer
var wybor_gier_dwoch: VBoxContainer
var ekran_online: VBoxContainer
var zawartosc_online: VBoxContainer
var tytul_online: Label
var adres_online: LineEdit
var status_online: Label
var adresy_hosta_label: Label
var kopiuj_adres_hosta: Button
var tryb_online_arena = false
var przycisk_tryb_online_klasyczny: Button
var przycisk_tryb_online_arena: Button
var adres_hosta_do_skopiowania = ""
var instrukcje_polaczenia: Label
var aktywne_ustawienia_bota = "klasyczna"
var dzwiek_klikniecia: AudioStreamPlayer

@onready var trudnosc = $CenterContainer/OpcjeJedenGracz/Trudnosc
@onready var limit_jeden = $CenterContainer/OpcjeJedenGracz/LimitJeden
@onready var limit_dwoch = $CenterContainer/OpcjeDwochGraczy/LimitDwoch

@onready var rozmiar_jeden = $CenterContainer/OpcjeJedenGracz/RozmiarPlanszyJeden
@onready var rozmiar_dwoch = $CenterContainer/OpcjeDwochGraczy/RozmiarPlanszyDwoch


var demo_pilka = Vector2.ZERO
var demo_predkosc = Vector2(460.0, 260.0)
var demo_slady: Array[Vector2] = []
var demo_lewa_y = 0.0
var demo_prawa_y = 0.0
var demo_gotowy = false
var przyciemnienie_tla = 0.0
var docelowe_przyciemnienie = 0.0


func _enter_tree():
	Ustawienia.wczytaj()


func _ready():
	_utworz_ekrany_wyboru_gier()
	_utworz_ekran_online()
	_styluj_menu()
	ekran_online.custom_minimum_size.x = 500.0
	instrukcje_polaczenia.add_theme_font_size_override("font_size", 16)
	dzwiek_klikniecia = AudioStreamPlayer.new()
	dzwiek_klikniecia.name = "DzwiekKliknieciaMenu"
	dzwiek_klikniecia.stream = DZWIEK_MENU_GENERATOR.utworz_plumkniecie()
	dzwiek_klikniecia.volume_db = -8.0
	dzwiek_klikniecia.bus = &"Efekty"
	add_child(dzwiek_klikniecia)

	$CenterContainer/EkranGlowny/Graj.pressed.connect(_pokaz_wybor_trybu)
	$CenterContainer/EkranGlowny/Ustawienia.pressed.connect(_pokaz_ustawienia)
	$CenterContainer/EkranGlowny/Wyjdz.pressed.connect(_wyjdz_z_gry)

	$CenterContainer/WyborTrybu/JedenGracz.pressed.connect(_pokaz_wybor_gier_jeden)
	$CenterContainer/WyborTrybu/DwochGraczy.pressed.connect(_pokaz_wybor_gier_dwoch)
	$CenterContainer/WyborTrybu/Wroc.pressed.connect(_pokaz_ekran_glowny)

	$CenterContainer/OpcjeJedenGracz/StartJeden.pressed.connect(_start_jeden_gracz)
	$CenterContainer/OpcjeJedenGracz/WrocJeden.pressed.connect(_pokaz_wybor_gier_jeden)

	$CenterContainer/OpcjeDwochGraczy/StartDwoch.pressed.connect(_start_dwoch_graczy)
	$CenterContainer/OpcjeDwochGraczy/WrocDwoch.pressed.connect(_pokaz_wybor_gier_dwoch)

	ekran_ustawien.back_requested.connect(_pokaz_ekran_glowny)

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


	$CenterContainer/EkranGlowny/Tytuł.text = "PONG"
	$CenterContainer/EkranGlowny/Graj.text = "Graj"
	$CenterContainer/EkranGlowny/Ustawienia.text = "Ustawienia"
	$CenterContainer/EkranGlowny/Wyjdz.text = "Wyjdź z gry"

	$CenterContainer/WyborTrybu/TytulTrybu.text = "Wybierz tryb"
	$CenterContainer/WyborTrybu/JedenGracz.text = "1 gracz"
	$CenterContainer/WyborTrybu/DwochGraczy.text = "2 graczy"
	_dodaj_opis_trybu($CenterContainer/WyborTrybu/JedenGracz, "1 GRACZ", "", KOLOR_TURKUS_NEON)
	_dodaj_opis_trybu($CenterContainer/WyborTrybu/DwochGraczy, "2 GRACZY", "", KOLOR_ROZ_NEON)
	var przycisk_multiplayer = Button.new()
	przycisk_multiplayer.name = "Multiplayer"
	wybor_trybu.add_child(przycisk_multiplayer)
	wybor_trybu.move_child(przycisk_multiplayer, $CenterContainer/WyborTrybu/Wroc.get_index())
	_styluj_przycisk(przycisk_multiplayer)
	_dodaj_opis_trybu(przycisk_multiplayer, "Multiplayer", "", KOLOR_TURKUS_NEON)
	przycisk_multiplayer.pressed.connect(_pokaz_ekran_online)
	$CenterContainer/WyborTrybu/Wroc.text = "Wróć"

	$CenterContainer/OpcjeJedenGracz/TytulOpcjiJeden.text = "Gra z botem"
	$CenterContainer/OpcjeJedenGracz/EtykietaLimituJeden.text = "Limit punktów"
	$CenterContainer/OpcjeJedenGracz/StartJeden.text = "Graj"
	$CenterContainer/OpcjeJedenGracz/WrocJeden.text = "Wróć"

	$CenterContainer/OpcjeDwochGraczy/EtykietaLimituDwoch.text = "Limit punktów"
	$CenterContainer/OpcjeDwochGraczy/StartDwoch.text = "Graj"
	$CenterContainer/OpcjeDwochGraczy/WrocDwoch.text = "Wróć"


	_pokaz_ekran_glowny()
	_podlacz_dzwiek_klikniecia($CenterContainer)
	queue_redraw()


func _podlacz_dzwiek_klikniecia(wezel: Node) -> void:
	if wezel is BaseButton:
		wezel.pressed.connect(_odtworz_dzwiek_klikniecia)
	for dziecko in wezel.get_children():
		_podlacz_dzwiek_klikniecia(dziecko)


func _odtworz_dzwiek_klikniecia() -> void:
	dzwiek_klikniecia.play()


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
	# Animowana partia zajmuje całe tło. Nie rysujemy obramowania boiska,
	# które wcześniej tworzyło drugi, nachodzący na menu prostokąt.
	var paletka_w = clampf(boisko.size.x * 0.012, 12.0, 20.0)
	var paletka_h = clampf(boisko.size.y * 0.22, 66.0, 116.0)
	var lewa = Rect2(Vector2(boisko.position.x + 14.0, demo_lewa_y - paletka_h * 0.5), Vector2(paletka_w, paletka_h))
	var prawa = Rect2(Vector2(boisko.end.x - 14.0 - paletka_w, demo_prawa_y - paletka_h * 0.5), Vector2(paletka_w, paletka_h))
	draw_rect(lewa.grow(8.0), Color(KOLOR_TURKUS_NEON, 0.2), true)
	draw_rect(lewa, Color("#40dff5"), true)
	draw_rect(lewa, Color("#c7faff"), false, 2.0)
	draw_rect(prawa.grow(8.0), Color(KOLOR_ROZ_NEON, 0.22), true)
	draw_rect(prawa, Color("#ff4fa3"), true)
	draw_rect(prawa, Color("#ffe0f1"), false, 2.0)
	for i in range(demo_slady.size()):
		var udzial = float(i + 1) / float(demo_slady.size() + 1)
		draw_circle(demo_slady[i], lerpf(2.0, 7.0, udzial), Color(KOLOR_TURKUS_NEON, udzial * 0.55))
	draw_circle(demo_pilka, 19.0, Color(KOLOR_TURKUS_NEON, 0.32))
	draw_circle(demo_pilka, 10.0, KOLOR_TURKUS_NEON)
	draw_circle(demo_pilka, 5.5, Color("#ffffff"))
	if przyciemnienie_tla > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.03, 0.055, przyciemnienie_tla), true)


func _prostokat_boisko() -> Rect2:
	var margines_x = size.x * 0.045
	var margines_y = size.y * 0.08
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
	demo_predkosc = demo_predkosc.normalized() * 460.0
	if demo_slady.is_empty() or demo_pilka.distance_to(demo_slady.back()) > 2.5:
		demo_slady.append(stara_pozycja)
		if demo_slady.size() > 16:
			demo_slady.pop_front()
	demo_pilka = nowa_pozycja
	var cel_lewej = demo_pilka.y if demo_predkosc.x < 0.0 else boisko.get_center().y
	var cel_prawej = demo_pilka.y if demo_predkosc.x > 0.0 else boisko.get_center().y
	demo_lewa_y = move_toward(demo_lewa_y, cel_lewej, 300.0 * delta)
	demo_prawa_y = move_toward(demo_prawa_y, cel_prawej, 300.0 * delta)
	demo_lewa_y = clampf(demo_lewa_y, boisko.position.y + paletka_h * 0.5, boisko.end.y - paletka_h * 0.5)
	demo_prawa_y = clampf(demo_prawa_y, boisko.position.y + paletka_h * 0.5, boisko.end.y - paletka_h * 0.5)


func _styluj_menu():
	var karta = Panel.new()
	karta.name = "KartaMenu"
	karta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	karta.offset_left = 24.0
	karta.offset_top = 24.0
	karta.offset_right = -24.0
	karta.offset_bottom = -24.0
	karta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var styl_karty = StyleBoxFlat.new()
	styl_karty.bg_color = Color("#0c1628", 0.56)
	styl_karty.border_color = Color(KOLOR_TURKUS_NEON, 0.28)
	styl_karty.set_border_width_all(1)
	styl_karty.set_corner_radius_all(20)
	styl_karty.shadow_color = Color(KOLOR_TURKUS_NEON, 0.08)
	styl_karty.shadow_size = 18
	styl_karty.shadow_offset = Vector2.ZERO
	karta.add_theme_stylebox_override("panel", styl_karty)
	add_child(karta)
	move_child(karta, 0)

	for ekran in [ekran_glowny, wybor_trybu, wybor_gier_jeden, wybor_gier_dwoch, ekran_online, opcje_jeden_gracz, opcje_dwoch_graczy]:
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
	for ekran_wyboru in [wybor_gier_jeden, wybor_gier_dwoch]:
		ekran_wyboru.get_node("Tytul").add_theme_font_size_override("font_size", 28)
		ekran_wyboru.get_node("Tytul").add_theme_font_override("font", FONT_ARCADE)
		ekran_wyboru.get_node("Tytul").add_theme_color_override("font_color", KOLOR_TURKUS_NEON)
	for element in zawartosc_online.get_children():
		if element is Control:
			element.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if element is Label:
			element.add_theme_font_size_override("font_size", 18)
			element.add_theme_color_override("font_color", Color("#e8f4ff"))
	tytul_online.add_theme_font_size_override("font_size", 28)
	tytul_online.add_theme_font_override("font", FONT_ARCADE)
	tytul_online.add_theme_color_override("font_color", KOLOR_TURKUS_NEON)

	for guzik in [
		$CenterContainer/EkranGlowny/Graj,
		$CenterContainer/EkranGlowny/Ustawienia,
		$CenterContainer/EkranGlowny/Wyjdz,
		$CenterContainer/WyborTrybu/JedenGracz,
		$CenterContainer/WyborTrybu/DwochGraczy,
		$CenterContainer/WyborTrybu/Wroc,
		$CenterContainer/OpcjeJedenGracz/StartJeden,
		$CenterContainer/OpcjeJedenGracz/WrocJeden,
		$CenterContainer/OpcjeDwochGraczy/StartDwoch,
		$CenterContainer/OpcjeDwochGraczy/WrocDwoch,
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
	$CenterContainer/EkranGlowny/Wyjdz.set_meta("neon_akcent", KOLOR_ROZ_NEON)
	for guzik_powrotu in [
		$CenterContainer/WyborTrybu/Wroc,
		$CenterContainer/OpcjeJedenGracz/WrocJeden,
		$CenterContainer/OpcjeDwochGraczy/WrocDwoch,
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
	przycisk.custom_minimum_size = Vector2(420.0, 72.0 if opis.is_empty() else 88.0)
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
	if opis.is_empty():
		var etykieta = Label.new()
		etykieta.text = tytul
		etykieta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		etykieta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etykieta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etykieta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		etykieta.add_theme_font_override("font", FONT_ARCADE)
		etykieta.add_theme_font_size_override("font_size", 26)
		etykieta.add_theme_color_override("font_color", Color("#f2f8ff"))
		przycisk.add_child(etykieta)
		return
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
	_dodaj_karte_wyboru(wybor_gier_jeden, "Klasyczny", "", KOLOR_TURKUS_NEON, _pokaz_opcje_jednego_gracza)
	_dodaj_karte_wyboru(wybor_gier_jeden, "Nieskończony", "", KOLOR_FIOLET_NEON, _start_endless_rally)
	_dodaj_karte_wyboru(wybor_gier_jeden, "Arena", "", Color("#ffb454"), _pokaz_opcje_areny)
	_dodaj_karte_wyboru(wybor_gier_jeden, "Wróć", "", Color("#7892ad"), _pokaz_wybor_trybu, true)

	wybor_gier_dwoch = VBoxContainer.new()
	wybor_gier_dwoch.name = "WyborGierDwochGraczy"
	wybor_gier_dwoch.alignment = BoxContainer.ALIGNMENT_CENTER
	center_container.add_child(wybor_gier_dwoch)
	wybor_gier_dwoch.hide()
	_dodaj_ekran_wyboru_gier(wybor_gier_dwoch, "Tryb dla dwóch graczy")
	_dodaj_karte_wyboru(wybor_gier_dwoch, "KLASYCZNY POJEDYNEK", "", KOLOR_ROZ_NEON, _pokaz_opcje_dwoch_graczy)
	_dodaj_karte_wyboru(wybor_gier_dwoch, "ARENA", "", Color("#ffb454"), _start_arena.bind(true))
	_dodaj_karte_wyboru(wybor_gier_dwoch, "Wróć", "", Color("#7892ad"), _pokaz_wybor_trybu, true)


func _dodaj_ekran_wyboru_gier(ekran: VBoxContainer, tekst_tytulu: String):
	var tytul = Label.new()
	tytul.name = "Tytul"
	tytul.text = tekst_tytulu
	tytul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ekran.add_child(tytul)


func _utworz_ekran_online() -> void:
	ekran_online = VBoxContainer.new()
	ekran_online.name = "EkranOnline"
	ekran_online.alignment = BoxContainer.ALIGNMENT_CENTER
	ekran_online.custom_minimum_size = Vector2(500.0, 0.0)
	center_container.add_child(ekran_online)
	ekran_online.hide()
	var przewijanie = ScrollContainer.new()
	przewijanie.name = "PrzewijanieMultiplayer"
	przewijanie.custom_minimum_size = Vector2(500.0, 460.0)
	przewijanie.size_flags_vertical = Control.SIZE_EXPAND_FILL
	przewijanie.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	przewijanie.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	ekran_online.add_child(przewijanie)
	var odstep_paska = MarginContainer.new()
	odstep_paska.add_theme_constant_override("margin_left", 18)
	odstep_paska.add_theme_constant_override("margin_right", 24)
	odstep_paska.add_theme_constant_override("margin_top", 18)
	odstep_paska.add_theme_constant_override("margin_bottom", 18)
	odstep_paska.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	przewijanie.add_child(odstep_paska)
	zawartosc_online = VBoxContainer.new()
	zawartosc_online.name = "ZawartoscMultiplayer"
	zawartosc_online.add_theme_constant_override("separation", 24)
	zawartosc_online.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	odstep_paska.add_child(zawartosc_online)

	tytul_online = Label.new()
	tytul_online.name = "TytulOnline"
	tytul_online.text = "Gra online"
	tytul_online.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zawartosc_online.add_child(tytul_online)

	var opis_hosta = Label.new()
	opis_hosta.name = "InstrukcjePolaczenia"
	instrukcje_polaczenia = opis_hosta
	opis_hosta.text = "Połączcie oba komputery przez Tailscale. Host kopiuje swój adres, wybiera tryb Klasyczny lub Arena i tworzy mecz. Drugi gracz wpisuje otrzymany adres w polu poniżej i dołącza — zagra w tym samym trybie co host."
	opis_hosta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opis_hosta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zawartosc_online.add_child(opis_hosta)
	adresy_hosta_label = Label.new()
	adresy_hosta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adresy_hosta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zawartosc_online.add_child(adresy_hosta_label)
	kopiuj_adres_hosta = Button.new()
	kopiuj_adres_hosta.custom_minimum_size.y = 48.0
	_styluj_przycisk(kopiuj_adres_hosta)
	kopiuj_adres_hosta.pressed.connect(_kopiuj_adres_hosta)
	zawartosc_online.add_child(kopiuj_adres_hosta)

	var hostuj = Button.new()
	var etykieta_trybu = Label.new()
	etykieta_trybu.text = "TRYB MECZU - WYBIERA HOST"
	etykieta_trybu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_trybu.add_theme_font_override("font", FONT_ARCADE)
	etykieta_trybu.add_theme_font_size_override("font_size", 20)
	etykieta_trybu.add_theme_color_override("font_color", KOLOR_TURKUS_NEON)
	zawartosc_online.add_child(etykieta_trybu)
	var wybory_trybu = HBoxContainer.new()
	wybory_trybu.add_theme_constant_override("separation", 12)
	zawartosc_online.add_child(wybory_trybu)
	var grupa_trybu = ButtonGroup.new()
	przycisk_tryb_online_klasyczny = Button.new()
	przycisk_tryb_online_klasyczny.text = "Klasyczny"
	przycisk_tryb_online_klasyczny.toggle_mode = true
	przycisk_tryb_online_klasyczny.button_group = grupa_trybu
	przycisk_tryb_online_klasyczny.button_pressed = true
	przycisk_tryb_online_klasyczny.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	przycisk_tryb_online_klasyczny.custom_minimum_size = Vector2(0.0, 54.0)
	_styluj_przycisk(przycisk_tryb_online_klasyczny)
	przycisk_tryb_online_klasyczny.custom_minimum_size.x = 0.0
	przycisk_tryb_online_klasyczny.toggled.connect(func(wybrany: bool):
		if wybrany:
			tryb_online_arena = false
	)
	wybory_trybu.add_child(przycisk_tryb_online_klasyczny)
	przycisk_tryb_online_arena = Button.new()
	przycisk_tryb_online_arena.text = "Arena"
	przycisk_tryb_online_arena.toggle_mode = true
	przycisk_tryb_online_arena.button_group = grupa_trybu
	przycisk_tryb_online_arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	przycisk_tryb_online_arena.custom_minimum_size = Vector2(0.0, 54.0)
	_styluj_przycisk(przycisk_tryb_online_arena)
	przycisk_tryb_online_arena.custom_minimum_size.x = 0.0
	przycisk_tryb_online_arena.add_theme_stylebox_override("pressed", _nowy_styl_przycisku(Color("#302616"), Color("#ffb454")))
	przycisk_tryb_online_arena.add_theme_stylebox_override("hover", _nowy_styl_przycisku(Color("#2c251d"), Color("#ffb454")))
	przycisk_tryb_online_arena.toggled.connect(func(wybrany: bool):
		if wybrany:
			tryb_online_arena = true
	)
	wybory_trybu.add_child(przycisk_tryb_online_arena)

	hostuj.text = "Utwórz mecz jako host"
	hostuj.custom_minimum_size.y = 58.0
	_styluj_przycisk(hostuj)
	hostuj.pressed.connect(_utworz_mecz_online)
	zawartosc_online.add_child(hostuj)

	var opis_adresu = Label.new()
	opis_adresu.text = "Adres Tailscale hosta (np. 100.x.x.x) lub adres lokalny w tej samej sieci"
	opis_adresu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opis_adresu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zawartosc_online.add_child(opis_adresu)

	adres_online = LineEdit.new()
	adres_online.placeholder_text = "IP hosta, np. 100.80.12.34"
	adres_online.alignment = HORIZONTAL_ALIGNMENT_CENTER
	zawartosc_online.add_child(adres_online)
	var wskazowka = Label.new()
	wskazowka.text = "Obaj gracze używają własnych klawiszy gracza 1: góra, dół i dash."
	wskazowka.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wskazowka.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wskazowka.add_theme_color_override("font_color", Color("#b9cde2"))
	zawartosc_online.add_child(wskazowka)

	var dolacz = Button.new()
	dolacz.text = "Dołącz do meczu"
	dolacz.custom_minimum_size.y = 58.0
	_styluj_przycisk(dolacz)
	dolacz.pressed.connect(_dolacz_do_meczu_online)
	zawartosc_online.add_child(dolacz)

	status_online = Label.new()
	status_online.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_online.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_online.add_theme_color_override("font_color", Color("#b9cde2"))
	zawartosc_online.add_child(status_online)

	var wroc = Button.new()
	wroc.text = "Wróć"
	wroc.custom_minimum_size.y = 54.0
	_styluj_przycisk(wroc)
	wroc.pressed.connect(_wroc_z_ekranu_online)
	ekran_online.add_child(wroc)
	_styluj_scrollbar_multiplayer(przewijanie.get_v_scroll_bar())

	Siec.polaczono_z_hostem.connect(_online_polaczono_z_hostem)
	Siec.otrzymano_tryb_meczu.connect(_online_tryb_meczu_otrzymany)
	Siec.blad_polaczenia.connect(_online_blad_polaczenia)


func _styluj_scrollbar_multiplayer(pasek: VScrollBar) -> void:
	pasek.custom_minimum_size.x = 14
	pasek.add_theme_constant_override("grabber_min_size", 52)
	var tor = StyleBoxFlat.new()
	tor.bg_color = Color("#081321", 0.9)
	tor.border_color = Color(KOLOR_TURKUS_NEON, 0.14)
	tor.set_border_width_all(1)
	tor.set_corner_radius_all(7)
	pasek.add_theme_stylebox_override("scroll", tor)
	pasek.add_theme_stylebox_override("scroll_focus", tor)
	var uchwyt = StyleBoxFlat.new()
	uchwyt.bg_color = Color("#315b70")
	uchwyt.border_color = Color(KOLOR_TURKUS_NEON, 0.62)
	uchwyt.set_border_width_all(1)
	uchwyt.set_corner_radius_all(7)
	uchwyt.shadow_color = Color(KOLOR_TURKUS_NEON, 0.12)
	uchwyt.shadow_size = 4
	pasek.add_theme_stylebox_override("grabber", uchwyt)
	var hover = uchwyt.duplicate()
	hover.bg_color = Color("#3f8298")
	hover.border_color = Color(KOLOR_TURKUS_NEON, 0.92)
	hover.shadow_color = Color(KOLOR_TURKUS_NEON, 0.28)
	hover.shadow_size = 7
	pasek.add_theme_stylebox_override("grabber_highlight", hover)


func _odswiez_adresy_hosta() -> void:
	var adresy_tailscale = Siec.adresy_tailscale()
	var adresy_lokalne = Siec.adresy_ipv4_lokalne()
	kopiuj_adres_hosta.disabled = false
	var tekst_tailscale = ", ".join(adresy_tailscale) if not adresy_tailscale.is_empty() else "niedostępny — uruchom Tailscale"
	var tekst_lokalny = ", ".join(adresy_lokalne) if not adresy_lokalne.is_empty() else "brak"
	adresy_hosta_label.text = "Adresy do udostępnienia jako host\nTailscale: %s\nSieć lokalna: %s" % [tekst_tailscale, tekst_lokalny]
	if not adresy_tailscale.is_empty():
		adres_hosta_do_skopiowania = adresy_tailscale[0]
		kopiuj_adres_hosta.text = "Kopiuj adres Tailscale"
	elif not adresy_lokalne.is_empty():
		adres_hosta_do_skopiowania = adresy_lokalne[0]
		kopiuj_adres_hosta.text = "Kopiuj adres lokalny"
	else:
		adres_hosta_do_skopiowania = ""
		kopiuj_adres_hosta.text = "Brak adresu do skopiowania"
		kopiuj_adres_hosta.disabled = true
	return


func _kopiuj_adres_hosta() -> void:
	if adres_hosta_do_skopiowania.is_empty():
		return
	DisplayServer.clipboard_set(adres_hosta_do_skopiowania)
	status_online.text = "Skopiowano adres: %s" % adres_hosta_do_skopiowania


func _utworz_mecz_online() -> void:
	var tryb = "arena" if tryb_online_arena else "klasyczny"
	var blad = Siec.utworz_serwer(tryb)
	if blad != OK:
		status_online.text = "Nie udało się uruchomić hosta. Zamknij inne uruchomione mecze i spróbuj ponownie."
		return
	_przygotuj_tryb_online(tryb_online_arena)
	get_tree().change_scene_to_file("res://scena_główna.tscn")


func _dolacz_do_meczu_online() -> void:
	var blad = Siec.dolacz_do_serwera(adres_online.text)
	if blad != OK:
		status_online.text = "Nie udało się rozpocząć połączenia. Sprawdź adres IP."
		return
	status_online.text = "Łączenie z hostem…"


func _online_polaczono_z_hostem() -> void:
	if not is_inside_tree() or not ekran_online.visible:
		return
	status_online.text = "Pobieranie trybu meczu od hosta…"
	Siec.popros_o_tryb_meczu()


func _online_tryb_meczu_otrzymany(tryb: String) -> void:
	if not is_inside_tree() or not ekran_online.visible:
		return
	_przygotuj_tryb_online(tryb == "arena")
	get_tree().change_scene_to_file("res://scena_główna.tscn")


func _online_blad_polaczenia() -> void:
	if not is_inside_tree():
		return
	Siec.rozlacz()
	if is_instance_valid(status_online):
		status_online.text = "Nie udało się połączyć. Sprawdź IP, zaporę i dostępność hosta."


func _przygotuj_tryb_online(arena: bool) -> void:
	Ustawienia.tryb = "online"
	Ustawienia.arena_dwoch_graczy = false
	Ustawienia.online_arena = arena
	Ustawienia.rozmiar_planszy = "standardowa"
	Ustawienia.limit_punktow = 5
	Ustawienia.ustaw_geometrie_planszy()
	Siec.pauza_lokalna = false


func _wroc_z_ekranu_online() -> void:
	if Siec.czy_klient():
		Siec.rozlacz()
	_pokaz_wybor_trybu()


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
	if is_instance_valid(ekran_online):
		ekran_online.hide()
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


func _pokaz_ekran_online():
	status_online.text = ""
	_odswiez_adresy_hosta()
	_pokaz_ekran(ekran_online)


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


func _wyjdz_z_gry():
	get_tree().quit()


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
