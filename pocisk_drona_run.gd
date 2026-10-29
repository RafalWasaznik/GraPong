class_name PociskDronaRun
extends CharacterBody2D

signal trafiono_granice(pozycja: Vector2, normalna: Vector2)

signal trafiono_gracza(pozycja: Vector2)

const WARSTWA_GRACZA: int = 8
const PREDKOSC: float = 300.0
const PROMIEN: float = 4.0
var run_state: RunState
var zuzyty: bool = false


func _ready() -> void:
	add_to_group("pociski_dronow")
	Ustawienia.paleta_przeciwnikow_zmieniona.connect(queue_redraw)
	collision_layer = 0
	collision_mask = WARSTWA_GRACZA
	var kolizja := CollisionShape2D.new()
	var ksztalt := CircleShape2D.new()
	ksztalt.radius = PROMIEN
	kolizja.shape = ksztalt
	add_child(kolizja)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if zuzyty or is_queued_for_deletion():
		return
	if run_state == null or run_state.boss_aktywny or run_state.lives <= 0:
		queue_free()
		return
	if run_state.wybor_aktywny:
		return
	var ruch := velocity * delta
	var koniec := global_position + ruch
	var granice := Rect2(Vector2(Ustawienia.lewa_granica, Ustawienia.gorna_granica + 10.0), Vector2(Ustawienia.prawa_granica - Ustawienia.lewa_granica, Ustawienia.dolna_granica - Ustawienia.gorna_granica - 20.0))
	var bezpieczne := granice.grow(-PROMIEN)
	var t := 1.0
	var normalna := Vector2.ZERO
	for os in range(2):
		if ruch[os] == 0.0:
			continue
		var granica := bezpieczne.end[os] if ruch[os] > 0.0 else bezpieczne.position[os]
		var kandydat := (granica - global_position[os]) / ruch[os]
		if kandydat >= 0.0 and kandydat <= t:
			t = kandydat
			normalna = Vector2.ZERO
			normalna[os] = -signf(ruch[os])
	var kontakt := move_and_collide(ruch * t)
	if kontakt != null:
		zuzyty = true
		if kontakt.get_collider() is PaletkaBazowa:
			trafiono_gracza.emit(kontakt.get_position())
		queue_free()
	elif normalna != Vector2.ZERO:
		zuzyty = true
		var miejsce := global_position - normalna * PROMIEN
		trafiono_granice.emit(miejsce, normalna)
		var gra := get_parent() as GraPongAPI
		if gra != null and is_instance_valid(gra.efekty_wizualne):
			gra.efekty_wizualne.kontakt_pocisku(miejsce, normalna)
		queue_free()
	elif not granice.has_point(koniec):
		zuzyty = true
		queue_free()



func _draw() -> void:
	var paleta := PaletaPrzeciwnikow.pobierz(self)
	var ogon := -velocity.normalized() * 12.0
	draw_line(ogon, Vector2.ZERO, Color(paleta.zagrozenie, 0.4), 8.0, true)
	draw_line(ogon, Vector2.ZERO, paleta.zagrozenie, 3.0, true)
	draw_circle(Vector2.ZERO, PROMIEN, paleta.swiatlo)
	draw_circle(Vector2.ZERO, 2.0, paleta.rdzen)
