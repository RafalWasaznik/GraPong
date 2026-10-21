class_name MenuGlowne
extends Control

const CHARAKTERY_BOTA = ["defensywny", "ofensywny", "agresywny", "nieprzewidywalny"]
const KOLOR_TURKUS_NEON = Color("#55e7ff")
const KOLOR_FIOLET_NEON = Color("#ad83ff")
const KOLOR_ROZ_NEON = Color("#ff5fb7")
const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")
const DZWIEK_MENU_GENERATOR = preload("res://dzwiek_menu.gd")
const SKRYPT_EKRANOW_MENU = preload("res://menu_ekrany.gd")

@onready var ekran_glowny = $CenterContainer/EkranGlowny
@onready var center_container = $CenterContainer
@onready var wybor_trybu = $CenterContainer/WyborTrybu
@onready var opcje_jeden_gracz = $CenterContainer/OpcjeJedenGracz
@onready var opcje_dwoch_graczy = $CenterContainer/OpcjeDwochGraczy
@onready var ekran_ustawien = $CenterContainer/EkranUstawien
@onready var konfiguracja_online: KonfiguracjaOnline = $KonfiguracjaOnline
@onready var tlo_menu: TloMenu = $Tlo

var aktywne_ustawienia_bota = "klasyczna"
var ekrany_menu: MenuEkrany
var dzwiek_klikniecia: AudioStreamPlayer

@onready var trudnosc = $CenterContainer/OpcjeJedenGracz/Trudnosc
@onready var limit_jeden = $CenterContainer/OpcjeJedenGracz/LimitJeden
@onready var limit_dwoch = $CenterContainer/OpcjeDwochGraczy/LimitDwoch

@onready var rozmiar_jeden = $CenterContainer/OpcjeJedenGracz/RozmiarPlanszyJeden
@onready var rozmiar_dwoch = $CenterContainer/OpcjeDwochGraczy/RozmiarPlanszyDwoch



func _enter_tree():
	Ustawienia.wczytaj()


func _utworz_kontekst_ekranow() -> MenuEkranyKontekst:
	var kontekst := MenuEkranyKontekst.new()
	kontekst.center_container = center_container
	kontekst.ekran_glowny = ekran_glowny
	kontekst.wybor_trybu = wybor_trybu
	kontekst.opcje_jeden_gracz = opcje_jeden_gracz
	kontekst.opcje_dwoch_graczy = opcje_dwoch_graczy
	kontekst.ekran_ustawien = ekran_ustawien
	kontekst.tlo = tlo_menu
	kontekst.konfiguracja_online = konfiguracja_online
	return kontekst


func _ready():
	ekrany_menu = SKRYPT_EKRANOW_MENU.new()
	var kontekst_ekranow := _utworz_kontekst_ekranow()
	ekrany_menu.inicjalizuj(kontekst_ekranow)
	ekrany_menu.akcja_zadana.connect(_obsluz_akcje_ekranow)
	ekrany_menu.utworz_ekrany_wyboru_gier()
	ekrany_menu.utworz_ekran_online()
	_styluj_menu()
	ekrany_menu.ekran_online.custom_minimum_size.x = 500.0
	ekrany_menu.instrukcje_polaczenia.add_theme_font_size_override("font_size", 16)
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


func _podlacz_dzwiek_klikniecia(wezel: Node) -> void:
	if wezel is BaseButton:
		wezel.pressed.connect(_odtworz_dzwiek_klikniecia)
	for dziecko in wezel.get_children():
		_podlacz_dzwiek_klikniecia(dziecko)


func _odtworz_dzwiek_klikniecia() -> void:
	dzwiek_klikniecia.play()


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

	for ekran in [ekran_glowny, wybor_trybu, ekrany_menu.wybor_gier_jeden, ekrany_menu.wybor_gier_dwoch, ekrany_menu.ekran_online, opcje_jeden_gracz, opcje_dwoch_graczy]:
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
	for ekran_wyboru in [ekrany_menu.wybor_gier_jeden, ekrany_menu.wybor_gier_dwoch]:
		ekran_wyboru.get_node("Tytul").add_theme_font_size_override("font_size", 28)
		ekran_wyboru.get_node("Tytul").add_theme_font_override("font", FONT_ARCADE)
		ekran_wyboru.get_node("Tytul").add_theme_color_override("font_color", KOLOR_TURKUS_NEON)
	for element in ekrany_menu.zawartosc_online.get_children():
		if element is Control:
			element.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if element is Label:
			element.add_theme_font_size_override("font_size", 18)
			element.add_theme_color_override("font_color", Color("#e8f4ff"))
	ekrany_menu.tytul_online.add_theme_font_size_override("font_size", 28)
	ekrany_menu.tytul_online.add_theme_font_override("font", FONT_ARCADE)
	ekrany_menu.tytul_online.add_theme_color_override("font_color", KOLOR_TURKUS_NEON)

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


func _wycentruj_teksty(wezel: Node) -> void:
	if wezel is Label:
		wezel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wezel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		wezel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elif wezel is Button:
		wezel.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for dziecko in wezel.get_children():
		_wycentruj_teksty(dziecko)



func _styluj_przycisk(guzik: Button) -> void:
	StylMenu.styluj_przycisk(guzik, Vector2(420.0, 52.0), KOLOR_TURKUS_NEON, Color("#14243a"), Color("#31506b"), Color("#1b3049"), Color("#102638"), Color("#35bcd5"), 21)


func _nowy_styl_przycisku(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	return StylMenu.styl_przycisku_karty(tlo, obramowanie)


func _nowy_styl_pola(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	return StylMenu.styl_pola(tlo, obramowanie)


func _dodaj_opis_trybu(przycisk: Button, tytul: String, opis: String, akcent: Color):
	StylMenu.dodaj_opis_trybu(przycisk, tytul, opis, akcent, FONT_ARCADE)


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


func _pokaz_ekran(ekran: Control) -> void:
	ekrany_menu.pokaz_ekran(ekran)


func _obsluz_akcje_ekranow(akcja: MenuEkrany.Akcja) -> void:
	match akcja:
		MenuEkrany.Akcja.OPCJE_JEDNEGO_GRACZA:
			_pokaz_opcje_jednego_gracza()
		MenuEkrany.Akcja.START_ENDLESS:
			_start_endless_rally()
		MenuEkrany.Akcja.OPCJE_ARENY:
			_pokaz_opcje_areny()
		MenuEkrany.Akcja.WYBOR_TRYBU:
			_pokaz_wybor_trybu()
		MenuEkrany.Akcja.OPCJE_DWOCH_GRACZY:
			_pokaz_opcje_dwoch_graczy()
		MenuEkrany.Akcja.START_ARENA:
			_start_arena(true)


func _pokaz_ekran_glowny():
	_pokaz_ekran(ekran_glowny)


func _pokaz_wybor_trybu():
	_pokaz_ekran(wybor_trybu)


func _pokaz_wybor_gier_jeden():
	_pokaz_ekran(ekrany_menu.wybor_gier_jeden)


func _pokaz_wybor_gier_dwoch():
	_pokaz_ekran(ekrany_menu.wybor_gier_dwoch)


func _pokaz_ekran_online():
	konfiguracja_online.pokaz()


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
