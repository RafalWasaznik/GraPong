class_name MenuEkrany
extends RefCounted

enum Akcja { OPCJE_JEDNEGO_GRACZA, START_ENDLESS, OPCJE_ARENY, WYBOR_TRYBU, OPCJE_DWOCH_GRACZY, START_ARENA }
signal akcja_zadana(akcja: Akcja)

const KOLOR_TURKUS_NEON = Color("#55e7ff")
const KOLOR_FIOLET_NEON = Color("#ad83ff")
const KOLOR_ROZ_NEON = Color("#ff72ac")
const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")

var animacja_ekranu: Tween
var kontekst: MenuEkranyKontekst
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
var przycisk_tryb_online_klasyczny: Button
var przycisk_tryb_online_arena: Button
var instrukcje_polaczenia: Label

func inicjalizuj(zaleznosci: MenuEkranyKontekst) -> void:
	kontekst = zaleznosci


func utworz_ekrany_wyboru_gier() -> void:
	wybor_gier_jeden = VBoxContainer.new()
	wybor_gier_jeden.name = "WyborGierJedenGracz"
	wybor_gier_jeden.alignment = BoxContainer.ALIGNMENT_CENTER
	kontekst.center_container.add_child(wybor_gier_jeden)
	wybor_gier_jeden.hide()
	_dodaj_ekran_wyboru_gier(wybor_gier_jeden, "Tryb dla jednego gracza")
	_dodaj_karte_wyboru(wybor_gier_jeden, "Klasyczny", "", KOLOR_TURKUS_NEON, Akcja.OPCJE_JEDNEGO_GRACZA)
	_dodaj_karte_wyboru(wybor_gier_jeden, "Nieskończony", "", KOLOR_FIOLET_NEON, Akcja.START_ENDLESS, true)
	_dodaj_karte_wyboru(wybor_gier_jeden, "Arena", "", KOLOR_TURKUS_NEON, Akcja.OPCJE_ARENY)
	_dodaj_karte_wyboru(wybor_gier_jeden, "Wróć", "", Color("#7892ad"), Akcja.WYBOR_TRYBU, true)

	wybor_gier_dwoch = VBoxContainer.new()
	wybor_gier_dwoch.name = "WyborGierDwochGraczy"
	wybor_gier_dwoch.alignment = BoxContainer.ALIGNMENT_CENTER
	kontekst.center_container.add_child(wybor_gier_dwoch)
	wybor_gier_dwoch.hide()
	_dodaj_ekran_wyboru_gier(wybor_gier_dwoch, "Tryb dla dwóch graczy")
	_dodaj_karte_wyboru(wybor_gier_dwoch, "Klasyczny", "", KOLOR_ROZ_NEON, Akcja.OPCJE_DWOCH_GRACZY)
	_dodaj_karte_wyboru(wybor_gier_dwoch, "Arena", "", KOLOR_TURKUS_NEON, Akcja.START_ARENA)
	_dodaj_karte_wyboru(wybor_gier_dwoch, "Wróć", "", Color("#7892ad"), Akcja.WYBOR_TRYBU, true)


func _dodaj_ekran_wyboru_gier(ekran: VBoxContainer, tekst_tytulu: String):
	var tytul = Label.new()
	tytul.name = "Tytul"
	tytul.text = tekst_tytulu
	tytul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ekran.add_child(tytul)


func utworz_ekran_online() -> void:
	ekran_online = VBoxContainer.new()
	ekran_online.name = "EkranOnline"
	ekran_online.alignment = BoxContainer.ALIGNMENT_CENTER
	ekran_online.add_theme_constant_override("separation", 24)
	ekran_online.custom_minimum_size = Vector2(500.0, 0.0)
	kontekst.center_container.add_child(ekran_online)
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
	opis_hosta.text = "Obaj gracze muszą być połączeni przez Tailscale. Wybierz swoją rolę."
	opis_hosta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opis_hosta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	zawartosc_online.add_child(opis_hosta)
	wybor_online = VBoxContainer.new()
	wybor_online.add_theme_constant_override("separation", 24)
	zawartosc_online.add_child(wybor_online)
	var host_menu = Button.new()
	host_menu.text = "Utwórz mecz"
	host_menu.custom_minimum_size.y = 58.0
	_styluj_przycisk(host_menu)
	host_menu.pressed.connect(kontekst.konfiguracja_online.pokaz_ustawienia_hosta)
	wybor_online.add_child(host_menu)
	var dolacz_menu = Button.new()
	dolacz_menu.text = "Dołącz do meczu"
	dolacz_menu.custom_minimum_size.y = 58.0
	_styluj_przycisk(dolacz_menu)
	dolacz_menu.pressed.connect(kontekst.konfiguracja_online.pokaz_ustawienia_dolaczania)
	wybor_online.add_child(dolacz_menu)
	ekran_host_online = VBoxContainer.new()
	ekran_host_online.add_theme_constant_override("separation", 20)
	ekran_host_online.hide()
	zawartosc_online.add_child(ekran_host_online)
	ekran_dolacz_online = VBoxContainer.new()
	ekran_dolacz_online.add_theme_constant_override("separation", 24)
	ekran_dolacz_online.hide()
	zawartosc_online.add_child(ekran_dolacz_online)
	adresy_hosta_label = Label.new()
	adresy_hosta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adresy_hosta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ekran_host_online.add_child(adresy_hosta_label)
	kopiuj_adres_hosta = Button.new()
	kopiuj_adres_hosta.custom_minimum_size.y = 48.0
	_styluj_przycisk(kopiuj_adres_hosta)
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
	wybory_trybu.add_child(przycisk_tryb_online_klasyczny)
	przycisk_tryb_online_arena = Button.new()
	przycisk_tryb_online_arena.text = "Arena"
	przycisk_tryb_online_arena.toggle_mode = true
	przycisk_tryb_online_arena.button_group = grupa_trybu
	przycisk_tryb_online_arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	przycisk_tryb_online_arena.custom_minimum_size = Vector2(0.0, 54.0)
	_styluj_przycisk(przycisk_tryb_online_arena)
	przycisk_tryb_online_arena.custom_minimum_size.x = 0.0
	przycisk_tryb_online_arena.add_theme_stylebox_override("pressed", StylMenu.styl_przycisku_karty(Color("#102638"), KOLOR_TURKUS_NEON))
	przycisk_tryb_online_arena.add_theme_stylebox_override("hover", StylMenu.styl_przycisku_karty(Color("#1b3049"), KOLOR_TURKUS_NEON))
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
	ekran_host_online.add_child(warunek_online)
	var popup_warunku = warunek_online.get_popup()
	var styl_popup_warunku = StyleBoxFlat.new()
	styl_popup_warunku.bg_color = Color("#0c1727", 0.9)
	styl_popup_warunku.border_color = Color("#3b5a73")
	styl_popup_warunku.set_border_width_all(0)
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
	styl_najechania_warunku.border_width_bottom = 2
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
	pole_wartosci_warunku.add_theme_stylebox_override("normal", StylMenu.styl_pola(Color("#0a1323"), Color("#304b68")))
	pole_wartosci_warunku.add_theme_stylebox_override("focus", StylMenu.styl_pola(Color("#0a1323"), KOLOR_TURKUS_NEON))
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
	hostuj.pressed.connect(kontekst.konfiguracja_online.utworz_mecz)
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
	dolacz.pressed.connect(kontekst.konfiguracja_online.dolacz_do_meczu)
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
		edycja.add_theme_stylebox_override("normal", StylMenu.styl_pola(Color("#0a1323"), Color("#304b68")))
		edycja.add_theme_stylebox_override("focus", StylMenu.styl_pola(Color("#0a1323"), KOLOR_TURKUS_NEON))
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
	wroc.pressed.connect(kontekst.konfiguracja_online.wroc)
	ekran_online.add_child(wroc)
	_styluj_scrollbar_multiplayer(przewijanie.get_v_scroll_bar())

	kontekst.konfiguracja_online.pokaz_ekran_requested.connect(pokaz_ekran)
	kontekst.konfiguracja_online.pokaz_wybor_trybu_requested.connect(_pokaz_wybor_trybu)
	var kontrolki = KontrolkiKonfiguracjiOnline.new()
	kontrolki.ekran = ekran_online
	kontrolki.wybor = wybor_online
	kontrolki.host = ekran_host_online
	kontrolki.dolacz = ekran_dolacz_online
	kontrolki.tytul = tytul_online
	kontrolki.instrukcje = instrukcje_polaczenia
	kontrolki.status = status_online
	kontrolki.adres = adres_online
	kontrolki.nazwa_hosta = nazwa_hosta_online
	kontrolki.nazwa_dolaczajacego = nazwa_dolaczajacego_online
	kontrolki.warunek = warunek_online
	kontrolki.wartosc_warunku = wartosc_warunku_online
	kontrolki.etykieta_warunku = etykieta_warunku_online
	kontrolki.wskazowka_warunku = wskazowka_warunku_online
	kontrolki.adresy_hosta = adresy_hosta_label
	kontrolki.kopiuj_adres = kopiuj_adres_hosta
	kontrolki.tryb_arena = przycisk_tryb_online_arena
	kontekst.konfiguracja_online.inicjalizuj(kontrolki)


func _styluj_scrollbar_multiplayer(pasek: VScrollBar) -> void:
	pasek.custom_minimum_size.x = 14
	pasek.add_theme_constant_override("grabber_min_size", 52)
	var tor = StyleBoxFlat.new()
	tor.bg_color = Color("#081321", 0.9)
	tor.border_color = Color(KOLOR_TURKUS_NEON, 0.14)
	tor.set_border_width_all(0)
	tor.set_corner_radius_all(7)
	pasek.add_theme_stylebox_override("scroll", tor)
	pasek.add_theme_stylebox_override("scroll_focus", tor)
	var uchwyt = StyleBoxFlat.new()
	uchwyt.bg_color = Color("#315b70")
	uchwyt.border_color = Color(KOLOR_TURKUS_NEON, 0.62)
	uchwyt.set_border_width_all(0)
	uchwyt.set_corner_radius_all(7)
	uchwyt.shadow_color = Color(KOLOR_TURKUS_NEON, 0.12)
	uchwyt.shadow_size = 0
	pasek.add_theme_stylebox_override("grabber", uchwyt)
	var hover = uchwyt.duplicate()
	hover.bg_color = Color("#3f8298")
	hover.border_color = Color(KOLOR_TURKUS_NEON, 0.92)
	hover.shadow_color = Color(KOLOR_TURKUS_NEON, 0.28)
	hover.shadow_size = 0
	pasek.add_theme_stylebox_override("grabber_highlight", hover)


func _dodaj_karte_wyboru(ekran: VBoxContainer, tytul: String, opis: String, akcent: Color, akcja: Akcja, tylko_przycisk: bool = false) -> void:
	var przycisk = Button.new()
	przycisk.name = "Wybor" + str(ekran.get_child_count())
	przycisk.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ekran.add_child(przycisk)
	_styluj_przycisk(przycisk)
	if tylko_przycisk:
		przycisk.text = tytul
	else:
		StylMenu.dodaj_opis_trybu(przycisk, tytul, opis, akcent, FONT_ARCADE)
	przycisk.pressed.connect(_emituj_akcje.bind(akcja))


func _emituj_akcje(akcja: Akcja) -> void:
	akcja_zadana.emit(akcja)


func _styluj_przycisk(przycisk: Button) -> void:
	StylMenu.styluj_przycisk(przycisk, Vector2(420.0, 52.0), KOLOR_TURKUS_NEON, Color("#14243a"), Color("#31506b"), Color("#1b3049"), Color("#102638"), Color("#35bcd5"), 21)


func pokaz_ekran(ekran: Control) -> void:
	var wszystkie_ekrany: Array[Control] = [
		kontekst.ekran_glowny, kontekst.wybor_trybu, wybor_gier_jeden, wybor_gier_dwoch,
		kontekst.opcje_jeden_gracz, kontekst.opcje_dwoch_graczy, kontekst.ekran_ustawien
	]
	if is_instance_valid(ekran_online):
		wszystkie_ekrany.append(ekran_online)
	kontekst.tlo.ustaw_przyciemnienie(ekran != kontekst.ekran_glowny)
	for ekran_menu in wszystkie_ekrany:
		ekran_menu.hide()
	ekran.show()
	ekran.modulate.a = 0.0
	if is_instance_valid(animacja_ekranu):
		animacja_ekranu.kill()
	ekran.pivot_offset = ekran.size * 0.5
	ekran.scale = Vector2.ONE * 0.985
	animacja_ekranu = kontekst.center_container.create_tween()
	animacja_ekranu.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animacja_ekranu.parallel().tween_property(ekran, "modulate:a", 1.0, 0.20)
	animacja_ekranu.parallel().tween_property(ekran, "scale", Vector2.ONE, 0.24)


func _pokaz_wybor_trybu() -> void:
	pokaz_ekran(kontekst.wybor_trybu)


