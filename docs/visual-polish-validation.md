# Oprawa Ponga - zmiany i weryfikacja 2026-10-29

## Zmienione elementy

- `tlo_meczu.gd`: pełnoekranowa powierzchnia, dopasowanie do areny i okna, automatyczny wariant nowego meczu, przenikanie przez 0,65 s także pod pauzą. Szybkie kolejne zmiany mają limit czterech poprzednich warstw, zwalnianych po przejściu.
- `shaders/tlo_meczu.gdshader`: Cyberpunk z obwodami, impulsami i sylwetką zabudowy; Kosmos z gładkimi proceduralnymi mgławicami i gwiazdami ekranowymi; Synthwave z gradientem nieba, słońcem, świetlnym horyzontem i siatką perspektywiczną; Matrix z trzema skalami i tempami strumieni. Środek areny jest spokojniejszy. Ograniczona jakość pomija drobne warstwy, a wyłączenie efektów zatrzymuje rysowanie proceduralne.
- `ustawienia.gd`: sygnał wyboru motywu oddzielony od ogólnego odświeżenia grafiki. Motyw zmienia się bez ingerencji w mecz. Zapis korzysta z istniejącego `ustawienia.cfg`.
- `ustawienia_menu.gd`, `ustawienia_menu.tscn`: usunięte pole ziarna i nieaktualna informacja o zmianie dopiero w nowym meczu. Ponowny wybór Losowo jest dostępny. Ten sam ekran działa w menu i pod Escape.
- `neon_arcade_theme.tres`: spójne style list i popupów, SpinBox, pól, suwaków, pasków przewijania, checkboxów i przełączników; stany hover, pressed, focus i disabled. Wykorzystane istniejące zasoby Kenney i StyleBoxFlat. Wspólny motyw obejmuje również pozostałe ekrany.
- `tlo_menu.gd`: przecięcie powierzchni paletki zamiast odbicia za nią, małe kroki symulacji, reset po chybieniu i po wyjściu poza obszar, kontrola prędkości i watchdog. Nie zmieniono fizyki meczu.
- `wybor_ulepszenia.gd`: przyciemnienie, fade i przesunięcie nagłówka, wejście kart co 0,10 s z dołu i skali 0,95, hover, potwierdzenie i zamknięcie przez 0,22 s. Ochrona przed duplikacją i wielokrotnym wyborem, zachowany jednoramkowy guard przed wznowieniem. Bez zmian efektów i balansu ulepszeń.

## Wykonane sprawdzenia

Uruchomiono źródła w **Godot 4.7.2, Mobile/D3D12, NVIDIA RTX 4070**. Pomocnicza scena sterowała rzeczywistymi scenami projektu i zapisywała renderowane klatki. To kontrola integracji i wyglądu, a nie pełne rozegranie wszystkich trybów. Testy używały osobnego profilu APPDATA/LOCALAPPDATA w `.godot/polish-profile`; ustawienia gracza nie były nadpisywane.

- Cztery motywy renderowane przy intensywności 100%, w pełnej oraz ograniczonej jakości; obejrzane zrzuty głównych motywów.
- Zmiany podczas pauzy: oba obszary tła, trwające przenikanie i usunięcie starych warstw. Sprawdzona seria 12 szybkich wyborów.
- Zachowane pozycja i prędkość piłki oraz wynik podczas zmiany w pauzie; dodatkowo brak natychmiastowego resetu w działających trybach bot, 2graczy i Arena.
- Losowo losuje ponownie po świadomym powtórnym wyborze. Zmiana jakości i intensywności zachowuje wariant. Nowe instancje meczu mają różne ziarna; jawnie podany taki sam seed zachowuje deterministyczną sygnaturę.
- Zapis i odczyt motywu oraz jakości z istniejącego pliku, następnie odczyt w osobnym uruchomieniu Godota: poprawny.
- Renderowane okna 1152×720, 800×600 i 1600×900; zmiana rozmiaru także podczas pauzy. Karty ulepszeń sprawdzone również przy 800×600.
- Jakość Wyłączone oraz intensywność 0% ukrywają warstwę proceduralną.
- Symulacja menu: **20 minut przyspieszonego czasu symulacji** w krokach 1/60 s, wymuszone wyjście daleko poza boisko i zerowa prędkość. Piłka wróciła do aktywnej symulacji. Nie był to 20-minutowy test w czasie rzeczywistym.
- Wybór ulepszenia: wejście i stan końcowy wyrenderowane, dwie próby wyboru dały jedno ulepszenie, zamknięcie wznowiło grę. Powtórne otwarcie nie powieliło kart. Klawisz 1 wysłany przez Input na początku wejścia zakończył wybór bez blokady.
- Obejrzane menu, ustawienia, rozwinięta lista motywów, ustawienia pod Escape, wybór ulepszeń i podsumowanie meczu.
- Końcowy zestaw asercji integracyjnych: **0 niepowodzeń**, kod wyjścia 0. `git diff --check`: bez błędów whitespace.

Podczas prób Godot zgłaszał środowiskowy błąd odczytu systemowego magazynu certyfikatów. Przy części zamknięć pojawiał się komunikat o dwóch obiektach ObjectDB i jednym zasobie pozostającym w użyciu; ten sam komunikat wystąpił też w krótkim bazowym uruchomieniu menu. Nie zgłoszono błędów kompilacji nowych shaderów ani skryptów w końcowym przebiegu.

## Podglądy

- [Cyberpunk](visual-polish/motyw_1.png)
- [Kosmos](visual-polish/motyw_2.png)
- [Synthwave](visual-polish/motyw_3.png)
- [Digital Matrix](visual-polish/motyw_4.png)
- [Ustawienia](visual-polish/ustawienia.png)
- [Ustawienia pod Escape](visual-polish/pauza_ustawienia.png)
- [Wybór ulepszeń](visual-polish/ulepszenia.png)
- [Podsumowanie](visual-polish/podsumowanie.png)

Pomocnicze sceny, pełne logi i dodatkowe klatki są w ignorowanym `.godot/` (`polish_qa.gd`, `polish-qa-run.log`, `polish-restart.log`, `polish-qa/`); nie są częścią eksportu.

## Granice weryfikacji

Nie wykonano pełnych meczów we wszystkich trybach, wszystkich kombinacji wydarzeń i bossów ani meczu online na dwóch komputerach. Nie zmieniono pakietów sieciowych, zasad, fizyki właściwego meczu ani balansu. Nie wykonano nowego eksportu EXE; istniejący eksport nie zawiera tych zmian. Załącznik zadania zawierał tylko tekst, bez referencyjnych zrzutów.
