class_name ObslugaOnline
extends Node

const WYMAGANE_POLA_STANU = [
	"pilka", "lewa_y", "prawa_y", "dash_lewy", "dash_prawy",
	"wynik_gracza", "wynik_ai", "koniec", "runda_online", "czas_meczu",
	"stat_odbicia_gracza", "stat_odbicia_rywala", "stat_mocne_odbicia_gracza",
	"stat_mocne_odbicia_rywala", "biezaca_wymiana", "najdluzsza_wymiana",
	"komunikat_konca", "czas_pozostaly", "odbicia_paletki", "odbicia_sciany", "arena"
]

signal gra_rozpoczeta
signal gra_zatrzymana
signal mecz_zakonczony(tekst: String)

const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")

var gra: GraPongAPI
var czas_wejscia = 0.0
var czas_stanu = 0.0
var poprzedni_stan: Dictionary = {}
var aktualny_stan: Dictionary = {}
var komunikat: Label
var etykieta_warunku: Label
var czas_pozostaly = 0.0
var tekst_konca = ""
var powrot_zaplany = false
var przewidywane_prawe_y = 0.0
var licznik_odbic_paletka = 0
var licznik_odbic_sciana = 0
var odebrane_odbicia_paletka = 0
var odebrane_odbicia_sciana = 0
var otrzymano_pierwszy_stan = false


func uruchom(gra_glowna: GraPongAPI) -> void:
	gra = gra_glowna
	czas_pozostaly = Siec.limit_czasu_meczu
	set_process(true)
	_utworz_interfejs()
	Siec.gracz_polaczyl.connect(_gracz_polaczyl)
	Siec.gracz_rozlaczyl.connect(_gracz_rozlaczyl)
	Siec.polaczono_z_hostem.connect(_polaczono_z_hostem)
	Siec.host_rozlaczyl.connect(_host_rozlaczyl)
	Siec.nazwa_gracza_2_zmieniona.connect(_zmieniono_nazwe_gracza)

	gra.paletka_gracza.set_physics_process(false)
	gra.paletka_rywala.set_physics_process(false)
	_pilka().set_physics_process(false)
	gra.bonus_manager.set_process(false)
	gra.bonus_manager.set_physics_process(false)

	if Siec.czy_host():
		_ustaw_komunikat("Oczekiwanie na drugiego gracza", Color("#55e7ff"))
		var polaczeni = multiplayer.get_peers()
		if not polaczeni.is_empty():
			_gracz_polaczyl(polaczeni[0])
	else:
		przewidywane_prawe_y = _prawa_paletka().position.y
		_ustaw_komunikat("Łączenie z hostem…", Color("#55e7ff"))
		if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			_polaczono_z_hostem()


func _pilka() -> Pilka:
	return gra.pilka_glowna


func _lewa_paletka() -> PaletkaBazowa:
	return gra.paletka_gracza


func _prawa_paletka() -> PaletkaBazowa:
	return gra.paletka_rywala


func _przebieg_meczu() -> PrzebiegMeczu:
	return gra.przebieg_meczu


func _manager_areny() -> ArenaManagerAPI:
	return gra.arena_manager


func _process(delta: float) -> void:
	if Siec.czy_host() and Siec.warunek_meczu == "czas" and not multiplayer.get_peers().is_empty() and not gra.mecz_zakonczony:
		Siec.pozostaly_czas_meczu = maxf(0.0, Siec.pozostaly_czas_meczu - delta)
		czas_pozostaly = Siec.pozostaly_czas_meczu
		if czas_pozostaly <= 0.0:
			_przebieg_meczu().zakoncz_po_czasie()
	_odswiez_etykiete_warunku()
	_obsluz_siec(delta)


func _utworz_interfejs() -> void:
	var warstwa = CanvasLayer.new()
	warstwa.name = "WarstwaStatusuOnline"
	warstwa.layer = 20
	add_child(warstwa)
	komunikat = Label.new()
	komunikat.name = "StatusOnline"
	komunikat.position = Vector2(0.0, 0.0)
	komunikat.size = Vector2(get_viewport().get_visible_rect().size.x, 26.0)
	komunikat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	komunikat.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	komunikat.add_theme_font_override("font", FONT_ARCADE)
	komunikat.add_theme_font_size_override("font_size", 13)
	komunikat.add_theme_color_override("font_color", Color("#55e7ff"))
	warstwa.add_child(komunikat)
	etykieta_warunku = Label.new()
	etykieta_warunku.name = "WarunekMeczuOnline"
	etykieta_warunku.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	etykieta_warunku.offset_top = 78.0
	etykieta_warunku.offset_bottom = 106.0
	etykieta_warunku.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_warunku.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etykieta_warunku.add_theme_font_override("font", FONT_ARCADE)
	etykieta_warunku.add_theme_font_size_override("font_size", 20)
	etykieta_warunku.add_theme_color_override("font_color", Color("#ffd27a"))
	warstwa.add_child(etykieta_warunku)
	_odswiez_etykiete_warunku()


func _odswiez_etykiete_warunku() -> void:
	if not is_instance_valid(etykieta_warunku):
		return
	if Siec.warunek_meczu == "czas":
		var sekundy = maxi(0, ceili(czas_pozostaly))
		var minuty = floori(float(sekundy) / 60.0)
		etykieta_warunku.text = "%02d:%02d" % [minuty, sekundy % 60]
	else:
		etykieta_warunku.text = "Do %d punktów" % Siec.limit_punktow_meczu


func _ustaw_komunikat(tekst: String, kolor: Color = Color("#55e7ff")) -> void:
	if not is_instance_valid(komunikat):
		return
	komunikat.text = tekst
	komunikat.add_theme_color_override("font_color", kolor)
	komunikat.show()


func _gracz_polaczyl(id: int) -> void:
	if not Siec.czy_host() or not multiplayer.get_peers().has(id):
		return
	_ustaw_komunikat("Gracz dołączył — powodzenia!", Color("#55e7ff"))
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(komunikat) and komunikat.text == "Gracz dołączył — powodzenia!":
			komunikat.hide()
	)
	gra_rozpoczeta.emit()


func _zmieniono_nazwe_gracza(_nazwa: String) -> void:
	gra._odswiez_rysowanie()


func _gracz_rozlaczyl(_id: int) -> void:
	if not Siec.czy_host():
		return
	_prawa_paletka().sieciowy_kierunek = 0.0
	_prawa_paletka().sieciowy_dash_zadany = false
	gra_zatrzymana.emit()
	_ustaw_komunikat("Gracz rozłączony — oczekiwanie na kolejnego", Color("#ffb454"))


func _polaczono_z_hostem() -> void:
	if Siec.czy_klient():
		_ustaw_komunikat("Połączono z hostem", Color("#55e7ff"))


func _host_rozlaczyl() -> void:
	if not Siec.czy_klient() or powrot_zaplany:
		return
	powrot_zaplany = true
	_ustaw_komunikat("Host zakończył połączenie — wracam do menu…", Color("#ff647a"))
	get_tree().create_timer(2.0).timeout.connect(_wroc_do_menu)


func _wroc_do_menu() -> void:
	Siec.rozlacz()
	Ustawienia.tryb = "bot"
	get_tree().change_scene_to_file("res://menu.tscn")


func _obsluz_siec(delta: float) -> void:
	if Siec.czy_klient():
		_obsluz_klienta(delta)
		return
	if not Siec.czy_host() or multiplayer.get_peers().is_empty():
		return
	czas_wejscia += delta
	if czas_wejscia < 1.0 / 30.0:
		return
	czas_wejscia = 0.0
	var manager_areny := _manager_areny()
	var przebieg_meczu := _przebieg_meczu()
	var dane_areny: Dictionary = manager_areny.dane_sieciowe() if manager_areny != null else {}
	rpc("online_odbierz_stan", {
		"pilka": _pilka().position,
		"lewa_y": _lewa_paletka().position.y,
		"prawa_y": _prawa_paletka().position.y,
		"dash_lewy": _lewa_paletka().dash_odnowienie,
		"dash_prawy": _prawa_paletka().dash_odnowienie,
		"wynik_gracza": przebieg_meczu.wynik_gracza,
		"wynik_ai": przebieg_meczu.wynik_ai,
		"koniec": przebieg_meczu.mecz_zakonczony,
		"czas_meczu": przebieg_meczu.czas_meczu,
		"stat_odbicia_gracza": przebieg_meczu.stat_odbicia_gracza,
		"stat_odbicia_rywala": przebieg_meczu.stat_odbicia_rywala,
		"stat_mocne_odbicia_gracza": przebieg_meczu.stat_mocne_odbicia_gracza,
		"stat_mocne_odbicia_rywala": przebieg_meczu.stat_mocne_odbicia_rywala,
		"biezaca_wymiana": przebieg_meczu.biezaca_wymiana,
		"najdluzsza_wymiana": przebieg_meczu.najdluzsza_wymiana,
		"komunikat_konca": tekst_konca,
		"czas_pozostaly": Siec.pozostaly_czas_meczu,
		"runda_online": Siec.runda_online,
		"odbicia_paletki": licznik_odbic_paletka,
		"odbicia_sciany": licznik_odbic_sciana,
		"arena": dane_areny
	})


func _obsluz_klienta(delta: float) -> void:
	var paletka_prawa: PaletkaBazowa = _prawa_paletka()
	if is_instance_valid(komunikat) and komunikat.text == "Połączono z hostem":
		komunikat.hide()
	var kierunek = 0.0 if Siec.pauza_lokalna else Input.get_axis("lewy_gora", "lewy_dol")
	czas_wejscia += delta
	if czas_wejscia >= 1.0 / 30.0 and _klient_polaczony():
		czas_wejscia = 0.0
		rpc_id(1, "online_ustaw_kierunek", kierunek)
	if not Siec.pauza_lokalna and Input.is_action_just_pressed("dash_gracza_1") and _klient_polaczony():
		rpc_id(1, "online_zadaj_dash")
		if _prawa_paletka().dash_odnowienie <= 0.0:
			var dash_kierunek = signf(kierunek) if not is_zero_approx(kierunek) else _prawa_paletka().ostatni_kierunek
			paletka_prawa._rozpocznij_dash(dash_kierunek)
	if not Siec.pauza_lokalna and not is_zero_approx(kierunek):
		_prawa_paletka().ostatni_kierunek = signf(kierunek)
	if paletka_prawa.dash_aktywne:
		paletka_prawa._aktualizuj_dash(delta)
		paletka_prawa.position.y += paletka_prawa.velocity.y * delta
		paletka_prawa._ogranicz_pozycje_y()
		przewidywane_prawe_y = paletka_prawa.position.y
	else:
		var polowa_paletki = paletka_prawa._polowa_wysokosci_paletki()
		przewidywane_prawe_y = clampf(
			przewidywane_prawe_y + kierunek * 400.0 * delta,
			Ustawienia.gorna_granica + polowa_paletki,
			Ustawienia.dolna_granica - polowa_paletki
		)
		paletka_prawa.position.y = przewidywane_prawe_y
	if not aktualny_stan.is_empty():
		czas_stanu += delta
		var postep = clampf(czas_stanu / 0.1, 0.0, 1.0)
		_pilka().position = (poprzedni_stan["pilka"] as Vector2).lerp(aktualny_stan["pilka"], postep)
		_lewa_paletka().position.y = lerpf(float(poprzedni_stan["lewa_y"]), float(aktualny_stan["lewa_y"]), postep)


func _klient_polaczony() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func odnotuj_odbicie_paletki() -> void:
	if Ustawienia.tryb == "online" and Siec.czy_host():
		licznik_odbic_paletka += 1


func odnotuj_odbicie_sciany() -> void:
	if Ustawienia.tryb == "online" and Siec.czy_host():
		licznik_odbic_sciana += 1


@rpc("any_peer", "call_remote", "unreliable_ordered")
func online_ustaw_kierunek(kierunek: float) -> void:
	if not Siec.czy_host() or not _nadawca_jest_graczem():
		return
	_prawa_paletka().sieciowy_kierunek = clampf(kierunek, -1.0, 1.0)


@rpc("any_peer", "call_remote", "reliable")
func online_zadaj_dash() -> void:
	if not Siec.czy_host() or not _nadawca_jest_graczem():
		return
	_prawa_paletka().sieciowy_dash_zadany = true


func ponow_rozgrywke() -> bool:
	if Siec.czy_klient():
		_ustaw_komunikat("Prośba o ponowne rozpoczęcie meczu…", Color("#55e7ff"))
		rpc_id(1, "online_zadaj_ponowne")
		return true
	if Siec.czy_host():
		Siec.runda_online += 1
		Siec.pozostaly_czas_meczu = Siec.limit_czasu_meczu
		get_tree().reload_current_scene()
		return true
	return false


@rpc("any_peer", "call_remote", "reliable")
func online_zadaj_ponowne() -> void:
	if not Siec.czy_host() or not _nadawca_jest_graczem() or not gra.mecz_zakonczony:
		return
	Siec.runda_online += 1
	Siec.pozostaly_czas_meczu = Siec.limit_czasu_meczu
	get_tree().reload_current_scene()


func _nadawca_jest_graczem() -> bool:
	var polaczeni = multiplayer.get_peers()
	return not polaczeni.is_empty() and multiplayer.get_remote_sender_id() == polaczeni[0]


@rpc("authority", "call_remote", "unreliable_ordered")
func online_odbierz_stan(stan: Dictionary) -> void:
	if not Siec.czy_klient():
		return
	for pole in WYMAGANE_POLA_STANU:
		if not stan.has(pole):
			push_warning("Odrzucono niekompletny stan meczu online; brak pola: %s" % pole)
			return
	if typeof(stan["arena"]) != TYPE_DICTIONARY:
		push_warning("Odrzucono niekompletny stan meczu online; pole arena ma nieprawidłowy typ.")
		return
	if typeof(stan["pilka"]) != TYPE_VECTOR2 or typeof(stan["koniec"]) != TYPE_BOOL or typeof(stan["komunikat_konca"]) != TYPE_STRING:
		push_warning("Odrzucono stan meczu online z nieprawidłowym typem danych.")
		return
	for pole in ["lewa_y", "prawa_y", "dash_lewy", "dash_prawy", "czas_meczu", "czas_pozostaly"]:
		if typeof(stan[pole]) not in [TYPE_FLOAT, TYPE_INT]:
			push_warning("Odrzucono stan meczu online; pole %s ma nieprawidłowy typ." % pole)
			return
	var manager_areny := _manager_areny()
	if manager_areny != null and stan.has("arena"):
		manager_areny.ustaw_stan_zdalny(stan["arena"])
	if int(stan["runda_online"]) != Siec.runda_online:
		Siec.runda_online = int(stan["runda_online"])
		get_tree().reload_current_scene()
		return
	_przebieg_meczu().ustaw_stan_zdalny(stan)
	if not otrzymano_pierwszy_stan:
		odebrane_odbicia_paletka = int(stan["odbicia_paletki"])
		odebrane_odbicia_sciana = int(stan["odbicia_sciany"])
		otrzymano_pierwszy_stan = true
	var wynik_gracza_poprzedni = int(aktualny_stan.get("wynik_gracza", stan["wynik_gracza"]))
	var wynik_rywala_poprzedni = int(aktualny_stan.get("wynik_ai", stan["wynik_ai"]))
	var nowe_odbicia_paletki = int(stan["odbicia_paletki"]) - odebrane_odbicia_paletka
	var nowe_odbicia_sciany = int(stan["odbicia_sciany"]) - odebrane_odbicia_sciana
	var lewa = _lewa_paletka()
	var prawa = _prawa_paletka()
	var poprzedni_cooldown_gracza = lewa.dash_odnowienie
	var poprzedni_cooldown_prawej = prawa.dash_odnowienie
	var prawa_y = float(stan["prawa_y"])
	przewidywane_prawe_y += clampf(prawa_y - przewidywane_prawe_y, -65.0, 65.0) * 0.4
	poprzedni_stan = aktualny_stan.duplicate() if not aktualny_stan.is_empty() else stan.duplicate()
	aktualny_stan = stan
	czas_stanu = 0.0
	(gra.etykieta_wyniku_gracza).text = str(stan["wynik_gracza"])
	(gra.etykieta_wyniku_rywala).text = str(stan["wynik_ai"])
	czas_pozostaly = float(stan.get("czas_pozostaly", czas_pozostaly))
	_odswiez_etykiete_warunku()
	lewa.dash_odnowienie = float(stan["dash_lewy"])
	prawa.dash_odnowienie = float(stan["dash_prawy"])
	if poprzedni_cooldown_gracza <= 0.0 and lewa.dash_odnowienie > 0.0:
		if not poprzedni_stan.is_empty():
			lewa.dash_efekt_kierunek = signf(float(stan["lewa_y"]) - float(poprzedni_stan["lewa_y"]))
		lewa.dash_efekt_czas = 0.28
		lewa.dzwiek_dasha.play()
		lewa.queue_redraw()
	if poprzedni_cooldown_prawej <= 0.0 and prawa.dash_odnowienie > 0.0:
		if not poprzedni_stan.is_empty():
			prawa.dash_efekt_kierunek = signf(float(stan["prawa_y"]) - float(poprzedni_stan["prawa_y"]))
		prawa.dash_efekt_czas = 0.28
		prawa.dzwiek_dasha.play()
		prawa.queue_redraw()
	(gra.wskazniki_dasha).queue_redraw()
	if nowe_odbicia_paletki > 0:
		_pilka().dzwiek_paletka.play()
	if nowe_odbicia_sciany > 0:
		_pilka().dzwiek_sciana.play()
	odebrane_odbicia_paletka = int(stan["odbicia_paletki"])
	odebrane_odbicia_sciana = int(stan["odbicia_sciana"])
	if int(stan["wynik_gracza"]) != wynik_gracza_poprzedni or int(stan["wynik_ai"]) != wynik_rywala_poprzedni:
		gra.odtworz_dzwiek_punktu()
	if bool(stan["koniec"]) and not gra.mecz_zakonczony:
		mecz_zakonczony.emit(str(stan.get("komunikat_konca", "Koniec meczu — wynik %d : %d" % [stan["wynik_gracza"], stan["wynik_ai"]])))


func ustaw_tekst_konca(tekst: String) -> void:
	tekst_konca = tekst


func _odswiez_rysowanie() -> void:
	gra._odswiez_rysowanie()

