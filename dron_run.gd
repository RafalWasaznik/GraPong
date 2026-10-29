class_name DronRun
extends KrysztalRun

signal wystrzelono(pocisk: PociskDronaRun)

const DRONE_SPAWN_CHANCE: float = 0.30
const MAX_ACTIVE_DRONES: int = 2
const DRONE_SCORE: int = 2
const DRONE_FIRE_INTERVAL_MIN: float = 2.5
const DRONE_FIRE_INTERVAL_MAX: float = 4.0
const DRONE_WARNING_DURATION: float = 0.5
const CZAS_NAMIERZANIA: float = 0.4

var sledzony_cel: Vector2
var paletka: PaletkaBazowa
var czas_do_strzalu: float = 0.0
var ostrzezenie: float = 0.0
var kierunek_dzialka: Vector2 = Vector2.LEFT
var zablokowany_kierunek: Vector2 = Vector2.LEFT
var blysk_lufy: float = 0.0
var miejsce_trafienia := Vector2(-18.0, -8.0)
var slady_trafien: Array[Vector2] = []
var czas_trafienia: float = 0.0
var numer_trafienia: int = 0


func trafienie(obrazenia: int, od_pilki: bool = true) -> void:
	if rozpad or is_queued_for_deletion():
		return
	var poprzednie_hp := hp
	var poprzedni_pancerz := armor_hp
	super.trafienie(obrazenia, od_pilki)
	if hp == poprzednie_hp and armor_hp == poprzedni_pancerz:
		return
	numer_trafienia += 1
	czas_trafienia = 0.22
	if not od_pilki:
		miejsce_trafienia = Vector2.RIGHT.rotated(numer_trafienia * 2.4) * 20.0
	miejsce_trafienia = miejsce_trafienia.limit_length(27.0)
	slady_trafien.append(miejsce_trafienia)
	if slady_trafien.size() > 12:
		slady_trafien.pop_front()



static func czy_zastapic(aktywne: int) -> bool:
	return aktywne < MAX_ACTIVE_DRONES and randf() < DRONE_SPAWN_CHANCE


func nagroda_bazowa() -> float:
	return float(DRONE_SCORE)


func _ready() -> void:
	super._ready()
	name = "DronBojowy"
	sledzony_cel = paletka.global_position if is_instance_valid(paletka) else global_position + Vector2.LEFT
	czas_do_strzalu = randf_range(DRONE_FIRE_INTERVAL_MIN, DRONE_FIRE_INTERVAL_MAX)


func _physics_process(delta: float) -> void:
	if run_state == null or not run_state.wybor_aktywny:
		czas_trafienia = maxf(0.0, czas_trafienia - delta)
	super._physics_process(delta)
	if rozpad or is_queued_for_deletion() or run_state == null or run_state.wybor_aktywny or run_state.boss_aktywny or not is_instance_valid(paletka):
		return
	blysk_lufy = maxf(0.0, blysk_lufy - delta)
	if ostrzezenie > 0.0:
		ostrzezenie = maxf(0.0, ostrzezenie - delta)
		if ostrzezenie == 0.0:
			_wystrzel()
	else:
		sledzony_cel = sledzony_cel.lerp(paletka.global_position, 1.0 - exp(-delta / CZAS_NAMIERZANIA))
		kierunek_dzialka = (sledzony_cel - global_position).normalized()
		czas_do_strzalu -= delta
		if czas_do_strzalu <= DRONE_WARNING_DURATION:
			zablokowany_kierunek = kierunek_dzialka
			ostrzezenie = DRONE_WARNING_DURATION
	queue_redraw()


func _wystrzel() -> void:
	var pocisk := PociskDronaRun.new()
	pocisk.run_state = run_state
	pocisk.position = position + zablokowany_kierunek * (PROMIEN + 7.0)
	pocisk.velocity = zablokowany_kierunek * PociskDronaRun.PREDKOSC
	wystrzelono.emit(pocisk)
	get_parent().add_child(pocisk)
	blysk_lufy = 0.12
	czas_do_strzalu = randf_range(DRONE_FIRE_INTERVAL_MIN, DRONE_FIRE_INTERVAL_MAX)
	var gra := get_parent() as GraPongAPI
	if gra != null and is_instance_valid(gra.efekty_wizualne):
		gra.efekty_wizualne.dzwiek_energii(0)


func _draw() -> void:
	var paleta := PaletaPrzeciwnikow.pobierz(self)
	if rozpad:
		_rysuj_awarie()
		return
	var puls := 0.5 + 0.5 * sin(czas_animacji * 5.0)
	var ladunek := 1.0 - ostrzezenie / DRONE_WARNING_DURATION if ostrzezenie > 0.0 else 0.0
	var uszkodzenie := stopien_uszkodzenia()
	var migotanie := 1.0 - (uszkodzenie if etap_uszkodzenia() > 0 else 0.0) * 0.18 * (0.5 + 0.5 * sin(czas_animacji * 11.0 + float(get_instance_id() % 31)))
	var energia := paleta.zagrozenie.lerp(paleta.swiatlo, 0.35 + puls * 0.25).lerp(paleta.rdzen, ladunek * 0.7).lerp(Color.WHITE, maxf(blysk * 4.0, blysk_lufy * 6.0))
	energia = Color(energia * migotanie, 1.0)
	if ostrzezenie > 0.0:
		draw_line(zablokowany_kierunek * 35.0, zablokowany_kierunek * 1800.0, Color(0.03,0.01,0.04,0.7), 3.0, true)
		draw_line(zablokowany_kierunek * 35.0, zablokowany_kierunek * 1800.0, Color(paleta.zagrozenie, 0.55), 1.0, true)
	var etap := etap_uszkodzenia()
	# Mechanizm pod segmentami pozostaje w tym samym obrysie na każdym etapie.
	for znak in [-1.0, 1.0]:
		var y: float = znak * 18.0
		draw_rect(Rect2(-22, y - 4, 45, 8), paleta.korpus)
		for i in range(7):
			draw_line(Vector2(-19 + i * 6, y - 3), Vector2(-16 + i * 6, y + 3), paleta.pancerz_ciezki, 1.4, true)
		draw_line(Vector2(-20,y),Vector2(21,y),Color(energia,0.65),1.2,true)
		for i in range(3):
			var x := -23.0 + i * 16.0
			var wyrwa := (etap >= 2 and i == (0 if znak < 0 else 2)) or (etap == 3 and i == 1)
			if wyrwa:
				draw_colored_polygon(PackedVector2Array([Vector2(x,y-5),Vector2(x+5,y-5),Vector2(x+2,y),Vector2(x+6,y+5),Vector2(x,y+5)]),paleta.pancerz)
				continue
			var plyta := PackedVector2Array([Vector2(x,y-5),Vector2(x+12,y-5),Vector2(x+15,y+3),Vector2(x+10,y+6),Vector2(x,y+5)])
			draw_colored_polygon(plyta,paleta.pancerz)
			draw_line(plyta[0]+Vector2(2,1),plyta[1],paleta.swiatlo,1.2,true)
			draw_circle(Vector2(x+4,y+2),1.5,paleta.korpus)
			if etap > 0 and i != 1:
				draw_polyline(PackedVector2Array([Vector2(x+9,y-5),Vector2(x+6,y-1),Vector2(x+9,y+2),Vector2(x+7,y+5)]),paleta.korpus,2.0,true)
	var korpus := PackedVector2Array([Vector2(-20,-12),Vector2(12,-15),Vector2(23,-7),Vector2(23,7),Vector2(12,15),Vector2(-20,12)])
	draw_colored_polygon(korpus, paleta.korpus)
	korpus.append(korpus[0])
	draw_polyline(korpus, paleta.pancerz_ciezki, 2.0, true)
	for i in range(5):
		draw_line(Vector2(-15+i*7,-10),Vector2(-15+i*7,10),paleta.pancerz_ciezki,1.4,true)
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 20, energia, 1.5,true)
	for i in range(4):
		if etap >= 2 and i == 0 or etap == 3 and i == 3:
			continue
		var kierunek := Vector2.RIGHT.rotated(PI*0.25+i*PI*0.5)
		var srodek := kierunek*11.0
		var przesuniecie := kierunek*(etap*0.6)
		var plyta := PackedVector2Array([srodek+Vector2(-7,-5)+przesuniecie,srodek+Vector2(5,-5),srodek+Vector2(7,3),srodek+Vector2(-5,5)])
		draw_colored_polygon(plyta,paleta.pancerz)
		draw_line(plyta[0],plyta[1],paleta.swiatlo,1.0,true)
		if etap > 0:
			draw_polyline(PackedVector2Array([srodek+Vector2(-3,-5),srodek+Vector2(1,-1),srodek+Vector2(-2,4)]),paleta.korpus,1.6,true)
	draw_circle(Vector2.ZERO, 9.0 + puls + ladunek * 4.0, Color(energia, 0.18 + ladunek * 0.25))
	draw_circle(Vector2.ZERO, 5.0, energia)
	draw_circle(Vector2(-2,-2), 2.0, paleta.rdzen)
	for slad in slady_trafien:
		if etap == 0:
			continue
		var wewnatrz := -slad.normalized()
		draw_polyline(PackedVector2Array([slad,slad+wewnatrz*4.0+Vector2(1,2),slad+wewnatrz*8.0]),paleta.korpus,2.2,true)
		draw_line(slad+Vector2(1,0),slad+wewnatrz*4.0,Color(paleta.pekniecie,0.8),0.9,true)
	if etap == 3 and fmod(czas_animacji, 0.83) < 0.12:
		var miejsce: Vector2 = slady_trafien.back() if not slady_trafien.is_empty() else Vector2(14,-9)
		draw_polyline(PackedVector2Array([miejsce,miejsce+Vector2(5,-6),miejsce+Vector2(2,-10),miejsce+Vector2(9,-13)]),Color(paleta.swiatlo,0.75),1.2,true)
	var axe := zablokowany_kierunek if ostrzezenie > 0.0 or blysk_lufy > 0.0 else kierunek_dzialka
	draw_set_transform(-axe * (blysk_lufy / 0.12) * 3.0, axe.angle())
	draw_circle(Vector2(6,0), 8.0, paleta.pancerz)
	draw_rect(Rect2(5,-5,29,10), paleta.korpus)
	if etap < 3:
		draw_rect(Rect2(10,-3,10,6), paleta.pancerz)
	if etap < 2:
		draw_rect(Rect2(22,-3,11,6), paleta.pancerz)
	else:
		for i in range(4):
			draw_line(Vector2(22+i*3,-3),Vector2(22+i*3,3),paleta.pancerz_ciezki,1.2,true)
	draw_line(Vector2(13,0), Vector2(34,0), energia, 2.0 + (2.0 if ostrzezenie > 0.0 else 0.0), true)
	draw_rect(Rect2(30,-6,5,12), paleta.pancerz_ciezki)
	if etap_uszkodzenia() > 0:
		draw_polyline(PackedVector2Array([Vector2(18,-5),Vector2(23,-1),Vector2(22,4)]), Color(paleta.zagrozenie, uszkodzenie), 1.5, true)
	if blysk_lufy > 0.0:
		var flash := blysk_lufy / 0.12
		draw_arc(Vector2(35,0), 3.0 + (1.0 - flash) * 16.0, 0.0, TAU, 20, Color(paleta.swiatlo, flash * 0.7), 1.5, true)
		draw_colored_polygon(PackedVector2Array([Vector2(35,-7),Vector2(35+20*flash,0),Vector2(35,7),Vector2(40,0)]), Color(paleta.rdzen, flash))
	draw_set_transform(Vector2.ZERO)
	if czas_trafienia > 0.0:
		var t := 1.0 - czas_trafienia / 0.22
		var sila := clampf(Ustawienia.intensywnosc_efektow / 100.0, 0.0, 1.0)
		draw_circle(miejsce_trafienia, 5.0 * (1.0-t), Color(paleta.swiatlo,(1.0-t)*sila))
		for i in range(5):
			var kierunek := Vector2.RIGHT.rotated(float(i)*1.7+numer_trafienia*0.8)
			var fragment := miejsce_trafienia+kierunek*(3.0+t*16.0)
			draw_line(fragment,fragment-kierunek*3.0,Color(paleta.swiatlo,(1.0-t)*sila),1.2,true)
			if i % 2 == 0:
				draw_colored_polygon(PackedVector2Array([fragment,fragment+Vector2(3,1),fragment+Vector2(1,3)]),Color(paleta.pancerz,(1.0-t)*sila))

func _rysuj_awarie() -> void:
	var paleta := PaletaPrzeciwnikow.pobierz(self)
	var t := clampf(czas_rozpadu / CZAS_ROZPADU, 0.0, 1.0)
	var alfa := 1.0 - t
	draw_circle(Vector2.ZERO, alfa * 15.0, Color(paleta.swiatlo, alfa * 0.65))
	draw_arc(Vector2.ZERO, 8.0 + t * 36.0, 0.0, TAU, 24, Color(paleta.zagrozenie, alfa * 0.6), 1.5, true)
	for i in range(5 + wariant_rozpadu):
		var kierunek := Vector2.RIGHT.rotated(i * 2.4 + wariant_rozpadu * 0.3)
		var miejsce := kierunek * (9.0 + t * (28.0 + i * 3.0))
		draw_set_transform(miejsce, t * (i - 2.0))
		draw_rect(Rect2(-5,-3,10,6), Color(paleta.pancerz, alfa))
		draw_line(Vector2(-4,-2),Vector2(4,-2), Color(paleta.swiatlo, alfa), 1.2, true)
		draw_set_transform(Vector2.ZERO)
		if t < 0.7:
			draw_polyline(PackedVector2Array([kierunek * 6.0, miejsce + kierunek.orthogonal() * 6.0, miejsce]), Color(paleta.swiatlo, alfa * 0.65), 1.2, true)

