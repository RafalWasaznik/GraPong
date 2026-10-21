class_name ArenaManagerAPI
extends Node

func _brak_implementacji(metoda: String) -> void:
	push_error("ArenaManagerAPI nie ma implementacji metody: " + metoda)


func mnoznik_predkosci() -> float:
	_brak_implementacji("mnoznik_predkosci")
	return 1.0


func przyspieszenie_y(_predkosc_pozioma: float) -> float:
	_brak_implementacji("przyspieszenie_y")
	return 0.0


func przygotuj_pilke(_pilka: PilkaAPI, _delta: float) -> float:
	_brak_implementacji("przygotuj_pilke")
	return 1.0


func wzmocnij_odbicie_od_sciany(_pilka: PilkaAPI, _nazwa_sciany: String) -> void:
	_brak_implementacji("wzmocnij_odbicie_od_sciany")


func dane_sieciowe() -> Dictionary:
	_brak_implementacji("dane_sieciowe")
	return {}


func ustaw_stan_zdalny(_dane: Dictionary) -> void:
	_brak_implementacji("ustaw_stan_zdalny")


func po_zdobyciu_punktu() -> void:
	_brak_implementacji("po_zdobyciu_punktu")


func mocne_sciany_aktywne() -> bool:
	_brak_implementacji("mocne_sciany_aktywne")
	return false


func wieksza_arena_aktywna() -> bool:
	_brak_implementacji("wieksza_arena_aktywna")
	return false


func strefa_przyspieszenia_aktywna() -> bool:
	_brak_implementacji("strefa_przyspieszenia_aktywna")
	return false


func bramka_aktywna() -> bool:
	_brak_implementacji("bramka_aktywna")
	return false


func dane_bramki() -> Array[Rect2]:
	_brak_implementacji("dane_bramki")
	return []


func przezroczystosc_bramki() -> float:
	_brak_implementacji("przezroczystosc_bramki")
	return 0.0


func sciana_srodka_aktywna() -> bool:
	_brak_implementacji("sciana_srodka_aktywna")
	return false


func przezroczystosc_sciany_srodka() -> float:
	_brak_implementacji("przezroczystosc_sciany_srodka")
	return 0.0


func uruchom(_gra: GraPongAPI, _zdalny: bool = false, _oczekuj_na_gracza: bool = false) -> void:
	_brak_implementacji("uruchom")


func rozpocznij() -> void:
	_brak_implementacji("rozpocznij")


func zatrzymaj() -> void:
	_brak_implementacji("zatrzymaj")
