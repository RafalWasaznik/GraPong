extends Node

signal polaczono_z_hostem
signal blad_polaczenia
signal host_rozlaczyl
signal gracz_polaczyl(id: int)
signal gracz_rozlaczyl(id: int)
signal otrzymano_tryb_meczu(tryb: String)

const PORT = 24567
const LIMIT_GRACZY = 2

var rola = ""
var adres_hosta = ""
var pauza_lokalna = false
var runda_online = 0
var tryb_online = "klasyczny"


func _ready() -> void:
	multiplayer.peer_connected.connect(func(id): gracz_polaczyl.emit(id))
	multiplayer.peer_disconnected.connect(func(id): gracz_rozlaczyl.emit(id))
	multiplayer.connected_to_server.connect(func(): polaczono_z_hostem.emit())
	multiplayer.connection_failed.connect(func(): blad_polaczenia.emit())
	multiplayer.server_disconnected.connect(func(): host_rozlaczyl.emit())


func utworz_serwer(wybrany_tryb: String = "klasyczny") -> Error:
	rozlacz()
	runda_online = 0
	tryb_online = "arena" if wybrany_tryb == "arena" else "klasyczny"
	var peer = ENetMultiplayerPeer.new()
	var blad = peer.create_server(PORT, LIMIT_GRACZY - 1)
	if blad != OK:
		return blad
	multiplayer.multiplayer_peer = peer
	rola = "host"
	return OK


func dolacz_do_serwera(adres: String) -> Error:
	rozlacz()
	runda_online = 0
	var docelowy_adres = adres.strip_edges()
	if docelowy_adres.is_empty():
		return ERR_INVALID_PARAMETER
	var peer = ENetMultiplayerPeer.new()
	var blad = peer.create_client(docelowy_adres, PORT)
	if blad != OK:
		return blad
	multiplayer.multiplayer_peer = peer
	rola = "klient"
	adres_hosta = docelowy_adres
	return OK


func rozlacz() -> void:
	rola = ""
	pauza_lokalna = false
	multiplayer.multiplayer_peer = null


func czy_host() -> bool:
	return rola == "host" and multiplayer.is_server()


func czy_klient() -> bool:
	return rola == "klient" and multiplayer.multiplayer_peer != null


func popros_o_tryb_meczu() -> void:
	if czy_klient() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		rpc_id(1, "online_wyslij_tryb_meczu")


@rpc("any_peer", "call_remote", "reliable")
func online_wyslij_tryb_meczu() -> void:
	if not czy_host():
		return
	var nadawca = multiplayer.get_remote_sender_id()
	if nadawca <= 0 or not multiplayer.get_peers().has(nadawca):
		return
	rpc_id(nadawca, "online_odbierz_tryb_meczu", tryb_online)


@rpc("authority", "call_remote", "reliable")
func online_odbierz_tryb_meczu(otrzymany_tryb: String) -> void:
	if not czy_klient():
		return
	tryb_online = "arena" if otrzymany_tryb == "arena" else "klasyczny"
	otrzymano_tryb_meczu.emit(tryb_online)


func adresy_ipv4_lokalne() -> PackedStringArray:
	var wynik: PackedStringArray = []
	var tailscale = adresy_tailscale()
	for adres in IP.get_local_addresses():
		if adres.split(".").size() == 4 and not adres.begins_with("127.") and not adres.begins_with("169.254.") and not tailscale.has(adres):
			wynik.append(adres)
	return wynik


func adresy_tailscale() -> PackedStringArray:
	var wynik: PackedStringArray = []
	for adres in IP.get_local_addresses():
		var oktety = adres.split(".")
		if oktety.size() != 4 or oktety[0] != "100" or not oktety[1].is_valid_int():
			continue
		var drugi_oktet = oktety[1].to_int()
		if drugi_oktet < 64 or drugi_oktet > 127:
			continue
		var poprawny_ipv4 = true
		for oktet in oktety:
			if not oktet.is_valid_int() or oktet.to_int() < 0 or oktet.to_int() > 255:
				poprawny_ipv4 = false
				break
		if poprawny_ipv4:
			wynik.append(adres)
	return wynik
