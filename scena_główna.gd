extends Node2D

const SCENA_PILKI = preload("res://piłka.tscn")
const ARENA_MANAGER_SCRIPT = preload("res://arena_manager.gd")
const DZWIEK_PUNKTU = preload("res://punkt_sukces.wav")
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
var odbicia_areny = 0
var dzwiek_punktu: AudioStreamPlayer
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
	$"Piłka".odbicie_paletki.connect(_on_odbicie_paletki)
	$"Piłka".statystyki_odbicia.connect(_zarejestruj_odbicie)
	ekran_konca.connect("menu_pressed", _on_przycisk_menu)
	ekran_konca.connect("replay_pressed", _on_przycisk_ponownie)

	dzwiek_punktu = AudioStreamPlayer.new()
	dzwiek_punktu.name = "DzwiekPunktu"
	dzwiek_punktu.stream = DZWIEK_PUNKTU
	dzwiek_punktu.volume_db = -8.0
	dzwiek_punktu.bus = &"Efekty"
	add_child(dzwiek_punktu)

	if Ustawienia.tryb == "endless":
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
	var srodek = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) / 2.0
	var gora_karty = maxf(20.0, Ustawienia.gorna_granica - wysokosc - 24.0)
	if Ustawienia.tryb == "arena":
		gora_karty = maxf(12.0, Ustawienia.gorna_granica - wysokosc - 32.0)
	if Ustawienia.tryb == "endless":
		szerokosc = 150.0
		wysokosc = clampf(Ustawienia.gorna_granica - 16.0, 56.0, 78.0)
		odstep = 10.0
		gora_karty = maxf(6.0, Ustawienia.gorna_granica - wysokosc - 12.0)
	var x_pierwszej = srodek - szerokosc - odstep / 2.0
	var x = x_pierwszej + numer_karty * (szerokosc + odstep)

	return Rect2(Vector2(x, gora_karty), Vector2(szerokosc, wysokosc))


func _ustaw_etykiety_wyniku():
	if Ustawienia.tryb == "arena":
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
	$BonusManager.wyczysc_po_punkcie()
	odbicia_areny = 0
	_odswiez_rysowanie()
	if arena_manager != null:
		arena_manager.call("po_zdobyciu_punktu")

	var pilka_glowna = $"Piłka"

	for pilka in get_tree().get_nodes_in_group("pilki"):
		if pilka != pilka_glowna:
			pilka.queue_free()

	var z_botem = Ustawienia.tryb == "bot" or (Ustawienia.tryb == "arena" and not Ustawienia.arena_dwoch_graczy)

	if wynik_gracza >= Ustawienia.limit_punktow:
		koniec_gry("Wygrałeś!" if z_botem else "Wygrywa gracz 1!")
	elif wynik_ai >= Ustawienia.limit_punktow:
		koniec_gry("Przegrałeś!" if z_botem else "Wygrywa gracz 2!")
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


func _on_odbicie_paletki() -> void:
	if Ustawienia.tryb != "arena":
		return
	odbicia_areny += 1
	_odswiez_rysowanie()


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
	nowa_pilka.odbicie_paletki.connect(_on_odbicie_paletki)
	nowa_pilka.statystyki_odbicia.connect(_zarejestruj_odbicie)

	get_tree().create_timer(CZAS_DODATKOWEJ_PILKI, false).timeout.connect(
		nowa_pilka.queue_free
	)


func koniec_gry(tekst: String) -> void:
	mecz_zakonczony = true
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


func _on_przycisk_menu():
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_przycisk_ponownie():
	get_tree().paused = false
	get_tree().reload_current_scene()
