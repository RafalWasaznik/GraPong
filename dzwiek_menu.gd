extends RefCounted


static func utworz_plumkniecie() -> AudioStreamWAV:
	const CZESTOTLIWOSC = 22050
	const CZAS_TRWANIA = 0.065
	var liczba_probek = int(CZESTOTLIWOSC * CZAS_TRWANIA)
	var dane = PackedByteArray()
	dane.resize(liczba_probek * 2)
	var losowy = RandomNumberGenerator.new()
	losowy.randomize()
	var faza = 0.0

	for indeks in range(liczba_probek):
		var czas = float(indeks) / float(CZESTOTLIWOSC)
		var postep = float(indeks) / float(liczba_probek)
		var czestotliwosc = lerpf(920.0, 680.0, postep)
		faza += TAU * czestotliwosc / float(CZESTOTLIWOSC)
		var atak = clampf(czas / 0.0015, 0.0, 1.0)
		var obwiednia = atak * exp(-czas * 48.0)
		var transjent = losowy.randf_range(-1.0, 1.0) * exp(-czas * 650.0) * 0.08
		var ton = sin(faza) * 0.86 + sin(faza * 2.0) * 0.14
		var probka = ton * obwiednia * 0.28 + transjent
		dane.encode_s16(indeks * 2, clampi(roundi(probka * 32767.0), -32768, 32767))

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = CZESTOTLIWOSC
	stream.stereo = false
	stream.data = dane
	return stream
