class_name ScianaSrodkaArena
extends Node

const CZAS_ZANIKANIA = 0.38
const PROMIEN = 54.0
const SZEROKOSC = 10.0
const LICZBA_SEGMENTOW = 48

var gra: GraPongAPI
var cialo: StaticBody2D
var postep = 0.0
var animacja: Tween


func uruchom(gra_glowna: GraPongAPI) -> void:
	gra = gra_glowna


func _process(_delta: float) -> void:
	if is_instance_valid(cialo):
		var pozycja = Vector2(
			(Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5,
			(Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5
		)
		if cialo.position != pozycja:
			cialo.position = pozycja


func aktywna() -> bool:
	return is_instance_valid(cialo) and postep > 0.0


func aktualizuj_pozycje() -> void:
	_ustaw_pozycje()


func przezroczystosc() -> float:
	return postep


func utworz() -> void:
	if is_instance_valid(cialo):
		if is_instance_valid(animacja):
			animacja.kill()
		animacja = null
		postep = 1.0
		return

	cialo = StaticBody2D.new()
	cialo.name = "ScianaSrodkaArena"
	cialo.collision_layer = 1
	cialo.collision_mask = 1
	add_child(cialo)
	var ksztalt_sciany = RectangleShape2D.new()
	var dlugosc_segmentu = 2.0 * PROMIEN * sin(PI / LICZBA_SEGMENTOW)
	ksztalt_sciany.size = Vector2(SZEROKOSC, dlugosc_segmentu + 3.0)
	for i in range(LICZBA_SEGMENTOW):
		var kat = TAU * float(i) / float(LICZBA_SEGMENTOW)
		var kolizja = CollisionShape2D.new()
		kolizja.shape = ksztalt_sciany
		kolizja.position = Vector2(cos(kat), sin(kat)) * PROMIEN
		kolizja.rotation = kat
		cialo.add_child(kolizja)
	postep = 1.0
	_ustaw_pozycje()
	_odswiez_rysowanie()


func wygasz(czas: float = CZAS_ZANIKANIA) -> void:
	if not is_instance_valid(cialo):
		return
	if is_instance_valid(animacja):
		animacja.kill()
	animacja = create_tween()
	animacja.set_trans(Tween.TRANS_CUBIC)
	animacja.set_ease(Tween.EASE_IN)
	animacja.tween_method(_ustaw_postep, postep, 0.0, maxf(czas, 0.01))
	animacja.tween_callback(_usun)


func zatrzymaj() -> void:
	if is_instance_valid(animacja):
		animacja.kill()
	_usun()


func _ustaw_pozycje() -> void:
	if not is_instance_valid(cialo):
		return
	cialo.position = Vector2(
		(Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5,
		(Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5
	)


func _ustaw_postep(wartosc: float) -> void:
	postep = clampf(wartosc, 0.0, 1.0)
	_odswiez_rysowanie()


func _usun() -> void:
	if is_instance_valid(cialo):
		cialo.queue_free()
	cialo = null
	postep = 0.0
	animacja = null
	_odswiez_rysowanie()


func _odswiez_rysowanie() -> void:
	if is_instance_valid(gra):
		gra._odswiez_rysowanie()
