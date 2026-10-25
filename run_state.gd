class_name RunState
extends RefCounted

const UPGRADE_EVERY_HITS: int = 10

var paddleWidthMult: float = 1.0
var ballSpeedMult: float = 1.0
var baseSlowMult: float = 1.0
var curseSpeedMult: float = 1.0
var lives: int = 3
var maxLives: int = 3
var score: float = 0.0
var scoreMult: float = 1.0
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
var ballCount: int = 1
var hits: int = 0
var ownedStacks: Array[StringName] = []
var wybor_aktywny: bool = false


func liczba_stosow(id: StringName) -> int:
	return ownedStacks.count(id)


func zarejestruj_odbicie(idealne: bool) -> void:
	hits += 1
	score += (1 + (precisionBonus if idealne else 0)) * scoreMult
	if shieldRecharge > 0:
		shieldHits = mini(shieldHits + 1, shieldRecharge)
	if regenInterval > 0:
		regenHits += 1
		if regenHits >= regenInterval:
			regenHits = 0
			lives = mini(lives + 1, maxLives)


func uzyj_tarczy() -> bool:
	if shieldRecharge <= 0 or shieldHits < shieldRecharge:
		return false
	shieldHits = 0
	return true


func rozpocznij_dash() -> void:
	if slowMult < 1.0:
		slowRemaining = 0.5


func aktualizuj_czas(delta: float) -> void:
	slowRemaining = maxf(0.0, slowRemaining - delta)


func mnoznik_predkosci() -> float:
	return ballSpeedMult * (slowMult if slowRemaining > 0.0 else 1.0)
