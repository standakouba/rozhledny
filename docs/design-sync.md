# Návrh: sdílení dat přes vlastní úložiště

Stav: **návrh, neimplementováno.**

## Cíl

Dva telefony v jedné domácnosti vidí stejná data, aniž by kdokoli musel ručně
posílat soubor. Bez serveru, bez účtů, bez toho aby data prošla přes vývojáře.

## Proč ne backend

Aplikace je vydaná i pro cizí lidi. Vlastní server by z autora udělal správce
osobních údajů se vším, co k tomu patří — mazání na žádost, hlášení incidentů,
náklady rostoucí s počtem uživatelů. Za synchronizaci dvou telefonů v jedné
rodině se to nevyplatí.

Tenhle návrh drží data v úložišti, které si zvolí uživatel. Pro Play to
znamená, že deklarace „vývojář neshromažďuje žádná data“ **zůstává pravdivá**.

---

## Jádro: složka a soubor na zařízení

Uživatel jednou vybere složku, kterou už mu synchronizuje Google Drive,
Dropbox, Nextcloud nebo Syncthing. Android na to má Storage Access Framework,
takže není potřeba OAuth ani API klíč — aplikace dostane trvalé oprávnění
k jedné složce a nikam jinam nevidí.

**Každé zařízení zapisuje výhradně vlastní soubor** a cizí jen čte:

```
sdílená složka/
  rozhledny-a3f2....json      zapisuje telefon A, čte telefon B
  rozhledny-9c81....json      zapisuje telefon B, čte telefon A
  photos/
    e7d1....jpg               zapisuje ten, kdo fotku pořídil
```

Tohle je podstatné rozhodnutí. Kdyby oba telefony zapisovaly do jednoho
souboru, cloudový klient by při souběžné změně vyrobil „konfliktní kopii“
a museli bychom řešit něco, co jde návrhem úplně obejít. Takhle je **zápis
bezkonfliktní z principu** a slučování se děje lokálně při čtení — tam, kde
už máme otestovanou logiku.

Identifikátor zařízení je náhodné UUID vygenerované při prvním spuštění.
Vedle něj se ukládá jméno („Standa“, „Manželka“), aby šlo v Nastavení ukázat,
odkud data přišla.

## Formát: data zvlášť od fotek

Export do ZIPu zůstává, jak je — na ruční poslání mailem se hodí. **Pro
synchronizaci se ale použije jiné uspořádání**, a to schválně:

| | Soubor | Chování |
|---|---|---|
| Data | `rozhledny-<id>.json` | přepisuje se při každé změně, řádově desítky kB |
| Fotky | `photos/<uuid>.jpg` | zapíše se jednou a už nikdy nemění |

Kdyby se synchronizoval jeden ZIP se vším, znamenala by každá zapsaná návštěva
nové nahrání **všech** fotek. Při dvou stech fotkách to jsou stovky megabajtů
při každé změně. Fotky jsou přitom neměnné a identifikované UUID, takže se
každá přenese právě jednou.

Obojí používá stejné `encodeBackup` / `decodeBackup` / `mergeBackup`, které
už existují a jsou otestované.

## Kdy se zapisuje

**Po změně dat, s odkladem zhruba deseti sekund.** Ne při ukončení aplikace.

Tohle je podstatné rozhodnutí, ne detail. Android nezaručuje, že stav
`detached` vůbec doručí — proces může zabít kvůli paměti, aplikace může
spadnout. Kdyby zápis visel na ukončení, tiše by se ztratily poslední změny
a projevilo by se to až za měsíc tím, že na druhém telefonu něco chybí.
Zápis po změně naopak proběhne, dokud aplikace prokazatelně žije.

Odklad je tam proto, že jedna zapsaná návštěva znamená několik zápisů do
databáze za sebou — návštěva, fotka, úprava hodnocení. Bez něj by to byly
čtyři přepisy sdíleného souboru a cloud by čtyřikrát nahrával.

Doplňkově:

- **při odchodu do pozadí** (`paused`, který systém doručuje spolehlivě) —
  dopíše to, co ještě čeká v odkladu
- **jen když se od posledního zápisu opravdu něco změnilo**; bez téhle
  pojistky by se soubor přepsal při každém přepnutí aplikace a cloudový
  klient by donekonečna nahrával identický obsah
- ručně tlačítkem v Nastavení

Fotky stojí mimo tuhle logiku: zapíšou se jednou při přidání a už se nikdy
nemění.

## Kdy se čte

- při spuštění aplikace, jakmile je databáze připravená
- při návratu z pozadí, nejvýš jednou za pět minut

## Slučování a konflikty

Beze změny oproti dnešku: párování podle `uuid`, při kolizi vyhrává vyšší
`updatedAt`, smazané záznamy mají náhrobek, aby je import nevzkřísil.

**Známé omezení, které tenhle návrh neřeší:** `updatedAt` pochází z hodin
zařízení. Když jde jeden telefon výrazně napřed, vyhraje jeho verze i v případě,
že byla zapsaná dřív. Pro dva telefony v jedné domácnosti je to přijatelné;
pořádné řešení by znamenalo logické hodiny, což je na tenhle rozsah zbytečné.

**Podezřelé duplicity** (stejná rozhledna, stejný den, jiné UUID) se dnes
hlásí dialogem po importu. Při automatické synchronizaci by dialog vyskakoval
bez vyžádání — místo toho se objeví nenápadné upozornění v Nastavení.

## Chybové stavy

Všechny musí skončit tím, že aplikace normálně funguje dál. Synchronizace je
nadstavba, ne podmínka.

| Co se stane | Co aplikace udělá |
|---|---|
| Oprávnění ke složce zaniklo | pozná to a vyzve k novému výběru složky |
| Cloud soubor ještě nestáhl, je prázdný nebo useknutý | přeskočí ho, zkusí příště |
| Cizí soubor má novější formát | přeskočí ho a řekne, že je potřeba aktualizace |
| Telefon je offline | nic, zkusí příště |
| Zápis se přeruší | zapisuje se do dočasného jména a teprve pak přejmenuje |

Osiřelé fotky (návštěva smazána, soubor zůstal) se **záměrně nemažou** — jiné
zařízení je ještě může potřebovat. Úklid je na později a stojí za samostatné
rozmyšlení.

## Dopad na Google Play

- **Data safety zůstává „vývojář neshromažďuje žádná data“** — data putují do
  úložiště uživatele, ne k nám
- **Zásady ochrany údajů se musí doplnit** o odstavec, že si uživatel může
  zvolit složku, kam aplikace zapisuje zálohu, a že za obsah toho úložiště
  odpovídá poskytovatel, kterého si zvolil
- Funkce je **vypnutá, dokud si uživatel složku nevybere**, takže pro ostatní
  se nic nemění

## Nastavení

Nová sekce „Sdílená složka“: výběr složky, jméno tohoto zařízení, čas poslední
synchronizace, tlačítko synchronizovat teď, vypnout.

## Testy

Slučování je pokryté. Nově je potřeba ověřit:

- zařízení nečte vlastní soubor
- poškozený nebo prázdný soubor se přeskočí a nezhavaruje běh
- fotka se zapíše jednou, druhá synchronizace ji už nepřenáší
- dvě synchronizace za sebou beze změny dat nezmění ani jeden soubor
- ztracené oprávnění ke složce nezpůsobí pád

## Technické podklady

Trvalé oprávnění ke složce přes SAF umí balíček `saf`, případně
`android_file_picker`, který už máme v závislostech přes `file_picker`.
Před implementací je potřeba vybrat jeden a ověřit, že přežije restart
aplikace i telefonu — to je hlavní neznámá celého návrhu.

## Co tenhle návrh nedělá

- **není to okamžitá synchronizace.** Změna se objeví, až druhý telefon
  spustí aplikaci a cloud stihne soubor přenést. Pro společné výlety to stačí;
  kdo chce vidět změnu během vteřiny, potřebuje backend.
- neřeší víc než pár zařízení. Při deseti telefonech by čtení všech souborů
  přestalo být zadarmo.
