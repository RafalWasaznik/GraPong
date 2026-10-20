extends RefCounted


static func utworz_stream() -> AudioStreamWAV:
	const CZESTOTLIWOSC = 22050
	const CZAS_TRWANIA = 0.22
	var liczba_probek = int(CZESTOTLIWOSC * CZAS_TRWANIA)
	var dane = PackedByteArray()
	dane.resize(liczba_probek * 2)
	var losowy = RandomNumberGenerator.new()
	losowy.randomize()
	var przefiltrowany_szum = 0.0
	var faza = 0.0

	for indeks in range(liczba_probek):
		var postep = float(indeks) / float(liczba_probek)
		var obwiednia = pow(1.0 - postep, 2.0) * sin(PI * postep)
		przefiltrowany_szum = lerpf(przefiltrowany_szum, losowy.randf_range(-1.0, 1.0), 0.42)
		var czestotliwosc = lerpf(980.0, 180.0, postep)
		faza += TAU * czestotliwosc / float(CZESTOTLIWOSC)
		var probka = (przefiltrowany_szum * 0.65 + sin(faza) * 0.35) * obwiednia * 0.46
		dane.encode_s16(indeks * 2, clampi(roundi(probka * 32767.0), -32768, 32767))

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = CZESTOTLIWOSC
	stream.stereo = false
	stream.data = dane
	return stream
