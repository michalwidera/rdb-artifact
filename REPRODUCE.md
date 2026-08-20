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

## 3. Tryb analityczny — regeneracja tabel i figur

Stan 2026-08-20: osobno zweryfikowano regenerację K6c, K24e, K26v3, G3,
SDF/CSDF, K19 oraz testy replay/ECG. Wyniki miały niezerową liczność; werdykty K24e
były bajtowo identyczne z zachowanymi plikami, a pozostałe raporty różniły się
co najwyżej nagłówkiem czasu/commita. Nie ma jeszcze jednego autonomicznego
skryptu uruchamiającego cały ten zestaw, więc Krok 5 nie jest zamknięty.

`fig:qrs` także pozostaje otwarty. Przepis `xqry -s qrs_out -p 400,400` nie
określa, które okno 400 rekordów należy utrwalić. Końcowe okno bieżącego replay
ma inną liczbę widocznych pików niż PNG z 2026-07-14. Bez jawnego wyboru okna
podmiana rysunku nie byłaby deterministycznym odtworzeniem.

## 4. Tryb pomiarowy — powtórzenie pomiarów

`[K9b/Krok 5]` — powtórzenie kampanii na własnym sprzęcie. Tryb sprawdza
platformę i provenance **przed** startem, zapisuje wersje kernela, toolchainu
i ustawienia CPU/schedulera, i **nie obiecuje identycznych czasów**.

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
rozstrzygnięcia okna danych, trzy archiwa raw są nieobecne, tryb analityczny
nie ma jeszcze wspólnego entrypointu, a tryb pomiarowy nie odtwarza czasów.
