# Instrukcja odtworzenia

Wejściem jest **wyłącznie to repozytorium**. Nie potrzebujesz niczego, czego nie
ma w tym pliku; każde miejsce, w którym trzeba było „wiedzieć", jest defektem
instrukcji i prosimy o zgłoszenie go jako issue.

## 0. Czego potrzebujesz

`git`, `bash`. Do trybu pomiarowego dodatkowo toolchain silnika (Conan 2, CMake,
Ninja, kompilator C++23) — opisany w `retractordb/CLAUDE.md`.

## 1. Pobranie przypiętego układu repozytoriów

```bash
git clone https://github.com/michalwidera/rdb-artifact.git
cd rdb-artifact
./bin/checkout.sh ./artifact-workspace
```

Skrypt klonuje pięć repozytoriów **osobno**, do jawnego układu, i przełącza je
na pełne SHA domyślnego snapshotu z manifestu. Nie ma tu submodułów. Snapshot
używa aktualnego HEAD silnika, ponieważ zawiera krytyczne poprawki narzędzi.

Audyt historycznego układu kampanii jest osobnym trybem:

```bash
./bin/checkout.sh ./historical-workspace campaign/H10-K24e
```

Nie używaj tego trybu jako domyślnego środowiska nowego pomiaru. Zachowuje on
rzeczywiste provenance kampanii, nie bieżące narzędzia.

## 2. Kontrola przypięć — wykonać przed czymkolwiek innym

```bash
RDB_WORKSPACE=./artifact-workspace \
RDB_XRETRACTOR=./artifact-workspace/retractordb/build/Debug/src/retractor/xretractor \
./bin/verify_pins.sh snapshot
```

Skrypt sprawdza faktyczne `HEAD` pięciu checkoutów, tagi i ich osiągalność,
dowód równoważności drzewa `src/` K24e, 15 obecnych archiwów po SHA-256, trzy
jawne braki oraz — gdy podano `RDB_XRETRACTOR` — rewizję osadzoną w binarium.
Kod wyjścia różny od zera oznacza rozjazd — **nie kontynuuj**.

Kontrola binarium porównuje siedmioznakowy prefiks SHA publikowany obecnie przez
`xretractor --help` z pełnym SHA oczekiwanym przez manifest. Jest to granica
metadanych istniejącej binarki; skrypt nie udaje kontroli pełnych 40 znaków.

Inwentarz archiwów raw jest niezmiennikiem **snapshotu** i sprawdza się go tylko
w trybie `snapshot`. W trybie kampanii checkout stoi na starszej rewizji, na
której późniejsze archiwa jeszcze nie istnieją, więc sprawdzanie ich tam
raportowałoby nieobecność jako uszkodzenie — skrypt wypisuje wtedy `SKIP`
z odesłaniem do trybu `snapshot` (znalezisko K9b-F5).

## 3. Tryb analityczny — regeneracja tabel i figur

```bash
./bin/reproduce_analytic.sh --workspace ./artifact-workspace
```

Jedno polecenie, osiem grup, żadnego silnika i żadnego sprzętu pomiarowego.
Skrypt najpierw wywołuje `verify_pins.sh` i **odmawia regeneracji czegokolwiek**,
gdy workspace nie zgadza się z manifestem. Potem, grupa po grupie, uruchamia
własny zamrożony kod analityczny kampanii na danych leżących w przypiętym
checkoucie, zapisuje produkty do `tables/<grupa>/` i wypisuje **liczności**,
nie słowo „OK" — kontrola, która nie umie powiedzieć, ile porównała, nie jest
kontrolą. Każdy produkt jest dodatkowo porównywany z wersją zachowaną w git.

| Grupa | Artefakt | Liczności raportowane przez skrypt |
|---|---|---|
| `k6c` | `tab:k6-primary` | 780 przebiegów, 13 komórek, klasy A/B/C = 0/12/1 |
| `k22v5` | `tab:k22-constructs` | 45 konstruktów, 1764 przejrzane trafienia, 36 wierszy modyfikacji |
| `k24e` | `tab:tail-exactness` | 10 010 planów, 35 835 / 35 703 obserwacji, 9/9 klas dokładnych ogona i początku |
| `k26v3` | `tab:h9-primary` | 3/3 rodziny wspierające, 22 wiersze bramek |
| `g3` | 75 548 / 143 065 922 | 0 niezgodności, 10 mutacji, 13 sprawdzeń tożsamości silnika |
| `k19` | 468 220 / 2 239 488 | 4 mutacje, werdykt OK |
| `k18` | deterministyczne artefakty | 67 porównanych plików, 16 `.meta` po pominięciu znacznika, 51 bajtowo identycznych, 6 sprawdzeń round-trip |
| `ecg` | `fig:qrs` | 400 próbek w klatce, 2 zespoły QRS, piki na x=128 i x=371 |

Przebieg z 2026-08-20 na przypiętym snapshocie: **osiem grup na osiem**,
wszystkie porównania z zachowanymi plikami zgodne — bajtowo, z jednym wyjątkiem
raportu G3, który różni się wyłącznie wierszem `- wygenerowano:`.

Siedem grup nie potrzebuje silnika. Ósma, `ecg`, potrzebuje: przekaż jej
`--xretractor` i `--xqry`, a bez nich zgłosi `SKIP` i wypisze przepis. Binarium
jest przy tym bramkowane tak samo jak w trybie pomiarowym — rysunek ma pochodzić
z przypiętego silnika, nie z tego, co akurat leży na `PATH`.

Workspace jest **jednorazowy** i część zamrożonych skryptów pisze obok swoich
wejść; skrypt raportuje, ile plików każda grupa w nim ruszyła, i nigdy nie pisze
poza workspace.

### Okno `fig:qrs`

Przepis `xqry -s qrs_out -p 400,400` ustala **rozmiar** okna (400 próbek), ale
nie jego **położenie**: wykres przesuwa się i pokazuje to, co akurat przelatywało,
gdy przestano patrzeć. Rysunek z 2026-07-14 powstał w nieodnotowanej chwili,
więc nie dawał się odtworzyć — to było znalezisko K9b-F2.

Położenie ustala limit elementów. Reguła przyjęta 2026-08-20:

```bash
cd retractordb/examples/ecg/rec205
xretractor rec205-qrs.rql -r -k -x -m 1671
xqry -w -s qrs_out -p 400,400 -m 1671 | gnuplot
```

Klatka końcowa to zawsze próbki `[1271,1670]` strumienia `qrs_out`, z zespołami
QRS na `x=128` i `x=371`. Oś `x` biegnie wstecz w czasie: `x=0` to próbka
najnowsza. Skrypt sprawdza tę własność liczbowo — 400 próbek w klatce, dwa
zespoły, piki na przypiętych pozycjach z tolerancją 3 próbek — więc podmiana
danych albo silnika zatrzyma grupę, zamiast po cichu narysować co innego.

**Porównanie z rysunkiem z lipca:** morfologia bez zmian. Ten sam kształt
sygnału, ta sama obwiednia, te same impulsy detekcji w tych samych miejscach,
ta sama skala amplitud. Różniło się wyłącznie położenie okna. Nie jest to więc
znalezisko zmieniające jakąkolwiek liczbę artykułu w rozumieniu reguły
zamrożenia zakresu.

## 4. Tryb pomiarowy — powtórzenie pomiarów

```bash
./bin/reproduce_measure.sh --campaign campaign/H9-K26v3 \
  --workspace ./artifact-workspace --xretractor /sciezka/do/xretractor
```

Powtórzenie kampanii na własnym sprzęcie. Kolejność jest wiążąca: skrypt
najpierw zapisuje środowisko maszyny sterującej do `tables/measure/environment-*.tsv`
(kernel, PREEMPT_RT, model i liczba CPU, governory, SMT, `cmdline`, typ `/dev/shm`,
wersje toolchainu, SHA-256 binarium), potem sprawdza proweniencję — `verify_pins.sh`
dla wybranej kampanii i `verify_binary.sh` dla binarium — i dopiero wtedy podaje
przepis startowy. **Niezgodność zatrzymuje skrypt kodem 2 i nic nie zostaje
uruchomione.** Środowisko zapisuje się nawet wtedy, bo odmowa też jest informacją
o maszynie.

Skrypt **niczego nie startuje**. Przebieg trwa dobami i nie może ruszyć jako
skutek uboczny kontroli wstępnej; start jest osobnym poleceniem wydanym maszynie
pomiarowej. Czasy **nie są obiecane**: odtwarza się procedura werdyktu zastosowana
do liczb zmierzonych w zapisanych warunkach, nie same liczby.

### Autonomia przebiegu — wymaganie, nie udogodnienie

Kampanie tego projektu trwają **dobami** (K26v3 P8: trzy). Odtworzenie nie może
wymagać, żeby maszyna sterująca stała włączona przez cały ten czas — to jest
warunek wykonalności, nie wygody. Tryb pomiarowy realizuje wzorzec sprawdzony
w K26v3 P8 (`rdb-experiment/results_20260814_K26v3/`):

* maszyna sterująca **startuje i odbiera**; między jednym a drugim może być
  wyłączona i przebieg na tym nie ucierpi;
* przebieg prowadzi **usługa `systemd` na maszynie pomiarowej**, wstająca po
  boocie, więc przeżywa restart i zanik zasilania;
* długi przebieg jest **łańcuchem odcinków**, nie jednym procesem; między
  odcinkami maszyna pomiarowa restartuje się sama;
* **postęp widać w plikach**, nie w pamięci procesu: dopisywany log, znacznik
  ukończenia odcinka, status odcinka, znacznik zatrzymania;
* **skrypt odbiorczy jest bezstanowy i idempotentny** — wolno go uruchomić
  kiedykolwiek i dowolną liczbę razy, także dopiero po całym pomiarze;
* zakończenie ma **jednoznaczny sygnał**, odróżnialny od „jeszcze liczy"
  i od „przerwane z błędem";
* przebieg można **zatrzymać zdalnie jednym poleceniem**.

W praktyce oznacza to, że nadzór sprowadza się do okresowego, ręcznego odczytu
stanu — raz na kilka godzin albo raz na dobę, jak wygodnie.

## 5. Co jest celowo niedeterministyczne

Jedynym celowo niedeterministycznym polem trwałych artefaktów jest zakres
**offset 0–7** każdego głównego pliku `*.meta`: `int64_t` zawierający liczbę
nanosekund czasu utworzenia od epoki zegara systemowego, zapisany w natywnym
porządku bajtów platformy. Implementuje to `MetaIndexStore::writeHeader()`.

Porównanie wyłącza dokładnie te osiem bajtów (`tail -c +9`). Cała pozostała
część `.meta` — flaga luki, `recordCount`, liczba bitów i spakowany wzorzec
`NULL` — musi być identyczna. Plik `*.meta.shadow` **nie ma tego nagłówka** i
jest porównywany w całości. Dane, `.desc`, `.shadow` i pozostałe artefakty też
są porównywane w całości.

Kontrola nie może przejść na pustym zbiorze: wypisuje liczbę porównanych plików,
wymaga identycznego zbioru nazw i niezerowej liczności wskazanych strumieni.
Regresja silnika `it_replay_stability-run` wymaga co najmniej 36 plików i
niepustych danych dziewięciu nazwanych strumieni; K18 porównał 67 plików.

## 6. Granice

Patrz [`MANIFEST.md`](MANIFEST.md) sekcja 5. W skrócie: `fig:qrs` wymaga
rozstrzygnięcia okna danych, trzy archiwa raw są nieobecne, tryb pomiarowy nie
odtwarza czasów, a jego autonomia (§4) jest zapisana, lecz jeszcze nie sprawdzona
próbą z faktycznie odłączoną maszyną sterującą.
