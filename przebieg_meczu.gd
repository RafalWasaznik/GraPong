class_name PrzebiegMeczu
extends Node

const SCENA_PILKI_ENDLESS = preload("res://piłka.tscn")

const SZEROKOSC_INFO_ENDLESS = 440.0
const CZCIONKA_ENDLESS = preload("res://assets/fonts/Oxanium.ttf")
const KOLOR_TURKUS_ENDLESS = Color("#55e7ff")
const KOLOR_FIOLET_ENDLESS = Color("#ad83ff")

var gra: GraPongAPI
var wynik_gracza = 0
var wynik_ai = 0
var czas_meczu = 0.0
var stat_odbicia_gracza = 0
var stat_odbicia_rywala = 0
var stat_mocne_odbicia_gracza = 0
var stat_mocne_odbicia_rywala = 0
var biezaca_wymiana = 0
var najdluzsza_wymiana = 0
var endless_odbicia = 0
var wybor_oczekuje: bool = false
var run_state: RunState
var rejestr_ulepszen: Array[UlepszenieRun] = UlepszenieRun.katalog()
var wybor_ulepszenia: WyborUlepszenia
var endless_wysokosc_startowa = 120.0
var mecz_zakonczony = false
var endless_info: HBoxContainer
var endless_wartosci: Array[Label] = []
var endless_powiadomienie: Label


func uruchom(gra_glowna: GraPongAPI) -> void:
	gra = gra_glowna
	if Ustawienia.tryb == "endless":
		var ksztalt_paletki = gra.lewa_paletka().kolizja.shape as RectangleShape2D
		if ksztalt_paletki != null:
			endless_wysokosc_startowa = ksztalt_paletki.size.y
		run_state = RunState.new()
		gra.pilka().run_state = run_state
		gra.lewa_paletka().run_state = run_state
		wybor_ulepszenia = WyborUlepszenia.new()
		gra.add_child(wybor_ulepszenia)
		wybor_ulepszenia.wybrano.connect(_zastosuj_stan_endless)
		_zastosuj_stan_endless()


func _physics_process(delta: float) -> void:
	if run_state != null and not mecz_zakonczony:
		run_state.aktualizuj_czas(delta)


func _process(delta: float) -> void:
	if not mecz_zakonczony:
		czas_meczu += delta
		if Ustawienia.tryb == "endless" and is_instance_valid(endless_info):
			_odswiez_info_endless()


func zarejestruj_odbicie(strona: String, mocne: bool) -> void:
	if strona == "gracz":
		stat_odbicia_gracza += 1
		if mocne:
			stat_mocne_odbicia_gracza += 1
	else:
		stat_odbicia_rywala += 1
		if mocne:
			stat_mocne_odbicia_rywala += 1
	biezaca_wymiana += 1
	najdluzsza_wymiana = maxi(najdluzsza_wymiana, biezaca_wymiana)


func ustaw_stan_zdalny(stan: StanMeczuOnline) -> void:
	wynik_gracza = stan.wynik_gracza
	wynik_ai = stan.wynik_ai
	czas_meczu = stan.czas_meczu
	stat_odbicia_gracza = stan.stat_odbicia_gracza
	stat_odbicia_rywala = stan.stat_odbicia_rywala
	stat_mocne_odbicia_gracza = stan.stat_mocne_odbicia_gracza
	stat_mocne_odbicia_rywala = stan.stat_mocne_odbicia_rywala
	biezaca_wymiana = stan.biezaca_wymiana
	najdluzsza_wymiana = stan.najdluzsza_wymiana


func _on_punkt(strona: String) -> void:
	if mecz_zakonczony:
		return
	gra.zresetuj_rozpad_punktu()
	gra.lewa_paletka().reset_po_punkcie()
	gra.prawa_paletka().reset_po_punkcie()
	if Ustawienia.tryb == "endless":
		run_state.lives -= 1
		biezaca_wymiana = 0
		gra.odtworz_dzwiek_punktu()
		_zastosuj_stan_endless()
		if run_state.lives <= 0:
			_zakoncz_endless()
		else:
			gra.lewa_paletka().set_physics_process(true)
			run_state.slowRemaining = 0.0
			_odnow_pilki_endless.call_deferred()
		return

	gra.odtworz_dzwiek_punktu()
	biezaca_wymiana = 0
	if strona == "lewa":
		wynik_ai += 1
	else:
		wynik_gracza += 1

	gra.ustaw_wyniki(wynik_gracza, wynik_ai)
	if Ustawienia.tryb != "online":
		(gra.bonusy()).wyczysc_po_punkcie()
	var arena_manager := gra.menedzer_areny()
	if arena_manager != null:
		arena_manager.po_zdobyciu_punktu()
	gra.odswiez_rysowanie()

	var pilka_glowna := gra.pilka()
	for pilka in get_tree().get_nodes_in_group("pilki"):
		if pilka != pilka_glowna:
			pilka.queue_free()

	var z_botem = Ustawienia.tryb == "bot" or (Ustawienia.tryb == "arena" and not Ustawienia.arena_dwoch_graczy)
	if Ustawienia.tryb == "online" and Siec.warunek_meczu == "czas":
		gra.lewa_paletka().set_physics_process(true)
		gra.prawa_paletka().set_physics_process(true)
		pilka_glowna.set_physics_process(true)
		pilka_glowna.reset()
	elif Ustawienia.tryb == "online" and wynik_gracza >= Siec.limit_punktow_meczu:
		zakoncz_mecz("Wygrywa %s!" % Siec.nazwa_gracza_1)
	elif Ustawienia.tryb == "online" and wynik_ai >= Siec.limit_punktow_meczu:
		zakoncz_mecz("Wygrywa %s!" % Siec.nazwa_gracza_2)
	elif wynik_gracza >= Ustawienia.limit_punktow:
		zakoncz_mecz("Wygrałeś!" if z_botem else "Wygrywa gracz 1!")
	elif wynik_ai >= Ustawienia.limit_punktow:
		zakoncz_mecz("Przegrałeś!" if z_botem else "Wygrywa gracz 2!")
	else:
		gra.lewa_paletka().set_physics_process(true)
		gra.prawa_paletka().set_physics_process(true)
		pilka_glowna.set_physics_process(true)
		pilka_glowna.reset()


func zarejestruj_odbicie_endless(idealne: bool) -> void:
	if Ustawienia.tryb != "endless" or mecz_zakonczony or run_state == null:
		return
	run_state.zarejestruj_odbicie(idealne)
	endless_odbicia = run_state.hits
	wynik_gracza = floori(run_state.score)
	wynik_ai = run_state.lives
	gra.ustaw_wyniki(wynik_gracza, run_state.lives)
	if run_state.hits % RunState.UPGRADE_EVERY_HITS == 0 and not wybor_oczekuje and not run_state.wybor_aktywny:
		wybor_oczekuje = true
		_pokaz_wybor_endless.call_deferred()
	_odswiez_info_endless()


func _pokaz_wybor_endless() -> void:
	wybor_oczekuje = false
	if mecz_zakonczony or run_state == null:
		return
	var oferty := UlepszenieRun.losuj(run_state, rejestr_ulepszen)
	if not oferty.is_empty():
		wybor_ulepszenia.pokaz(run_state, oferty)


func _zastosuj_stan_endless() -> void:
	gra.lewa_paletka().ustaw_wysokosc(endless_wysokosc_startowa * run_state.paddleWidthMult)
	gra.lewa_paletka()._ogranicz_pozycje_y()
	wynik_ai = run_state.lives
	wynik_gracza = floori(run_state.score)
	gra.ustaw_wyniki(wynik_gracza, run_state.lives)
	_uzupelnij_pilki_endless.call_deferred()
	_odswiez_info_endless()


func _uzupelnij_pilki_endless() -> void:
	if run_state == null or mecz_zakonczony or run_state.lives <= 0:
		return
	var liczba := get_tree().get_nodes_in_group("pilki").size()
	while liczba < run_state.ballCount:
		var nowa := SCENA_PILKI_ENDLESS.instantiate() as Pilka
		nowa.run_state = run_state
		nowa.punkt.connect(_on_punkt)
		nowa.odbicie_gracza.connect(zarejestruj_odbicie_endless)
		nowa.statystyki_odbicia.connect(zarejestruj_odbicie)
		gra.add_child(nowa)
		_ustaw_start_pilki_endless(nowa, liczba)
		liczba += 1


func _ustaw_start_pilki_endless(pilka: Pilka, indeks: int) -> void:
	var odstep := minf(100.0, (Ustawienia.dolna_granica - Ustawienia.gorna_granica) / 4.0)
	pilka.position.y += (0.0 if indeks == 0 else (-odstep if indeks == 1 else odstep))
	pilka.srodek_intro = pilka.position


func _odnow_pilki_endless() -> void:
	if run_state == null or mecz_zakonczony:
		return
	_uzupelnij_pilki_endless()
	var indeks := 0
	for wezel in get_tree().get_nodes_in_group("pilki"):
		var pilka := wezel as Pilka
		pilka.reset()
		_ustaw_start_pilki_endless(pilka, indeks)
		indeks += 1


func _zakoncz_endless() -> void:
	zakoncz_mecz("Koniec rozgrywki")
	for pilka in get_tree().get_nodes_in_group("pilki"):
		(pilka as Pilka).run_state = null
	gra.lewa_paletka().run_state = null
	wybor_ulepszenia.stan = null
	wybor_ulepszenia.oferty.clear()
	run_state = null


func zakoncz_po_czasie() -> void:
	if wynik_gracza > wynik_ai:
		zakoncz_mecz("Koniec czasu — wygrywa %s!" % Siec.nazwa_gracza_1)
	elif wynik_ai > wynik_gracza:
		zakoncz_mecz("Koniec czasu — wygrywa %s!" % Siec.nazwa_gracza_2)
	else:
		zakoncz_mecz("Koniec czasu — remis!")


func dodaj_info_endless() -> void:
	endless_info = HBoxContainer.new()
	endless_info.name = "InformacjaEndless"
	endless_info.custom_minimum_size = Vector2(SZEROKOSC_INFO_ENDLESS, 58.0)
	endless_info.add_theme_constant_override("separation", 10)
	endless_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endless_info.z_index = 10
	_dodaj_grupe_info_endless(endless_info, "DO ULEPSZENIA", 150.0, KOLOR_TURKUS_ENDLESS)
	_dodaj_grupe_info_endless(endless_info, "ŻYCIA", 150.0, Color("#b8c9dc"))
	_dodaj_grupe_info_endless(endless_info, "ULEPSZENIA", 120.0, KOLOR_FIOLET_ENDLESS)
	gra.add_child(endless_info)
	endless_powiadomienie = Label.new()
	endless_powiadomienie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endless_powiadomienie.add_theme_font_size_override("font_size", 14)
	endless_powiadomienie.add_theme_color_override("font_color", KOLOR_TURKUS_ENDLESS)
	endless_powiadomienie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endless_powiadomienie.size = Vector2(560.0, 42.0)
	gra.add_child(endless_powiadomienie)
	get_viewport().size_changed.connect(_ustaw_pozycje_info_endless)
	_ustaw_pozycje_info_endless()
	_odswiez_info_endless()


func _dodaj_grupe_info_endless(uklad: HBoxContainer, tytul: String, szerokosc: float, akcent: Color, rozmiar_wartosci: int = 15) -> void:
	var karta := PanelContainer.new()
	karta.custom_minimum_size = Vector2(szerokosc, 58.0)
	karta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color("#101f34d9")
	styl.border_color = Color(akcent, 0.45)
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(10)
	styl.content_margin_left = 6.0
	styl.content_margin_right = 6.0
	styl.content_margin_top = 4.0
	styl.content_margin_bottom = 4.0
	karta.add_theme_stylebox_override("panel", styl)
	uklad.add_child(karta)
	var kolumna := VBoxContainer.new()
	kolumna.alignment = BoxContainer.ALIGNMENT_CENTER
	kolumna.add_theme_constant_override("separation", 1)
	kolumna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	karta.add_child(kolumna)
	var etykieta := Label.new()
	etykieta.text = tytul
	etykieta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta.add_theme_font_override("font", CZCIONKA_ENDLESS)
	etykieta.add_theme_font_size_override("font_size", 10)
	etykieta.add_theme_color_override("font_color", Color("#9fb3ca"))
	etykieta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolumna.add_child(etykieta)
	var wartosc := Label.new()
	wartosc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wartosc.add_theme_font_override("font", CZCIONKA_ENDLESS)
	wartosc.add_theme_font_size_override("font_size", rozmiar_wartosci)
	wartosc.add_theme_color_override("font_color", akcent)
	wartosc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolumna.add_child(wartosc)
	endless_wartosci.append(wartosc)


func _ustaw_pozycje_info_endless() -> void:
	var wymiar = get_viewport().get_visible_rect().size
	var szerokosc_planszy = Ustawienia.prawa_granica - Ustawienia.lewa_granica
	var szerokosc = minf(SZEROKOSC_INFO_ENDLESS, maxf(0.0, szerokosc_planszy - 24.0))
	var prawa_krawedz = minf(Ustawienia.prawa_granica - 12.0, wymiar.x - 12.0)
	var x = prawa_krawedz - szerokosc
	var y = minf(Ustawienia.dolna_granica + 12.0, wymiar.y - 70.0)
	if is_instance_valid(endless_info):
		endless_info.position = Vector2(x, y)
		endless_info.size = Vector2(szerokosc, 58.0)
	if is_instance_valid(endless_powiadomienie):
		endless_powiadomienie.position = Vector2(
			(Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5 - 280.0,
			Ustawienia.gorna_granica + 42.0
		)


func _odswiez_info_endless() -> void:
	if endless_info == null or run_state == null:
		return
	var pozostaly_wybor := false
	var posiadane: PackedStringArray = []
	for ulepszenie in rejestr_ulepszen:
		var stosy := run_state.liczba_stosow(ulepszenie.id)
		pozostaly_wybor = pozostaly_wybor or stosy < ulepszenie.maxStacks
		if stosy > 0:
			posiadane.append("%s ×%d" % [ulepszenie.nazwa, stosy])
	endless_wartosci[0].text = "%d/%d" % [run_state.hits % RunState.UPGRADE_EVERY_HITS, RunState.UPGRADE_EVERY_HITS] if pozostaly_wybor else "MAKSIMUM"
	endless_wartosci[1].text = "%d/%d" % [run_state.lives, run_state.maxLives]
	endless_wartosci[2].text = str(run_state.ownedStacks.size())
	endless_powiadomienie.text = "  |  ".join(posiadane) if not posiadane.is_empty() else "Co %d odbić wybierasz ulepszenie" % RunState.UPGRADE_EVERY_HITS


func zakoncz_mecz(tekst: String) -> void:
	if mecz_zakonczony:
		return
	mecz_zakonczony = true
	if Ustawienia.tryb == "online":
		gra.ustaw_tekst_konca_online(tekst)
	gra.pokaz_wyniki(false)
	(gra.ekran_konca_meczu()).pokaz(tekst, pobierz_podsumowanie())
	if is_instance_valid(endless_info):
		endless_info.hide()
	if is_instance_valid(endless_powiadomienie):
		endless_powiadomienie.hide()
	gra.ukryj_informacje_graczowi()
	gra.odswiez_rysowanie()
	(gra.bonusy()).zatrzymaj()
	var arena_manager := gra.menedzer_areny()
	if arena_manager != null:
		arena_manager.zatrzymaj()
	for pilka in get_tree().get_nodes_in_group("pilki"):
		pilka.set_physics_process(false)
	gra.lewa_paletka().set_physics_process(false)
	gra.prawa_paletka().set_physics_process(false)


func pobierz_podsumowanie() -> PodsumowanieMeczu:
	var podsumowanie := PodsumowanieMeczu.new()
	podsumowanie.tryb = Ustawienia.tryb
	podsumowanie.czas_meczu = czas_meczu
	podsumowanie.wynik_gracza = wynik_gracza
	podsumowanie.wynik_ai = wynik_ai
	podsumowanie.odbicia_lacznie = stat_odbicia_gracza + stat_odbicia_rywala
	podsumowanie.mocne_odbicia_lacznie = stat_mocne_odbicia_gracza + stat_mocne_odbicia_rywala
	if Ustawienia.tryb == "endless" and run_state != null:
		podsumowanie.ulepszenia_endless = run_state.ownedStacks.size()
		podsumowanie.mnoznik_predkosci_endless = run_state.ballSpeedMult
		podsumowanie.rozmiar_paletki_endless = roundi(run_state.paddleWidthMult * 100.0)
	podsumowanie.najdluzsza_wymiana = najdluzsza_wymiana
	return podsumowanie
