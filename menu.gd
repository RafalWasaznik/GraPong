extends Control

const CHARAKTERY_BOTA = ["defensywny", "ofensywny", "agresywny", "nieprzewidywalny"]
const KOLOR_TLA_NEON = Color("#050914")
const KOLOR_TURKUS_NEON = Color("#55e7ff")
const KOLOR_FIOLET_NEON = Color("#ad83ff")
const KOLOR_ROZ_NEON = Color("#ff5fb7")
const KOLOR_PILKI_DEMO = Color("#ffd166")
const KOLOR_BLYSKU_DEMO = Color("#fff0a8")
const DEMO_MAX_PRZESZKOD = 15
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
var wybor_online: VBoxContainer
var ekran_host_online: VBoxContainer
var ekran_dolacz_online: VBoxContainer
var tytul_online: Label
var adres_online: LineEdit
var nazwa_hosta_online: LineEdit
var nazwa_dolaczajacego_online: LineEdit
var warunek_online: OptionButton
var wartosc_warunku_online: SpinBox
var etykieta_warunku_online: Label
var wskazowka_warunku_online: Label
var status_online: Label
var adresy_hosta_label: Label
var kopiuj_adres_hosta: Button
var tryb_online_arena = false
var przycisk_tryb_online_klasyczny: Button
var przycisk_tryb_online_arena: Button
var adres_hosta_do_skopiowania = ""
var instrukcje_polaczenia: Label
var tryb_ekranu_online = "wybor"
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
var demo_przeszkody: Array[Dictionary] = []
var demo_poprzednie_miejsca: Array[Vector2] = []
var demo_czas_do_przeszkody = 1.4
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
	draw_circle(Vector2(size.x * 0.12, size.y * 0.18), size.y * 0.42, Color("#183047", 0.12))
	draw_circle(Vector2(size.x * 0.88, size.y * 0.82), size.y * 0.48, Color("#241c3b", 0.10))
	if przyciemnienie_tla > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.03, 0.055, przyciemnienie_tla), true)
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
		draw_circle(demo_slady[i], lerpf(2.0, 7.0, udzial), Color(KOLOR_PILKI_DEMO, udzial * 0.55))
	for przeszkoda in demo_przeszkody:
		var miejsce: Vector2 = boisko.position + Vector2(przeszkoda["miejsce"].x * boisko.size.x, przeszkoda["miejsce"].y * boisko.size.y)
		var blysk: float = przeszkoda["blysk"]
		var zycie_pozostale: float = float(przeszkoda["zycie"]) - float(przeszkoda["wiek"])
		var pojawienie: float = float(przeszkoda["pojawienie"]) * clampf(zycie_pozostale / 0.8, 0.0, 1.0)
		var kolor = KOLOR_BLYSKU_DEMO if blysk > 0.0 else KOLOR_FIOLET_NEON
		draw_circle(miejsce, 17.0 * pojawienie + blysk * 8.0, Color(kolor, (0.12 + blysk * 0.3) * pojawienie))
		draw_circle(miejsce, 10.0 * pojawienie, Color("#17152a", pojawienie))
		draw_circle(miejsce, 8.0 * pojawienie, Color(kolor, (0.72 + blysk * 0.28) * pojawienie), false, 2.0)
		draw_circle(miejsce, 3.5 * pojawienie, Color.WHITE if blysk > 0.0 else Color(kolor, 0.9 * pojawienie))
	draw_circle(demo_pilka, 20.0, Color("#ff9f43", 0.34))
	draw_circle(demo_pilka, 11.0, KOLOR_PILKI_DEMO)
	draw_circle(demo_pilka, 5.5, Color("#ffffff"))


func _prostokat_boisko() -> Rect2:
	var margines_x = size.x * 0.045
	var margines_y = size.y * 0.08
	return Rect2(Vector2(margines_x, margines_y), Vector2(maxf(size.x - margines_x * 2.0, 1.0), maxf(size.y - margines_y * 2.0, 1.0)))


func _symuluj_tlo(delta):
	var boisko = _prostokat_boisko()
	if demo_przeszkody.size() < DEMO_MAX_PRZESZKOD:
		demo_czas_do_przeszkody -= delta
		if demo_czas_do_przeszkody <= 0.0:
			_dodaj_przeszkode_demo(boisko)
			demo_czas_do_przeszkody = 0.45
	for indeks in range(demo_przeszkody.size() - 1, -1, -1):
		var przeszkoda = demo_przeszkody[indeks]
		przeszkoda["blysk"] = maxf(float(przeszkoda["blysk"]) - delta, 0.0)
		przeszkoda["pojawienie"] = minf(float(przeszkoda["pojawienie"]) + delta * 2.5, 1.0)
		przeszkoda["wiek"] = float(przeszkoda["wiek"]) + delta
		if float(przeszkoda["wiek"]) >= float(przeszkoda["zycie"]):
			demo_poprzednie_miejsca.append(przeszkoda["miejsce"])
			if demo_poprzednie_miejsca.size() > 3:
				demo_poprzednie_miejsca.pop_front()
			demo_przeszkody.remove_at(indeks)
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
	for przeszkoda in demo_przeszkody:
		var miejsce: Vector2 = boisko.position + Vector2(przeszkoda["miejsce"].x * boisko.size.x, przeszkoda["miejsce"].y * boisko.size.y)
		var roznica = nowa_pozycja - miejsce
		var odleglosc = roznica.length()
		var odleglosc_odbicia = 18.0
		if odleglosc < odleglosc_odbicia:
			var normalna = roznica / odleglosc if odleglosc > 0.01 else -demo_predkosc.normalized()
			if demo_predkosc.dot(normalna) < 0.0:
				demo_predkosc = demo_predkosc.bounce(normalna)
				nowa_pozycja = miejsce + normalna * (odleglosc_odbicia + 0.5)
				przeszkoda["blysk"] = 0.45
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


func _dodaj_przeszkode_demo(boisko: Rect2) -> void:
	var nowe_miejsce = Vector2.ZERO
	var znaleziono_miejsce = false
	for _proba in range(100):
		var kandydat = Vector2(randf_range(0.08, 0.92), randf_range(0.1, 0.9))
		var pozycja = boisko.position + Vector2(kandydat.x * boisko.size.x, kandydat.y * boisko.size.y)
		if pozycja.distance_to(demo_pilka) < 70.0:
			continue
		var za_blisko_innej = false
		for istniejaca in demo_przeszkody:
			var inne_miejsce: Vector2 = istniejaca["miejsce"]
			var inna_pozycja = boisko.position + Vector2(inne_miejsce.x * boisko.size.x, inne_miejsce.y * boisko.size.y)
			if pozycja.distance_to(inna_pozycja) < 42.0:
				za_blisko_innej = true
				break
		if not za_blisko_innej:
			for poprzednie_miejsce in demo_poprzednie_miejsca:
				var poprzednia_pozycja = boisko.position + Vector2(poprzednie_miejsce.x * boisko.size.x, poprzednie_miejsce.y * boisko.size.y)
				if pozycja.distance_to(poprzednia_pozycja) < 55.0:
					za_blisko_innej = true
					break
		if not za_blisko_innej:
			nowe_miejsce = kandydat
			znaleziono_miejsce = true
			break
	if znaleziono_miejsce:
		demo_przeszkody.append({
			"miejsce": nowe_miejsce,
			"blysk": 0.0,
			"pojawienie": 0.0,
			"wiek": 0.0,
			"zycie": randf_range(7.0, 11.0),
		})


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
		styl_popup.bg_color = Color("#111c2b", 0.9)
		styl_popup.border_color = Color("#3b5a73")
		styl_popup.set_border_width_all(1)
		styl_popup.set_corner_radius_all(10)
		popup.add_theme_stylebox_override("panel", styl_popup)
		popup.add_theme_color_override("font_color", Color("#e8f4ff"))
		popup.add_theme_color_override("font_hover_color", Color.WHITE)
		popup.add_theme_color_override("font_selected_color", KOLOR_TURKUS_NEON)
		var styl_najechania = StyleBoxFlat.new()
		styl_najechania.bg_color = Color("#1b304a", 0.92)
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
	ekran_online.add_theme_constant_override("separation", 14)
	ekran_online.custom_minimum_size = Vector2(500.0, 0.0)
	center_container.add_child(ekran_online)
	ekran_online.hide()
	var przewijanie = ScrollContainer.new()
	przewijanie.name = "PrzewijanieMultiplayer"
	przewijanie.custom_minimum_size = Vector2(500.0, 500.0)
	przewijanie.size_flags_vertical = Control.SIZE_EXPAND_FILL
	przewijanie.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	przewijanie.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	ekran_online.add_child(przewijanie)
	var odstep_paska = MarginContainer.new()
	odstep_paska.add_theme_constant_override("margin_left", 18)
	odstep_paska.add_theme_constant_override("margin_right", 24)
	odstep_paska.add_theme_constant_override("margin_top", 10)
	odstep_paska.add_theme_constant_override("margin_bottom", 10)
	odstep_paska.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	przewijanie.add_child(odstep_paska)
	zawartosc_online = VBoxContainer.new()
	zawartosc_online.name = "ZawartoscMultiplayer"
	zawartosc_online.add_theme_constant_override("separation", 16)
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
	opis_hosta.text = "Obaj gracze muszą być połączeni przez Tailscale. Wybierz swoją rolę."
	opis_hosta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opis_hosta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zawartosc_online.add_child(opis_hosta)
	wybor_online = VBoxContainer.new()
	wybor_online.add_theme_constant_override("separation", 14)
	zawartosc_online.add_child(wybor_online)
	var host_menu = Button.new()
	host_menu.text = "Utwórz mecz"
	host_menu.custom_minimum_size.y = 58.0
	_styluj_przycisk(host_menu)
	host_menu.pressed.connect(_pokaz_ustawienia_hosta_online)
	wybor_online.add_child(host_menu)
	var dolacz_menu = Button.new()
	dolacz_menu.text = "Dołącz do meczu"
	dolacz_menu.custom_minimum_size.y = 58.0
	_styluj_przycisk(dolacz_menu)
	dolacz_menu.pressed.connect(_pokaz_ustawienia_dolaczania_online)
	wybor_online.add_child(dolacz_menu)
	ekran_host_online = VBoxContainer.new()
	ekran_host_online.add_theme_constant_override("separation", 9)
	ekran_host_online.hide()
	zawartosc_online.add_child(ekran_host_online)
	ekran_dolacz_online = VBoxContainer.new()
	ekran_dolacz_online.add_theme_constant_override("separation", 16)
	ekran_dolacz_online.hide()
	zawartosc_online.add_child(ekran_dolacz_online)
	adresy_hosta_label = Label.new()
	adresy_hosta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adresy_hosta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ekran_host_online.add_child(adresy_hosta_label)
	kopiuj_adres_hosta = Button.new()
	kopiuj_adres_hosta.custom_minimum_size.y = 48.0
	_styluj_przycisk(kopiuj_adres_hosta)
	kopiuj_adres_hosta.pressed.connect(_kopiuj_adres_hosta)
	ekran_host_online.add_child(kopiuj_adres_hosta)

	var hostuj = Button.new()
	var etykieta_trybu = Label.new()
	etykieta_trybu.text = "Wybierz tryb meczu"
	etykieta_trybu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_trybu.add_theme_font_override("font", FONT_ARCADE)
	etykieta_trybu.add_theme_font_size_override("font_size", 20)
	etykieta_trybu.add_theme_color_override("font_color", KOLOR_TURKUS_NEON)
	ekran_host_online.add_child(etykieta_trybu)
	var etykieta_nazwy_hosta = Label.new()
	etykieta_nazwy_hosta.text = "Twoja nazwa"
	etykieta_nazwy_hosta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ekran_host_online.add_child(etykieta_nazwy_hosta)
	nazwa_hosta_online = LineEdit.new()
	nazwa_hosta_online.text = "Gracz 1"
	nazwa_hosta_online.max_length = 16
	nazwa_hosta_online.placeholder_text = "Wpisz nazwę gracza"
	nazwa_hosta_online.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ekran_host_online.add_child(nazwa_hosta_online)
	var wybory_trybu = HBoxContainer.new()
	wybory_trybu.add_theme_constant_override("separation", 12)
	ekran_host_online.add_child(wybory_trybu)
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
	var etykieta_rodzaju_warunku = Label.new()
	etykieta_rodzaju_warunku.text = "Warunek zwycięstwa"
	etykieta_rodzaju_warunku.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ekran_host_online.add_child(etykieta_rodzaju_warunku)
	warunek_online = OptionButton.new()
	warunek_online.add_item("Do limitu punktów", 0)
	warunek_online.add_item("Na czas", 1)
	warunek_online.custom_minimum_size.y = 50.0
	_styluj_przycisk(warunek_online)
	warunek_online.item_selected.connect(_zmien_warunek_online)
	ekran_host_online.add_child(warunek_online)
	var popup_warunku = warunek_online.get_popup()
	var styl_popup_warunku = StyleBoxFlat.new()
	styl_popup_warunku.bg_color = Color("#0c1727", 0.9)
	styl_popup_warunku.border_color = Color("#3b5a73")
	styl_popup_warunku.set_border_width_all(1)
	styl_popup_warunku.set_corner_radius_all(10)
	styl_popup_warunku.content_margin_left = 8.0
	styl_popup_warunku.content_margin_right = 8.0
	styl_popup_warunku.content_margin_top = 6.0
	styl_popup_warunku.content_margin_bottom = 6.0
	popup_warunku.add_theme_stylebox_override("panel", styl_popup_warunku)
	popup_warunku.add_theme_color_override("font_color", Color("#e8f4ff"))
	popup_warunku.add_theme_color_override("font_hover_color", Color.WHITE)
	popup_warunku.add_theme_color_override("font_selected_color", KOLOR_TURKUS_NEON)
	popup_warunku.add_theme_font_override("font", FONT_ARCADE)
	popup_warunku.add_theme_font_size_override("font_size", 18)
	var styl_najechania_warunku = StyleBoxFlat.new()
	styl_najechania_warunku.bg_color = Color("#1b3049", 0.92)
	styl_najechania_warunku.border_color = KOLOR_TURKUS_NEON
	styl_najechania_warunku.set_border_width_all(1)
	styl_najechania_warunku.set_corner_radius_all(6)
	popup_warunku.add_theme_stylebox_override("hover", styl_najechania_warunku)
	etykieta_warunku_online = Label.new()
	etykieta_warunku_online.text = "Limit punktów"
	etykieta_warunku_online.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wartosc_warunku_online = SpinBox.new()
	wartosc_warunku_online.min_value = 1
	wartosc_warunku_online.max_value = 50
	wartosc_warunku_online.value = 5
	wartosc_warunku_online.step = 1
	wartosc_warunku_online.suffix = " pkt"
	wartosc_warunku_online.editable = true
	wartosc_warunku_online.custom_minimum_size = Vector2(180.0, 48.0)
	wartosc_warunku_online.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wartosc_warunku_online.add_theme_font_size_override("font_size", 20)
	wartosc_warunku_online.add_theme_color_override("font_color", Color("#e8f4ff"))
	var pole_wartosci_warunku = wartosc_warunku_online.get_line_edit()
	pole_wartosci_warunku.alignment = HORIZONTAL_ALIGNMENT_CENTER
	pole_wartosci_warunku.add_theme_font_size_override("font_size", 20)
	pole_wartosci_warunku.add_theme_color_override("font_color", Color("#e8f4ff"))
	pole_wartosci_warunku.add_theme_color_override("caret_color", KOLOR_TURKUS_NEON)
	pole_wartosci_warunku.add_theme_stylebox_override("normal", _nowy_styl_pola(Color("#0a1323"), Color("#304b68")))
	pole_wartosci_warunku.add_theme_stylebox_override("focus", _nowy_styl_pola(Color("#0a1323"), KOLOR_TURKUS_NEON))
	var wiersz_limitu = HBoxContainer.new()
	wiersz_limitu.add_theme_constant_override("separation", 14)
	wiersz_limitu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wiersz_limitu.add_child(etykieta_warunku_online)
	wiersz_limitu.add_child(wartosc_warunku_online)
	ekran_host_online.add_child(wiersz_limitu)
	etykieta_warunku_online.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wskazowka_warunku_online = Label.new()
	wskazowka_warunku_online.text = "Po czasie wygrywa gracz z większą liczbą punktów."
	wskazowka_warunku_online.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wskazowka_warunku_online.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wskazowka_warunku_online.add_theme_color_override("font_color", Color("#b9cde2"))
	wskazowka_warunku_online.hide()
	ekran_host_online.add_child(wskazowka_warunku_online)

	hostuj.text = "Utwórz mecz jako host"
	hostuj.custom_minimum_size.y = 58.0
	_styluj_przycisk(hostuj)
	hostuj.pressed.connect(_utworz_mecz_online)
	ekran_host_online.add_child(hostuj)

	var opis_adresu = Label.new()
	opis_adresu.text = "Twoja nazwa"
	opis_adresu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opis_adresu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ekran_dolacz_online.add_child(opis_adresu)
	nazwa_dolaczajacego_online = LineEdit.new()
	nazwa_dolaczajacego_online.text = "Gracz 2"
	nazwa_dolaczajacego_online.max_length = 16
	nazwa_dolaczajacego_online.placeholder_text = "Wpisz nazwę gracza"
	nazwa_dolaczajacego_online.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ekran_dolacz_online.add_child(nazwa_dolaczajacego_online)
	var etykieta_adresu = Label.new()
	etykieta_adresu.text = "Adres Tailscale hosta"
	etykieta_adresu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_adresu.add_theme_font_size_override("font_size", 18)
	etykieta_adresu.add_theme_color_override("font_color", Color("#e8f4ff"))
	ekran_dolacz_online.add_child(etykieta_adresu)

	adres_online = LineEdit.new()
	adres_online.placeholder_text = "IP hosta, np. 100.80.12.34"
	adres_online.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ekran_dolacz_online.add_child(adres_online)
	var wskazowka = Label.new()
	wskazowka.text = "Tryb i warunek zwycięstwa ustala host."
	wskazowka.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wskazowka.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wskazowka.add_theme_color_override("font_color", Color("#b9cde2"))
	ekran_dolacz_online.add_child(wskazowka)

	var dolacz = Button.new()
	dolacz.text = "Dołącz do meczu"
	dolacz.custom_minimum_size.y = 58.0
	_styluj_przycisk(dolacz)
	dolacz.pressed.connect(_dolacz_do_meczu_online)
	ekran_dolacz_online.add_child(dolacz)

	status_online = Label.new()
	status_online.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_online.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_online.add_theme_color_override("font_color", Color("#b9cde2"))
	zawartosc_online.add_child(status_online)
	for etykieta in [adresy_hosta_label, etykieta_trybu, etykieta_nazwy_hosta, etykieta_rodzaju_warunku, etykieta_warunku_online, opis_adresu, etykieta_adresu, wskazowka, wskazowka_warunku_online]:
		etykieta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		etykieta.add_theme_font_size_override("font_size", 18)
		etykieta.add_theme_color_override("font_color", Color("#e8f4ff"))
	etykieta_trybu.add_theme_font_override("font", FONT_ARCADE)
	etykieta_trybu.add_theme_font_size_override("font_size", 20)
	etykieta_trybu.add_theme_color_override("font_color", KOLOR_TURKUS_NEON)
	for edycja in [nazwa_hosta_online, nazwa_dolaczajacego_online, adres_online]:
		edycja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edycja.add_theme_font_size_override("font_size", 18)
		edycja.add_theme_color_override("font_color", Color("#e8f4ff"))
		edycja.add_theme_color_override("font_placeholder_color", Color("#93a9c2"))
		edycja.add_theme_color_override("caret_color", KOLOR_TURKUS_NEON)
		edycja.add_theme_stylebox_override("normal", _nowy_styl_pola(Color("#0a1323"), Color("#304b68")))
		edycja.add_theme_stylebox_override("focus", _nowy_styl_pola(Color("#0a1323"), KOLOR_TURKUS_NEON))
		edycja.custom_minimum_size.y = 48.0
	warunek_online.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ekran_host_online.move_child(etykieta_nazwy_hosta, 0)
	ekran_host_online.move_child(nazwa_hosta_online, 1)
	ekran_host_online.move_child(etykieta_trybu, 2)
	ekran_host_online.move_child(wybory_trybu, 3)
	ekran_host_online.move_child(etykieta_rodzaju_warunku, 4)
	ekran_host_online.move_child(warunek_online, 5)
	ekran_host_online.move_child(wiersz_limitu, 6)
	ekran_host_online.move_child(wskazowka_warunku_online, 7)
	ekran_host_online.move_child(adresy_hosta_label, 8)
	ekran_host_online.move_child(kopiuj_adres_hosta, 9)
	ekran_host_online.move_child(hostuj, 10)

	var wroc = Button.new()
	wroc.text = "Wróć"
	wroc.custom_minimum_size.y = 54.0
	_styluj_przycisk(wroc)
	wroc.pressed.connect(_wroc_z_ekranu_online)
	ekran_online.add_child(wroc)
	_styluj_scrollbar_multiplayer(przewijanie.get_v_scroll_bar())

	Siec.polaczono_z_hostem.connect(_online_polaczono_z_hostem)
	Siec.otrzymano_ustawienia_meczu.connect(_online_tryb_meczu_otrzymany)
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


func _zmien_warunek_online(indeks: int) -> void:
	if indeks == 1:
		etykieta_warunku_online.text = "Czas gry"
		wartosc_warunku_online.min_value = 1
		wartosc_warunku_online.max_value = 60
		wartosc_warunku_online.value = 3
		wartosc_warunku_online.suffix = " min"
		wskazowka_warunku_online.show()
	else:
		etykieta_warunku_online.text = "Limit punktów"
		wartosc_warunku_online.min_value = 1
		wartosc_warunku_online.max_value = 50
		wartosc_warunku_online.value = 5
		wartosc_warunku_online.suffix = " pkt"
		wskazowka_warunku_online.hide()


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
	var warunek = "czas" if warunek_online.selected == 1 else "punkty"
	var blad = Siec.utworz_serwer(tryb, nazwa_hosta_online.text, warunek, int(wartosc_warunku_online.value))
	if blad != OK:
		status_online.text = "Nie udało się uruchomić hosta. Zamknij inne uruchomione mecze i spróbuj ponownie."
		return
	_przygotuj_tryb_online(tryb_online_arena)
	get_tree().change_scene_to_file("res://scena_główna.tscn")


func _dolacz_do_meczu_online() -> void:
	Siec.nazwa_gracza_2 = nazwa_dolaczajacego_online.text.strip_edges()
	var blad = Siec.dolacz_do_serwera(adres_online.text)
	if blad != OK:
		status_online.text = "Nie udało się rozpocząć połączenia. Sprawdź adres IP."
		return
	status_online.text = "Łączenie z hostem…"


func _online_polaczono_z_hostem() -> void:
	if not is_inside_tree() or not ekran_online.visible:
		return
	status_online.text = "Pobieranie ustawień meczu…"
	Siec.popros_o_ustawienia_meczu(nazwa_dolaczajacego_online.text)


func _online_tryb_meczu_otrzymany(ustawienia: Dictionary) -> void:
	if not is_inside_tree() or not ekran_online.visible:
		return
	_przygotuj_tryb_online(str(ustawienia.get("tryb", "klasyczny")) == "arena")
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
	Ustawienia.limit_punktow = Siec.limit_punktow_meczu
	Ustawienia.ustaw_geometrie_planszy()
	Siec.pauza_lokalna = false


func _wroc_z_ekranu_online() -> void:
	if tryb_ekranu_online != "wybor":
		if Siec.czy_klient():
			Siec.rozlacz()
		status_online.text = ""
		tryb_ekranu_online = "wybor"
		wybor_online.show()
		ekran_host_online.hide()
		ekran_dolacz_online.hide()
		tytul_online.text = "Gra online"
		instrukcje_polaczenia.text = "Obaj gracze muszą być połączeni przez Tailscale. Wybierz swoją rolę."
		return
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
	styl.bg_color = Color(tlo.r, tlo.g, tlo.b, minf(tlo.a, 0.78))
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
	styl.bg_color = Color(tlo.r, tlo.g, tlo.b, minf(tlo.a, 0.82))
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
	tryb_ekranu_online = "wybor"
	wybor_online.show()
	ekran_host_online.hide()
	ekran_dolacz_online.hide()
	tytul_online.text = "Gra online"
	instrukcje_polaczenia.text = "Obaj gracze muszą być połączeni przez Tailscale. Wybierz swoją rolę."
	_odswiez_adresy_hosta()
	_pokaz_ekran(ekran_online)


func _pokaz_ustawienia_hosta_online() -> void:
	tryb_ekranu_online = "host"
	status_online.text = ""
	wybor_online.hide()
	ekran_dolacz_online.hide()
	ekran_host_online.show()
	tytul_online.text = "Utwórz mecz"
	instrukcje_polaczenia.text = "Wybierz tryb, utwórz mecz i wyślij adres drugiemu graczowi."
	_odswiez_adresy_hosta()


func _pokaz_ustawienia_dolaczania_online() -> void:
	tryb_ekranu_online = "dolacz"
	status_online.text = ""
	wybor_online.hide()
	ekran_host_online.hide()
	ekran_dolacz_online.show()
	tytul_online.text = "Dołącz do meczu"
	instrukcje_polaczenia.text = "Wpisz adres Tailscale hosta, aby dołączyć do jego meczu."
	adres_online.grab_focus()


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
