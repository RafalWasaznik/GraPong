class_name TrudnoscRun
extends RefCounted

class DIFFICULTY:
	const SAT_COUNT: int = 3
	const SAT_COUNT_LATE: int = 4
	const SAT_HP: int = 2
	const SAT_HP_CAP: int = 2
	const SAT_RADIUS: float = 18.0
	const ORBIT_RADIUS: float = 102.0
	const ORBIT_INNER_RADIUS: float = 70.0
	const ORBIT_SPEED: float = 0.48
	const EXPOSE_MS: float = 8000.0
	const REGEN_SAT_MS: float = 1200.0
	const SAT_SCORE: float = 12.0
	const CORE_MOVE_SPEED: float = 12.0
	const PULSE_COUNT: int = 14
	const PULSE_SPEED_MULT: float = 0.65
	const PULSE_GAP: float = 0.9
	const CRYSTAL_HP_BASE: int = 3
	const CRYSTAL_HP_CAP: int = 6
	const CRYSTAL_HP_STEP: int = 40
	const BOSS_HP_BASE: int = 20
	const BOSS_MOVE_SPEED: float = 125.0
	const PROJECTILE_SPEED_BASE: float = 180.0
	const COOLDOWN_BASE_MS: float = 3500.0
	const BOSS_HP_MULT_CAP: float = 3.0
	const BOSS_HP_GROWTH: float = 0.35
	const PROJECTILE_SPEED_CAP: float = 260.0
	const PROJECTILE_SPEED_GROWTH: float = 0.04
	const COOLDOWN_MIN_MS: float = 3000.0
	const COOLDOWN_GROWTH: float = 0.04
	const TELEGRAPH_MIN_MS: float = 600.0
	const SPAWN_BASE_MS: float = 5000.0
	const SPAWN_MIN_MS: float = 2500.0
	const SPAWN_MAX_MS: float = 10000.0
	const SPAWN_RATE_GROWTH: float = 0.08
	const SPAWN_RATE_CAP: float = 1.5
	const RATE_WINDOW: float = 30.0
	const ADAPT_STEP: float = 0.20
	const ADAPT_SMOOTH: float = 0.25
	const CAPACITY_FLOOR: float = 0.25
	const CRYSTAL_LIMIT: int = 3
	const CRYSTAL_LIMIT_LATE: int = 4
	const LATE_BOSS_INDEX: int = 2
	const VARIANT_UNLOCKS: Array[int] = [0, 15, 25, 35]
	const VARIANT_WEIGHTS: Array[float] = [5.0, 2.0, 2.0, 2.0]
	const VARIANT_SHIFTS: Array[float] = [-3.0, 2.0, 2.0, 2.0]
	const MIX_HITS: float = 150.0
	const PATTERN_UNLOCKS: Array[int] = [0, 0, 1, 2]
	const LAYOUT_UNLOCKS: Array[int] = [0, 15, 25, 35]
	const LAYOUT_SPACING: float = 86.0
	const SPAWN_ATTEMPTS: int = 24
	const TRACK_PADDING: float = 12.0
	const FIELD_LEFT_MARGIN: float = 40.0
	const FIELD_TOP_MARGIN: float = 90.0
	const FIELD_RIGHT_MARGIN: float = 120.0
	const FIELD_BOTTOM_MARGIN: float = 24.0
	const BALL_MARGIN: float = 30.0
	const CENTER_MARGIN: float = 10.0
	const SPREAD_ANGLE: float = 0.18
	const BURST_COUNT: int = 3
	const BURST_STEP_MS: float = 220.0
	const WALL_SPEED_MULT: float = 0.65
	const WALL_SPACING: float = 52.0
	const WALL_GAP: float = 240.0
	const DODGE_TRAVEL_MIN_MS: float = 1200.0

var boss_max_hp: int
var projectile_speed: float
var cooldown_ms: float
var crystal_hp: int
var crystal_limit: int
var boss_hp_mult: float
var projectile_speed_mult: float
var cooldown_mult: float
var telegraph_ms: float
var target_spawn_rate_mult: float
var variant_weights: Array[float] = []
var patterns: Array[int] = []
var layouts: Array[int] = []


static func getDifficulty(totalHits: int, bossIndex: int) -> TrudnoscRun:
	var wynik := TrudnoscRun.new()
	var hits := maxi(0, totalHits)
	var indeks := maxi(0, bossIndex)
	wynik.crystal_hp = mini(DIFFICULTY.CRYSTAL_HP_CAP, DIFFICULTY.CRYSTAL_HP_BASE + floori(float(hits) / DIFFICULTY.CRYSTAL_HP_STEP))
	wynik.crystal_limit = DIFFICULTY.CRYSTAL_LIMIT_LATE if indeks >= DIFFICULTY.LATE_BOSS_INDEX else DIFFICULTY.CRYSTAL_LIMIT
	wynik.boss_hp_mult = minf(DIFFICULTY.BOSS_HP_MULT_CAP, 1.0 + DIFFICULTY.BOSS_HP_GROWTH * sqrt(float(indeks)))
	wynik.projectile_speed_mult = 1.0 + DIFFICULTY.PROJECTILE_SPEED_GROWTH * sqrt(float(indeks))
	wynik.cooldown_mult = 1.0 / (1.0 + DIFFICULTY.COOLDOWN_GROWTH * sqrt(float(indeks)))
	var definicje := BossDefinicja.katalog()
	var boss := definicje[indeks % definicje.size()]
	wynik.boss_max_hp = roundi(boss.maxHp * wynik.boss_hp_mult)
	wynik.projectile_speed = minf(DIFFICULTY.PROJECTILE_SPEED_CAP, boss.attackSpeed * wynik.projectile_speed_mult)
	wynik.cooldown_ms = maxf(DIFFICULTY.COOLDOWN_MIN_MS, boss.attackCooldown * 1000.0 * wynik.cooldown_mult)
	wynik.telegraph_ms = DIFFICULTY.TELEGRAPH_MIN_MS
	wynik.target_spawn_rate_mult = minf(DIFFICULTY.SPAWN_RATE_CAP, 1.0 + DIFFICULTY.SPAWN_RATE_GROWTH * sqrt(float(indeks)))
	var postep := clampf(float(hits) / DIFFICULTY.MIX_HITS, 0.0, 1.0)
	for i in range(DIFFICULTY.VARIANT_UNLOCKS.size()):
		wynik.variant_weights.append(DIFFICULTY.VARIANT_WEIGHTS[i] + DIFFICULTY.VARIANT_SHIFTS[i] * postep if hits >= DIFFICULTY.VARIANT_UNLOCKS[i] else 0.0)
	for i in range(DIFFICULTY.PATTERN_UNLOCKS.size()):
		if indeks >= DIFFICULTY.PATTERN_UNLOCKS[i]:
			wynik.patterns.append(i)
	for i in range(DIFFICULTY.LAYOUT_UNLOCKS.size()):
		if hits >= DIFFICULTY.LAYOUT_UNLOCKS[i]:
			wynik.layouts.append(i)
	return wynik
