class_name RunState
extends RefCounted

const UPGRADE_EVERY_POINTS: int = 10
const UPGRADE_POINT_THRESHOLDS: Array[int] = [5, 10, 15]
const BOSS_EVERY_POINTS: int = 50
const INVULN_MS: int = 1500
const DASH_IFRAME_MS: int = 250
const CZAS_DO_MAKS_PREDKOSCI: float = 180.0
const MAKS_PREDKOSC_ZA_CZAS: float = 1.5

var czas_rozgrywki: float = 0.0
var paddleWidthMult: float = 1.0
var ballSpeedMult: float = 1.0
var ballSizeMult: float = 1.0
var lives: int = 3
var maxLives: int = 3
var score: float = 0.0
var magnetRadius: float = 0.0
var magnetPull: float = 0.0
var shieldRecharge: int = 0
var shieldHits: int = 0
var precisionBonus: int = 0
var regenInterval: int = 0
var regenHits: int = 0
var slowMult: float = 1.0
var slowRemaining: float = 0.0
var dashCooldownMult: float = 1.0
var ballDamage: int = 1
var targetSpawnRateMult: float = 1.0
var targetRewardMult: float = 1.0
var hits: int = 0
var ownedStacks: Array[StringName] = []
var wybor_aktywny: bool = false
var invulnRemaining: float = 0.0
var dashIframeRemaining: float = 0.0
var shieldBurstRemaining: float = 0.0
var dodgeSparkRemaining: float = 0.0
var dodgeSparkPosition: Vector2 = Vector2.ZERO
var bossIndex: int = 0
var nextBossScore: int = BOSS_EVERY_POINTS
var boss_aktywny: bool = false
var punkty_zamrozone: bool = false


func liczba_stosow(id: StringName) -> int:
	return ownedStacks.count(id)


func zarejestruj_odbicie(idealne: bool) -> void:
	hits += 1
	dodaj_punkty(1.0)


func dodaj_punkty(ile: float) -> void:
	if punkty_zamrozone:
		return
	var poprzedni_wynik := floori(score)
	score += maxf(0.0, ile)
	var zdobyte := floori(score) - poprzedni_wynik
	if shieldRecharge > 0:
		shieldHits = mini(shieldHits + zdobyte, shieldRecharge)
	if regenInterval > 0:
		regenHits += zdobyte
		var odnowione_zycia := floori(float(regenHits) / regenInterval)
		regenHits %= regenInterval
		lives = mini(lives + odnowione_zycia, maxLives)


func uzyj_tarczy() -> bool:
	if shieldRecharge <= 0 or shieldHits < shieldRecharge:
		return false
	shieldHits = 0
	shieldBurstRemaining = 0.3
	return true


func rozpocznij_dash() -> void:
	dashIframeRemaining = DASH_IFRAME_MS / 1000.0
	if slowMult < 1.0:
		slowRemaining = 0.5


func aktualizuj_czas(delta: float) -> void:
	czas_rozgrywki += delta
	slowRemaining = maxf(0.0, slowRemaining - delta)
	invulnRemaining = maxf(0.0, invulnRemaining - delta)
	dashIframeRemaining = maxf(0.0, dashIframeRemaining - delta)
	shieldBurstRemaining = maxf(0.0, shieldBurstRemaining - delta)
	dodgeSparkRemaining = maxf(0.0, dodgeSparkRemaining - delta)


func mnoznik_predkosci() -> float:
	return ballSpeedMult * mnoznik_predkosci_za_czas() * (slowMult if slowRemaining > 0.0 else 1.0)


func mnoznik_predkosci_za_czas() -> float:
	return lerpf(1.0, MAKS_PREDKOSC_ZA_CZAS, clampf(czas_rozgrywki / CZAS_DO_MAKS_PREDKOSCI, 0.0, 1.0))
