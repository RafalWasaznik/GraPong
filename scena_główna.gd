extends Node2D

const SCENA_PILKI = preload("res://piłka.tscn")
const ARENA_MANAGER_SCRIPT = preload("res://arena_manager.gd")
const DZWIEK_PUNKTU = preload("res://punkt_sukces.wav")
const DZWIEKI_GRY = preload("res://dzwieki_gry.gd")
const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")

const CZAS_DODATKOWEJ_PILKI = 8.0
const MNOZNIK_PREDKOSCI_DODATKOWEJ = 0.8
const PREDKOSC_BAZOWA_ENDLESS = 560.0
const WYSOKOSC_SCIANY = 20.0
const ODSTEP_PALETKI = 30.0

const KOLOR_GRACZA = Color("#55d8f2")
const KOLOR_AI = Color("#ff647a")

var wynik_gracza = 0
var wynik_ai = 0
var czas_meczu = 0.0
var stat_odbicia_gracza = 0
var stat_odbicia_rywala = 0
var stat_mocne_odbicia_gracza = 0
var stat_mocne_odbicia_rywala = 0
var biezaca_wymiana = 0
var najdluzsza_wymiana = 0
var dzwiek_punktu: AudioStreamPlayer
var dzwiek_bonusu: AudioStreamPlayer
var dzwiek_modyfikatora: AudioStreamPlayer
var endless_odbicia = 0
var endless_wysokosc_startowa = 120.0
var endless_wysokosc_aktualna = 120.0
var endless_info: Label
var panel_informacyjny: PanelContainer
@onready var rysowanie_areny: Node2D = $RysowanieAreny
@onready var ekran_konca: CanvasLayer = $EkranKonca
var arena_manager: Node
var animacja_granic_areny: Tween
var animacja_wymiarow_areny: Tween
var animacja_strefy: Tween
var animacja_wysokosci_paletek: Tween
var postep_animacji_strefy = 0.0
var bazowe_wysokosci_paletek = Vector2.ZERO
var animacja_gumowej_sciany: Tween
var gumowa_sciana_strona = 0
var gumowa_sciana_y = 0.0
var gumowa_sciana_ugiecie = 0.0
var gumowa_sciana_kula_id = 0
var rozpad_punktu_trwa = false
var mecz_zakonczony = false
var online_czas_wejscia = 0.0
var online_czas_stanu = 0.0
var online_poprzedni_stan: Dictionary = {}
var online_aktualny_stan: Dictionary = {}
var online_komunikat: Label
var online_czas_etykieta: Label
var online_czas_pozostaly = 0.0
var online_tekst_konca = ""
var online_powrot_zaplany = false
var online_przewidywane_prawe_y = 0.0
var online_licznik_odbic_paletka = 0
var online_licznik_odbic_sciana = 0
var online_odebrane_odbicia_paletka = 0
var online_odebrane_odbicia_sciana = 0
var online_otrzymano_pierwszy_stan = false


func _enter_tree():
	Ustawienia.ustaw_geometrie_planszy()
	_ustaw_geometrie_sceny()


func _ustaw_geometrie_sceny():
	var lewa = Ustawienia.lewa_granica
	var prawa = Ustawienia.prawa_granica
	var gora = Ustawienia.gorna_granica
	var dol = Ustawienia.dolna_granica

	var srodek_x = (lewa + prawa) / 2.0
	var srodek_y = (gora + dol) / 2.0
	var szerokosc = prawa - lewa

	$"górna ściana".position = Vector2(srodek_x, gora)
	$"dolna ściana".position = Vector2(srodek_x, dol)

	_ustaw_ksztalt_sciany(
		$"górna ściana/CollisionShape2D",
		szerokosc
	)
	_ustaw_ksztalt_sciany(
		$"dolna ściana/CollisionShape2D",
		szerokosc
	)

	$Paletka.position = Vector2(lewa + ODSTEP_PALETKI, srodek_y)
	$PaletkaAI.position = Vector2(prawa - ODSTEP_PALETKI, srodek_y)


func _ustaw_ksztalt_sciany(kolizja: CollisionShape2D, szerokosc: float):
	if kolizja.shape is RectangleShape2D:
		if is_equal_approx((kolizja.shape as RectangleShape2D).size.x, szerokosc):
			return
		var ksztalt = kolizja.shape.duplicate() as RectangleShape2D
		ksztalt.size = Vector2(szerokosc, WYSOKOSC_SCIANY)
		kolizja.shape = ksztalt


func ustaw_granice_areny(gora: float, dol: float) -> void:
	Ustawienia.gorna_granica = gora
	Ustawienia.dolna_granica = dol

	var srodek_x = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5
	var szerokosc = Ustawienia.prawa_granica - Ustawienia.lewa_granica
	$"górna ściana".position = Vector2(srodek_x, gora)
	$"dolna ściana".position = Vector2(srodek_x, dol)
	_ustaw_ksztalt_sciany($"górna ściana/CollisionShape2D", szerokosc)
	_ustaw_ksztalt_sciany($"dolna ściana/CollisionShape2D", szerokosc)

	var polowa_gracza = _polowa_wysokosci_paletki($Paletka)
	var polowa_ai = _polowa_wysokosci_paletki($PaletkaAI)
	$Paletka.position.y = clampf($Paletka.position.y, gora + polowa_gracza, dol - polowa_gracza)
	$PaletkaAI.position.y = clampf($PaletkaAI.position.y, gora + polowa_ai, dol - polowa_ai)
	for pilka in get_tree().get_nodes_in_group("pilki"):
		if pilka.position.y < gora + 13.0:
			pilka.position.y = gora + 13.0
			pilka.velocity.y = absf(pilka.velocity.y)
		elif pilka.position.y > dol - 13.0:
			pilka.position.y = dol - 13.0
			pilka.velocity.y = -absf(pilka.velocity.y)
	_ustaw_etykiety_wyniku()
	_odswiez_rysowanie()


func animuj_granice_areny(gora: float, dol: float, czas: float = 0.8) -> void:
	if is_instance_valid(animacja_granic_areny):
		animacja_granic_areny.kill()

	var granice_startowe = Vector2(Ustawienia.gorna_granica, Ustawienia.dolna_granica)
	var granice_docelowe = Vector2(gora, dol)
	animacja_granic_areny = create_tween()
	animacja_granic_areny.set_trans(Tween.TRANS_CUBIC)
	animacja_granic_areny.set_ease(Tween.EASE_IN_OUT)
	animacja_granic_areny.tween_method(
		_ustaw_granice_interpolowane,
		granice_startowe,
		granice_docelowe,
		czas
	)


func _ustaw_granice_interpolowane(granice: Vector2) -> void:
	ustaw_granice_areny(granice.x, granice.y)


func ustaw_wymiary_areny(lewa: float, prawa: float, gora: float, dol: float) -> void:
	Ustawienia.lewa_granica = lewa
	Ustawienia.prawa_granica = prawa
	Ustawienia.gorna_granica = gora
	Ustawienia.dolna_granica = dol
	var srodek_x = (lewa + prawa) * 0.5
	_ustaw_ksztalt_sciany($"górna ściana/CollisionShape2D", prawa - lewa)
	_ustaw_ksztalt_sciany($"dolna ściana/CollisionShape2D", prawa - lewa)
	$"górna ściana".position = Vector2(srodek_x, gora)
	$"dolna ściana".position = Vector2(srodek_x, dol)
	$Paletka.call("ustaw_pozycje_x", lewa + ODSTEP_PALETKI)
	$PaletkaAI.call("ustaw_pozycje_x", prawa - ODSTEP_PALETKI)
	var polowa_gracza = _polowa_wysokosci_paletki($Paletka)
	var polowa_ai = _polowa_wysokosci_paletki($PaletkaAI)
	$Paletka.position.y = clampf($Paletka.position.y, gora + polowa_gracza, dol - polowa_gracza)
	$PaletkaAI.position.y = clampf($PaletkaAI.position.y, gora + polowa_ai, dol - polowa_ai)
	for pilka in get_tree().get_nodes_in_group("pilki"):
		if pilka.position.y < gora + 13.0:
			pilka.position.y = gora + 13.0
			pilka.velocity.y = absf(pilka.velocity.y)
		elif pilka.position.y > dol - 13.0:
			pilka.position.y = dol - 13.0
			pilka.velocity.y = -absf(pilka.velocity.y)
	_ustaw_etykiety_wyniku()
	_odswiez_rysowanie()


func animuj_wymiary_areny(lewa: float, prawa: float, gora: float, dol: float, czas: float = 0.8) -> void:
	if is_instance_valid(animacja_wymiarow_areny):
		animacja_wymiarow_areny.kill()
	var start = Vector4(Ustawienia.lewa_granica, Ustawienia.prawa_granica, Ustawienia.gorna_granica, Ustawienia.dolna_granica)
	var cel = Vector4(lewa, prawa, gora, dol)
	animacja_wymiarow_areny = create_tween()
	animacja_wymiarow_areny.set_trans(Tween.TRANS_CUBIC)
	animacja_wymiarow_areny.set_ease(Tween.EASE_IN_OUT)
	animacja_wymiarow_areny.tween_method(_ustaw_wymiary_interpolowane, start, cel, czas)


func _ustaw_wymiary_interpolowane(wymiary: Vector4) -> void:
	ustaw_wymiary_areny(wymiary.x, wymiary.y, wymiary.z, wymiary.w)


func animuj_strefe_przyspieszenia(pokaz: bool, czas: float = 0.55) -> void:
	if is_instance_valid(animacja_strefy):
		animacja_strefy.kill()
	animacja_strefy = create_tween()
	animacja_strefy.set_trans(Tween.TRANS_CUBIC)
	animacja_strefy.set_ease(Tween.EASE_OUT if pokaz else Tween.EASE_IN)
	animacja_strefy.tween_method(
		_ustaw_postep_animacji_strefy,
		postep_animacji_strefy,
		1.0 if pokaz else 0.0,
		czas
	)


func _ustaw_postep_animacji_strefy(postep: float) -> void:
	postep_animacji_strefy = postep
	_odswiez_rysowanie()


func animuj_wysokosc_paletek(proporcja: float, czas: float = 0.45) -> void:
	if is_instance_valid(animacja_wysokosci_paletek):
		animacja_wysokosci_paletek.kill()
	if bazowe_wysokosci_paletek == Vector2.ZERO:
		bazowe_wysokosci_paletek = Vector2(
			_polowa_wysokosci_paletki($Paletka) * 2.0,
			_polowa_wysokosci_paletki($PaletkaAI) * 2.0
		)
	var wysokosci_startowe = Vector2(
		_polowa_wysokosci_paletki($Paletka) * 2.0,
		_polowa_wysokosci_paletki($PaletkaAI) * 2.0
	)
	var wysokosci_docelowe = bazowe_wysokosci_paletek * proporcja
	animacja_wysokosci_paletek = create_tween()
	animacja_wysokosci_paletek.set_trans(Tween.TRANS_CUBIC)
	animacja_wysokosci_paletek.set_ease(Tween.EASE_IN_OUT)
	animacja_wysokosci_paletek.tween_method(
		_ustaw_wysokosci_paletek,
		wysokosci_startowe,
		wysokosci_docelowe,
		czas
	)


func _ustaw_wysokosci_paletek(wysokosci: Vector2) -> void:
	$Paletka.call("ustaw_wysokosc", wysokosci.x)
	$PaletkaAI.call("ustaw_wysokosc", wysokosci.y)


func animuj_rozmiar_pilki(proporcja: float, czas: float = 0.55) -> void:
	for pilka in get_tree().get_nodes_in_group("pilki"):
		if pilka.has_method("animuj_rozmiar"):
			pilka.call("animuj_rozmiar", proporcja, czas)


func ustaw_ugiecie_gumowej_sciany(strona: int, y: float, ugiecie: float, kula_id: int) -> void:
	if is_instance_valid(animacja_gumowej_sciany):
		animacja_gumowej_sciany.kill()
	gumowa_sciana_strona = strona
	gumowa_sciana_y = y
	gumowa_sciana_ugiecie = ugiecie
	gumowa_sciana_kula_id = kula_id
	_odswiez_rysowanie()


func odpusc_gumowa_sciane(kula_id: int) -> void:
	if gumowa_sciana_kula_id != kula_id or gumowa_sciana_ugiecie <= 0.0:
		return
	if is_instance_valid(animacja_gumowej_sciany):
		animacja_gumowej_sciany.kill()
	animacja_gumowej_sciany = create_tween()
	animacja_gumowej_sciany.set_trans(Tween.TRANS_CUBIC)
	animacja_gumowej_sciany.set_ease(Tween.EASE_OUT)
	animacja_gumowej_sciany.tween_method(
		_ustaw_ugiecie_gumowej_sciany_animowane,
		gumowa_sciana_ugiecie,
		0.0,
		0.28
	)


func _ustaw_ugiecie_gumowej_sciany_animowane(ugiecie: float) -> void:
	gumowa_sciana_ugiecie = ugiecie
	_odswiez_rysowanie()


func _polowa_wysokosci_paletki(paletka: CharacterBody2D) -> float:
	var kolizja = paletka.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if kolizja != null and kolizja.shape is RectangleShape2D:
		return (kolizja.shape as RectangleShape2D).size.y * 0.5
	return 60.0


func _ready():
	set_process(true)

	$"Piłka".punkt.connect(_on_punkt)
	$"Piłka".odbicie_gracza.connect(_on_odbicie_gracza)
	$"Piłka".statystyki_odbicia.connect(_zarejestruj_odbicie)
	$"Piłka".odbicie_paletki.connect(_online_odnotuj_odbicie_paletki)
	$"Piłka".odbicie_sciany.connect(_online_odnotuj_odbicie_sciany)
	ekran_konca.connect("menu_pressed", _on_przycisk_menu)
	ekran_konca.connect("replay_pressed", _on_przycisk_ponownie)

	dzwiek_punktu = AudioStreamPlayer.new()
	dzwiek_punktu.name = "DzwiekPunktu"
	dzwiek_punktu.stream = DZWIEK_PUNKTU
	dzwiek_punktu.volume_db = -8.0
	dzwiek_punktu.bus = &"Efekty"
	add_child(dzwiek_punktu)
	dzwiek_bonusu = _stworz_odtwarzacz_efektu(
		"DzwiekBonusu",
		DZWIEKI_GRY.utworz_dzwiek_bonusu(),
		-5.0
	)
	dzwiek_modyfikatora = _stworz_odtwarzacz_efektu(
		"DzwiekModyfikatora",
		DZWIEKI_GRY.utworz_dzwiek_modyfikatora(),
		-7.0
	)

	if Ustawienia.tryb == "online":
		online_czas_pozostaly = Siec.limit_czasu_meczu
		if Ustawienia.online_arena:
			$CzasBonusu.stop()
			arena_manager = ARENA_MANAGER_SCRIPT.new()
			arena_manager.name = "ArenaManager"
			add_child(arena_manager)
			arena_manager.call("uruchom", self, Siec.czy_klient(), true)
		_inicjalizuj_online()
	elif Ustawienia.tryb == "endless":
		$PaletkaAI.hide()
		$PaletkaAI.set_physics_process(false)
		$PaletkaAI/CollisionShape2D.set_deferred("disabled", true)
		$CzasBonusu.stop()
		var ksztalt_paletki = $Paletka/CollisionShape2D.shape as RectangleShape2D
		if ksztalt_paletki != null:
			endless_wysokosc_startowa = ksztalt_paletki.size.y
			endless_wysokosc_aktualna = ksztalt_paletki.size.y
	elif Ustawienia.tryb == "arena":
		$CzasBonusu.stop()
		arena_manager = ARENA_MANAGER_SCRIPT.new()
		arena_manager.name = "ArenaManager"
		add_child(arena_manager)
		arena_manager.call("uruchom", self)
	else:
		$BonusManager.uruchom(self)
		$"Piłka".runda_rozpoczeta.connect(Callable($BonusManager, "runda_rozpoczeta"))
		if Ustawienia.tryb == "bot" or (Ustawienia.tryb == "arena" and not Ustawienia.arena_dwoch_graczy):
			_pokaz_styl_bota()

	_ustaw_etykiety_wyniku()
	if Ustawienia.tryb == "endless":
		_dodaj_info_endless()
	_odswiez_rysowanie()


func _stworz_odtwarzacz_efektu(nazwa: String, strumien: AudioStream, glosnosc_db: float) -> AudioStreamPlayer:
	var odtwarzacz = AudioStreamPlayer.new()
	odtwarzacz.name = nazwa
	odtwarzacz.stream = strumien
	odtwarzacz.volume_db = glosnosc_db
	odtwarzacz.bus = &"Efekty"
	add_child(odtwarzacz)
	return odtwarzacz


func odtworz_dzwiek_bonusu() -> void:
	dzwiek_bonusu.play()


func odtworz_dzwiek_modyfikatora() -> void:
	dzwiek_modyfikatora.play()


func _pokaz_styl_bota():
	var nazwa_stylu = "Defensywny"
	var opis_stylu = "Pilnuje przewidywanego miejsca odbicia"
	var kolor_stylu = Color("#55d8f2")
	match Ustawienia.charakter_bota:
		"ofensywny":
			nazwa_stylu = "Ofensywny"
			opis_stylu = "Szuka ostrych kątów odbicia"
			kolor_stylu = Color("#ffb454")
		"agresywny":
			nazwa_stylu = "Agresywny"
			opis_stylu = "Przyspiesza piłkę po swoim odbiciu"
			kolor_stylu = Color("#ff647a")
		"nieprzewidywalny":
			nazwa_stylu = "Nieprzewidywalny"
			opis_stylu = "Zmienia punkt ustawienia paletki"
			kolor_stylu = Color("#a78bfa")

	pokaz_informacje_graczowi("BOT: " + nazwa_stylu.to_upper(), opis_stylu, kolor_stylu, 3.0)


func pokaz_informacje_graczowi(tytul: String, opis: String, kolor: Color, czas: float) -> void:
	if is_instance_valid(panel_informacyjny):
		panel_informacyjny.hide()
		panel_informacyjny.queue_free()

	var panel = PanelContainer.new()
	panel.name = "InformacjaGracza"
	var szerokosc_panelu = 520.0 if tytul.length() > 26 else 420.0
	panel.position = Vector2(
		(Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5 - szerokosc_panelu * 0.5,
		Ustawienia.dolna_granica + 14.0
	)
	var tylko_jeden_wiersz = opis.strip_edges().is_empty()
	panel.size = Vector2(szerokosc_panelu, 48.0 if tylko_jeden_wiersz else 62.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 20
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	panel.scale = Vector2(0.94, 0.94)
	panel.pivot_offset = panel.size * 0.5
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color(0.04, 0.08, 0.13, 0.94)
	styl.border_color = kolor
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(12)
	styl.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	styl.shadow_size = 8
	styl.shadow_offset = Vector2(0.0, 4.0)
	styl.content_margin_left = 14.0
	styl.content_margin_right = 14.0
	styl.content_margin_top = 6.0
	styl.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", styl)
	add_child(panel)
	panel_informacyjny = panel

	var uklad = VBoxContainer.new()
	uklad.alignment = BoxContainer.ALIGNMENT_CENTER
	uklad.add_theme_constant_override("separation", 0)
	uklad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(uklad)
	var etykieta_tytulu = Label.new()
	etykieta_tytulu.text = tytul
	etykieta_tytulu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta_tytulu.add_theme_font_size_override("font_size", 19)
	etykieta_tytulu.add_theme_color_override("font_color", kolor)
	etykieta_tytulu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	uklad.add_child(etykieta_tytulu)
	if not tylko_jeden_wiersz:
		var etykieta_opisu = Label.new()
		etykieta_opisu.text = opis
		etykieta_opisu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etykieta_opisu.add_theme_font_size_override("font_size", 13)
		etykieta_opisu.add_theme_color_override("font_color", Color("#a9bdd0"))
		etykieta_opisu.mouse_filter = Control.MOUSE_FILTER_IGNORE
		uklad.add_child(etykieta_opisu)

	var wejscie = create_tween()
	wejscie.set_parallel(true)
	wejscie.tween_property(panel, "modulate", Color.WHITE, 0.28)
	var powiekszenie = wejscie.tween_property(panel, "scale", Vector2.ONE, 0.32)
	powiekszenie.set_trans(Tween.TRANS_BACK)
	powiekszenie.set_ease(Tween.EASE_OUT)

	var panel_do_usuniecia = panel
	var czas_zanikania = 0.4
	get_tree().create_timer(maxf(czas - czas_zanikania, 0.05)).timeout.connect(func():
		if is_instance_valid(panel_do_usuniecia) and not panel_do_usuniecia.is_queued_for_deletion():
			var wyjscie = create_tween()
			wyjscie.set_parallel(true)
			wyjscie.tween_property(panel_do_usuniecia, "modulate", Color(1.0, 1.0, 1.0, 0.0), czas_zanikania)
			var pomniejszenie = wyjscie.tween_property(panel_do_usuniecia, "scale", Vector2(0.96, 0.96), czas_zanikania)
			pomniejszenie.set_trans(Tween.TRANS_CUBIC)
			pomniejszenie.set_ease(Tween.EASE_IN)
			wyjscie.finished.connect(func():
				if is_instance_valid(panel_do_usuniecia):
					panel_do_usuniecia.queue_free()
			)
	)


func ukryj_informacje_graczowi() -> void:
	if is_instance_valid(panel_informacyjny):
		panel_informacyjny.queue_free()
		panel_informacyjny = null


func _zarejestruj_odbicie(strona: String, mocne: bool) -> void:
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


func _prostokat_karty_wyniku(numer_karty: int) -> Rect2:
	var szerokosc = 84.0
	var wysokosc = clampf(Ustawienia.gorna_granica - 32.0, 38.0, 54.0)
	var odstep = 6.0
	if Ustawienia.tryb == "online":
		szerokosc = 164.0
		wysokosc = 68.0
		odstep = 12.0
	var srodek = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) / 2.0
	var gora_karty = maxf(20.0, Ustawienia.gorna_granica - wysokosc - 24.0)
	if _czy_tryb_areny():
		gora_karty = maxf(12.0, Ustawienia.gorna_granica - wysokosc - 32.0)
	if Ustawienia.tryb == "online":
		gora_karty = maxf(8.0, Ustawienia.gorna_granica - wysokosc - 34.0)
	if Ustawienia.tryb == "endless":
		szerokosc = 150.0
		wysokosc = clampf(Ustawienia.gorna_granica - 16.0, 56.0, 78.0)
		odstep = 10.0
		gora_karty = maxf(6.0, Ustawienia.gorna_granica - wysokosc - 12.0)
	var x_pierwszej = srodek - szerokosc - odstep / 2.0
	var x = x_pierwszej + numer_karty * (szerokosc + odstep)

	return Rect2(Vector2(x, gora_karty), Vector2(szerokosc, wysokosc))


func _czy_tryb_areny() -> bool:
	return Ustawienia.tryb == "arena" or (Ustawienia.tryb == "online" and Ustawienia.online_arena)


func _ustaw_etykiety_wyniku():
	if Ustawienia.tryb in ["arena", "online"]:
		$WynikGracza.hide()
		$WynikAI.hide()
		return
	$WynikGracza.show()
	$WynikAI.show()
	if Ustawienia.tryb == "endless":
		$WynikGracza.text = str(wynik_gracza)
		$WynikAI.text = str(Ustawienia.rekord_endless)
		$WynikGracza.add_theme_font_size_override("font_size", 36)
		$WynikAI.add_theme_font_size_override("font_size", 36)
		_ustaw_etykiete($WynikGracza, _prostokat_karty_wyniku(0), KOLOR_GRACZA)
		_ustaw_etykiete($WynikAI, _prostokat_karty_wyniku(1), Color("#c4b5fd"))
		return
	_ustaw_etykiete($WynikGracza, _prostokat_karty_wyniku(0), KOLOR_GRACZA)
	_ustaw_etykiete($WynikAI, _prostokat_karty_wyniku(1), KOLOR_AI)
	$WynikGracza.add_theme_font_size_override("font_size", 36)
	$WynikAI.add_theme_font_size_override("font_size", 36)


func _ustaw_etykiete(etykieta: Label, karta: Rect2, kolor: Color):
	etykieta.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	etykieta.position = karta.position
	etykieta.size = karta.size
	etykieta.custom_minimum_size = karta.size
	etykieta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etykieta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etykieta.add_theme_color_override("font_color", kolor)
	if Ustawienia.tryb != "endless":
		etykieta.add_theme_font_size_override("font_size", 32)
	etykieta.z_index = 10


func _on_punkt(strona):
	if mecz_zakonczony:
		return
	rozpad_punktu_trwa = false
	if Ustawienia.tryb == "endless":
		_zakoncz_endless()
		return

	dzwiek_punktu.play()
	biezaca_wymiana = 0

	if strona == "lewa":
		wynik_ai += 1
	else:
		wynik_gracza += 1

	$WynikGracza.text = str(wynik_gracza)
	$WynikAI.text = str(wynik_ai)
	_odswiez_rysowanie()
	if Ustawienia.tryb != "online":
		$BonusManager.wyczysc_po_punkcie()
	_odswiez_rysowanie()
	if arena_manager != null:
		arena_manager.call("po_zdobyciu_punktu")

	var pilka_glowna = $"Piłka"

	for pilka in get_tree().get_nodes_in_group("pilki"):
		if pilka != pilka_glowna:
			pilka.queue_free()

	var z_botem = Ustawienia.tryb == "bot" or (Ustawienia.tryb == "arena" and not Ustawienia.arena_dwoch_graczy)

	if Ustawienia.tryb == "online" and Siec.warunek_meczu == "czas":
		$Paletka.set_physics_process(true)
		$PaletkaAI.set_physics_process(true)
		pilka_glowna.set_physics_process(true)
		pilka_glowna.reset()
	elif Ustawienia.tryb == "online" and wynik_gracza >= Siec.limit_punktow_meczu:
		koniec_gry("Wygrywa %s!" % Siec.nazwa_gracza_1)
	elif Ustawienia.tryb == "online" and wynik_ai >= Siec.limit_punktow_meczu:
		koniec_gry("Wygrywa %s!" % Siec.nazwa_gracza_2)
	elif wynik_gracza >= Ustawienia.limit_punktow:
		koniec_gry("Wygrywa %s!" % Siec.nazwa_gracza_1 if Ustawienia.tryb == "online" else ("Wygrałeś!" if z_botem else "Wygrywa gracz 1!"))
	elif wynik_ai >= Ustawienia.limit_punktow:
		koniec_gry("Wygrywa %s!" % Siec.nazwa_gracza_2 if Ustawienia.tryb == "online" else ("Przegrałeś!" if z_botem else "Wygrywa gracz 2!"))
	else:
		$Paletka.set_physics_process(true)
		$PaletkaAI.set_physics_process(true)
		pilka_glowna.set_physics_process(true)
		pilka_glowna.reset()


func rozpocznij_rozpad_pilki(pilka_punktujaca: Node) -> bool:
	if rozpad_punktu_trwa or mecz_zakonczony:
		return false
	rozpad_punktu_trwa = true
	for pilka in get_tree().get_nodes_in_group("pilki"):
		if pilka != pilka_punktujaca:
			pilka.set_physics_process(false)
	$Paletka.set_physics_process(false)
	$PaletkaAI.set_physics_process(false)
	$BonusManager.zatrzymaj()
	return true


func _dodaj_info_endless():
	endless_info = Label.new()
	endless_info.name = "InformacjaEndless"
	endless_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endless_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	endless_info.add_theme_font_size_override("font_size", 14)
	endless_info.add_theme_color_override("font_color", Color("#a9bdd0"))
	endless_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endless_info.z_index = 10
	add_child(endless_info)
	get_viewport().size_changed.connect(_ustaw_pozycje_info_endless)
	_ustaw_pozycje_info_endless()
	_odswiez_info_endless()


func _ustaw_pozycje_info_endless():
	if endless_info == null:
		return
	var wymiar = get_viewport_rect().size
	endless_info.position = Vector2(24.0, minf(Ustawienia.dolna_granica + 18.0, wymiar.y - 42.0))
	endless_info.size = Vector2(wymiar.x - 48.0, 24.0)


func _odswiez_info_endless():
	if endless_info == null:
		return
	var pilka = $"Piłka"
	var predkosc_razy = pilka.predkosc / PREDKOSC_BAZOWA_ENDLESS
	var procent_paletki = 100
	if endless_wysokosc_startowa > 0.0:
		procent_paletki = roundi(endless_wysokosc_aktualna / endless_wysokosc_startowa * 100.0)
	endless_info.text = "Idealne trafienie: +2 pkt   ·   Prędkość ×%.2f   ·   Paletka %d%%   ·   Przyspieszenie co 5 odbić, skrócenie co 12" % [predkosc_razy, procent_paletki]


func _on_odbicie_gracza(perfect_hit: bool):
	if Ustawienia.tryb != "endless" or mecz_zakonczony:
		return

	endless_odbicia += 1
	wynik_gracza += (3 if perfect_hit else 1)
	$WynikGracza.text = str(wynik_gracza)
	$WynikAI.text = str(Ustawienia.rekord_endless)

	if endless_odbicia % 5 == 0:
		$"Piłka".przyspiesz(1.08)
	if endless_odbicia % 12 == 0:
		_zmniejsz_paletke_endless()
	_odswiez_info_endless()


func _zmniejsz_paletke_endless():
	var etap = floori(float(endless_odbicia) / 12.0)
	var mnoznik = maxf(0.6, 1.0 - float(etap) * 0.08)
	endless_wysokosc_aktualna = endless_wysokosc_startowa * mnoznik
	$Paletka.call_deferred("ustaw_wysokosc", endless_wysokosc_aktualna)


func _zakoncz_endless():
	var nowy_rekord = wynik_gracza > Ustawienia.rekord_endless
	if nowy_rekord:
		Ustawienia.rekord_endless = wynik_gracza
		Ustawienia.zapisz()
	$WynikAI.text = str(Ustawienia.rekord_endless)
	if nowy_rekord:
		koniec_gry("Nowy rekord!")
	else:
		koniec_gry("Koniec próby")


func dodaj_dodatkowa_pilke(pilka_zrodlowa, pozycja_bonusu: Vector2):
	var nowa_pilka = SCENA_PILKI.instantiate()
	add_child(nowa_pilka)
	nowa_pilka.czas_rundy = pilka_zrodlowa.czas_rundy

	var kierunek = pilka_zrodlowa.velocity.normalized()
	if kierunek.length_squared() < 0.001:
		kierunek = Vector2.RIGHT

	var bok = Vector2(-kierunek.y, kierunek.x)
	var miejsce_a = pozycja_bonusu + bok * 28.0
	var miejsce_b = pozycja_bonusu - bok * 28.0
	var dystans_a = miejsce_a.distance_to(pilka_zrodlowa.global_position)
	var dystans_b = miejsce_b.distance_to(pilka_zrodlowa.global_position)
	nowa_pilka.global_position = miejsce_a if dystans_a >= dystans_b else miejsce_b

	nowa_pilka.predkosc = pilka_zrodlowa.predkosc * MNOZNIK_PREDKOSCI_DODATKOWEJ
	var odchylenie = deg_to_rad(randf_range(-12.0, 12.0))
	nowa_pilka.velocity = kierunek.rotated(odchylenie) * nowa_pilka.predkosc

	nowa_pilka.intro_aktywne = false
	nowa_pilka.queue_redraw()
	nowa_pilka.punkt.connect(_on_punkt)
	nowa_pilka.statystyki_odbicia.connect(_zarejestruj_odbicie)

	get_tree().create_timer(CZAS_DODATKOWEJ_PILKI, false).timeout.connect(
		nowa_pilka.queue_free
	)


func koniec_gry(tekst: String) -> void:
	mecz_zakonczony = true
	if Ustawienia.tryb == "online":
		online_tekst_konca = tekst
	$WynikGracza.hide()
	$WynikAI.hide()
	var dane_podsumowania = {
		"tryb": Ustawienia.tryb,
		"czas_meczu": czas_meczu,
		"wynik_gracza": wynik_gracza,
		"wynik_ai": wynik_ai,
		"odbicia_lacznie": stat_odbicia_gracza + stat_odbicia_rywala,
		"mocne_odbicia_lacznie": stat_mocne_odbicia_gracza + stat_mocne_odbicia_rywala,
		"rekord_endless": Ustawienia.rekord_endless,
		"najdluzsza_wymiana": najdluzsza_wymiana
	}
	ekran_konca.call("pokaz", tekst, dane_podsumowania)
	if is_instance_valid(endless_info):
		endless_info.hide()
	ukryj_informacje_graczowi()
	_odswiez_rysowanie()
	$BonusManager.zatrzymaj()
	if arena_manager != null:
		arena_manager.call("zatrzymaj")
	for pilka in get_tree().get_nodes_in_group("pilki"):
		pilka.set_physics_process(false)
	$Paletka.set_physics_process(false)
	$PaletkaAI.set_physics_process(false)


func _odswiez_rysowanie() -> void:
	if is_instance_valid(rysowanie_areny):
		rysowanie_areny.queue_redraw()


func _process(delta: float) -> void:
	if not mecz_zakonczony:
		czas_meczu += delta
	if Ustawienia.tryb == "online":
		if Siec.czy_host() and Siec.warunek_meczu == "czas" and not multiplayer.get_peers().is_empty() and not mecz_zakonczony:
			Siec.pozostaly_czas_meczu = maxf(0.0, Siec.pozostaly_czas_meczu - delta)
			online_czas_pozostaly = Siec.pozostaly_czas_meczu
			if online_czas_pozostaly <= 0.0:
				koniec_gry(_tekst_wyniku_po_czasie())
		_odswiez_etykiete_czasu_online()
		_online_obsluz(delta)


func _inicjalizuj_online() -> void:
	_utworz_komunikat_online()
	Siec.gracz_polaczyl.connect(_online_gracz_polaczyl)
	Siec.gracz_rozlaczyl.connect(_online_gracz_rozlaczyl)
	Siec.polaczono_z_hostem.connect(_online_polaczono)
	Siec.host_rozlaczyl.connect(_online_host_rozlaczyl)
	Siec.nazwa_gracza_2_zmieniona.connect(_online_zmieniono_nazwe_gracza)

	$Paletka.set_physics_process(false)
	$PaletkaAI.set_physics_process(false)
	$"Piłka".set_physics_process(false)
	$BonusManager.set_process(false)
	$BonusManager.set_physics_process(false)

	if Siec.czy_host():
		_online_ustaw_komunikat("Oczekiwanie na drugiego gracza", Color("#55e7ff"))
		var polaczeni = multiplayer.get_peers()
		if not polaczeni.is_empty():
			_online_gracz_polaczyl(polaczeni[0])
	else:
		online_przewidywane_prawe_y = $PaletkaAI.position.y
		_online_ustaw_komunikat("Łączenie z hostem…", Color("#55e7ff"))
		if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			_online_polaczono()


func _utworz_komunikat_online() -> void:
	var warstwa = CanvasLayer.new()
	warstwa.name = "WarstwaStatusuOnline"
	warstwa.layer = 20
	add_child(warstwa)
	online_komunikat = Label.new()
	online_komunikat.name = "StatusOnline"
	online_komunikat.position = Vector2(0.0, 0.0)
	online_komunikat.size = Vector2(get_viewport_rect().size.x, 26.0)
	online_komunikat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	online_komunikat.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	online_komunikat.add_theme_font_override("font", FONT_ARCADE)
	online_komunikat.add_theme_font_size_override("font_size", 13)
	online_komunikat.add_theme_color_override("font_color", Color("#55e7ff"))
	warstwa.add_child(online_komunikat)
	online_czas_etykieta = Label.new()
	online_czas_etykieta.name = "WarunekMeczuOnline"
	online_czas_etykieta.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	online_czas_etykieta.offset_top = 78.0
	online_czas_etykieta.offset_bottom = 106.0
	online_czas_etykieta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	online_czas_etykieta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	online_czas_etykieta.add_theme_font_override("font", FONT_ARCADE)
	online_czas_etykieta.add_theme_font_size_override("font_size", 20)
	online_czas_etykieta.add_theme_color_override("font_color", Color("#ffd27a"))
	warstwa.add_child(online_czas_etykieta)
	_odswiez_etykiete_czasu_online()


func _odswiez_etykiete_czasu_online() -> void:
	if not is_instance_valid(online_czas_etykieta):
		return
	if Siec.warunek_meczu == "czas":
		var sekundy = maxi(0, ceili(online_czas_pozostaly))
		var minuty = floori(float(sekundy) / 60.0)
		online_czas_etykieta.text = "%02d:%02d" % [minuty, sekundy % 60]
	else:
		online_czas_etykieta.text = "Do %d punktów" % Siec.limit_punktow_meczu


func _tekst_wyniku_po_czasie() -> String:
	if wynik_gracza > wynik_ai:
		return "Koniec czasu — wygrywa %s!" % Siec.nazwa_gracza_1
	if wynik_ai > wynik_gracza:
		return "Koniec czasu — wygrywa %s!" % Siec.nazwa_gracza_2
	return "Koniec czasu — remis!"


func _online_ustaw_komunikat(tekst: String, kolor: Color = Color("#55e7ff")) -> void:
	if not is_instance_valid(online_komunikat):
		return
	online_komunikat.text = tekst
	online_komunikat.add_theme_color_override("font_color", kolor)
	online_komunikat.show()


func _online_gracz_polaczyl(id: int) -> void:
	if not Siec.czy_host() or not multiplayer.get_peers().has(id):
		return
	_online_ustaw_komunikat("Gracz dołączył — powodzenia!", Color("#55e7ff"))
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(online_komunikat) and online_komunikat.text == "Gracz dołączył — powodzenia!":
			online_komunikat.hide()
	)
	$Paletka.set_physics_process(true)
	$PaletkaAI.set_physics_process(true)
	if arena_manager != null:
		arena_manager.call("rozpocznij")
	$"Piłka".reset()
	$"Piłka".set_physics_process(true)


func _online_zmieniono_nazwe_gracza(_nazwa: String) -> void:
	_odswiez_rysowanie()


func _online_gracz_rozlaczyl(id: int) -> void:
	if not Siec.czy_host():
		return
	$PaletkaAI.sieciowy_kierunek = 0.0
	$PaletkaAI.sieciowy_dash_zadany = false
	$Paletka.set_physics_process(false)
	$PaletkaAI.set_physics_process(false)
	$"Piłka".set_physics_process(false)
	if arena_manager != null:
		arena_manager.set_process(false)
		arena_manager.set_physics_process(false)
	_online_ustaw_komunikat("Gracz rozłączony — oczekiwanie na kolejnego", Color("#ffb454"))


func _online_polaczono() -> void:
	if Siec.czy_klient():
		_online_ustaw_komunikat("Połączono z hostem", Color("#55e7ff"))


func _online_host_rozlaczyl() -> void:
	if not Siec.czy_klient() or online_powrot_zaplany:
		return
	online_powrot_zaplany = true
	_online_ustaw_komunikat("Host zakończył połączenie — wracam do menu…", Color("#ff647a"))
	get_tree().create_timer(2.0).timeout.connect(_online_wroc_do_menu)


func _online_wroc_do_menu() -> void:
	Siec.rozlacz()
	Ustawienia.tryb = "bot"
	get_tree().change_scene_to_file("res://menu.tscn")


func _online_obsluz(delta: float) -> void:
	if Siec.czy_klient():
		if online_komunikat.text == "Połączono z hostem":
			online_komunikat.hide()
		var kierunek = 0.0 if Siec.pauza_lokalna else Input.get_axis("lewy_gora", "lewy_dol")
		online_czas_wejscia += delta
		if online_czas_wejscia >= 1.0 / 30.0 and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			online_czas_wejscia = 0.0
			rpc_id(1, "online_ustaw_kierunek", kierunek)
		if not Siec.pauza_lokalna and Input.is_action_just_pressed("dash_gracza_1") and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			rpc_id(1, "online_zadaj_dash")
			if $PaletkaAI.dash_odnowienie <= 0.0:
				var dash_kierunek = signf(kierunek) if not is_zero_approx(kierunek) else $PaletkaAI.ostatni_kierunek
				$PaletkaAI._rozpocznij_dash(dash_kierunek)
		if not Siec.pauza_lokalna and not is_zero_approx(kierunek):
			$PaletkaAI.ostatni_kierunek = signf(kierunek)
		if $PaletkaAI.dash_aktywne:
			$PaletkaAI._aktualizuj_dash(delta)
			$PaletkaAI.position.y += $PaletkaAI.velocity.y * delta
			$PaletkaAI._ogranicz_pozycje_y()
			online_przewidywane_prawe_y = $PaletkaAI.position.y
		else:
			var polowa_paletki = $PaletkaAI._polowa_wysokosci_paletki()
			online_przewidywane_prawe_y = clampf(
				online_przewidywane_prawe_y + kierunek * 400.0 * delta,
				Ustawienia.gorna_granica + polowa_paletki,
				Ustawienia.dolna_granica - polowa_paletki
			)
			$PaletkaAI.position.y = online_przewidywane_prawe_y
		if not online_aktualny_stan.is_empty():
			online_czas_stanu += delta
			var postep = clampf(online_czas_stanu / 0.1, 0.0, 1.0)
			var poprzednia_pilka: Vector2 = online_poprzedni_stan["pilka"]
			var aktualna_pilka: Vector2 = online_aktualny_stan["pilka"]
			$"Piłka".position = poprzednia_pilka.lerp(aktualna_pilka, postep)
			$Paletka.position.y = lerpf(float(online_poprzedni_stan["lewa_y"]), float(online_aktualny_stan["lewa_y"]), postep)
		return
	if not Siec.czy_host() or multiplayer.get_peers().is_empty():
		return
	online_czas_wejscia += delta
	if online_czas_wejscia < 1.0 / 30.0:
		return
	online_czas_wejscia = 0.0
	var dane_areny: Dictionary = arena_manager.call("dane_sieciowe") if arena_manager != null else {}
	rpc("online_odbierz_stan", {
		"pilka": $"Piłka".position,
		"lewa_y": $Paletka.position.y,
		"prawa_y": $PaletkaAI.position.y,
		"dash_lewy": $Paletka.dash_odnowienie,
		"dash_prawy": $PaletkaAI.dash_odnowienie,
		"wynik_gracza": wynik_gracza,
		"wynik_ai": wynik_ai,
		"koniec": mecz_zakonczony,
		"komunikat_konca": online_tekst_konca,
		"czas_pozostaly": Siec.pozostaly_czas_meczu,
		"runda_online": Siec.runda_online,
		"odbicia_paletki": online_licznik_odbic_paletka,
		"odbicia_sciany": online_licznik_odbic_sciana,
		"arena": dane_areny
	})


func _online_odnotuj_odbicie_paletki() -> void:
	if Ustawienia.tryb == "online" and Siec.czy_host():
		online_licznik_odbic_paletka += 1


func _online_odnotuj_odbicie_sciany() -> void:
	if Ustawienia.tryb == "online" and Siec.czy_host():
		online_licznik_odbic_sciana += 1


@rpc("any_peer", "call_remote", "unreliable_ordered")
func online_ustaw_kierunek(kierunek: float) -> void:
	if not Siec.czy_host() or not _online_nadawca_jest_graczem():
		return
	$PaletkaAI.sieciowy_kierunek = clampf(kierunek, -1.0, 1.0)


@rpc("any_peer", "call_remote", "reliable")
func online_zadaj_dash() -> void:
	if not Siec.czy_host() or not _online_nadawca_jest_graczem():
		return
	$PaletkaAI.sieciowy_dash_zadany = true


@rpc("any_peer", "call_remote", "reliable")
func online_zadaj_ponowne() -> void:
	if not Siec.czy_host() or not _online_nadawca_jest_graczem() or not mecz_zakonczony:
		return
	Siec.runda_online += 1
	Siec.pozostaly_czas_meczu = Siec.limit_czasu_meczu
	get_tree().reload_current_scene()


func _online_nadawca_jest_graczem() -> bool:
	var polaczeni = multiplayer.get_peers()
	return not polaczeni.is_empty() and multiplayer.get_remote_sender_id() == polaczeni[0]


@rpc("authority", "call_remote", "unreliable_ordered")
func online_odbierz_stan(stan: Dictionary) -> void:
	if not Siec.czy_klient():
		return
	if arena_manager != null and stan.has("arena"):
		arena_manager.call("ustaw_stan_zdalny", stan["arena"])
	if int(stan["runda_online"]) != Siec.runda_online:
		Siec.runda_online = int(stan["runda_online"])
		get_tree().reload_current_scene()
		return
	if not online_otrzymano_pierwszy_stan:
		online_odebrane_odbicia_paletka = int(stan["odbicia_paletki"])
		online_odebrane_odbicia_sciana = int(stan["odbicia_sciany"])
		online_otrzymano_pierwszy_stan = true
	var poprzedni_wynik_gracza = int(online_aktualny_stan.get("wynik_gracza", stan["wynik_gracza"]))
	var poprzedni_wynik_ai = int(online_aktualny_stan.get("wynik_ai", stan["wynik_ai"]))
	var nowe_odbicia_paletki = int(stan["odbicia_paletki"]) - online_odebrane_odbicia_paletka
	var nowe_odbicia_sciany = int(stan["odbicia_sciany"]) - online_odebrane_odbicia_sciana
	var poprzedni_cooldown_gracza = $Paletka.dash_odnowienie
	var poprzedni_cooldown_dasha = $PaletkaAI.dash_odnowienie
	var autorytatywna_pozycja_prawej = float(stan["prawa_y"])
	online_przewidywane_prawe_y += clampf(autorytatywna_pozycja_prawej - online_przewidywane_prawe_y, -65.0, 65.0) * 0.4
	if not online_aktualny_stan.is_empty():
		online_poprzedni_stan = online_aktualny_stan.duplicate()
	else:
		online_poprzedni_stan = stan.duplicate()
	online_aktualny_stan = stan
	online_czas_stanu = 0.0
	$WynikGracza.text = str(stan["wynik_gracza"])
	$WynikAI.text = str(stan["wynik_ai"])
	online_czas_pozostaly = float(stan.get("czas_pozostaly", online_czas_pozostaly))
	_odswiez_etykiete_czasu_online()
	$Paletka.dash_odnowienie = float(stan["dash_lewy"])
	$PaletkaAI.dash_odnowienie = float(stan["dash_prawy"])
	if poprzedni_cooldown_gracza <= 0.0 and $Paletka.dash_odnowienie > 0.0:
		if not online_poprzedni_stan.is_empty():
			$Paletka.dash_efekt_kierunek = signf(float(stan["lewa_y"]) - float(online_poprzedni_stan["lewa_y"]))
		$Paletka.dash_efekt_czas = 0.28
		$Paletka.dzwiek_dasha.play()
		$Paletka.queue_redraw()
	if poprzedni_cooldown_dasha <= 0.0 and $PaletkaAI.dash_odnowienie > 0.0:
		if not online_poprzedni_stan.is_empty():
			$PaletkaAI.dash_efekt_kierunek = signf(float(stan["prawa_y"]) - float(online_poprzedni_stan["prawa_y"]))
		$PaletkaAI.dash_efekt_czas = 0.28
		$PaletkaAI.dzwiek_dasha.play()
		$PaletkaAI.queue_redraw()
	$WskaznikiDasha.queue_redraw()
	if nowe_odbicia_paletki > 0:
		$"Piłka"/DzwiekPaletka.play()
	if nowe_odbicia_sciany > 0:
		$"Piłka"/DzwiekSciana.play()
	online_odebrane_odbicia_paletka = int(stan["odbicia_paletki"])
	online_odebrane_odbicia_sciana = int(stan["odbicia_sciany"])
	if int(stan["wynik_gracza"]) != poprzedni_wynik_gracza or int(stan["wynik_ai"]) != poprzedni_wynik_ai:
		dzwiek_punktu.play()
	if stan["koniec"] and not mecz_zakonczony:
		koniec_gry(str(stan.get("komunikat_konca", "Koniec meczu — wynik %d : %d" % [stan["wynik_gracza"], stan["wynik_ai"]])))


func _on_przycisk_menu():
	if Ustawienia.tryb == "online":
		Siec.rozlacz()
		Ustawienia.tryb = "bot"
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_przycisk_ponownie():
	get_tree().paused = false
	if Ustawienia.tryb == "online":
		Siec.pauza_lokalna = false
		if Siec.czy_klient():
			_online_ustaw_komunikat("Prośba o ponowne rozpoczęcie meczu…", Color("#55e7ff"))
			rpc_id(1, "online_zadaj_ponowne")
			return
		if Siec.czy_host():
			Siec.runda_online += 1
			Siec.pozostaly_czas_meczu = Siec.limit_czasu_meczu
	get_tree().reload_current_scene()
