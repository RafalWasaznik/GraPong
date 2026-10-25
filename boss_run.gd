class_name BossRun
extends StaticBody2D

signal satelita_zniszczony

signal gotowy
signal pokonany
signal trafiono_gracza(pozycja: Vector2)

const KOLOR: Color = Color("#ad83ff")
const ROZMIAR: Vector2 = Vector2(64.0, 144.0)
const PROMIEN_POCISKU: float = 9.0

const DIFFICULTY = TrudnoscRun.DIFFICULTY

class Trafienie extends RefCounted:
	var obrazenia: int
	var satelita: int
	var zewnetrzny_luk: bool

	func _init(ile: int, cel: int, luk: bool) -> void:
		obrazenia = ile
		satelita = cel
		zewnetrzny_luk = luk

var faza: BossDefinicja.FazaRdzenia
var sat_hp: Array[int] = []
var sat_kolizje: Array[CollisionShape2D] = []
var sat_blysk: Array[float] = []
var sat_cooldown: Array[float] = []
var orbita: float = 0.0
var kierunek_orbity: float = 1.0
var czas_odwrocenia: float = 0.0
var czas_rdzenia: float = 0.0
var odsloniecie: float = 0.0
var regeneracja: float = 0.0
var regeneruje: bool = false
var regen_indeks: int = 0
var sat_strzelec: int = 0
var indeks_fazy: int = 0
var numer_pulsu: int = 0
var puls: bool = false
var osloniety_blysk: float = 0.0
var luka_pulsu: float = 0.0
var trudnosc: TrudnoscRun
var totalHits: int = 0
var kolejnosc: Array[int] = []
var ostatni_atak: int = -1
var atak: BossDefinicja.Atak
var ostrzezenie: float = 0.0
var seria_pozostalo: int = 0
var czas_serii: float = 0.0
var cel_ataku: Vector2
var start_ataku: Vector2
var zaplanowane_starty: Array[Vector2] = []
var zaplanowane_kierunki: Array[Vector2] = []

var definicja: BossDefinicja
var bossIndex: int = 0
var paletka: PaletkaBazowa
var pilka: Pilka
var hp: int
var maxHp: int
var intro: float = 1.2
var blysk: float = 0.0
var cooldown_trafienia: float = 0.0
var czas_ataku: float = 0.0
var kierunek: float = 1.0
var rozpad: float = 0.0
var pociski: Array[Vector2] = []
var predkosci_pociskow: Array[Vector2] = []
var kolizja: CollisionShape2D


func _ready() -> void:
	trudnosc = TrudnoscRun.getDifficulty(totalHits, bossIndex)
	maxHp = trudnosc.boss_max_hp
	hp = maxHp
	collision_layer = 1
	collision_mask = 0
	kolizja = CollisionShape2D.new()
	var ksztalt := RectangleShape2D.new()
	ksztalt.size = ROZMIAR
	kolizja.shape = ksztalt
	add_child(kolizja)
	if definicja.id == &"rdzen":
		_przygotuj_rdzen()
	czas_ataku = trudnosc.cooldown_ms / 1000.0
	position = Vector2(Ustawienia.prawa_granica - (DIFFICULTY.ORBIT_RADIUS + 44.0 if faza != null else 90.0), (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5)


func przygotuj_trafienie(obrazenia: int, ksztalt: Object, normalna: Vector2) -> Trafienie:
	var indeks := sat_kolizje.find(ksztalt)
	var luk := indeks >= 0 and normalna.dot(sat_kolizje[indeks].position.normalized()) > 0.15
	return Trafienie.new(obrazenia, indeks, luk)


func trafienie(kontakt: Trafienie) -> void:
	var obrazenia := kontakt.obrazenia
	if faza != null:
		if intro > 0.0 or hp <= 0:
			return
		if kontakt.satelita >= 0:
			_traf_satellite(kontakt)
			return
		if _zywe_satelity() > 0 or regeneruje:
			osloniety_blysk = 0.16
			return
	if intro > 0.0 or hp <= 0 or cooldown_trafienia > 0.0:
		return
	hp = maxi(0, hp - obrazenia)
	blysk = 0.16
	cooldown_trafienia = 0.10
	if hp == 0:
		kolizja.set_deferred("disabled", true)
		for sat in sat_kolizje:
			sat.set_deferred("disabled", true)
		pociski.clear()
		predkosci_pociskow.clear()
		pilka.set_physics_process(false)
		pilka.set_process(false)
	queue_redraw()


func _physics_process(delta: float) -> void:
	queue_redraw()
	if intro > 0.0:
		intro = maxf(0.0, intro - delta)
		if intro == 0.0:
			gotowy.emit()
		return
	if hp <= 0:
		rozpad += delta
		if rozpad >= 0.5:
			set_physics_process(false)
			pokonany.emit()
			queue_free()
		return
	if faza != null:
		_aktualizuj_rdzen(delta)
	blysk = maxf(0.0, blysk - delta)
	cooldown_trafienia = maxf(0.0, cooldown_trafienia - delta)
	var minimum: float = Ustawienia.gorna_granica + 90.0
	var maksimum := maxf(minimum, Ustawienia.dolna_granica - ROZMIAR.y * 0.5 - 12.0)
	position.x = Ustawienia.prawa_granica - (DIFFICULTY.ORBIT_RADIUS + 44.0 if faza != null else 90.0)
	if faza == null and ostrzezenie <= 0.0 and seria_pozostalo == 0:
		position.y += kierunek * definicja.speed * delta
	if position.y <= minimum or position.y >= maksimum:
		position.y = clampf(position.y, minimum, maksimum)
		kierunek *= -1.0
	if ostrzezenie > 0.0:
		ostrzezenie = maxf(0.0, ostrzezenie - delta)
		if ostrzezenie == 0.0:
			_wystrzel_wzor()
	elif seria_pozostalo > 0:
		czas_serii -= delta
		if czas_serii <= 0.0:
			_dodaj_pocisk(start_ataku, (cel_ataku - start_ataku).normalized())
			seria_pozostalo -= 1
			czas_serii = DIFFICULTY.BURST_STEP_MS / 1000.0
	else:
		czas_ataku -= delta
		if czas_ataku <= 0.0:
			_zapowiedz_wzor()
	var ksztalt := paletka.kolizja.shape as RectangleShape2D
	var prostokat := Rect2(paletka.position - ksztalt.size * 0.5, ksztalt.size).grow(PROMIEN_POCISKU)
	for i in range(pociski.size() - 1, -1, -1):
		var start := pociski[i]
		pociski[i] += predkosci_pociskow[i] * delta
		var kontakt := prostokat.has_point(pociski[i]) or prostokat.has_point(start)
		var rogi := [prostokat.position, Vector2(prostokat.end.x, prostokat.position.y), prostokat.end, Vector2(prostokat.position.x, prostokat.end.y)]
		for j in range(4):
			kontakt = kontakt or Geometry2D.segment_intersects_segment(start, pociski[i], rogi[j], rogi[(j + 1) % 4]) != null
		if kontakt or pociski[i].x < Ustawienia.lewa_granica - 30.0 or pociski[i].x > Ustawienia.prawa_granica + 30.0 or pociski[i].y < Ustawienia.gorna_granica or pociski[i].y > Ustawienia.dolna_granica:
			var pozycja_kontaktu := pociski[i]
			pociski.remove_at(i)
			predkosci_pociskow.remove_at(i)
			if kontakt:
				trafiono_gracza.emit(pozycja_kontaktu)
				return


func odrocz_atak_po_stracie() -> void:
	pociski.clear()
	predkosci_pociskow.clear()
	ostrzezenie = 0.0
	seria_pozostalo = 0
	zaplanowane_starty.clear()
	zaplanowane_kierunki.clear()
	czas_ataku = maxf(RunState.INVULN_MS, trudnosc.cooldown_ms) / 1000.0
	queue_redraw()


func _zapowiedz_wzor() -> void:
	if faza != null:
		_zapowiedz_rdzen()
		return
	if kolejnosc.is_empty():
		kolejnosc.assign(trudnosc.patterns)
		kolejnosc.shuffle()
		if kolejnosc.size() > 1 and kolejnosc[-1] == ostatni_atak:
			var pierwszy := kolejnosc[0]
			kolejnosc[0] = kolejnosc[-1]
			kolejnosc[-1] = pierwszy
	ostatni_atak = kolejnosc.pop_back()
	atak = definicja.ataki[ostatni_atak]
	ostrzezenie = maxf(trudnosc.telegraph_ms, atak.telegraph_ms) / 1000.0
	start_ataku = position - Vector2(ROZMIAR.x * 0.5 + PROMIEN_POCISKU, 0.0)
	cel_ataku = paletka.position
	zaplanowane_starty.clear()
	zaplanowane_kierunki.clear()
	var kierunek_celu := (cel_ataku - start_ataku).normalized()
	match atak.wzor:
		BossDefinicja.Wzor.ROZRZUT:
			for kat in [-DIFFICULTY.SPREAD_ANGLE, DIFFICULTY.SPREAD_ANGLE]:
				zaplanowane_starty.append(start_ataku)
				zaplanowane_kierunki.append(kierunek_celu.rotated(kat))
		BossDefinicja.Wzor.SCIANA:
			var polowa_paletki := (paletka.kolizja.shape as RectangleShape2D).size.y * 0.5
			var luka := maxf(DIFFICULTY.WALL_GAP, polowa_paletki * 2.0 + PROMIEN_POCISKU * 4.0)
			var srodek_luki := clampf(cel_ataku.y, Ustawienia.gorna_granica + luka * 0.5, Ustawienia.dolna_granica - luka * 0.5)
			var y: float = Ustawienia.gorna_granica + PROMIEN_POCISKU
			while y < Ustawienia.dolna_granica - PROMIEN_POCISKU:
				if absf(y - srodek_luki) > luka * 0.5:
					zaplanowane_starty.append(Vector2(start_ataku.x, y))
					zaplanowane_kierunki.append(Vector2.LEFT)
				y += DIFFICULTY.WALL_SPACING
		_:
			zaplanowane_starty.append(start_ataku)
			zaplanowane_kierunki.append(kierunek_celu)


func _wystrzel_wzor() -> void:
	for i in range(zaplanowane_starty.size()):
		_dodaj_pocisk(zaplanowane_starty[i], zaplanowane_kierunki[i])
	if atak.wzor == BossDefinicja.Wzor.SERIA:
		seria_pozostalo = DIFFICULTY.BURST_COUNT - 1
		czas_serii = DIFFICULTY.BURST_STEP_MS / 1000.0
	czas_ataku = trudnosc.cooldown_ms / 1000.0


func _dodaj_pocisk(start: Vector2, kierunek_pocisku: Vector2) -> void:
	var dystans := maxf(0.0, start.x - paletka.position.x)
	var predkosc := minf(trudnosc.projectile_speed, dystans / (DIFFICULTY.DODGE_TRAVEL_MIN_MS / 1000.0))
	if atak.wzor == BossDefinicja.Wzor.SCIANA:
		predkosc *= DIFFICULTY.WALL_SPEED_MULT
	elif puls:
		predkosc *= DIFFICULTY.PULSE_SPEED_MULT
	pociski.append(start)
	predkosci_pociskow.append(kierunek_pocisku * predkosc)


func _draw() -> void:
	var srodek := Vector2((Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5, Ustawienia.gorna_granica - 46.0) - position
	draw_line(srodek + Vector2(-180, 12), srodek + Vector2(180, 12), Color(KOLOR, 0.2), 6.0)
	draw_line(srodek + Vector2(-180, 12), srodek + Vector2(-180.0 + 360.0 * float(hp) / float(maxHp), 12), KOLOR, 6.0)
	if hp <= 0:
		for i in range(12):
			var wektor := Vector2.RIGHT.rotated(TAU * float(i) / 12.0)
			draw_line(wektor * (20.0 + rozpad * 180.0), wektor * (35.0 + rozpad * 200.0), Color(KOLOR, 1.0 - rozpad * 2.0), 3.0, true)
		return
	if faza != null:
		_rysuj_rdzen(srodek)
		_rysuj_pociski_i_ostrzezenie()
		return
	var kolor := KOLOR.lerp(Color.WHITE, blysk / 0.16)
	var punkty := PackedVector2Array([Vector2(0, -72), Vector2(32, -35), Vector2(32, 35), Vector2(0, 72), Vector2(-32, 35), Vector2(-32, -35)])
	draw_colored_polygon(punkty, Color(kolor, 0.22))
	punkty.append(punkty[0])
	draw_polyline(punkty, kolor, 3.0, true)
	draw_circle(Vector2.ZERO, 12.0, kolor)
	_rysuj_pociski_i_ostrzezenie()


func _rysuj_pociski_i_ostrzezenie() -> void:
	if ostrzezenie > 0.0:
		var srodek_x: float = (Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5
		draw_circle(Vector2.ZERO, ROZMIAR.x, Color(KOLOR, 0.3))
		for i in range(zaplanowane_starty.size()):
			var start := zaplanowane_starty[i]
			var wektor := zaplanowane_kierunki[i]
			var dlugosc := maxf(0.0, (start.x - srodek_x) / maxf(0.01, -wektor.x))
			if faza != null:
				dlugosc = 2000.0
				if absf(wektor.x) > 0.001:
					var granica_x: float = Ustawienia.prawa_granica if wektor.x > 0.0 else Ustawienia.lewa_granica
					dlugosc = minf(dlugosc, maxf(0.0, (granica_x - start.x) / wektor.x))
				if absf(wektor.y) > 0.001:
					var granica_y: float = Ustawienia.dolna_granica if wektor.y > 0.0 else Ustawienia.gorna_granica
					dlugosc = minf(dlugosc, maxf(0.0, (granica_y - start.y) / wektor.y))
			draw_line(start - position, start + wektor * dlugosc - position, Color(KOLOR, 0.45), 2.0, true)
	for pocisk in pociski:
		draw_circle(pocisk - position, PROMIEN_POCISKU + 5.0, Color("#ff72b533"))
		draw_circle(pocisk - position, PROMIEN_POCISKU, Color("#ff72b5"))


func _przygotuj_rdzen() -> void:
	faza = definicja.faza_rdzenia(bossIndex)
	var ksztalt := CircleShape2D.new()
	ksztalt.radius = 30.0
	kolizja.shape = ksztalt
	var liczba := maxi(faza.sat_count, DIFFICULTY.SAT_COUNT_LATE if bossIndex >= 3 else DIFFICULTY.SAT_COUNT)
	for i in range(liczba):
		var sat := CollisionShape2D.new()
		var okrag := CircleShape2D.new()
		okrag.radius = DIFFICULTY.SAT_RADIUS
		sat.shape = okrag
		add_child(sat)
		sat_kolizje.append(sat)
		sat_hp.append(mini(DIFFICULTY.SAT_HP, DIFFICULTY.SAT_HP_CAP))
		sat_blysk.append(0.0)
		sat_cooldown.append(0.0)
	_ustaw_orbite()


func _zywe_satelity() -> int:
	var liczba: int = 0
	for zdrowie in sat_hp:
		if zdrowie > 0:
			liczba += 1
	return liczba


func _traf_satellite(kontakt: Trafienie) -> void:
	var i := kontakt.satelita
	if not kontakt.zewnetrzny_luk or sat_hp[i] <= 0 or sat_cooldown[i] > 0.0:
		return
	sat_hp[i] = maxi(0, sat_hp[i] - kontakt.obrazenia)
	sat_cooldown[i] = 0.10
	sat_blysk[i] = 0.45 if sat_hp[i] == 0 else 0.16
	if sat_hp[i] == 0:
		sat_kolizje[i].set_deferred("disabled", true)
		if ostrzezenie > 0.0:
			_anuluj_zapowiedz_rdzenia()
		satelita_zniszczony.emit()
		if _zywe_satelity() == 0 and not regeneruje:
			_odslon_rdzen()


func _odslon_rdzen() -> void:
	odsloniecie = DIFFICULTY.EXPOSE_MS / 1000.0
	_anuluj_zapowiedz_rdzenia()
	indeks_fazy = 0


func _anuluj_zapowiedz_rdzenia() -> void:
	ostrzezenie = 0.0
	seria_pozostalo = 0
	zaplanowane_starty.clear()
	zaplanowane_kierunki.clear()
	czas_ataku = trudnosc.cooldown_ms / 1000.0


func _ustaw_orbite() -> void:
	for i in range(sat_kolizje.size()):
		var promien := DIFFICULTY.ORBIT_INNER_RADIUS if faza.warstwy and i % 2 == 0 else DIFFICULTY.ORBIT_RADIUS
		var kat := orbita + TAU * float(i) / float(sat_kolizje.size())
		sat_kolizje[i].position = Vector2.RIGHT.rotated(kat) * promien


func _aktualizuj_rdzen(delta: float) -> void:
	czas_rdzenia += delta
	osloniety_blysk = maxf(0.0, osloniety_blysk - delta)
	for i in range(sat_hp.size()):
		sat_blysk[i] = maxf(0.0, sat_blysk[i] - delta)
		sat_cooldown[i] = maxf(0.0, sat_cooldown[i] - delta)
	if ostrzezenie <= 0.0:
		position.y = (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5 + sin(czas_rdzenia * 0.3) * definicja.speed
		orbita += kierunek_orbity * DIFFICULTY.ORBIT_SPEED * delta
		_ustaw_orbite()
	if faza.odwrocenie_ms > 0.0:
		czas_odwrocenia += delta
		if czas_odwrocenia >= faza.odwrocenie_ms / 1000.0:
			czas_odwrocenia = 0.0
			kierunek_orbity *= -1.0
	if odsloniecie > 0.0:
		odsloniecie = maxf(0.0, odsloniecie - delta)
		if odsloniecie == 0.0:
			regeneruje = true
			regen_indeks = 0
			regeneracja = 0.0
			_anuluj_zapowiedz_rdzenia()
	if regeneruje:
		regeneracja -= delta
		if regeneracja <= 0.0:
			sat_hp[regen_indeks] = mini(DIFFICULTY.SAT_HP, DIFFICULTY.SAT_HP_CAP)
			sat_kolizje[regen_indeks].set_deferred("disabled", false)
			sat_blysk[regen_indeks] = 0.16
			regen_indeks += 1
			regeneracja = DIFFICULTY.REGEN_SAT_MS / 1000.0
			if regen_indeks == sat_hp.size():
				regeneruje = false


func _zapowiedz_rdzen() -> void:
	puls = _zywe_satelity() == 0 and not regeneruje
	var wzory: Array[BossDefinicja.Atak] = faza.odsloniety if puls else faza.osloniety
	atak = wzory[indeks_fazy % wzory.size()]
	indeks_fazy += 1
	ostrzezenie = maxf(trudnosc.telegraph_ms, atak.telegraph_ms) / 1000.0
	zaplanowane_starty.clear()
	zaplanowane_kierunki.clear()
	cel_ataku = paletka.position
	if puls:
		numer_pulsu += 1
		var luka := (cel_ataku - position).angle()
		if faza.przesuwana_luka:
			luka += sin(float(numer_pulsu) * 1.7) * 0.36
		luka_pulsu = luka
		for i in range(DIFFICULTY.PULSE_COUNT):
			var kat := TAU * float(i) / float(DIFFICULTY.PULSE_COUNT)
			if absf(angle_difference(kat, luka)) < DIFFICULTY.PULSE_GAP * 0.5:
				continue
			var wektor := Vector2.RIGHT.rotated(kat)
			zaplanowane_starty.append(position + wektor * 36.0)
			zaplanowane_kierunki.append(wektor)
	else:
		var pozostalo := 2 if atak.wzor == BossDefinicja.Wzor.SATELITY_PARA else 1
		for krok in range(sat_hp.size()):
			var i := (sat_strzelec + krok) % sat_hp.size()
			if sat_hp[i] <= 0:
				continue
			var start := position + sat_kolizje[i].position
			zaplanowane_starty.append(start)
			zaplanowane_kierunki.append((cel_ataku - start).normalized())
			pozostalo -= 1
			if pozostalo == 0:
				sat_strzelec = (i + 1) % sat_hp.size()
				break


func _szesciokat(srodek: Vector2, promien: float, kolor: Color) -> void:
	var punkty := PackedVector2Array()
	for i in range(6):
		punkty.append(srodek + Vector2.RIGHT.rotated(TAU * float(i) / 6.0) * promien)
	draw_colored_polygon(punkty, Color(kolor, 0.18))
	punkty.append(punkty[0])
	draw_polyline(punkty, kolor, 2.0, true)


func _rysuj_rdzen(hud: Vector2) -> void:
	var osloniety := _zywe_satelity() > 0 or regeneruje
	var kolor := Color("#55e7ff") if osloniety else Color("#ff72b5")
	kolor = kolor.lerp(Color.WHITE, blysk / 0.16)
	draw_arc(Vector2.ZERO, DIFFICULTY.ORBIT_RADIUS, 0.0, TAU, 96, Color(KOLOR, 0.13), 1.0, true)
	if faza.warstwy:
		draw_arc(Vector2.ZERO, DIFFICULTY.ORBIT_INNER_RADIUS, 0.0, TAU, 72, Color(KOLOR, 0.10), 1.0, true)
	draw_circle(Vector2.ZERO, 34.0 + sin(czas_rdzenia * 3.0) * 3.0, Color(kolor, 0.10))
	if puls and ostrzezenie > 0.0:
		draw_arc(Vector2.ZERO, 52.0, luka_pulsu - DIFFICULTY.PULSE_GAP * 0.5, luka_pulsu + DIFFICULTY.PULSE_GAP * 0.5, 20, Color("#55e7ff"), 3.0, true)
	_szesciokat(Vector2.ZERO, 30.0, kolor)
	draw_circle(Vector2.ZERO, 9.0, kolor)
	if osloniety:
		draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 64, Color(Color("#55e7ff").lerp(Color("#ad83ff"), osloniety_blysk / 0.16), 0.6), 3.0, true)
	for i in range(sat_hp.size()):
		var lokalna := sat_kolizje[i].position
		var pip := hud + Vector2((float(i) - float(sat_hp.size() - 1) * 0.5) * 22.0, 28.0)
		draw_circle(pip, 5.0, Color(KOLOR, 0.15))
		if sat_hp[i] > 0:
			draw_arc(pip, 5.0, -PI * 0.5, -PI * 0.5 + TAU * float(sat_hp[i]) / float(mini(DIFFICULTY.SAT_HP, DIFFICULTY.SAT_HP_CAP)), 24, kolor, 2.0, true)
			_szesciokat(lokalna, DIFFICULTY.SAT_RADIUS, KOLOR.lerp(Color.WHITE, minf(1.0, sat_blysk[i] / 0.16)))
			var kat := lokalna.angle()
			draw_arc(lokalna, DIFFICULTY.SAT_RADIUS + 3.0, kat - PI * 0.5, kat + PI * 0.5, 24, Color("#55e7ff"), 2.0, true)
		elif sat_blysk[i] > 0.0:
			for j in range(6):
				var wektor := Vector2.RIGHT.rotated(TAU * float(j) / 6.0)
				var dystans := 18.0 + (0.45 - sat_blysk[i]) * 90.0
				draw_line(lokalna + wektor * dystans, lokalna + wektor * (dystans + 9.0), Color(KOLOR, sat_blysk[i] / 0.45), 2.0, true)
