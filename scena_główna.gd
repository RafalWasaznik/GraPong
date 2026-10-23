extends GraPongAPI

const SCENA_PILKI = preload("res://piłka.tscn")
const DZWIEK_PUNKTU = preload("res://punkt_sukces.wav")
const DZWIEKI_GRY = preload("res://dzwieki_gry.gd")
const FONT_ARCADE = preload("res://assets/fonts/Oxanium.ttf")

const CZAS_DODATKOWEJ_PILKI = 8.0
const MNOZNIK_PREDKOSCI_DODATKOWEJ = 0.8
const WYSOKOSC_SCIANY = 20.0
const ODSTEP_PALETKI = 30.0
const KOLOR_GRACZA = Color("#55d8f2")
const KOLOR_AI = Color("#ff647a")

var dzwiek_bonusu: AudioStreamPlayer
var dzwiek_modyfikatora: AudioStreamPlayer
var dzwiek_punktu: AudioStreamPlayer
var dzwiek_kamienia_milowego: AudioStreamPlayer
var dzwiek_rekordu: AudioStreamPlayer
var panel_informacyjny: PanelContainer
var animacja_granic_areny: Tween
var animacja_wymiarow_areny: Tween
var animacja_strefy: Tween
var animacja_wysokosci_paletek: Tween
var bazowe_wysokosci_paletek = Vector2.ZERO
var animacja_gumowej_sciany: Tween


func pobierz_wynik_gracza() -> int:
	return _przebieg_meczu.wynik_gracza


func pobierz_wynik_ai() -> int:
	return _przebieg_meczu.wynik_ai


func czy_mecz_zakonczony() -> bool:
	return _przebieg_meczu.mecz_zakonczony


func _enter_tree():
	if not przygotuj_referencje_sceny():
		return
	Ustawienia.ustaw_geometrie_planszy()
	_ustaw_geometrie_sceny()


func _ustaw_geometrie_sceny():
	var lewa = Ustawienia.lewa_granica
	var prawa = Ustawienia.prawa_granica
	var gora = Ustawienia.gorna_granica
	var dol = Ustawienia.dolna_granica

	var srodek_y = (gora + dol) / 2.0

	_ustaw_sciany_areny(lewa, prawa, gora, dol)

	_paletka_gracza.position = Vector2(lewa + ODSTEP_PALETKI, srodek_y)
	_paletka_rywala.position = Vector2(prawa - ODSTEP_PALETKI, srodek_y)


func _ustaw_sciany_areny(lewa: float, prawa: float, gora: float, dol: float) -> void:
	var srodek_x = (lewa + prawa) * 0.5
	var szerokosc = prawa - lewa
	_sciana_gorna.position = Vector2(srodek_x, gora)
	_sciana_dolna.position = Vector2(srodek_x, dol)
	_ustaw_ksztalt_sciany(_ksztalt_sciany_gornej, szerokosc)
	_ustaw_ksztalt_sciany(_ksztalt_sciany_dolnej, szerokosc)


func _ogranicz_paletki_pionowo(gora: float, dol: float) -> void:
	var polowa_gracza = _polowa_wysokosci_paletki(_paletka_gracza)
	var polowa_ai = _polowa_wysokosci_paletki(_paletka_rywala)
	_paletka_gracza.position.y = clampf(_paletka_gracza.position.y, gora + polowa_gracza, dol - polowa_gracza)
	_paletka_rywala.position.y = clampf(_paletka_rywala.position.y, gora + polowa_ai, dol - polowa_ai)


func _ogranicz_pilki_do_granic(gora: float, dol: float) -> void:
	for pilka in get_tree().get_nodes_in_group("pilki"):
		var promien: float = pilka.promien_aktualny()
		if pilka.position.y < gora + promien:
			pilka.position.y = gora + promien
			pilka.velocity.y = absf(pilka.velocity.y)
		elif pilka.position.y > dol - promien:
			pilka.position.y = dol - promien
			pilka.velocity.y = -absf(pilka.velocity.y)


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

	_ustaw_sciany_areny(Ustawienia.lewa_granica, Ustawienia.prawa_granica, gora, dol)
	_ogranicz_paletki_pionowo(gora, dol)
	_ogranicz_pilki_do_granic(gora, dol)
	_ustaw_etykiety_wyniku()
	odswiez_rysowanie()


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
	_ustaw_sciany_areny(lewa, prawa, gora, dol)
	_paletka_gracza.ustaw_pozycje_x(lewa + ODSTEP_PALETKI)
	_paletka_rywala.ustaw_pozycje_x(prawa - ODSTEP_PALETKI)
	_ogranicz_paletki_pionowo(gora, dol)
	_ogranicz_pilki_do_granic(gora, dol)
	_ustaw_etykiety_wyniku()
	odswiez_rysowanie()


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
		_postep_animacji_strefy,
		1.0 if pokaz else 0.0,
		czas
	)


func _ustaw_postep_animacji_strefy(postep: float) -> void:
	_postep_animacji_strefy = postep
	odswiez_rysowanie()


func animuj_wysokosc_paletek(proporcja: float, czas: float = 0.45) -> void:
	if is_instance_valid(animacja_wysokosci_paletek):
		animacja_wysokosci_paletek.kill()
	if bazowe_wysokosci_paletek == Vector2.ZERO:
		bazowe_wysokosci_paletek = Vector2(
			_polowa_wysokosci_paletki(_paletka_gracza) * 2.0,
			_polowa_wysokosci_paletki(_paletka_rywala) * 2.0
		)
	var wysokosci_startowe = Vector2(
		_polowa_wysokosci_paletki(_paletka_gracza) * 2.0,
		_polowa_wysokosci_paletki(_paletka_rywala) * 2.0
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
	_paletka_gracza.ustaw_wysokosc(wysokosci.x)
	_paletka_rywala.ustaw_wysokosc(wysokosci.y)


func animuj_rozmiar_pilki(proporcja: float, czas: float = 0.55) -> void:
	for pilka in get_tree().get_nodes_in_group("pilki"):
		(pilka as PilkaAPI).animuj_rozmiar(proporcja, czas)


func ustaw_ugiecie_gumowej_sciany(strona: int, y: float, ugiecie: float, kula_id: int) -> void:
	if is_instance_valid(animacja_gumowej_sciany):
		animacja_gumowej_sciany.kill()
	_gumowa_sciana_strona = strona
	_gumowa_sciana_y = y
	_gumowa_sciana_ugiecie = ugiecie
	_gumowa_sciana_kula_id = kula_id
	odswiez_rysowanie()


func odpusc_gumowa_sciane(kula_id: int) -> void:
	if _gumowa_sciana_kula_id != kula_id or _gumowa_sciana_ugiecie <= 0.0:
		return
	if is_instance_valid(animacja_gumowej_sciany):
		animacja_gumowej_sciany.kill()
	animacja_gumowej_sciany = create_tween()
	animacja_gumowej_sciany.set_trans(Tween.TRANS_CUBIC)
	animacja_gumowej_sciany.set_ease(Tween.EASE_OUT)
	animacja_gumowej_sciany.tween_method(
		_ustaw_ugiecie_gumowej_sciany_animowane,
		_gumowa_sciana_ugiecie,
		0.0,
		0.28
	)


func _ustaw_ugiecie_gumowej_sciany_animowane(ugiecie: float) -> void:
	_gumowa_sciana_ugiecie = ugiecie
	odswiez_rysowanie()


func _polowa_wysokosci_paletki(paletka: PaletkaBazowa) -> float:
	var kolizja = paletka.kolizja
	if kolizja != null and kolizja.shape is RectangleShape2D:
		return (kolizja.shape as RectangleShape2D).size.y * 0.5
	return 60.0


func _ready():
	if not _referencje_sceny_poprawne:
		return
	_pilka_glowna.punkt.connect(_przebieg_meczu._on_punkt)
	_pilka_glowna.odbicie_gracza.connect(_przebieg_meczu.zarejestruj_odbicie_endless)
	_pilka_glowna.statystyki_odbicia.connect(_przebieg_meczu.zarejestruj_odbicie)
	_pilka_glowna.odbicie_paletki.connect(_obsluga_online.odnotuj_odbicie_paletki)
	_pilka_glowna.odbicie_sciany.connect(_obsluga_online.odnotuj_odbicie_sciany)
	_ekran_konca.menu_pressed.connect(_on_przycisk_menu)
	_ekran_konca.replay_pressed.connect(_on_przycisk_ponownie)
	_obsluga_online.gra_rozpoczeta.connect(_online_uruchom_gre)
	_obsluga_online.gra_zatrzymana.connect(_online_zatrzymaj_gre)
	_obsluga_online.mecz_zakonczony.connect(_przebieg_meczu.zakoncz_mecz)
	_przebieg_meczu.uruchom(self)

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
	dzwiek_kamienia_milowego = _stworz_odtwarzacz_efektu(
		"DzwiekKamieniaMilowego",
		DZWIEKI_GRY.utworz_dzwiek_kamienia_milowego(),
		-4.0
	)
	dzwiek_rekordu = _stworz_odtwarzacz_efektu(
		"DzwiekRekordu",
		DZWIEKI_GRY.utworz_dzwiek_rekordu(),
		-1.0
	)

	if Ustawienia.tryb == "online":
		if Ustawienia.online_arena:
			_czas_bonusu.stop()
			_arena_manager = ArenaManager.new()
			_arena_manager.name = "ArenaManager"
			add_child(_arena_manager)
			_arena_manager.uruchom(self, Siec.czy_klient(), true)
		_obsluga_online.uruchom(self)
	elif Ustawienia.tryb == "endless":
		_paletka_rywala.hide()
		_paletka_rywala.set_physics_process(false)
		_paletka_rywala.kolizja.set_deferred("disabled", true)
		_czas_bonusu.stop()
	elif Ustawienia.tryb == "arena":
		_czas_bonusu.stop()
		_arena_manager = ArenaManager.new()
		_arena_manager.name = "ArenaManager"
		add_child(_arena_manager)
		_arena_manager.uruchom(self)
	else:
		_bonus_manager.uruchom(self)
		_pilka_glowna.runda_rozpoczeta.connect(_bonus_manager.runda_rozpoczeta)
		if Ustawienia.tryb == "bot" or (Ustawienia.tryb == "arena" and not Ustawienia.arena_dwoch_graczy):
			_pokaz_styl_bota()

	_ustaw_etykiety_wyniku()
	if Ustawienia.tryb == "endless":
		_przebieg_meczu.dodaj_info_endless()
	odswiez_rysowanie()


func _online_uruchom_gre() -> void:
	_paletka_gracza.set_physics_process(true)
	_paletka_rywala.set_physics_process(true)
	if _arena_manager != null:
		_arena_manager.rozpocznij()
	_pilka_glowna.reset()
	_pilka_glowna.set_physics_process(true)


func _online_zatrzymaj_gre() -> void:
	_paletka_gracza.set_physics_process(false)
	_paletka_rywala.set_physics_process(false)
	_pilka_glowna.set_physics_process(false)
	if _arena_manager != null:
		_arena_manager.set_process(false)
		_arena_manager.set_physics_process(false)


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


func odtworz_dzwiek_punktu() -> void:
	dzwiek_punktu.play()


func ustaw_tekst_konca_online(tekst: String) -> void:
	_obsluga_online.ustaw_tekst_konca(tekst)


func odtworz_dzwiek_modyfikatora() -> void:
	dzwiek_modyfikatora.play()


func odtworz_dzwiek_kamienia_milowego() -> void:
	dzwiek_kamienia_milowego.play()


func odtworz_dzwiek_rekordu() -> void:
	dzwiek_rekordu.play()


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


func prostokat_karty_wyniku(numer_karty: int) -> Rect2:
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
		_etykieta_wyniku_gracza.hide()
		_etykieta_wyniku_rywala.hide()
		return
	_etykieta_wyniku_gracza.show()
	_etykieta_wyniku_rywala.show()
	if Ustawienia.tryb == "endless":
		_etykieta_wyniku_gracza.text = str(wynik_gracza)
		_etykieta_wyniku_rywala.text = str(Ustawienia.rekord_endless)
		_etykieta_wyniku_gracza.add_theme_font_size_override("font_size", 36)
		_etykieta_wyniku_rywala.add_theme_font_size_override("font_size", 36)
		_ustaw_etykiete(_etykieta_wyniku_gracza, prostokat_karty_wyniku(0), KOLOR_GRACZA)
		_ustaw_etykiete(_etykieta_wyniku_rywala, prostokat_karty_wyniku(1), Color("#c4b5fd"))
		return
	_ustaw_etykiete(_etykieta_wyniku_gracza, prostokat_karty_wyniku(0), KOLOR_GRACZA)
	_ustaw_etykiete(_etykieta_wyniku_rywala, prostokat_karty_wyniku(1), KOLOR_AI)
	_etykieta_wyniku_gracza.add_theme_font_size_override("font_size", 36)
	_etykieta_wyniku_rywala.add_theme_font_size_override("font_size", 36)


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


func rozpocznij_rozpad_pilki(pilka_punktujaca: PilkaAPI) -> bool:
	if _rozpad_punktu_trwa or mecz_zakonczony:
		return false
	_rozpad_punktu_trwa = true
	for pilka in get_tree().get_nodes_in_group("pilki"):
		if pilka != pilka_punktujaca:
			pilka.set_physics_process(false)
	_paletka_gracza.set_physics_process(false)
	_paletka_rywala.set_physics_process(false)
	_bonus_manager.zatrzymaj()
	return true


func dodaj_dodatkowa_pilke(pilka_zrodlowa: PilkaAPI, pozycja_bonusu: Vector2) -> void:
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
	nowa_pilka.punkt.connect(_przebieg_meczu._on_punkt)
	nowa_pilka.statystyki_odbicia.connect(_przebieg_meczu.zarejestruj_odbicie)

	get_tree().create_timer(CZAS_DODATKOWEJ_PILKI, false).timeout.connect(
		nowa_pilka.queue_free
	)


func odswiez_rysowanie() -> void:
	if is_instance_valid(_rysowanie_areny):
		_rysowanie_areny.queue_redraw()


func _on_przycisk_menu():
	if Ustawienia.tryb == "online":
		Siec.rozlacz()
		Ustawienia.tryb = "bot"
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_przycisk_ponownie():
	get_tree().paused = false
	if Ustawienia.tryb == "online":
		Siec.pauza_lokalna = false
		if _obsluga_online.ponow_rozgrywke():
			return
	get_tree().reload_current_scene()
