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

const KOLOR_TLA = Color("#080e18")
const KOLOR_PLANSZY = Color("#142235")
const KOLOR_RAMKI = Color("#46627e")
const KOLOR_LINII = Color("#7892ad")
const KOLOR_KARTY_WYNIKU = Color("#0b1725")
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
var arena_manager: Node
var animacja_granic_areny: Tween
var animacja_wymiarow_areny: Tween
var animacja_strefy: Tween
var animacja_wysokosci_paletek: Tween
var postep_animacji_strefy = 0.0
var bazowe_wysokosci_paletek = Vector2.ZERO
var etykiety_nazw_statystyk: Array[Label] = []
var etykiety_wartosci_statystyk: Array[Label] = []
var animacja_gumowej_sciany: Tween
var gumowa_sciana_strona = 0
var gumowa_sciana_y = 0.0
var gumowa_sciana_ugiecie = 0.0
var gumowa_sciana_kula_id = 0
var rozpad_punktu_trwa = false


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
	queue_redraw()


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
	queue_redraw()


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
	queue_redraw()


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
	queue_redraw()


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
	queue_redraw()


func _polowa_wysokosci_paletki(paletka: CharacterBody2D) -> float:
	var kolizja = paletka.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if kolizja != null and kolizja.shape is RectangleShape2D:
		return (kolizja.shape as RectangleShape2D).size.y * 0.5
	return 60.0


func _ready():
	set_process(true)
	$Komunikat.visible = false
	$PrzyciskMenu.visible = false
	_styluj_ekran_konca()

	$"Piłka".punkt.connect(_on_punkt)
	$"Piłka".odbicie_gracza.connect(_on_odbicie_gracza)
	$"Piłka".odbicie_paletki.connect(_on_odbicie_paletki)
	$"Piłka".statystyki_odbicia.connect(_zarejestruj_odbicie)
	$PrzyciskMenu.pressed.connect(_on_przycisk_menu)

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
	queue_redraw()


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


func _styluj_ekran_konca():
	var przyciemnienie_konca = ColorRect.new()
	przyciemnienie_konca.name = "PrzyciemnienieKoniecGry"
	przyciemnienie_konca.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	przyciemnienie_konca.color = Color(0.015, 0.025, 0.06, 0.7)
	przyciemnienie_konca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	przyciemnienie_konca.z_index = 5
	add_child(przyciemnienie_konca)
	przyciemnienie_konca.hide()

	var karta = Panel.new()
	karta.name = "KartaKoniecGry"
	karta.custom_minimum_size = Vector2(620.0, 520.0)
	karta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	karta.z_index = 10
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color("#0c1628f7")
	styl.border_color = Color("#55e7ff")
	styl.set_border_width_all(2)
	styl.set_corner_radius_all(22)
	styl.content_margin_left = 30.0
	styl.content_margin_right = 30.0
	styl.content_margin_top = 30.0
	styl.content_margin_bottom = 30.0
	styl.shadow_color = Color("#55e7ff30")
	styl.shadow_size = 26
	styl.shadow_offset = Vector2(0.0, 10.0)
	karta.add_theme_stylebox_override("panel", styl)
	add_child(karta)
	karta.hide()
	_utworz_podsumowanie_statystyk()

	var komunikat = $Komunikat
	komunikat.add_theme_font_override("font", FONT_ARCADE)
	komunikat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	komunikat.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	komunikat.add_theme_font_size_override("font_size", 40)
	komunikat.add_theme_color_override("font_color", Color("#55e7ff"))
	komunikat.z_index = 11
	var wynik_koncowy = Label.new()
	wynik_koncowy.name = "WynikKoncowy"
	wynik_koncowy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wynik_koncowy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wynik_koncowy.add_theme_font_override("font", FONT_ARCADE)
	wynik_koncowy.add_theme_font_size_override("font_size", 35)
	wynik_koncowy.add_theme_color_override("font_color", Color("#e8f4ff"))
	wynik_koncowy.z_index = 11
	add_child(wynik_koncowy)
	wynik_koncowy.hide()

	var przycisk = $PrzyciskMenu
	przycisk.text = "Wróć do menu"
	przycisk.custom_minimum_size = Vector2(300.0, 56.0)
	przycisk.alignment = HORIZONTAL_ALIGNMENT_CENTER
	przycisk.add_theme_font_size_override("font_size", 20)
	przycisk.add_theme_color_override("font_color", Color("#e8f4ff"))
	przycisk.add_theme_color_override("font_hover_color", Color.WHITE)
	przycisk.add_theme_stylebox_override("normal", _styl_przycisku(Color("#111e32"), Color("#344d64")))
	przycisk.add_theme_stylebox_override("hover", _styl_przycisku(Color("#192d45"), Color("#ad83ff")))
	przycisk.add_theme_stylebox_override("pressed", _styl_przycisku(Color("#102638"), Color("#7958c7")))
	przycisk.add_theme_stylebox_override("focus", _styl_przycisku(Color("#111e32"), Color("#ad83ff")))
	przycisk.z_index = 11
	przycisk.pivot_offset = przycisk.custom_minimum_size * 0.5
	przycisk.resized.connect(func(): przycisk.pivot_offset = przycisk.size * 0.5)
	przycisk.mouse_entered.connect(_animuj_przycisk.bind(przycisk, true))
	przycisk.mouse_exited.connect(_animuj_przycisk.bind(przycisk, false))
	var przycisk_ponownie = Button.new()
	przycisk_ponownie.name = "PrzyciskPonownie"
	przycisk_ponownie.text = "Zagraj ponownie"
	przycisk_ponownie.custom_minimum_size = Vector2(300.0, 52.0)
	przycisk_ponownie.alignment = HORIZONTAL_ALIGNMENT_CENTER
	przycisk_ponownie.add_theme_font_size_override("font_size", 20)
	przycisk_ponownie.add_theme_color_override("font_color", Color("#e8f4ff"))
	przycisk_ponownie.add_theme_color_override("font_hover_color", Color.WHITE)
	przycisk_ponownie.add_theme_stylebox_override("normal", _styl_przycisku(Color("#102838"), Color("#258fa5")))
	przycisk_ponownie.add_theme_stylebox_override("hover", _styl_przycisku(Color("#123b4a"), Color("#55e7ff")))
	przycisk_ponownie.add_theme_stylebox_override("pressed", _styl_przycisku(Color("#0e2d39"), Color("#35bcd5")))
	przycisk_ponownie.add_theme_stylebox_override("focus", _styl_przycisku(Color("#102838"), Color("#55e7ff")))
	przycisk_ponownie.z_index = 11
	przycisk_ponownie.pivot_offset = przycisk_ponownie.custom_minimum_size * 0.5
	przycisk_ponownie.resized.connect(func(): przycisk_ponownie.pivot_offset = przycisk_ponownie.size * 0.5)
	przycisk_ponownie.mouse_entered.connect(_animuj_przycisk.bind(przycisk_ponownie, true))
	przycisk_ponownie.mouse_exited.connect(_animuj_przycisk.bind(przycisk_ponownie, false))
	przycisk_ponownie.pressed.connect(_on_przycisk_ponownie)
	add_child(przycisk_ponownie)
	przycisk_ponownie.hide()
	get_viewport().size_changed.connect(_ustaw_pozycje_ekranu_konca)
	_ustaw_pozycje_ekranu_konca()


func _ustaw_pozycje_ekranu_konca():
	var wymiar = get_viewport_rect().size
	var srodek = wymiar * 0.5
	var karta = $KartaKoniecGry
	karta.position = srodek - Vector2(310.0, 260.0)
	karta.size = Vector2(620.0, 520.0)
	$Komunikat.position = srodek + Vector2(-270.0, -228.0)
	$Komunikat.size = Vector2(540.0, 96.0)
	$WynikKoncowy.position = srodek + Vector2(-270.0, -132.0)
	$WynikKoncowy.size = Vector2(540.0, 48.0)
	$PodsumowanieStatystyk.position = srodek + Vector2(-255.0, -70.0)
	$PodsumowanieStatystyk.size = Vector2(508.0, 200.0)
	$PrzyciskPonownie.position = srodek + Vector2(-150.0, 139.0)
	$PrzyciskPonownie.size = Vector2(300.0, 52.0)
	$PrzyciskMenu.position = srodek + Vector2(-150.0, 198.0)
	$PrzyciskMenu.size = Vector2(300.0, 52.0)


func _utworz_podsumowanie_statystyk() -> void:
	var siatka = GridContainer.new()
	siatka.name = "PodsumowanieStatystyk"
	siatka.columns = 2
	siatka.custom_minimum_size = Vector2(508.0, 200.0)
	siatka.size = Vector2(508.0, 200.0)
	siatka.add_theme_constant_override("h_separation", 12)
	siatka.add_theme_constant_override("v_separation", 12)
	siatka.mouse_filter = Control.MOUSE_FILTER_IGNORE
	siatka.z_index = 11
	add_child(siatka)
	siatka.hide()

	for i in range(4):
		var uklad_statystyki = VBoxContainer.new()
		uklad_statystyki.custom_minimum_size = Vector2(248.0, 94.0)
		uklad_statystyki.add_theme_constant_override("separation", 4)
		uklad_statystyki.mouse_filter = Control.MOUSE_FILTER_IGNORE
		siatka.add_child(uklad_statystyki)

		var nazwa = Label.new()
		nazwa.custom_minimum_size = Vector2(248.0, 28.0)
		nazwa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nazwa.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nazwa.add_theme_font_size_override("font_size", 16)
		nazwa.add_theme_color_override("font_color", Color("#c5d8ed"))
		nazwa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		uklad_statystyki.add_child(nazwa)
		etykiety_nazw_statystyk.append(nazwa)

		var karta = PanelContainer.new()
		karta.custom_minimum_size = Vector2(248.0, 62.0)
		karta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var styl = StyleBoxFlat.new()
		styl.bg_color = Color("#101f34")
		styl.border_color = Color("#315270")
		styl.set_border_width_all(2)
		styl.set_corner_radius_all(12)
		styl.shadow_color = Color("#55e7ff12")
		styl.shadow_size = 8
		styl.content_margin_left = 10.0
		styl.content_margin_right = 10.0
		styl.content_margin_top = 4.0
		styl.content_margin_bottom = 4.0
		karta.add_theme_stylebox_override("panel", styl)
		uklad_statystyki.add_child(karta)

		var wartosc = Label.new()
		wartosc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wartosc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		wartosc.add_theme_font_size_override("font_size", 31)
		wartosc.add_theme_font_override("font", FONT_ARCADE)
		wartosc.add_theme_color_override("font_color", Color("#55e7ff"))
		wartosc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		karta.add_child(wartosc)
		etykiety_wartosci_statystyk.append(wartosc)


func _odswiez_statystyki_koncowe() -> void:
	var czas = maxi(0, roundi(czas_meczu))
	var tekst_czasu = "%02d:%02d" % [floori(float(czas) / 60.0), czas % 60]
	var nazwy: Array[String]
	var wartosci: Array[String]
	if Ustawienia.tryb == "endless":
		$WynikKoncowy.text = "WYNIK  ·  %d" % wynik_gracza
	else:
		$WynikKoncowy.text = "%d     :     %d" % [wynik_gracza, wynik_ai]

	if Ustawienia.tryb == "endless":
		nazwy = ["Czas próby", "Odbicia łącznie", "Mocne odbicia łącznie", "Rekord osobisty"]
		wartosci = [tekst_czasu, str(stat_odbicia_gracza + stat_odbicia_rywala), str(stat_mocne_odbicia_gracza + stat_mocne_odbicia_rywala), str(Ustawienia.rekord_endless)]
	else:
		nazwy = ["Czas meczu", "Odbicia łącznie", "Mocne odbicia łącznie", "Najdłuższa wymiana"]
		wartosci = [
			tekst_czasu,
			str(stat_odbicia_gracza + stat_odbicia_rywala),
			str(stat_mocne_odbicia_gracza + stat_mocne_odbicia_rywala),
			str(najdluzsza_wymiana)
		]

	for i in range(4):
		etykiety_nazw_statystyk[i].text = nazwy[i]
		etykiety_wartosci_statystyk[i].text = wartosci[i]


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


func _animuj_przycisk(przycisk: Control, aktywne: bool):
	if przycisk.has_meta("animacja_najechania"):
		var poprzednia = przycisk.get_meta("animacja_najechania")
		if is_instance_valid(poprzednia):
			poprzednia.kill()
	var animacja = create_tween()
	przycisk.set_meta("animacja_najechania", animacja)
	animacja.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacja.tween_property(przycisk, "scale", Vector2(1.035, 1.035) if aktywne else Vector2.ONE, 0.14)


func _styl_przycisku(tlo: Color, obramowanie: Color) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = tlo
	styl.border_color = obramowanie
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(10)
	styl.content_margin_left = 18.0
	styl.content_margin_right = 18.0
	styl.content_margin_top = 8.0
	styl.content_margin_bottom = 8.0
	return styl


func _draw():
	var rozmiar_okna = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, rozmiar_okna), KOLOR_TLA, true)

	var plansza = Rect2(
		Vector2(Ustawienia.lewa_granica, Ustawienia.gorna_granica),
		Vector2(
			Ustawienia.prawa_granica - Ustawienia.lewa_granica,
			Ustawienia.dolna_granica - Ustawienia.gorna_granica
		)
	)

	draw_rect(plansza, KOLOR_PLANSZY, true)
	draw_rect(plansza, KOLOR_RAMKI, false, 3.0)
	draw_rect(plansza.grow(-10.0), Color(0.24, 0.39, 0.54, 0.2), false, 1.0)
	_rysuj_gumowe_sciany()
	if Ustawienia.tryb == "arena" and arena_manager != null and arena_manager.call("wieksza_arena_aktywna"):
		draw_rect(plansza, Color(0.65, 0.84, 1.0, 0.78), false, 3.0)

	var srodek_x = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) / 2.0
	var srodek_y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) / 2.0
	if Ustawienia.tryb == "arena" and postep_animacji_strefy > 0.001:
		var szerokosc_strefy = 104.0 * postep_animacji_strefy
		var strefa = Rect2(
			Vector2(srodek_x - szerokosc_strefy * 0.5, Ustawienia.gorna_granica),
			Vector2(szerokosc_strefy, Ustawienia.dolna_granica - Ustawienia.gorna_granica)
		)
		draw_rect(strefa, Color(1.0, 0.73, 0.22, 0.13 * postep_animacji_strefy), true)
		var kolor_krawedzi = Color(1.0, 0.79, 0.34, 0.72 * postep_animacji_strefy)
		draw_line(strefa.position, Vector2(strefa.position.x, strefa.end.y), kolor_krawedzi, 2.0)
		draw_line(Vector2(strefa.end.x, strefa.position.y), strefa.end, kolor_krawedzi, 2.0)
	if Ustawienia.tryb == "arena" and arena_manager != null and arena_manager.call("mocne_sciany_aktywne"):
		var kolor_scian = Color(1.0, 0.78, 0.3, 0.8)
		draw_line(Vector2(Ustawienia.lewa_granica, Ustawienia.gorna_granica), Vector2(Ustawienia.prawa_granica, Ustawienia.gorna_granica), kolor_scian, 4.0)
		draw_line(Vector2(Ustawienia.lewa_granica, Ustawienia.dolna_granica), Vector2(Ustawienia.prawa_granica, Ustawienia.dolna_granica), kolor_scian, 4.0)
	draw_arc(
		Vector2(srodek_x, srodek_y),
		54.0,
		0.0,
		TAU,
		64,
		Color(0.37, 0.59, 0.77, 0.17),
		2.0
	)
	draw_circle(Vector2(srodek_x, srodek_y), 3.0, Color(0.45, 0.67, 0.84, 0.3))
	var y = Ustawienia.gorna_granica + 20.0
	var koniec_linii = Ustawienia.dolna_granica - 10.0

	while y < koniec_linii:
		draw_line(
			Vector2(srodek_x, y),
			Vector2(srodek_x, min(y + 12.0, koniec_linii)),
			KOLOR_LINII,
			3.0
		)
		y += 24.0
	_rysuj_bramke_areny()

	if not $Komunikat.visible:
		var karta_gracza = _prostokat_karty_wyniku(0)
		var karta_ai = _prostokat_karty_wyniku(1)

		draw_rect(karta_gracza, KOLOR_KARTY_WYNIKU, true)
		draw_rect(karta_ai, KOLOR_KARTY_WYNIKU, true)
		draw_rect(karta_gracza, KOLOR_GRACZA, false, 2.0)
		draw_rect(karta_ai, Color("#a78bfa") if Ustawienia.tryb == "endless" else KOLOR_AI, false, 2.0)
		if Ustawienia.tryb == "arena":
			var nazwa_gracza = "GRACZ 1" if Ustawienia.arena_dwoch_graczy else "GRACZ"
			var nazwa_przeciwnika = "GRACZ 2" if Ustawienia.arena_dwoch_graczy else "BOT"
			_rysuj_wynik_na_srodku(karta_gracza, str(wynik_gracza), KOLOR_GRACZA, nazwa_gracza)
			_rysuj_wynik_na_srodku(karta_ai, str(wynik_ai), KOLOR_AI, nazwa_przeciwnika)
			_rysuj_licznik_odbic_areny()
		elif Ustawienia.tryb == "endless":
			_rysuj_nazwe_wyniku(karta_gracza, "SERIA", KOLOR_GRACZA)
			_rysuj_nazwe_wyniku(karta_ai, "REKORD", Color("#c4b5fd"))


func _rysuj_gumowe_sciany() -> void:
	for strona in [-1, 1]:
		var x_bazowy = Ustawienia.lewa_granica if strona < 0 else Ustawienia.prawa_granica
		var kolor = KOLOR_GRACZA if strona < 0 else KOLOR_AI
		if gumowa_sciana_strona != strona or gumowa_sciana_ugiecie <= 0.1:
			draw_line(
				Vector2(x_bazowy, Ustawienia.gorna_granica),
				Vector2(x_bazowy, Ustawienia.dolna_granica),
				Color(kolor, 0.22),
				1.5,
				true
			)
			continue

		var punkty = PackedVector2Array()
		var y = Ustawienia.gorna_granica
		while y <= Ustawienia.dolna_granica:
			var odleglosc = (y - gumowa_sciana_y) / 66.0
			var profil = exp(-odleglosc * odleglosc)
			var x = x_bazowy + float(strona) * gumowa_sciana_ugiecie * profil
			punkty.append(Vector2(x, y))
			y += 10.0
		punkty.append(Vector2(
			x_bazowy + float(strona) * gumowa_sciana_ugiecie * exp(-pow((Ustawienia.dolna_granica - gumowa_sciana_y) / 66.0, 2.0)),
			Ustawienia.dolna_granica
		))
		draw_polyline(punkty, Color(kolor, 0.2), 8.0, true)
		draw_polyline(punkty, Color(kolor, 0.82), 2.5, true)


func _rysuj_licznik_odbic_areny() -> void:
	var font = FONT_ARCADE
	var srodek_x = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5
	var karta_wyniku = _prostokat_karty_wyniku(0)
	var dol_karty_wyniku = karta_wyniku.end.y
	var odstep = Ustawienia.gorna_granica - dol_karty_wyniku
	var wysokosc = clampf(odstep - 3.0, 10.0, 18.0)
	var plakietka = Rect2(
		Vector2(srodek_x - 66.0, dol_karty_wyniku + 2.0),
		Vector2(132.0, wysokosc)
	)
	var styl = StyleBoxFlat.new()
	styl.bg_color = Color("#0b1725")
	styl.border_color = Color("#29465f")
	styl.set_border_width_all(1)
	styl.set_corner_radius_all(7)
	draw_style_box(styl, plakietka)

	var rozmiar_fontu = 12 if wysokosc >= 16.0 else 10
	var etykieta = "ODBICIA"
	var wartosc = str(odbicia_areny)
	var szerokosc_etykiety = font.get_string_size(etykieta, HORIZONTAL_ALIGNMENT_LEFT, -1, rozmiar_fontu).x
	var szerokosc_wartosci = font.get_string_size(wartosc, HORIZONTAL_ALIGNMENT_LEFT, -1, rozmiar_fontu).x
	var szerokosc_tekstu = szerokosc_etykiety + 8.0 + szerokosc_wartosci
	var poczatek_x = srodek_x - szerokosc_tekstu * 0.5
	var linia_bazowa = plakietka.position.y + (plakietka.size.y + font.get_ascent(rozmiar_fontu) - font.get_descent(rozmiar_fontu)) * 0.5
	draw_string(
		font,
		Vector2(poczatek_x, linia_bazowa),
		etykieta,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		rozmiar_fontu,
		Color("#a9bdd0")
	)
	draw_string(
		font,
		Vector2(poczatek_x + szerokosc_etykiety + 8.0, linia_bazowa),
		wartosc,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		rozmiar_fontu,
		KOLOR_GRACZA
	)


func _rysuj_bramke_areny() -> void:
	if Ustawienia.tryb != "arena" or arena_manager == null:
		return
	if not bool(arena_manager.call("bramka_aktywna")):
		return

	var segmenty: Array[Rect2] = arena_manager.call("dane_bramki")
	var alfa = float(arena_manager.call("przezroczystosc_bramki"))
	var kolor_bramki = Color("#a78bfa")
	var kolor_wypelnienia = kolor_bramki
	kolor_wypelnienia.a = 0.88 * alfa
	var kolor_obramowania = Color(0.86, 0.79, 1.0, 0.95 * alfa)
	for segment in segmenty:
		draw_rect(segment, kolor_wypelnienia, true)
		draw_rect(segment, kolor_obramowania, false, 2.0)


func _rysuj_wynik_na_srodku(karta: Rect2, tekst: String, kolor: Color, nazwa: String) -> void:
	var font = FONT_ARCADE
	var proporcja = karta.size.y / 54.0
	var rozmiar_nazwy = maxi(9, roundi(12.0 * proporcja))
	var rozmiar_wyniku = maxi(28, roundi(36.0 * proporcja))
	var linia_nazwy = karta.position.y - 4.0
	var srodek_wyniku_y = karta.position.y + karta.size.y * 0.5
	var linia_wyniku = srodek_wyniku_y + (font.get_ascent(rozmiar_wyniku) - font.get_descent(rozmiar_wyniku)) * 0.5
	draw_string(
		font,
		Vector2(karta.position.x + 2.0, linia_nazwy),
		nazwa,
		HORIZONTAL_ALIGNMENT_CENTER,
		karta.size.x - 4.0,
		rozmiar_nazwy,
		Color(kolor, 0.78)
	)
	draw_string(
		font,
		Vector2(karta.position.x, linia_wyniku),
		tekst,
		HORIZONTAL_ALIGNMENT_CENTER,
		karta.size.x,
		rozmiar_wyniku,
		kolor
	)


func _rysuj_nazwe_wyniku(karta: Rect2, nazwa: String, kolor: Color) -> void:
	var font = FONT_ARCADE
	var rozmiar_czcionki = 19
	draw_string(
		font,
		Vector2(karta.position.x, karta.position.y - 5.0),
		nazwa,
		HORIZONTAL_ALIGNMENT_CENTER,
		karta.size.x,
		rozmiar_czcionki,
		kolor
	)


func _prostokat_karty_wyniku(numer_karty: int) -> Rect2:
	var szerokosc = 84.0
	var wysokosc = clampf(Ustawienia.gorna_granica - 32.0, 38.0, 54.0)
	var odstep = 6.0
	var srodek = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) / 2.0
	var gora_karty = maxf(20.0, Ustawienia.gorna_granica - wysokosc - 24.0)
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
	if $Komunikat.visible:
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
	queue_redraw()
	$BonusManager.wyczysc_po_punkcie()
	odbicia_areny = 0
	queue_redraw()
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
	if rozpad_punktu_trwa or $Komunikat.visible:
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
	if Ustawienia.tryb != "endless" or $Komunikat.visible:
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
	queue_redraw()


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


func koniec_gry(tekst):
	$Komunikat.text = tekst
	$Komunikat.visible = true
	$WynikGracza.hide()
	$WynikAI.hide()
	$PrzyciskMenu.visible = true
	$PrzyciskPonownie.visible = true
	$PrzyciemnienieKoniecGry.visible = true
	$KartaKoniecGry.visible = true
	_odswiez_statystyki_koncowe()
	$WynikKoncowy.show()
	$PodsumowanieStatystyk.show()
	_animuj_pokaz_podsumowania()
	if is_instance_valid(endless_info):
		endless_info.hide()
	ukryj_informacje_graczowi()
	queue_redraw()
	$BonusManager.zatrzymaj()
	if arena_manager != null:
		arena_manager.call("zatrzymaj")

	for pilka in get_tree().get_nodes_in_group("pilki"):
		pilka.set_physics_process(false)

	$Paletka.set_physics_process(false)
	$PaletkaAI.set_physics_process(false)


func _animuj_pokaz_podsumowania() -> void:
	var warstwy: Array[Control] = [
		$PrzyciemnienieKoniecGry,
		$KartaKoniecGry,
		$Komunikat,
		$WynikKoncowy,
		$PodsumowanieStatystyk,
		$PrzyciskPonownie,
		$PrzyciskMenu
	]
	for warstwa in warstwy:
		warstwa.modulate.a = 0.0
	var animacja = create_tween()
	animacja.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for warstwa in warstwy:
		animacja.parallel().tween_property(warstwa, "modulate:a", 1.0, 0.22)


func _process(delta: float) -> void:
	if not $Komunikat.visible:
		czas_meczu += delta


func _on_przycisk_menu():
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_przycisk_ponownie():
	get_tree().paused = false
	get_tree().reload_current_scene()
