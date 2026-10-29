extends Node

var ruchomy_mur: StaticBody2D
var bramka: RuchomaScianaArena
var gra: GraPongAPI
var bledy: int = 0
var kontrole: int = 0
var katalog := "res://docs"

func sprawdz(ok: bool, opis: String) -> void:
	kontrole += 1
	if not ok:
		bledy += 1
		push_error("FAIL: " + opis)
	else:
		print("PASS: ", opis)

func klatka() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame

func _ready() -> void:
	start.call_deferred()

func zatrzymaj(wezel: Node) -> void:
	wezel.set_physics_process(false)
	for dziecko in wezel.get_children():
		zatrzymaj(dziecko)

func sciana(pozycja: Vector2, rozmiar: Vector2) -> StaticBody2D:
	var cialo := StaticBody2D.new()
	var kolizja := CollisionShape2D.new()
	var ksztalt := RectangleShape2D.new()
	ksztalt.size = rozmiar
	kolizja.shape = ksztalt
	cialo.add_child(kolizja)
	gra.add_child(cialo)
	cialo.global_position = pozycja
	return cialo

func ruch(opis: String, start_pilki: Vector2, predkosc: Vector2, mnoznik: float = 1.0, klatek: int = 30) -> void:
	var pilka := gra.pilka()
	pilka.global_position = start_pilki
	pilka.velocity = predkosc
	pilka.predkosc = predkosc.length()
	pilka.czas_bez_postepu = 0.0
	var droga := 0.0
	var najdluzszy_zastoj := 0
	var zastoj := 0
	for i in range(klatek):
		if is_instance_valid(ruchomy_mur):
			ruchomy_mur.position += ruchomy_mur.constant_linear_velocity / 60.0
		if bramka != null:
			bramka.aktualizuj(1.0/60.0,true)
		await klatka()
		var przed := pilka.global_position
		pilka._przesun_z_kolizjami(1.0/60.0,mnoznik)
		var krok := pilka.global_position.distance_to(przed)
		droga += krok
		zastoj = zastoj + 1 if krok < predkosc.length()*mnoznik/60.0*0.05 else 0
		najdluzszy_zastoj = maxi(najdluzszy_zastoj,zastoj)
	sprawdz(droga > predkosc.length()*mnoznik/60.0*klatek*(0.2 if klatek == 1 else 0.45), opis+" - rzeczywista droga "+str(snappedf(droga,0.01)))
	sprawdz(najdluzszy_zastoj < 7,opis+" - brak utrwalonego zastoju")
	sprawdz(absf(pilka.velocity.length()-predkosc.length()) < 0.01,opis+" - zachowana szybkosc")

func start() -> void:
	Ustawienia.tryb = "2graczy"
	gra = load("res://scena_główna.tscn").instantiate() as GraPongAPI
	add_child(gra)
	await klatka()
	zatrzymaj(gra)
	var pilka := gra.pilka()
	pilka.run_state = RunState.new()
	pilka.intro_aktywne = false
	var srodek := Vector2((Ustawienia.lewa_granica+Ustawienia.prawa_granica)*0.5,(Ustawienia.gorna_granica+Ustawienia.dolna_granica)*0.5)
	var boss := BossRun.new()
	boss.definicja = BossDefinicja.katalog()[0]
	boss.paletka = gra.lewa_paletka()
	boss.pilka = pilka
	gra.add_child(boss)
	boss.set_physics_process(false)
	boss.global_position = srodek
	boss.intro = 0.0
	for znak in [-1.0,1.0]:
		await ruch("boss gora/dol "+str(znak),srodek+Vector2(-15,znak*85),Vector2(300,-znak*540),1.0,20)
	boss.global_position = Vector2(Ustawienia.prawa_granica-90,srodek.y)
	boss.kierunek = -1.0
	boss.czas_ataku = 1000.0
	boss.set_physics_process(true)
	var start_bossa := boss.global_position

	await ruch("boss nadjezdza",start_bossa+Vector2(-15,-81),Vector2(-300,-30),1.0,20)
	sprawdz(pilka.velocity.y < -30.0,"boss nadjezdza - odbicie wzgledem powierzchni")
	sprawdz(boss.global_position.distance_to(start_bossa)>1.0 and boss.constant_linear_velocity.y<0.0,"boss faktycznie rusza ku pilce")
	await ruch("boss nadjezdza na spowolniona pilke",boss.global_position+Vector2(-15,-81),Vector2(-300,-30),0.15,20)
	boss.queue_free()
	await klatka()
	var kamien := KrysztalRun.new()
	kamien.skonfiguruj(KrysztalRun.CRYSTAL_VARIANTS[3],pilka.run_state,srodek-Vector2(0,70),srodek+Vector2(0,70))
	gra.add_child(kamien)
	kamien.max_hp = 1000
	kamien.hp = 1000
	kamien.czas_pojawiania = kamien.CZAS_POJAWIANIA
	kamien.kolizja.disabled = false
	kamien.set_physics_process(true)
	await ruch("wedrujacy kamien",srodek+Vector2(-50,-10),Vector2(570,180),1.0,25)
	sprawdz(kamien.constant_linear_velocity.length() > 0.0,"kamien publikuje predkosc")
	kamien.queue_free()
	await klatka()
	var mur := sciana(srodek,Vector2(20,190))
	await ruch("sciana stala",srodek+Vector2(-28,0),Vector2(620,0),1.0,20)
	await ruch("wysoka predkosc",srodek+Vector2(-90,0),Vector2(6000,0),1.0,1)
	sprawdz(pilka.global_position.x < srodek.x-32,"wysoka predkosc - remainder wykonany po odbiciu")
	await ruch("spowolnienie ulepszenia",srodek+Vector2(-23,0),Vector2(620,0),0.2,25)
	mur.constant_linear_velocity = Vector2(-160,0)
	ruchomy_mur = mur
	await ruch("sciana ruchoma",srodek+Vector2(-20,20),Vector2(-50,300),1.0,20)
	ruchomy_mur = null
	mur.queue_free()
	await klatka()
	var gora := sciana(srodek+Vector2(0,-23),Vector2(180,20))
	var dol := sciana(srodek+Vector2(0,23),Vector2(180,20))
	await ruch("waski przeswit i szybkie kontakty",srodek+Vector2(-65,0),Vector2(500,370),1.0,25)
	gora.queue_free()
	dol.queue_free()
	await klatka()
	gora = sciana(srodek+Vector2(0,-40),Vector2(100,20))
	mur = sciana(srodek+Vector2(40,0),Vector2(20,100))
	await ruch("naroznik",srodek+Vector2(15,-15),Vector2(440,-440),1.0,25)
	gora.queue_free()
	mur.queue_free()
	await klatka()
	# Wychodzenie z nakladania nie moze odwrocic oddalajacej sie pilki.
	mur = sciana(srodek,Vector2(20,100))
	await klatka()
	pilka.global_position = srodek+Vector2(-19,0)
	pilka.velocity = Vector2(-620,0)
	pilka._przesun_z_kolizjami(1.0/60.0,1.0)
	sprawdz(pilka.velocity.x < 0.0 and pilka.global_position.x < srodek.x-25,"separacja oddalajacej sie pilki bez falszywego odbicia")
	mur.queue_free()
	await klatka()
	var arena := ArenaManager.new()
	gra.add_child(arena)
	gra._arena_manager = arena
	arena.uruchom(gra)
	arena.set_physics_process(false)
	arena.set_process(false)
	bramka = arena.ruchoma_sciana
	bramka.aktywuj("")
	bramka.czas_aktywna = 2.0
	bramka.aktualizuj(1.0/60.0,true)
	await klatka()
	var segment := bramka.segmenty()[0]
	await ruch("ruchoma krawedz bramki Areny",Vector2(segment.get_center().x-4,segment.end.y+10),Vector2(-300,-100),0.3,20)
	sprawdz(not bramka.predkosci_krawedzi.is_empty() and absf(bramka.predkosci_krawedzi[0].y)>1.0,"bramka publikuje ruch krawedzi zmienianego ksztaltu")
	bramka.zatrzymaj()
	bramka = null
	await klatka()
	# Glebokie zastane nakladanie i watchdog: naprawa tylko lokalna.
	mur = sciana(srodek,Vector2(20,100))
	await klatka()
	pilka.global_position = srodek+Vector2(-12,0)
	pilka.velocity = Vector2(-620,0)
	pilka._przesun_z_kolizjami(1.0/60.0,1.0)
	sprawdz(pilka.global_position.x < srodek.x-20 and pilka.velocity.x < 0.0,"zastane glebokie nakladanie rozdzielone lokalnie")
	mur.queue_free()
	await klatka()
	# Bledny stan: szczelina wezsza od srednicy, zero postepu mimo predkosci.
	var lewy := sciana(srodek+Vector2(-18,0),Vector2(20,80))
	var prawy := sciana(srodek+Vector2(18,0),Vector2(20,80))
	await klatka()
	pilka.global_position = srodek
	pilka.velocity = Vector2(620,0)
	pilka.czas_bez_postepu = 0.0
	var awarie_przed := pilka.awaryjne_separacje
	pilka.diagnostyka_kolizji = true
	for i in range(20):
		pilka._przesun_z_kolizjami(1.0/60.0,1.0)
		await klatka()
	sprawdz(pilka.awaryjne_separacje > awarie_przed,"watchdog wykrywa rzeczywisty brak postepu w blednym kontakcie")
	sprawdz(pilka.global_position.distance_to(srodek) < 12.0 and absf(pilka.velocity.length()-620.0)<0.01,"watchdog lokalny bez teleportu i zmiany szybkosci")
	lewy.queue_free()
	prawy.queue_free()
	pilka.diagnostyka_kolizji = false
	await klatka()
	await galeria()
	print("WYNIK: ",kontrole," kontroli, ",bledy," bledow")
	get_tree().quit(1 if bledy > 0 else 0)

func galeria() -> void:
	gra.hide()
	var tlo := ColorRect.new()
	tlo.color = Color("#080e18")
	tlo.size = Vector2(1280,720)
	add_child(tlo)
	for i in range(4):
		var dron := DronRun.new()
		dron.skonfiguruj(KrysztalRun.CRYSTAL_VARIANTS[0],RunState.new(),Vector2.ZERO,Vector2.ZERO)
		add_child(dron)
		dron.position = Vector2(170+i*290,210)
		dron.scale = Vector2.ONE*3.0
		dron.modulate.a = 1.0
		dron.set_physics_process(false)
		dron.max_hp = 20
		dron.hp = [20,15,10,5][i]
		dron.czas_animacji = 2.0
		sprawdz(dron.etap_uszkodzenia() == i,"dron prog etapu "+str(i))
		var etykieta := Label.new()
		etykieta.position = Vector2(95+i*290,85)
		etykieta.text = str(dron.hp)+" / 20 HP - etap "+str(i+1)
		etykieta.add_theme_font_size_override("font_size",20)
		add_child(etykieta)
		var kamien := KrysztalRun.new()
		add_child(kamien)
		kamien.set_physics_process(false)
		kamien.position = Vector2(170+i*290,420)
		kamien.scale = Vector2.ONE*2.0
		kamien.modulate.a = 1.0
		kamien.max_hp = 20
		kamien.hp = dron.hp
		kamien.queue_redraw()
		sprawdz((dron.kolizja.shape as ConvexPolygonShape2D).points == dron._punkty_szesciokata(30.0),"dron hitbox niezmieniony "+str(i))
		var poprzedni := dron.hp
		dron.miejsce_trafienia = Vector2(-18,-12)
		dron.trafienie(1)
		sprawdz(dron.hp == poprzedni-1 and dron.czas_trafienia > 0.0 and dron.slady_trafien.size() == 1,"dron kazde trafienie etapu "+str(i))
		dron.hp = poprzedni
		dron.czas_trafienia = 0.0
		dron.queue_redraw()
		if i == 3:
			dron.hp = 2
			dron.trafienie(1)
			sprawdz(dron.hp == 1 and not dron.rozpad and dron.czas_trafienia == 0.22 and dron.numer_trafienia == 2,"dron ostatnie przezyte trafienie czytelne")
			dron.hp = poprzedni
			dron.czas_trafienia = 0.0
	var strzelec := DronRun.new()
	strzelec.skonfiguruj(KrysztalRun.CRYSTAL_VARIANTS[0],RunState.new(),Vector2.ZERO,Vector2.ZERO)
	strzelec.paletka = gra.lewa_paletka()
	gra.add_child(strzelec)
	strzelec.position = Vector2(600,300)
	strzelec.set_physics_process(false)
	strzelec.czas_do_strzalu = 0.51
	strzelec._physics_process(0.02)
	sprawdz(is_equal_approx(strzelec.ostrzezenie,0.5),"ostrzezenie wiezyczki nadal 0.5s")
	var cel := strzelec.zablokowany_kierunek
	strzelec.paletka.position.y += 40.0
	strzelec._physics_process(0.1)
	sprawdz(strzelec.zablokowany_kierunek == cel,"namierzanie zablokowane podczas ostrzezenia")
	strzelec._physics_process(0.4)
	sprawdz(strzelec.blysk_lufy > 0.0 and strzelec.czas_do_strzalu >= 2.5 and strzelec.czas_do_strzalu <= 4.0,"strzal i interwal bez zmian")
	strzelec.queue_free()
	await klatka()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(katalog+"/wiezyczki-pancerz.png")
