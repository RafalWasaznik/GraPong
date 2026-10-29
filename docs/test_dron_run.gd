extends Node

var bledy: int = 0
var gra: GraPongAPI
var mecz: PrzebiegMeczu
var stan: RunState


func sprawdz(warunek: bool, opis: String) -> void:
	if warunek:
		print("PASS: ", opis)
	else:
		bledy += 1
		push_error("FAIL: " + opis)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start.call_deferred()


func klatki(ile: int) -> void:
	for i in range(ile):
		await get_tree().physics_frame
		await get_tree().process_frame


func dron_w(pozycja_drona: Vector2) -> DronRun:
	var dron := DronRun.new()
	dron.skonfiguruj(KrysztalRun.CRYSTAL_VARIANTS[0], stan, pozycja_drona, pozycja_drona)
	dron.paletka = gra.lewa_paletka()
	dron.wystrzelono.connect(mecz._podlacz_pocisk_drona)
	dron.zniszczony.connect(mecz._zniszczono_krysztal.bind(dron))
	gra.add_child(dron)
	dron.set_physics_process(false)
	mecz.krysztaly.append(dron)
	return dron


func start() -> void:
	await get_tree().process_frame
	Ustawienia.tryb = "endless"
	gra = load("res://scena_główna.tscn").instantiate() as GraPongAPI
	get_tree().root.add_child(gra)
	await klatki(2)
	mecz = gra.przebieg()
	stan = mecz.run_state
	mecz.set_physics_process(false)
	gra.pilka().set_physics_process(false)
	gra.lewa_paletka().set_physics_process(false)
	var gracz := gra.lewa_paletka()
	var bazowy_ksztalt := (gracz.kolizja.shape as RectangleShape2D).size
	seed(7129)
	var losowania := 0
	for i in range(10000):
		if DronRun.czy_zastapic(0):
			losowania += 1
	sprawdz(losowania > 3300 and losowania < 3700, "35%% RNG: %d/10000" % losowania)
	for i in range(100):
		sprawdz(not DronRun.czy_zastapic(2), "limit RNG 2") if i == 0 else DronRun.czy_zastapic(2)
	stan.hits = 120
	var limit_ok := true
	var widziano_drona := false
	var widziano_krysztal := false
	for i in range(45):
		mecz._spawn_krysztalu()
		limit_ok = limit_ok and mecz._liczba_dronow() <= 2
		for cel in mecz.krysztaly:
			widziano_drona = widziano_drona or cel is DronRun
			widziano_krysztal = widziano_krysztal or not cel is DronRun
		if i % 3 == 0:
			mecz._wyczysc_krysztaly()
			await klatki(1)
	sprawdz(limit_ok and widziano_drona and widziano_krysztal, "rzeczywisty spawn: drony i kamienie, max 2")
	mecz._wyczysc_krysztaly()
	await klatki(1)
	stan.hits = 0
	stan.upgradeProgress = 0
	var dron := dron_w(gracz.position + Vector2(380, 0))
	sprawdz(dron.hp == TrudnoscRun.getDifficulty(0,0).crystal_hp and dron.armor_hp == 0, "HP ze standardowego kamienia")
	dron.czas_do_strzalu = 0.51
	dron._physics_process(0.02)
	var kierunek := dron.zablokowany_kierunek
	sprawdz(is_equal_approx(dron.ostrzezenie, 0.5), "ostrzezenie 0.5s")
	gracz.position.y += 150
	dron._physics_process(0.25)
	sprawdz(dron.zablokowany_kierunek == kierunek, "kierunek nie sledzi gracza podczas warning")
	dron._physics_process(0.25)
	var pociski := get_tree().get_nodes_in_group("pociski_dronow")
	sprawdz(pociski.size() == 1 and (pociski[0] as PociskDronaRun).velocity.normalized().is_equal_approx(kierunek) and dron.blysk_lufy > 0.0, "strzal w zablokowany kierunek + muzzle flash")
	sprawdz(dron.czas_do_strzalu >= 2.5 and dron.czas_do_strzalu <= 4.0, "interwal 2.5-4s")
	await klatki(90)
	sprawdz(mecz.trafienia_dronow.is_empty(), "pocisk ominiety ruchem paletki")
	mecz._wyczysc_pociski_dronow()
	await klatki(1)
	gracz.position.y -= 150
	var pocisk := PociskDronaRun.new()
	pocisk.run_state = stan
	pocisk.position = gracz.position + Vector2(25, 0)
	pocisk.velocity = Vector2.LEFT * 300
	mecz._podlacz_pocisk_drona(pocisk)
	gra.add_child(pocisk)
	await klatki(10)
	sprawdz(mecz.trafienia_dronow.size() == 1 and not is_instance_valid(pocisk), "kolizja swept: dokladnie jedno trafienie i usuniecie")
	stan.shieldRecharge = 3
	stan.shieldHits = 3
	mecz._rozstrzygnij_zdarzenia_bossa()
	sprawdz(stan.lives == 3 and stan.shieldHits == 0, "tarcza pochlania pocisk")
	stan.shieldHits = 3
	stan.dashIframeRemaining = 0.2
	mecz._pocisk_drona_trafil(gracz.position)
	mecz._rozstrzygnij_zdarzenia_bossa()
	sprawdz(stan.lives == 3 and stan.shieldHits == 3, "dash iframe zachowuje tarcze")
	stan.dashIframeRemaining = 0.0
	stan.invulnRemaining = 1.0
	mecz._pocisk_drona_trafil(gracz.position)
	mecz._rozstrzygnij_zdarzenia_bossa()
	sprawdz(stan.lives == 3 and stan.shieldHits == 3, "nietykalnosc zachowuje tarcze")
	stan.invulnRemaining = 0.0
	stan.shieldHits = 0
	mecz._pocisk_drona_trafil(gracz.position)
	mecz.kolejkuj_strate_pilki_bossa()
	mecz._rozstrzygnij_zdarzenia_bossa()
	sprawdz(stan.lives == 2 and stan.invulnRemaining > 0.0, "pocisk i strata pilki: jedna utrata zycia")
	gra.pilka().set_physics_process(false)
	gracz.set_physics_process(false)
	stan.invulnRemaining = 0.0
	stan.targetRewardMult = 1.25
	var punkty_przed := stan.score
	dron.trafienie(dron.hp)
	sprawdz(is_equal_approx(stan.score - punkty_przed, 2.5) and mecz._liczba_dronow() == 0, "nagroda bazowa 2 z mnoznikami + zwolnienie limitu")
	sprawdz((gracz.kolizja.shape as RectangleShape2D).size == bazowy_ksztalt, "geometria paletki zachowana")
	stan.regenInterval = 2
	stan.regenHits = 1
	stan.zarejestruj_odbicie(false)
	sprawdz(stan.lives == 3, "istniejaca regeneracja po obrazeniach")
	mecz._wyczysc_krysztaly()
	await klatki(2)
	dron = dron_w(gracz.position + Vector2(250, 0))
	dron.set_physics_process(true)
	dron.czas_do_strzalu = 0.6
	get_tree().paused = true
	var czas_przed := dron.czas_do_strzalu
	await get_tree().create_timer(0.1).timeout
	sprawdz(dron.czas_do_strzalu == czas_przed, "pauza zatrzymuje drona")
	get_tree().paused = false
	dron.set_physics_process(false)
	stan.wybor_aktywny = true
	dron._physics_process(0.3)
	sprawdz(dron.czas_do_strzalu == czas_przed, "wybor ulepszen zatrzymuje drona")
	stan.wybor_aktywny = false
	dron._wystrzel()
	mecz._wyczysc_krysztaly()
	await klatki(20)
	sprawdz(get_tree().get_nodes_in_group("pociski_dronow").is_empty() and mecz.krysztaly.is_empty(), "cleanup dronow i pociskow")
	gra.queue_free()
	await klatki(2)
	Ustawienia.tryb = "2graczy"
	gra = load("res://scena_główna.tscn").instantiate() as GraPongAPI
	get_tree().root.add_child(gra)
	await klatki(3)
	sprawdz(gra.przebieg().run_state == null and gra.przebieg().krysztaly.is_empty(), "klasyczny 2 graczy bez dronow i RunState")
	gra.queue_free()
	await klatki(2)
	print("WYNIK: ", bledy, " bledow")
	get_tree().quit(bledy)
