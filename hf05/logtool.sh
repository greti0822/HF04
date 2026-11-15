#!/usr/bin/env bash
# logtool.sh - webszerver-log elemzo eszkoz (HF5)
# Hasznalat: ./logtool.sh -f LOGFAJL [kapcsolok]   (reszletek: --help)
set -euo pipefail                                   # hibanal alljon le, ismeretlen valtozora is

readonly EX_OK=0                                    # minden rendben
readonly EX_USAGE=2                                 # rossz hasznalat (hibas vagy hianyzo kapcsolo)
readonly EX_NOFILE=3                                # a logfajl nem letezik / nem olvashato
readonly EX_NOOUT=4                                 # a kimeneti fajlba nem lehet irni

FILE=""                                             # -f: a feldolgozando log (kotelezo)
TOP=10                                              # -t: toplistak hossza
STATUS=""                                           # -s: statuszkod-szuro (ures = nincs szuro)
OUTPUT=""                                           # -o: kimeneti fajl (ures = kepernyo)
QUIET=0                                             # -q: 1 = csak az osszefoglalo sor

# A sugo. Elobb ez keszult el, a mukodes elott: ez a terv.
usage() {                                           # sugo kiirasa a stdout-ra
  cat <<'HELP'
logtool.sh - webszerver access-log elemzo

Hasznalat:
  logtool.sh -f LOGFAJL [-t N] [-s KOD] [-o FAJL] [-q]
  logtool.sh -h

Kapcsolok:
  -h, --help          kiirja ezt a sugot, majd kilep 0-val
  -f, --file FAJL     a feldolgozando log (KOTELEZO)
  -t, --top N         hany elem legyen a toplistakban (alapertelmezes: 10)
  -s, --status KOD    csak az adott statuszkodu sorokat nezi (pl. 404)
  -o, --output FAJL   a riportot fajlba irja a kepernyo helyett
  -q, --quiet         csak a vegso osszefoglalo sort irja ki

Kimenet: top IP-k, statuszkod-megoszlas, egy mondatos osszefoglalo.

Kilepesi kodok:
  0  rendben    2  hibas hasznalat    3  a logfajl nem olvashato
  4  a kimeneti fajlba nem lehet irni

Pelda:
  logtool.sh -f access.log -s 404 -t 3
HELP
}

hiba_usage() {                                      # hibauzenet + sugo + kilepes 2-vel
  echo "Hiba: $1" >&2                               # a hiba a stderr-re megy
  usage >&2                                         # a sugo is a stderr-re
  exit "$EX_USAGE"                                  # nem 0 kilepesi kod
}

parse_args() {                                      # a kapcsolok feldolgozasa
  while [[ $# -gt 0 ]]; do                          # amig van feldolgozatlan argumentum
    case "$1" in                                    # az aktualis argumentum alapjan
      -h|--help)                                    # sugo kerese
        usage                                       # sugo a stdout-ra
        exit "$EX_OK" ;;                            # kilepes 0-val
      -f|--file)                                    # logfajl megadasa
        [[ $# -ge 2 ]] || hiba_usage "a $1 kapcsolohoz ertek kell"   # van-e utana ertek?
        FILE="$2"; shift 2 ;;                       # ertek elmentese, ket argumentum eldobasa
      -t|--top)                                     # toplista hossza
        [[ $# -ge 2 ]] || hiba_usage "a $1 kapcsolohoz ertek kell"   # van-e utana ertek?
        TOP="$2"; shift 2 ;;                        # ertek elmentese
      -s|--status)                                  # statuszkod-szuro
        [[ $# -ge 2 ]] || hiba_usage "a $1 kapcsolohoz ertek kell"   # van-e utana ertek?
        STATUS="$2"; shift 2 ;;                     # ertek elmentese
      -o|--output)                                  # kimeneti fajl
        [[ $# -ge 2 ]] || hiba_usage "a $1 kapcsolohoz ertek kell"   # van-e utana ertek?
        OUTPUT="$2"; shift 2 ;;                     # ertek elmentese
      -q|--quiet)                                   # csendes mod
        QUIET=1; shift ;;                           # nincs ertek, egy argumentum
      *)                                            # minden mas ismeretlen
        hiba_usage "ismeretlen kapcsolo: $1" ;;     # hiba + sugo + exit 2
    esac                                            # case vege
  done                                              # ciklus vege
}

ellenoriz_bemenet() {                               # a megadott ertekek ellenorzese
  [[ -n "$FILE" ]] || hiba_usage "hianyzik a -f kapcsolo (a logfajl)"   # kotelezo kapcsolo
  [[ "$TOP" =~ ^[1-9][0-9]*$ ]] || hiba_usage "a -t ertek pozitiv egesz szam legyen, nem '$TOP'"   # szam-e
  if [[ -n "$STATUS" && ! "$STATUS" =~ ^[0-9]{3}$ ]]; then   # ha van szuro, 3 szamjegy legyen
    hiba_usage "a -s ertek haromjegyu statuszkod legyen, nem '$STATUS'"   # hiba + exit 2
  fi                                                # if vege
  if [[ ! -f "$FILE" || ! -r "$FILE" ]]; then       # letezik es olvashato a fajl?
    echo "Hiba: a '$FILE' fajl nem letezik vagy nem olvashato." >&2   # ertelmes uzenet
    exit "$EX_NOFILE"                               # exit 3
  fi                                                # if vege
  if [[ -n "$OUTPUT" ]] && ! { : > "$OUTPUT"; } 2>/dev/null; then   # tudunk-e a kimeneti fajlba irni?
    echo "Hiba: a '$OUTPUT' fajlba nem lehet irni." >&2   # ertelmes uzenet
    exit "$EX_NOOUT"                                # exit 4
  fi                                                # if vege
}

szuro() {                                           # a log sorai, a -s szuro szerint
  awk -v s="$STATUS" 's == "" || $9 == s' "$FILE"   # ha nincs szuro, mindent; kulonben csak a $9 == s sorokat
}

top_ip() {                                          # a leggyakoribb IP-k
  local parancs="sort -k1,1nr -k2,2 | head -n $TOP" # rendezes: darab csokkeno, azonosnal IP szerint
  szuro | awk -v parancs="$parancs" '
    { db[$1]++ }                                    # keresek IP-nkent ($1 = IP)
    END {                                           # a vegen
      for (k in db) printf "%-6d %s\n", db[k], k | parancs   # darab + IP a sort-nak
      close(parancs)                                # lezaras: itt irodik ki az eredmeny
    }'
}

statusz_megoszlas() {                               # statuszkodonkent darab es szazalek
  local parancs="sort -k1,1n"                       # statuszkod szerint novekvo sorrend
  szuro | awk -v parancs="$parancs" '
    { db[$9]++ }                                    # keresek statuszkodonkent ($9)
    END {                                           # a vegen
      for (k in db) printf "%-6s %-6d %5.1f%%\n", k, db[k], db[k]*100/NR | parancs   # kod, db, szazalek
      close(parancs)                                # lezaras
    }'
}

osszefoglalo() {                                    # egyetlen osszefoglalo sor
  szuro | awk -v s="$STATUS" '
    { db[$1]++ }                                    # keresek IP-nkent
    END {                                           # a vegen
      if (NR == 0) { print "Nincs a feltetelnek megfelelo sor."; exit }   # ures eredmeny
      for (k in db) { egyedi++; if (db[k] > max) { max = db[k]; ip = k } }   # egyedi IP-k, legaktivabb
      if (s != "") printf "[%s-es keresek] ", s     # szuro eseten jelezzuk
      printf "Osszesen %d keres, %d egyedi IP. ", NR, egyedi   # darabszamok
      printf "A legaktivabb IP a %s, ami az osszes keres %.1f%%-at adta.\n", ip, max*100/NR   # a mondat
    }'
}

riport() {                                          # a teljes riport a stdout-ra
  if [[ "$QUIET" -eq 1 ]]; then                     # csendes modban
    osszefoglalo                                    # csak az osszefoglalo sor
    return                                          # kesz
  fi                                                # if vege
  echo "=== Top $TOP IP ==="                        # 1. szakasz cime
  top_ip                                            # toplista
  echo ""                                           # ures sor
  echo "=== Statuszkod-megoszlas ==="               # 2. szakasz cime
  statusz_megoszlas                                 # megoszlas
  echo ""                                           # ures sor
  echo "=== Osszefoglalo ==="                       # 3. szakasz cime
  osszefoglalo                                      # az osszefoglalo sor
}

main() {                                            # a program belepesi pontja
  parse_args "$@"                                   # kapcsolok feldolgozasa
  ellenoriz_bemenet                                 # ertekek ellenorzese
  if [[ -n "$OUTPUT" ]]; then                       # ha fajlba kell irni
    riport > "$OUTPUT"                              # a riport a fajlba megy
    [[ "$QUIET" -eq 1 ]] || echo "Riport elmentve: $OUTPUT"   # visszajelzes (csendes modban nem)
  else                                              # kulonben
    riport                                          # a kepernyore
  fi                                                # if vege
}

main "$@"                                           # inditas az osszes argumentummal
