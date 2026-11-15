# hf04 – webszerver-log riport

## Használat
    ./general-log.sh NEPTUN > access.log
    ./logriport.sh access.log

## Riport a saját adatomon
```
=== 1. Osszes keres ===
Kerések összesen:      4000
Egyedi IP-k:           3243

=== 2. Top 10 IP ===
758    193.224.41.77
1      10.0.187.179
1      10.1.165.177
1      10.105.130.190
1      10.107.198.229
1      10.109.69.124
1      10.110.150.51
1      10.111.169.135
1      10.113.87.25
1      10.114.102.183

=== 3. Statuszkod-megoszlas ===
200    2015    50.4%
301    387      9.7%
403    402     10.1%
404    372      9.3%
500    398      9.9%
502    426     10.7%

=== 4. Hibas kerések (4xx/5xx) URL szerint ===
216    /kepek/logo.png
210    /static/app.js
201    /admin
201    /api/v1/users
199    /
198    /index.html
197    /api/v1/orders
176    /login

=== 5. Kerések orankent ===
00:00  212
01:00  211
02:00  212
03:00  212
04:00  211
05:00  212
06:00  212
07:00  212
08:00  211
09:00  24
14:00  165
15:00  212
16:00  212
17:00  211
18:00  212
19:00  212
20:00  211
21:00  212
22:00  212
23:00  212
Csucs: 00:00 (212 keres)

=== 6. Atlagos valaszido (mp) ===
Osszes:      1.246
200-as:      1.247 (2015 keres)
500-as:      1.243 (398 keres)

=== 7. Kovetkeztetes ===
A legaktivabb IP a 193.224.41.77, ami az osszes keres 18.9%-at adta.
```
