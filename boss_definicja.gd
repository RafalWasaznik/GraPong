class_name BossDefinicja
extends RefCounted

enum Wzor { POJEDYNCZY, ROZRZUT, SERIA, SCIANA, SATELITY, SATELITY_PARA, PULS }

class Atak extends RefCounted:
	var wzor: Wzor
	var telegraph_ms: float

	func _init(typ: Wzor, ostrzezenie: float = TrudnoscRun.DIFFICULTY.TELEGRAPH_MIN_MS) -> void:
		wzor = typ
		telegraph_ms = maxf(TrudnoscRun.DIFFICULTY.TELEGRAPH_MIN_MS, ostrzezenie)

class FazaRdzenia extends RefCounted:
	var sat_count: int
	var odwrocenie_ms: float
	var warstwy: bool
	var przesuwana_luka: bool
	var osloniety: Array[Atak] = []
	var odsloniety: Array[Atak] = [Atak.new(Wzor.PULS)]

	func _init(liczba: int, odwrocenie: float, dwie_warstwy: bool, ruchoma_luka: bool, para: bool) -> void:
		sat_count = liczba
		odwrocenie_ms = odwrocenie
		warstwy = dwie_warstwy
		przesuwana_luka = ruchoma_luka
		osloniety = [Atak.new(Wzor.SATELITY)]
		if para:
			osloniety = [Atak.new(Wzor.SATELITY_PARA)]

var fazy: Array[FazaRdzenia] = []
var ataki: Array[Atak] = [Atak.new(Wzor.POJEDYNCZY), Atak.new(Wzor.ROZRZUT), Atak.new(Wzor.SERIA), Atak.new(Wzor.SCIANA)]
var id: StringName
var nazwa: String
var maxHp: int
var speed: float
var attackSpeed: float
var attackCooldown: float


func _init(identyfikator: StringName, nazwa_pl: String, zdrowie: int, ruch: float, predkosc_pocisku: float, odnowienie: float) -> void:
	id = identyfikator
	nazwa = nazwa_pl
	maxHp = zdrowie
	speed = ruch
	attackSpeed = predkosc_pocisku
	attackCooldown = odnowienie


func faza_rdzenia(indeks: int) -> FazaRdzenia:
	return fazy[(maxi(0, indeks) >> 1) % fazy.size()]


static func katalog() -> Array[BossDefinicja]:
	var straznik := BossDefinicja.new(&"straznik", "Strażnik kryształów", TrudnoscRun.DIFFICULTY.BOSS_HP_BASE, TrudnoscRun.DIFFICULTY.BOSS_MOVE_SPEED, TrudnoscRun.DIFFICULTY.PROJECTILE_SPEED_BASE, TrudnoscRun.DIFFICULTY.COOLDOWN_BASE_MS / 1000.0)
	var rdzen := BossDefinicja.new(&"rdzen", "Rdzeń", TrudnoscRun.DIFFICULTY.BOSS_HP_BASE, TrudnoscRun.DIFFICULTY.CORE_MOVE_SPEED, TrudnoscRun.DIFFICULTY.PROJECTILE_SPEED_BASE, TrudnoscRun.DIFFICULTY.COOLDOWN_BASE_MS / 1000.0)
	rdzen.fazy = [FazaRdzenia.new(3, 0.0, false, false, false), FazaRdzenia.new(4, 6000.0, false, false, true), FazaRdzenia.new(4, 6000.0, true, true, true)]
	rdzen.fazy[2].osloniety.append(Atak.new(Wzor.SATELITY))
	return [straznik, rdzen]
