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
./bin/checkout.sh ./artifact-workspace campaign/H10-K24e
```

Skrypt klonuje `retractordb` i `rdb-experiment` **osobno**, do jawnego układu,
i przełącza je na przypięcie wskazanej kampanii. Nie ma tu submodułów.

## 2. Kontrola przypięć — wykonać przed czymkolwiek innym

```bash
RDB_ENGINE=./artifact-workspace/retractordb \
RDB_EXPERIMENT=./artifact-workspace/rdb-experiment \
./bin/verify_pins.sh
```

Skrypt sprawdza cztery rzeczy: czy tagi kampanii wskazują SHA z manifestu, czy
każde przypięcie leży na gałęzi głównej, czy zgadza się dowód równoważności
drzewa `src/` dla K24e, i czy parzystość archiwów raw jest taka, jak opisuje
manifest. Kod wyjścia różny od zera oznacza rozjazd — **nie kontynuuj**.

## 3. Tryb analityczny — regeneracja tabel i figur

`[K9b/Krok 5]` — deterministyczna regeneracja każdej tabeli i figury artykułu
z zachowanych danych, bez powtarzania pomiarów.

## 4. Tryb pomiarowy — powtórzenie pomiarów

`[K9b/Krok 5]` — powtórzenie kampanii na własnym sprzęcie. Tryb sprawdza
platformę i provenance **przed** startem, zapisuje wersje kernela, toolchainu
i ustawienia CPU/schedulera, i **nie obiecuje identycznych czasów**.

## 5. Co jest celowo niedeterministyczne

`[K9b/Krok 6]` — lista bajtów `.meta`, które różnią się między przebiegami
z założenia. Znany punkt wyjścia: 8-bajtowy znacznik utworzenia w nagłówku,
wyłączany z porównania już w kampanii K18.

## 6. Granice

Patrz [`MANIFEST.md`](MANIFEST.md) sekcja 5. W skrócie: `fig:qrs` pochodzi
z rewizji sprzed napraw silnika, cztery archiwa raw są nieobecne, a tryb
pomiarowy nie odtwarza czasów.
