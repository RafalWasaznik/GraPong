extends Node

var bledy: int = 0
var kontrole: int = 0
var gra: GraPongAPI
var stan: RunState
var kontakty: Array[Vector2] = []
var normalne: Array[Vector2] = []


func sprawdz(ok: bool, opis: String) -> void:
	kontrole += 1
	if ok:
		print("PASS: ", opis)
	else:
		bledy += 1
		push_error("FAIL: " + opis)


func _ready() -> void:
	start.call_deferred()


func klatki(ile: int = 2) -> void:
	for i in range(ile):
		await get_tree().physics_frame
		await get_tree().process_frame


func wrog(punkt: Vector2, dron: bool = false, wedrujacy: bool = false) -> KrysztalRun:
	var cel: KrysztalRun = DronRun.new() if dron else KrysztalRun.new()
	cel.skonfiguruj(KrysztalRun.CRYSTAL_VARIANTS[3 if wedrujacy else 0], stan, punkt - Vector2(70,0) if wedrujacy else punkt, punkt + Vector2(70,0) if wedrujacy else punkt)
	gra.add_child(cel)
	cel.set_physics_process(false)
	cel.czas_pojawiania = cel.CZAS_POJAWIANIA
	cel.modulate.a = 1.0
	cel.kolizja.disabled = false
	return cel


func wyczysc() -> void:
	for cel in get_tree().get_nodes_in_group("przeciwnicy_run"):
		cel.queue_free()
	await klatki()


func start() -> void:
	Ustawienia.tryb = "endless"
	gra = load("res://scena_główna.tscn").instantiate() as GraPongAPI
	get_tree().root.add_child(gra)
	await klatki()
	gra.przebieg().set_physics_process(false)
	gra.pilka().set_physics_process(false)
	gra.lewa_paletka().set_physics_process(false)
	stan = gra.przebieg().run_state
	var pilka := gra.pilka()
	var srodek := Vector2((Ustawienia.lewa_granica + Ustawienia.prawa_granica) * 0.5, (Ustawienia.gorna_granica + Ustawienia.dolna_granica) * 0.5)
	for dron in [false, true]:
		var cel := wrog(srodek, dron)
		cel.max_hp = 100
		for hp in [100,76,75,67,66,51,50,34,33,26,25,1]:
			cel.hp = hp
			var oczekiwany := (0 if hp > 66 else (1 if hp > 33 else 2)) if dron else (0 if hp > 75 else (1 if hp > 50 else (2 if hp > 25 else 3)))
			sprawdz(cel.etap_uszkodzenia() == oczekiwany, "etap %s HP=%d/100" % ["dron" if dron else "kamien", hp])
		cel.max_hp = 6
		for zdrowie in [6,4,3,2,1]:
			cel.hp = zdrowie
			var oczekiwany := (0 if zdrowie >= 5 else (1 if zdrowie >= 3 else 2)) if dron else (0 if zdrowie >= 5 else (1 if zdrowie >= 4 else (2 if zdrowie >= 2 else 3)))
			sprawdz(cel.etap_uszkodzenia() == oczekiwany, "ratio %s HP=%d/6" % ["dron" if dron else "kamien", zdrowie])
		if not dron:
			for maksimum in [1, 2, 3]:
				cel.max_hp = maksimum
				cel.hp = maksimum
				var poprzedni := cel.etap_uszkodzenia()
				while cel.hp > 1:
					cel.trafienie(1)
					sprawdz(cel.etap_uszkodzenia() > poprzedni, "zmiana po trafieniu HP=%d/%d" % [cel.hp, maksimum])
					poprzedni = cel.etap_uszkodzenia()
		cel.max_hp = 100
		cel.hp = 90
		cel.trafienie(1)
		sprawdz(cel.hp == 89 and cel.blysk > 0.0 and cel.etap_uszkodzenia() == 0, "reakcja trafienia bez zmiany etapu")
		for wariant in range(3):
			cel.wariant_rozpadu = wariant
			cel.hp = 1
			cel.rozpad = false
			cel.trafienie(1)
			cel.czas_rozpadu = 0.1
			cel.queue_redraw()
			await klatki(1)
			sprawdz(cel.rozpad and cel.hp == 0, "rozpad %s wariant %d" % ["dron" if dron else "kamien", wariant])
		await wyczysc()
	for liczba in [1,4,8]:
		for i in range(liczba):
			wrog(srodek + Vector2((i % 3 - 1) * 65.0 if liczba > 1 else 0.0, (i / 3 - 1) * 65.0 if liczba > 1 else 0.0), i % 2 == 1)
		await klatki()
		pilka.reset_bezpieczny()
		pilka.set_physics_process(false)
		sprawdz(not pilka.respawn_oczekuje and BezpiecznyRespawn.wolne(pilka, pilka.global_position, pilka.PROMIEN_OKREGU if not pilka.intro_stacjonarne else pilka.promien_aktualny()), "wolny respawn grupa %d" % liczba)
		sprawdz(get_tree().get_nodes_in_group("przeciwnicy_run").size() == liczba, "respawn zachowuje %d wrogow" % liczba)
		await wyczysc()
	var wedrujacy := wrog(srodek, false, true)
	await klatki()
	pilka.reset()
	pilka.set_physics_process(false)
	sprawdz(BezpiecznyRespawn.wolne(pilka, pilka.global_position, pilka.PROMIEN_OKREGU), "respawn omija caly tor wanderera")
	wedrujacy.queue_free()
	await klatki()
	var centralna := StaticBody2D.new()
	var centralny_ksztalt := CollisionShape2D.new()
	var prostokat := RectangleShape2D.new()
	prostokat.size = Vector2(440,480)
	centralny_ksztalt.shape = prostokat
	centralna.add_child(centralny_ksztalt)
	centralna.position = srodek
	gra.add_child(centralna)
	await klatki()
	pilka.reset()
	pilka.set_physics_process(false)
	sprawdz(pilka.intro_stacjonarne and not pilka.respawn_oczekuje and BezpiecznyRespawn.wolne(pilka, pilka.global_position, pilka.promien_aktualny()), "fallback poza centrum: bezpieczny stacjonarny start")
	centralna.queue_free()
	await klatki()
	sprawdz(not BezpiecznyRespawn.wolne(pilka, Vector2(Ustawienia.lewa_granica - 50, srodek.y), 13.0), "odrzucenie punktu poza boczna granica")
	var blokada := StaticBody2D.new()
	var kolizja := CollisionShape2D.new()
	var ksztalt := RectangleShape2D.new()
	ksztalt.size = Vector2(4000,4000)
	kolizja.shape = ksztalt
	blokada.position = srodek
	blokada.add_child(kolizja)
	gra.add_child(blokada)
	await klatki()
	pilka.reset()
	pilka.set_physics_process(false)
	sprawdz(pilka.respawn_oczekuje, "pelna arena bez niebezpiecznego umieszczenia")
	pilka.proby_respawnu = 44
	pilka.czas_proby_respawnu = 0.0
	pilka._physics_process(0.02)
	sprawdz(pilka.respawn_oczekuje and pilka.czas_proby_respawnu == 2.0, "po limicie ograniczone ponowienia 2s")
	blokada.queue_free()
	await klatki()
	pilka.czas_proby_respawnu = 0.0
	pilka._physics_process(0.02)
	sprawdz(not pilka.respawn_oczekuje and pilka.srodek_intro == pilka.position, "odzyskanie po 44 probach i zwolnieniu miejsca")
	pilka.reset()
	pilka.set_physics_process(false)
	sprawdz(pilka.global_position.is_equal_approx(srodek), "wolny srodek pozostaje domyslny")
	var dron := wrog(srodek, true) as DronRun
	dron.paletka = gra.lewa_paletka()
	dron._wystrzel()
	sprawdz(dron.blysk_lufy > 0 and gra.efekty_wizualne.odtwarzacze_energii[0].bus == &"Efekty", "blysk strzalu i audio bus Efekty")
	for pocisk in get_tree().get_nodes_in_group("pociski_dronow"):
		pocisk.queue_free()
	await wyczysc()
	for kierunek in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		var pocisk := PociskDronaRun.new()
		pocisk.run_state = stan
		pocisk.position = srodek + Vector2(0,-150) if kierunek.x != 0.0 else srodek
		pocisk.velocity = kierunek * 10000.0
		pocisk.trafiono_granice.connect(func(p: Vector2, n: Vector2) -> void: kontakty.append(p); normalne.append(n))
		gra.add_child(pocisk)
		pocisk.set_physics_process(false)
		var przed := kontakty.size()
		pocisk._physics_process(1.0)
		pocisk._physics_process(1.0)
		sprawdz(kontakty.size() == przed + 1 and normalne.back() == -kierunek, "dokladnie jeden kontakt i normalna %s" % kierunek)
		if kontakty.size() == przed:
			continue
		var punkt: Vector2 = kontakty.back()
		var oczekiwany: float = Ustawienia.lewa_granica if kierunek == Vector2.LEFT else (Ustawienia.prawa_granica if kierunek == Vector2.RIGHT else (Ustawienia.gorna_granica + 10.0 if kierunek == Vector2.UP else Ustawienia.dolna_granica - 10.0))
		sprawdz(is_equal_approx(punkt.x if kierunek.x != 0.0 else punkt.y, oczekiwany), "punkt na powierzchni sciany %s" % kierunek)
		await klatki(1)
	sprawdz(gra.efekty_wizualne.odtwarzacze_energii[1].bus == &"Efekty", "audio kontaktu pod ustawieniami gry")
	for rodzaj in range(4):
		var stream := gra.efekty_wizualne.odtwarzacze_energii[rodzaj].stream as AudioStreamWAV
		sprawdz(stream != null and stream.data.size() > 4000, "syntetyczny dzwiek %d" % rodzaj)
	var efekty := gra.efekty_wizualne
	Ustawienia.intensywnosc_efektow = 70.0
	efekty.czas_od_odbicia = 1.0
	efekty.odbicie(Vector2(srodek.x, Ustawienia.gorna_granica + 10.0), Vector2.DOWN)
	sprawdz(efekty.kontakty_ramy.size() == 1 and efekty.kontakty_ramy[0].miejsce.y == Ustawienia.gorna_granica, "kontakt powierzchni sciany rozswietla rame")
	efekty.czas_od_odbicia = 1.0
	efekty.odbicie(Vector2(Ustawienia.prawa_granica, srodek.y), Vector2.LEFT, Color.WHITE, true)
	sprawdz(efekty.kontakty_ramy.size() == 2, "kontakt prawej ramy w Nieskonczonym")
	efekty._process(0.31)
	sprawdz(efekty.kontakty_ramy.is_empty(), "lokalne rozswietlenie wygasa")
	Ustawienia.intensywnosc_efektow = 0.0
	efekty.odbicie(Vector2(srodek.x, Ustawienia.gorna_granica + 10.0), Vector2.DOWN)
	sprawdz(efekty.kontakty_ramy.is_empty(), "wylaczone efekty nie dodaja kontaktow ramy")
	Ustawienia.intensywnosc_efektow = 70.0
	for i in range(6):
		var cel := wrog(srodek + Vector2((i % 3 - 1) * 120.0, -80.0 if i < 3 else 80.0), i >= 3)
		cel.max_hp = 100
		cel.hp = [100,60,25][i % 3]
		cel.czas_animacji = 1.2
		cel.queue_redraw()
	await klatki(3)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/obrazenia-etapy.png")
	await wyczysc()
	gra.queue_free()
	await klatki()
	for tryb in ["bot", "2graczy", "arena"]:
		Ustawienia.tryb = tryb
		gra = load("res://scena_główna.tscn").instantiate() as GraPongAPI
		get_tree().root.add_child(gra)
		await klatki(4)
		sprawdz(gra.przebieg().run_state == null and not gra.pilka().respawn_oczekuje, "runtime start trybu " + tryb)
		gra.queue_free()
		await klatki()
	print("WYNIK: %d kontroli, %d bledow" % [kontrole, bledy])
	get_tree().quit(bledy)

