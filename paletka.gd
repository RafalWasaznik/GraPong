extends CharacterBody2D

const SPEED = 400.0
const KOLOR_PALETKI = Color("#55d8f2")

@onready var start_x = position.x
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

func _physics_process(_delta):
	var kierunek = Input.get_axis("lewy_gora", "lewy_dol")
	if Ustawienia.tryb == "bot" or (Ustawienia.tryb == "arena" and not Ustawienia.arena_dwoch_graczy):
		kierunek += Input.get_axis("prawy_gora", "prawy_dol")
	velocity.y = clamp(kierunek, -1.0, 1.0) * SPEED
	move_and_slide()
	position.x = start_x


func ustaw_wysokosc(wysokosc: float):
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
