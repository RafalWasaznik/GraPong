extends CharacterBody2D

const SPEED_GRACZA = 400.0
const PROMIEN_PILKI = 13.0
const KOLOR_PALETKI = Color("#ff647a")
const CZAS_DASHU = 0.16
const CZAS_ODNOWIENIA_DASHU = 3.0
const ODLEGLOSC_DASHU = 190.0
const DZWIEK_DASH_GENERATOR = preload("res://dzwiek_dash.gd")

@onready var start_x = position.x

var nieprzewidywalny_czas = 0.0
var nieprzewidywalne_odchylenie = 0.0
var czas_blysku = 0.0
var idealne_odbicie = false
var dash_aktywne = false
var dash_czas = 0.0
var dash_start_y = 0.0
var dash_cel_y = 0.0
var dash_odnowienie = 0.0
var dash_efekt_czas = 0.0
var dash_efekt_kierunek = 0.0
var ostatni_kierunek = -1.0
var dzwiek_dasha: AudioStreamPlayer
var sieciowy_kierunek = 0.0
var sieciowy_dash_zadany = false


func _ready() -> void:
	$Obrys.hide()
	$ColorRect.hide()
	dzwiek_dasha = AudioStreamPlayer.new()
	dzwiek_dasha.name = "DzwiekDasha"
	dzwiek_dasha.stream = DZWIEK_DASH_GENERATOR.utworz_stream()
	dzwiek_dasha.volume_db = -9.0
	dzwiek_dasha.pitch_scale = 0.92
	dzwiek_dasha.bus = &"Efekty"
	add_child(dzwiek_dasha)
	queue_redraw()


func _process(delta: float) -> void:
	var odswiez = false
	if czas_blysku > 0.0:
		czas_blysku = maxf(0.0, czas_blysku - delta)
		odswiez = true
	if dash_efekt_czas > 0.0:
		dash_efekt_czas = maxf(0.0, dash_efekt_czas - delta)
		odswiez = true
	if odswiez:
		queue_redraw()


func _draw() -> void:
	var wysokosc = 120.0
	var ksztalt = $CollisionShape2D.shape as RectangleShape2D
	if ksztalt != null:
		wysokosc = ksztalt.size.y
	var czas_pelnego_blysku = 0.28 if idealne_odbicie else 0.14
	var blysk = clampf(czas_blysku / czas_pelnego_blysku, 0.0, 1.0)
	if dash_efekt_czas > 0.0:
		for i in range(3):
			var slad = StyleBoxFlat.new()
			var alfa_sladu = (0.28 - float(i) * 0.075) * dash_efekt_czas / 0.28
			slad.bg_color = Color(KOLOR_PALETKI.r, KOLOR_PALETKI.g, KOLOR_PALETKI.b, alfa_sladu)
			slad.set_corner_radius_all(5)
			var przesuniecie = -dash_efekt_kierunek * float(i + 1) * 30.0
			draw_style_box(slad, Rect2(-9.0, -wysokosc * 0.5 + przesuniecie, 18.0, wysokosc))

	var poswiata = StyleBoxFlat.new()
	poswiata.bg_color = Color(KOLOR_PALETKI.r, KOLOR_PALETKI.g, KOLOR_PALETKI.b, 0.08 + blysk * 0.12)
	poswiata.set_corner_radius_all(10)
	draw_style_box(poswiata, Rect2(-15.0, -wysokosc * 0.5 - 7.0, 30.0, wysokosc + 14.0))

	var obrys = StyleBoxFlat.new()
	obrys.bg_color = Color("#081321")
	obrys.border_color = Color(KOLOR_PALETKI.r, KOLOR_PALETKI.g, KOLOR_PALETKI.b, 0.72 + blysk * 0.28)
	obrys.set_border_width_all(1)
	obrys.set_corner_radius_all(7)
	draw_style_box(obrys, Rect2(-12.0, -wysokosc * 0.5 - 3.0, 24.0, wysokosc + 6.0))

	var wypelnienie = StyleBoxFlat.new()
	wypelnienie.bg_color = KOLOR_PALETKI.lerp(Color.WHITE, blysk * (0.72 if idealne_odbicie else 0.45))
	wypelnienie.set_corner_radius_all(5)
	draw_style_box(wypelnienie, Rect2(-9.0, -wysokosc * 0.5, 18.0, wysokosc))
	if idealne_odbicie and czas_blysku > 0.0:
		draw_line(Vector2(-6.0, 0.0), Vector2(6.0, 0.0), Color(1.0, 1.0, 1.0, blysk), 2.0)

	var wysokosc_strefy = wysokosc * 0.175
	var ciemniejszy_kolor = wypelnienie.bg_color.darkened(0.36)
	var strefa = StyleBoxFlat.new()
	strefa.bg_color = ciemniejszy_kolor
	strefa.set_corner_radius_all(4)
	draw_style_box(strefa, Rect2(-8.0, -wysokosc * 0.5 + 1.5, 16.0, wysokosc_strefy))
	draw_style_box(strefa, Rect2(-8.0, wysokosc * 0.5 - wysokosc_strefy - 1.5, 16.0, wysokosc_strefy))
	draw_line(Vector2(-6.0, -wysokosc * 0.5 + wysokosc_strefy + 1.5), Vector2(6.0, -wysokosc * 0.5 + wysokosc_strefy + 1.5), ciemniejszy_kolor.lightened(0.2), 1.0)
	draw_line(Vector2(-6.0, wysokosc * 0.5 - wysokosc_strefy - 1.5), Vector2(6.0, wysokosc * 0.5 - wysokosc_strefy - 1.5), ciemniejszy_kolor.lightened(0.2), 1.0)

	var wysokosc_blysku = maxf(wysokosc - 2.0 * (wysokosc_strefy + 5.0), 1.0)
	draw_rect(Rect2(-6.0, -wysokosc * 0.5 + wysokosc_strefy + 5.0, 3.0, wysokosc_blysku), Color(1.0, 1.0, 1.0, 0.22 + blysk * 0.2), true)
func efekt_odbicia(perfect_hit: bool = false) -> void:
	idealne_odbicie = perfect_hit
	czas_blysku = 0.28 if perfect_hit else 0.14
	queue_redraw()


func ustaw_pozycje_x(nowa_pozycja: float) -> void:
	start_x = nowa_pozycja
	position.x = nowa_pozycja


func _physics_process(delta):
	if Ustawienia.tryb == "online":
		if not Siec.czy_host():
			return
		var kierunek_online = sieciowy_kierunek
		if not is_zero_approx(kierunek_online):
			ostatni_kierunek = signf(kierunek_online)
		if sieciowy_dash_zadany and dash_odnowienie <= 0.0:
			var kierunek_dashu_online = signf(kierunek_online) if not is_zero_approx(kierunek_online) else ostatni_kierunek
			_rozpocznij_dash(kierunek_dashu_online)
		sieciowy_dash_zadany = false
		_odlicz_cooldown_dash(delta)
		if _aktualizuj_dash(delta):
			move_and_slide()
			_ogranicz_pozycje_y()
			position.x = start_x
			return
		velocity.y = kierunek_online * SPEED_GRACZA
		move_and_slide()
		_ogranicz_pozycje_y()
		position.x = start_x
		return
	if Ustawienia.tryb == "2graczy" or (Ustawienia.tryb == "arena" and Ustawienia.arena_dwoch_graczy):
		var kierunek = Input.get_axis("prawy_gora", "prawy_dol")
		if not is_zero_approx(kierunek):
			ostatni_kierunek = signf(kierunek)
		if Input.is_action_just_pressed("dash_gracza_2") and dash_odnowienie <= 0.0:
			var kierunek_dashu = signf(kierunek) if not is_zero_approx(kierunek) else ostatni_kierunek
			_rozpocznij_dash(kierunek_dashu)
		_odlicz_cooldown_dash(delta)
		if _aktualizuj_dash(delta):
			move_and_slide()
			_ogranicz_pozycje_y()
			position.x = start_x
			return
		velocity.y = kierunek * SPEED_GRACZA
	else:
		var predkosc_bota = 500.0
		var margines = 5.0

		match Ustawienia.trudnosc:
			"latwy":
				predkosc_bota = 350.0
				margines = 16.0
			"sredni":
				predkosc_bota = 450.0
				margines = 12.0
			"trudny":
				predkosc_bota = 550.0
				margines = 6.0
			"niemozliwy":
				predkosc_bota = 650.0
				margines = 0.0

		var pilka_cel = _wybierz_nadlatujaca_pilke()
		var nadlatuje = pilka_cel != null
		var przewidziane_y = _przewidz_przeciecie_y(pilka_cel) if nadlatuje else (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5
		var cel_y = przewidziane_y

		match Ustawienia.charakter_bota:
			"defensywny":
				# Wraca do środka, kiedy piłka leci na drugą stronę, i broni przewidywane miejsce odbicia.
				if not nadlatuje:
					cel_y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5

			"ofensywny":
				# Ustawia paletkę tak, by trafić piłkę blisko krawędzi i nadać jej ostry kąt.
				if nadlatuje:
					var polowa_do_ostrego_odbicia = _polowa_wysokosci_paletki()
					var trafienie_celowe = 0.72 if przewidziane_y < (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5 else -0.72
					cel_y -= trafienie_celowe * polowa_do_ostrego_odbicia
				else:
					cel_y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5

			"agresywny":
				# Dąży do częstych, szybkich wymian; prędkość piłki zwiększa się po jego odbiciu.
				if not nadlatuje:
					cel_y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5

			"nieprzewidywalny":
				# Zmienia punkt ustawienia co pewien czas, ale odchylenie maleje na wyższych trudnościach.
				nieprzewidywalny_czas -= delta
				if nieprzewidywalny_czas <= 0.0:
					var maksymalne_odchylenie = 58.0
					match Ustawienia.trudnosc:
						"sredni":
							maksymalne_odchylenie = 46.0
						"trudny":
							maksymalne_odchylenie = 34.0
						"niemozliwy":
							maksymalne_odchylenie = 22.0
					nieprzewidywalne_odchylenie = randf_range(-maksymalne_odchylenie, maksymalne_odchylenie)
					nieprzewidywalny_czas = randf_range(0.7, 1.5)
				cel_y += (nieprzewidywalne_odchylenie if nadlatuje else nieprzewidywalne_odchylenie * 0.35)

		var polowa_paletki = _polowa_wysokosci_paletki()
		cel_y = clampf(cel_y, Ustawienia.gorna_granica + polowa_paletki, Ustawienia.dolna_granica - polowa_paletki)
		var roznica = cel_y - position.y
		if nadlatuje and dash_odnowienie <= 0.0:
			var czas_do_paletki = maxf(0.0, (position.x - pilka_cel.position.x) / maxf(pilka_cel.velocity.x * _mnoznik_predkosci_areny(), 1.0))
			var prog_dasha = polowa_paletki + predkosc_bota * czas_do_paletki + 35.0
			if czas_do_paletki > CZAS_DASHU * 1.5 and czas_do_paletki < 0.65 and absf(roznica) > prog_dasha:
				_rozpocznij_dash(signf(roznica))

		if abs(roznica) > margines:
			var predkosc_ruchu = min(
				predkosc_bota,
				abs(roznica) / max(delta, 0.001)
			)
			velocity.y = sign(roznica) * predkosc_ruchu
		else:
			velocity.y = 0.0

	_odlicz_cooldown_dash(delta)
	if _aktualizuj_dash(delta):
		move_and_slide()
		_ogranicz_pozycje_y()
		position.x = start_x
		return
	move_and_slide()
	_ogranicz_pozycje_y()
	position.x = start_x


func _rozpocznij_dash(kierunek: float) -> void:
	if is_zero_approx(kierunek):
		return
	var polowa_wysokosci = _polowa_wysokosci_paletki()
	var minimum_y = Ustawienia.gorna_granica + polowa_wysokosci
	var maksimum_y = Ustawienia.dolna_granica - polowa_wysokosci
	var zasieg = minf(ODLEGLOSC_DASHU, (maksimum_y - minimum_y) * 0.8)
	var cel = clampf(position.y + signf(kierunek) * zasieg, minimum_y, maksimum_y)
	if is_equal_approx(cel, position.y):
		cel = clampf(position.y - signf(kierunek) * zasieg, minimum_y, maksimum_y)
		if is_equal_approx(cel, position.y):
			return
	dash_aktywne = true
	dash_czas = 0.0
	dash_start_y = position.y
	dash_cel_y = cel
	dash_efekt_kierunek = signf(kierunek)
	dash_efekt_czas = 0.28
	dash_odnowienie = CZAS_ODNOWIENIA_DASHU
	dzwiek_dasha.play()
	queue_redraw()


func _odlicz_cooldown_dash(delta: float) -> void:
	var odnowienie_przed_klatka = dash_odnowienie
	dash_odnowienie = maxf(0.0, dash_odnowienie - delta)
	if not is_equal_approx(odnowienie_przed_klatka, dash_odnowienie):
		queue_redraw()


func _aktualizuj_dash(delta: float) -> bool:
	if not dash_aktywne:
		return false
	dash_czas = minf(dash_czas + delta, CZAS_DASHU)
	var postep = clampf(dash_czas / CZAS_DASHU, 0.0, 1.0)
	var wygladzenie = postep * postep * (3.0 - 2.0 * postep)
	var pozycja_docelowa = lerpf(dash_start_y, dash_cel_y, wygladzenie)
	velocity.y = (pozycja_docelowa - position.y) / maxf(delta, 0.0001)
	if postep >= 1.0:
		dash_aktywne = false
	return true


func _ogranicz_pozycje_y() -> void:
	var polowa_wysokosci = _polowa_wysokosci_paletki()
	position.y = clampf(position.y, Ustawienia.gorna_granica + polowa_wysokosci, Ustawienia.dolna_granica - polowa_wysokosci)


func _polowa_wysokosci_paletki() -> float:
	var kolizja = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if kolizja != null and kolizja.shape is RectangleShape2D:
		return (kolizja.shape as RectangleShape2D).size.y * 0.5
	return 60.0


func ustaw_wysokosc(wysokosc: float) -> void:
	var kolizja = $CollisionShape2D
	if kolizja.shape is RectangleShape2D:
		var nowy_ksztalt = kolizja.shape.duplicate() as RectangleShape2D
		nowy_ksztalt.size.y = wysokosc
		kolizja.shape = nowy_ksztalt
	$Obrys.offset_top = -wysokosc * 0.5 - 3.0
	$Obrys.offset_bottom = wysokosc * 0.5 + 3.0
	$ColorRect.offset_top = -wysokosc * 0.5
	$ColorRect.offset_bottom = wysokosc * 0.5
	queue_redraw()


func _wybierz_nadlatujaca_pilke() -> CharacterBody2D:
	var wybrana_pilka: CharacterBody2D = null
	var najkrotszy_czas = INF

	for kandydat in get_tree().get_nodes_in_group("pilki"):
		if not is_instance_valid(kandydat):
			continue
		if kandydat.velocity.x <= 0.0:
			continue

		var predkosc_pozioma = kandydat.velocity.x * _mnoznik_predkosci_areny()
		var czas_do_paletki = (position.x - kandydat.position.x) / predkosc_pozioma
		if czas_do_paletki < 0.0:
			continue
		if czas_do_paletki < najkrotszy_czas:
			najkrotszy_czas = czas_do_paletki
			wybrana_pilka = kandydat

	return wybrana_pilka


func _przewidz_przeciecie_y(pilka: CharacterBody2D) -> float:
	var roznica_x = position.x - pilka.position.x
	var mnoznik = _mnoznik_predkosci_areny()
	var czas_do_paletki = maxf(0.0, roznica_x / maxf(pilka.velocity.x * mnoznik, 1.0))
	var przyspieszenie_y = 0.0
	if Ustawienia.tryb == "arena":
		var manager_areny = get_parent().get_node_or_null("ArenaManager")
		if manager_areny != null:
			przyspieszenie_y = manager_areny.call("przyspieszenie_y", pilka.velocity.x)
	var przewidziane_y = pilka.position.y + pilka.velocity.y * mnoznik * czas_do_paletki + 0.5 * przyspieszenie_y * czas_do_paletki * czas_do_paletki
	var gora = Ustawienia.gorna_granica + PROMIEN_PILKI
	var dol = Ustawienia.dolna_granica - PROMIEN_PILKI
	var zakres = maxf(dol - gora, 1.0)
	var pozycja_zawijana = fposmod(przewidziane_y - gora, zakres * 2.0)
	if pozycja_zawijana > zakres:
		return dol - (pozycja_zawijana - zakres)
	return gora + pozycja_zawijana


func _mnoznik_predkosci_areny() -> float:
	if Ustawienia.tryb != "arena":
		return 1.0
	var manager_areny = get_parent().get_node_or_null("ArenaManager")
	if manager_areny == null:
		return 1.0
	return float(manager_areny.call("mnoznik_predkosci"))
