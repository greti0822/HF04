#!/usr/bin/env bash
# Hasznalat: ./logriport.sh access.log
set -euo pipefail                                   # hiba eseten alljon le, ne hasznaljon beallitatlan valtozot

if [[ $# -ne 1 ]]; then                             # pontosan egy parametert varunk
  echo "Hasznalat: $0 LOGFAJL" >&2                  # a hibauzenet a stderr-re megy
  exit 2                                            # 2 = rossz hasznalat
fi

LOG="$1"                                            # a logfajl neve parameterbol jon

if [[ ! -r "$LOG" ]]; then                          # letezik es olvashato a fajl?
  echo "Hiba: a '$LOG' fajl nem letezik vagy nem olvashato." >&2   # ertelmes hibauzenet
  exit 1                                            # nem 0 kilepesi kod
fi

if [[ ! -s "$LOG" ]]; then                          # ures fajl?
  echo "Hiba: a '$LOG' fajl ures." >&2              # nincs mit elemezni
  exit 1                                            # nem 0 kilepesi kod
fi

# Egyetlen awk-hivas: egyszer olvassa a fajlt, mindent egyszerre szamol.
awk '
{                                                   # minden sorra lefut
  db_ip[$1]++                                       # kerések IP-nként ($1 = IP)
  db_st[$9]++                                       # kerések státuszkódonként ($9 = kod)
  split($4, ido, ":")                               # a [15/Nov/2026:13:45:12 mezo szetvagasa kettospontnál
  db_ora[ido[2]]++                                  # az ido[2] az ora (00-23)
  if ($9 >= 400) db_hiba[$7]++                      # 4xx/5xx eseten URL ($7) szerinti szamlalas
  vsum += $NF; vdb++                                # valaszido osszeg es darabszam ($NF = utolso mezo)
  if ($9 == 200) { s200 += $NF; d200++ }            # csak a 200-asok valaszideje
  if ($9 == 500) { s500 += $NF; d500++ }            # csak az 500-asok valaszideje
}
END {                                               # a fajl vegen jon a riport
  for (k in db_ip) egyedi++                         # egyedi IP-k megszamolasa

  print "=== 1. Osszes keres ==="                   # 1. szakasz cime
  printf "%-22s %d\n", "Kerések összesen:", NR      # osszes sor = osszes keres
  printf "%-22s %d\n", "Egyedi IP-k:", egyedi       # kulonbozo IP-k szama

  print ""                                          # ures sor
  print "=== 2. Top 10 IP ==="                      # 2. szakasz cime
  fflush()                                          # kiirás ürítése, hogy a sort elé kerüljön
  parancs = "sort -k1,1nr | head -n 10"             # csokkeno sorrend, elso 10
  for (k in db_ip) printf "%-6d %s\n", db_ip[k], k | parancs   # darab + IP a sort-nak
  close(parancs)                                    # lezárás: itt íródik ki az eredmény

  print ""                                          # ures sor
  print "=== 3. Statuszkod-megoszlas ==="           # 3. szakasz cime
  fflush()                                          # ürítés a sort elott
  parancs = "sort -k1,1n"                           # statuszkod szerint novekvo
  for (k in db_st) printf "%-6s %-6d %5.1f%%\n", k, db_st[k], db_st[k]*100/NR | parancs   # kod, db, szazalek
  close(parancs)                                    # lezárás

  print ""                                          # ures sor
  print "=== 4. Hibas kerések (4xx/5xx) URL szerint ==="   # 4. szakasz cime
  fflush()                                          # ürítés a sort elott
  parancs = "sort -k1,1nr"                          # leggyakoribb elol
  for (k in db_hiba) printf "%-6d %s\n", db_hiba[k], k | parancs   # darab + URL
  close(parancs)                                    # lezárás

  print ""                                          # ures sor
  print "=== 5. Kerések orankent ==="               # 5. szakasz cime
  for (h = 0; h < 24; h++) {                        # 0-tol 23-ig minden ora
    kulcs = sprintf("%02d", h)                      # ketjegyu ora, pl. 07
    n = db_ora[kulcs] + 0                           # ha nincs adat, 0
    if (n > max_ora) { max_ora = n; csucs = kulcs } # csucs-ora kovetese
    if (n > 0) printf "%s:00  %d\n", kulcs, n       # csak a nem ures orakat irjuk ki
  }
  printf "Csucs: %s:00 (%d keres)\n", csucs, max_ora   # a csucs-ora

  print ""                                          # ures sor
  print "=== 6. Atlagos valaszido (mp) ==="         # 6. szakasz cime
  printf "%-12s %.3f\n", "Osszes:", vsum/vdb        # teljes atlag
  if (d200 > 0) printf "%-12s %.3f (%d keres)\n", "200-as:", s200/d200, d200   # 200-asok atlaga
  else printf "%-12s nincs ilyen keres\n", "200-as:"                           # vedelem 0-val osztas ellen
  if (d500 > 0) printf "%-12s %.3f (%d keres)\n", "500-as:", s500/d500, d500   # 500-asok atlaga
  else printf "%-12s nincs ilyen keres\n", "500-as:"                           # vedelem 0-val osztas ellen

  for (k in db_ip) if (db_ip[k] > max_ip) { max_ip = db_ip[k]; top_ip = k }   # legaktivabb IP keresese

  print ""                                          # ures sor
  print "=== 7. Kovetkeztetes ==="                  # 7. szakasz cime
  printf "A legaktivabb IP a %s, ami az osszes keres %.1f%%-at adta.\n", top_ip, max_ip*100/NR   # egy mondat
}' "$LOG"                                           # az awk a parameterkent kapott fajlt olvassa
