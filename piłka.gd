extends CharacterBody2D

signal punkt(strona)
signal odbicie_gracza(perfect_hit: bool)
signal odbicie_paletki
signal statystyki_odbicia(strona: String, mocne: bool)
signal runda_rozpoczeta

const SPEED = 620.0
const MAX_SPEED = 1120.0
const CZAS_STARTU = 1.2
const PROMIEN_OKREGU = 52.0
const PROMIEN_PILKI = 13.0
const MAKS_PROBEK_SLADU = 9
const ODLEGLOSC_PROBEK_SLADU = 4.0
const CZAS_EFEKTU_PERFECT_HIT = 0.3
const GRANICA_PERFECT_HIT = 0.65
const MAKSYMALNY_KAT_ODBICIA = 65.0
const MAKS_UGIECIA_GUMA_NISKA = 8.4
const MAKS_UGIECIA_GUMA_SREDNIA = 15.6
const MAKS_UGIECIA_GUMA_WYSOKA = 24.0
const CZAS_ROZPADU = 0.38
const LICZBA_FRAGMENTOW = 18

var predkosc = SPEED
var intro_aktywne = false
var intro_czas = 0.0
var srodek_intro = Vector2.ZERO
var perfect_hit_czas = 0.0
var efekt_strefy_czas = 0.0
var slady_pozycji: Array[Vector2] = []
var deformacja_gumowa_pilki = 0.0
var zglasza_kontakt_z_guma = false
var rozpad_aktywny = false
var rozpad_czas = 0.0
var strona_punktu = ""
var fragmenty_rozpadu: Array[Dictionary] = []


func _ready():
	add_to_group("pilki")
	set_process(false)
	reset()


func _draw():
	if intro_aktywne:
		var postep = clamp(intro_czas / CZAS_STARTU, 0.0, 1.0)
		var przezroczystosc = 0.18 * postep

		draw_arc(
			srodek_intro - position,
			PROMIEN_OKREGU,
			0.0,
			TAU,
			64,
			Color(0.7, 0.9, 1.0, przezroczystosc),
			3.0,
			true
		)

	for i in range(maxi(slady_pozycji.size() - 1, 0)):
		var postep_sladu = float(i + 1) / float(maxi(slady_pozycji.size() - 1, 1))
		var przezroczystosc_sladu = 0.02 + postep_sladu * 0.12
		draw_line(
			slady_pozycji[i] - position,
			slady_pozycji[i + 1] - position,
			Color(0.34, 0.84, 0.96, przezroczystosc_sladu),
			2.0 + postep_sladu * 5.0,
			true
		)

	if rozpad_aktywny:
		for fragment in fragmenty_rozpadu:
			var bok = float(fragment["rozmiar"])
			var ksztalt = PackedVector2Array([
				Vector2(-bok, -bok * 0.45),
				Vector2(bok * 0.8, -bok),
				Vector2(bok, bok * 0.55),
				Vector2(-bok * 0.45, bok)
			])
			draw_set_transform(fragment["pozycja"], float(fragment["rotacja"]), Vector2.ONE)
			draw_colored_polygon(ksztalt, fragment["kolor"])
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var skala_x = 1.0 - deformacja_gumowa_pilki * 0.216
		var skala_y = 1.0 + deformacja_gumowa_pilki * 0.168
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(skala_x, skala_y))
		draw_circle(Vector2.ZERO, 19.0, Color(0.25, 0.82, 0.96, 0.07))
		draw_circle(Vector2.ZERO, 15.0, Color(0.03, 0.09, 0.14, 0.8))
		draw_circle(Vector2.ZERO, 12.5, Color("#7ceaff"))
		draw_circle(Vector2.ZERO, 9.5, Color("#f4fdff"))
		draw_circle(Vector2(-3.2, -3.5), 3.0, Color(1.0, 1.0, 1.0, 0.82))
		draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 40, Color(0.55, 0.91, 1.0, 0.55), 1.2, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if perfect_hit_czas > 0.0:
		var alfa = clamp(perfect_hit_czas / CZAS_EFEKTU_PERFECT_HIT, 0.0, 1.0)
		draw_arc(
			Vector2.ZERO,
			PROMIEN_PILKI + 16.0,
			0.0,
			TAU,
			48,
			Color(0.3, 1.0, 1.0, alfa),
			4.0,
			true
		)

	if efekt_strefy_czas > 0.0:
		var alfa_strefy = clamp(efekt_strefy_czas / 0.35, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 40, Color(1.0, 0.78, 0.3, alfa_strefy), 2.5, true)


func reset():
	set_physics_process(true)
	set_process(false)
	rozpad_aktywny = false
	fragmenty_rozpadu.clear()
	strona_punktu = ""
	position = Vector2(
		(Ustawienia.lewa_granica + Ustawienia.prawa_granica) / 2.0,
		(Ustawienia.gorna_granica + Ustawienia.dolna_granica) / 2.0
	)
	set_meta("w_strefie_przyspieszenia", true)

	predkosc = SPEED

	var kierunek_x = 1.0 if randf() < 0.5 else -1.0
	var kat = deg_to_rad(randf_range(-65.0, 65.0))
	velocity = Vector2(kierunek_x, tan(kat)).normalized() * predkosc

	intro_aktywne = true
	intro_czas = CZAS_STARTU
	srodek_intro = position
	slady_pozycji.clear()
	deformacja_gumowa_pilki = 0.0
	zglasza_kontakt_z_guma = false

	queue_redraw()


func przyspiesz(mnoznik: float = 1.15):
	predkosc = min(predkosc * mnoznik, MAX_SPEED)

	if velocity.length() > 0.0:
		velocity = velocity.normalized() * predkosc


func pokaz_efekt_strefy_przyspieszenia() -> void:
	efekt_strefy_czas = 0.35
	queue_redraw()


func pokaz_efekt_mocnego_odbicia() -> void:
	efekt_strefy_czas = 0.35
	queue_redraw()


func dodaj_dodatkowa_pilke(pozycja_bonusu: Vector2):
	var scena_glowna = get_parent()

	if scena_glowna.has_method("dodaj_dodatkowa_pilke"):
		scena_glowna.dodaj_dodatkowa_pilke(self, pozycja_bonusu)


func _physics_process(delta):
	if efekt_strefy_czas > 0.0:
		efekt_strefy_czas = maxf(0.0, efekt_strefy_czas - delta)
		queue_redraw()

	if perfect_hit_czas > 0.0:
		perfect_hit_czas = maxf(0.0, perfect_hit_czas - delta)
		queue_redraw()

	if intro_aktywne:
		_aktualizuj_intro(delta)
		return

	var mnoznik_predkosci_areny = 1.0
	if Ustawienia.tryb == "arena":
		var manager_areny = get_parent().get_node_or_null("ArenaManager")
		if manager_areny != null:
			mnoznik_predkosci_areny = float(manager_areny.call("przygotuj_pilke", self, delta))

	var collision = move_and_collide(velocity * delta * mnoznik_predkosci_areny)
	_aktualizuj_kontakt_z_gumowa_sciana(mnoznik_predkosci_areny, delta)

	if collision:
		var obiekt = collision.get_collider()
		var normalna = collision.get_normal()

		if obiekt is CharacterBody2D and obiekt.is_in_group("pilki"):
			_odbicie_od_pilki(obiekt, normalna)
			$DzwiekPaletka.play()

		elif obiekt is CharacterBody2D:
			var perfect_hit = _odbicie_od_paletki(
				obiekt,
				collision.get_position()
			)
			if obiekt.has_method("efekt_odbicia"):
				obiekt.call("efekt_odbicia")
			odbicie_paletki.emit()
			statystyki_odbicia.emit("gracz" if obiekt.name == "Paletka" else "rywal", perfect_hit)
			if Ustawienia.tryb == "endless" and obiekt.name == "Paletka":
				odbicie_gracza.emit(perfect_hit)
			if Ustawienia.tryb in ["bot", "arena"] and obiekt.name == "PaletkaAI" and Ustawienia.charakter_bota == "agresywny":
				przyspiesz(1.04)

			if perfect_hit:
				$DzwiekPerfectHit.play()
			else:
				$DzwiekPaletka.play()

		else:
			velocity = velocity.bounce(normalna)
			if Ustawienia.tryb == "arena":
				var manager_areny = get_parent().get_node_or_null("ArenaManager")
				if manager_areny != null:
					manager_areny.call("wzmocnij_odbicie_od_sciany", self, str(obiekt.name))
			$DzwiekSciana.play()

	_dodaj_probke_sladu()
	queue_redraw()

	if Ustawienia.tryb == "endless" and position.x + PROMIEN_PILKI >= Ustawienia.prawa_granica:
		position.x = Ustawienia.prawa_granica - PROMIEN_PILKI
		velocity.x = -absf(velocity.x)
		$DzwiekSciana.play()
		return

	if position.x + PROMIEN_PILKI <= Ustawienia.lewa_granica:
		_rozpocznij_rozpad_punktu("lewa")
		return

	if position.x - PROMIEN_PILKI >= Ustawienia.prawa_granica:
		_rozpocznij_rozpad_punktu("prawa")
		return


func _rozpocznij_rozpad_punktu(strona: String) -> void:
	if rozpad_aktywny:
		return
	var scena_glowna = get_parent()
	if scena_glowna.has_method("rozpocznij_rozpad_pilki"):
		if not bool(scena_glowna.call("rozpocznij_rozpad_pilki", self)):
			set_physics_process(false)
			return

	_odpusc_gumowa_sciane()
	slady_pozycji.clear()
	strona_punktu = strona
	rozpad_aktywny = true
	rozpad_czas = 0.0
	fragmenty_rozpadu.clear()
	for i in range(LICZBA_FRAGMENTOW):
		var kat = TAU * float(i) / float(LICZBA_FRAGMENTOW) + randf_range(-0.16, 0.16)
		var kierunek = Vector2.RIGHT.rotated(kat)
		fragmenty_rozpadu.append({
			"pozycja": kierunek * randf_range(0.0, 3.0),
			"predkosc": kierunek * randf_range(90.0, 205.0) + velocity * 0.08,
			"rotacja": randf_range(0.0, TAU),
			"obrot": randf_range(-8.0, 8.0),
			"rozmiar": randf_range(2.2, 4.2),
			"kolor": [Color("#f4fdff"), Color("#7ceaff"), Color("#55d8f2")][i % 3]
		})
	set_physics_process(false)
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if not rozpad_aktywny:
		return
	rozpad_czas += delta
	var postep = clampf(rozpad_czas / CZAS_ROZPADU, 0.0, 1.0)
	for fragment in fragmenty_rozpadu:
		fragment["predkosc"] += Vector2(0.0, 110.0) * delta
		fragment["pozycja"] += fragment["predkosc"] * delta
		fragment["rotacja"] = float(fragment["rotacja"]) + float(fragment["obrot"]) * delta
		var kolor: Color = fragment["kolor"]
		kolor.a = 1.0 - postep
		fragment["kolor"] = kolor
	queue_redraw()
	if rozpad_czas >= CZAS_ROZPADU:
		set_process(false)
		rozpad_aktywny = false
		fragmenty_rozpadu.clear()
		punkt.emit(strona_punktu)


func _aktualizuj_kontakt_z_gumowa_sciana(mnoznik_predkosci: float, delta: float) -> void:
	var strona = 0
	var wcisniecie = 0.0
	if velocity.x < 0.0:
		wcisniecie = Ustawienia.lewa_granica + PROMIEN_PILKI - position.x
		if wcisniecie > 0.0:
			strona = -1
	elif velocity.x > 0.0 and Ustawienia.tryb != "endless":
		wcisniecie = position.x - (Ustawienia.prawa_granica - PROMIEN_PILKI)
		if wcisniecie > 0.0:
			strona = 1

	if strona != 0:
		var rzeczywista_predkosc = velocity.length() * mnoznik_predkosci
		var maks_ugiecia = MAKS_UGIECIA_GUMA_NISKA
		if rzeczywista_predkosc >= SPEED * 1.65:
			maks_ugiecia = MAKS_UGIECIA_GUMA_WYSOKA
		elif rzeczywista_predkosc >= SPEED * 1.25:
			maks_ugiecia = MAKS_UGIECIA_GUMA_SREDNIA
		var postep = clampf(wcisniecie / (PROMIEN_PILKI * 2.0), 0.0, 1.0)
		var ugiecie = maks_ugiecia * postep
		var nowa_deformacja = postep
		if not is_equal_approx(deformacja_gumowa_pilki, nowa_deformacja):
			deformacja_gumowa_pilki = nowa_deformacja
			queue_redraw()
		var scena_glowna = get_parent()
		if scena_glowna.has_method("ustaw_ugiecie_gumowej_sciany"):
			scena_glowna.call("ustaw_ugiecie_gumowej_sciany", strona, position.y, ugiecie, get_instance_id())
		zglasza_kontakt_z_guma = true
	else:
		if zglasza_kontakt_z_guma:
			_odpusc_gumowa_sciane()
		if deformacja_gumowa_pilki > 0.0:
			deformacja_gumowa_pilki = move_toward(deformacja_gumowa_pilki, 0.0, delta * 5.0)
			queue_redraw()


func _odpusc_gumowa_sciane() -> void:
	if not zglasza_kontakt_z_guma:
		return
	zglasza_kontakt_z_guma = false
	var scena_glowna = get_parent()
	if scena_glowna.has_method("odpusc_gumowa_sciane"):
		scena_glowna.call("odpusc_gumowa_sciane", get_instance_id())


func _dodaj_probke_sladu() -> void:
	if not slady_pozycji.is_empty() and slady_pozycji[slady_pozycji.size() - 1].distance_to(position) < ODLEGLOSC_PROBEK_SLADU:
		return
	slady_pozycji.append(position)
	while slady_pozycji.size() > MAKS_PROBEK_SLADU:
		slady_pozycji.pop_front()


func _odbicie_od_paletki(
	paletka: CharacterBody2D,
	punkt_kontaktu: Vector2
) -> bool:
	var polowa_wysokosci = 60.0
	var kolizja = paletka.get_node_or_null("CollisionShape2D") as CollisionShape2D

	if kolizja != null and kolizja.shape is RectangleShape2D:
		polowa_wysokosci = (kolizja.shape as RectangleShape2D).size.y / 2.0

	var trafienie = clamp(
		(punkt_kontaktu.y - paletka.global_position.y) / maxf(polowa_wysokosci, 1.0),
		-1.0,
		1.0
	)
	var kat = deg_to_rad(trafienie * MAKSYMALNY_KAT_ODBICIA)
	var kierunek_x = 1.0 if global_position.x > paletka.global_position.x else -1.0
	velocity = Vector2(kierunek_x * cos(kat), sin(kat)).normalized() * predkosc
	position.x += kierunek_x * 0.5

	if absf(trafienie) >= GRANICA_PERFECT_HIT:
		predkosc = minf(predkosc * 1.07, MAX_SPEED)
		velocity = velocity.normalized() * predkosc
		perfect_hit_czas = CZAS_EFEKTU_PERFECT_HIT
		queue_redraw()
		return true

	return false


func _odbicie_od_pilki(inna_pilka: CharacterBody2D, normalna: Vector2):
	var predkosc_wzgledna = velocity - inna_pilka.velocity
	var predkosc_wzdluz_normalnej = predkosc_wzgledna.dot(normalna)

	# Wymiana składowych prędkości daje zderzenie dwóch piłek.
	if predkosc_wzdluz_normalnej < 0.0:
		velocity -= normalna * predkosc_wzdluz_normalnej
		inna_pilka.velocity += normalna * predkosc_wzdluz_normalnej

		predkosc = velocity.length()
		inna_pilka.predkosc = inna_pilka.velocity.length()

	# Lekko rozsuń piłki, by nie utknęły w sobie po zderzeniu.
	position += normalna * 0.5
	inna_pilka.position -= normalna * 0.5


func _aktualizuj_intro(delta):
	intro_czas -= delta

	var nastepna_pozycja = position + velocity * delta
	var odleglosc = nastepna_pozycja.distance_to(srodek_intro)
	var maksymalna_odleglosc = PROMIEN_OKREGU - PROMIEN_PILKI

	if odleglosc >= maksymalna_odleglosc:
		var normalna = (nastepna_pozycja - srodek_intro).normalized()
		velocity = velocity.bounce(normalna)
		nastepna_pozycja = srodek_intro + normalna * maksymalna_odleglosc

	position = nastepna_pozycja

	if intro_czas <= 0.0:
		intro_aktywne = false
		runda_rozpoczeta.emit()

	queue_redraw()
