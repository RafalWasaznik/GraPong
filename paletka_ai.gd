extends CharacterBody2D

const SPEED_GRACZA = 400.0
const PROMIEN_PILKI = 13.0
const KOLOR_PALETKI = Color("#ff647a")

@onready var start_x = position.x

var nieprzewidywalny_czas = 0.0
var nieprzewidywalne_odchylenie = 0.0
var czas_blysku = 0.0


func _ready() -> void:
	$Obrys.hide()
	$ColorRect.hide()
	queue_redraw()


func _process(delta: float) -> void:
	if czas_blysku > 0.0:
		czas_blysku = maxf(0.0, czas_blysku - delta)
		queue_redraw()


func _draw() -> void:
	var wysokosc = 120.0
	var ksztalt = $CollisionShape2D.shape as RectangleShape2D
	if ksztalt != null:
		wysokosc = ksztalt.size.y
	var blysk = clampf(czas_blysku / 0.14, 0.0, 1.0)

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
	wypelnienie.bg_color = KOLOR_PALETKI.lerp(Color.WHITE, blysk * 0.45)
	wypelnienie.set_corner_radius_all(5)
	draw_style_box(wypelnienie, Rect2(-9.0, -wysokosc * 0.5, 18.0, wysokosc))

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


func efekt_odbicia() -> void:
	czas_blysku = 0.14
	queue_redraw()


func ustaw_pozycje_x(nowa_pozycja: float) -> void:
	start_x = nowa_pozycja
	position.x = nowa_pozycja


func _physics_process(delta):
	if Ustawienia.tryb == "2graczy" or (Ustawienia.tryb == "arena" and Ustawienia.arena_dwoch_graczy):
		velocity.y = Input.get_axis("prawy_gora", "prawy_dol") * SPEED_GRACZA
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

		if abs(roznica) > margines:
			var predkosc_ruchu = min(
				predkosc_bota,
				abs(roznica) / max(delta, 0.001)
			)
			velocity.y = sign(roznica) * predkosc_ruchu
		else:
			velocity.y = 0.0

	move_and_slide()
	position.x = start_x


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
