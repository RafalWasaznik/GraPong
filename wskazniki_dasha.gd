extends Node2D

const CZAS_ODNOWIENIA_DASHU = 3.0
const SZEROKOSC_PASKA = 90.0
const WYSOKOSC_PASKA = 14.0

var gra: GraPongAPI
var styl_tla: StyleBoxFlat
var styl_wypelnienia: StyleBoxFlat
var styl_poswiaty: StyleBoxFlat


func _ready() -> void:
	gra = get_parent()
	styl_tla = _utworz_styl(Color("#101a29"), Color("#41536a"), 1)
	styl_wypelnienia = _utworz_styl(Color.RED, Color.TRANSPARENT, 0)
	styl_poswiaty = _utworz_styl(Color.TRANSPARENT, Color.GREEN, 2)
	styl_poswiaty.shadow_size = 9
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if gra == null or gra.mecz_zakonczony:
		return
	var dol_paska = minf(Ustawienia.dolna_granica + 35.0, get_viewport_rect().size.y - WYSOKOSC_PASKA - 18.0)
	var paletka_gracza := gra.paletka_gracza
	var paletka_rywala := gra.paletka_rywala
	_rysuj_pasek(paletka_gracza, dol_paska)
	if Ustawienia.tryb != "endless" and paletka_rywala != null and paletka_rywala.visible:
		_rysuj_pasek(paletka_rywala, dol_paska)


func _rysuj_pasek(paletka: PaletkaBazowa, y: float) -> void:
	if paletka == null or not paletka.visible:
		return
	var gotowosc = 1.0 - clampf(paletka.dash_odnowienie / CZAS_ODNOWIENIA_DASHU, 0.0, 1.0)
	var kolor = Color.from_hsv(lerpf(0.0, 0.33, gotowosc), 0.88, 1.0)
	var x_paska = clampf(
		paletka.global_position.x,
		Ustawienia.lewa_granica + SZEROKOSC_PASKA * 0.5 + 9.0,
		Ustawienia.prawa_granica - SZEROKOSC_PASKA * 0.5 - 9.0
	)
	var prostokat = Rect2(
		Vector2(x_paska - SZEROKOSC_PASKA * 0.5, y),
		Vector2(SZEROKOSC_PASKA, WYSOKOSC_PASKA)
	)
	draw_style_box(styl_tla, prostokat)
	var szerokosc_wypelnienia = maxf(8.0, (SZEROKOSC_PASKA - 6.0) * gotowosc)
	if szerokosc_wypelnienia > 0.0:
		styl_wypelnienia.bg_color = kolor
		draw_style_box(
			styl_wypelnienia,
			Rect2(prostokat.position + Vector2(3.0, 3.0), Vector2(szerokosc_wypelnienia, WYSOKOSC_PASKA - 6.0))
		)
	if gotowosc >= 1.0:
		var puls = 0.65 + 0.35 * (0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006))
		styl_poswiaty.border_color = Color(kolor, puls)
		styl_poswiaty.shadow_color = Color(kolor, puls * 0.72)
		draw_style_box(styl_poswiaty, prostokat.grow(1.0))


func _utworz_styl(kolor_tla: Color, kolor_obramowania: Color, grubosc_obramowania: int) -> StyleBoxFlat:
	var styl = StyleBoxFlat.new()
	styl.bg_color = kolor_tla
	styl.border_color = kolor_obramowania
	styl.set_border_width_all(grubosc_obramowania)
	styl.set_corner_radius_all(8)
	return styl
