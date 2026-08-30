# Změny

Verze se zapisuje do `pubspec.yaml` jako `version: MAJOR.MINOR.PATCH+BUILD`
a aplikace ji ukazuje v Nastavení → O aplikaci.

## Jak čísla zvyšovat

| Část | Kdy se zvýší | Příklad |
|---|---|---|
| **MAJOR** | změna, po které starší verze přestane rozumět datům | nový formát zálohy, přečíslování schématu tak, že zpětný import nefunguje |
| **MINOR** | nová funkce | kompas na mapě, popisy z Wikipedie, statistiky |
| **PATCH** | oprava chování, které mělo fungovat už dřív | kompas ukazoval špatným směrem, neukládala se úprava názvu |
| **+BUILD** | **vždy, při každé instalaci do telefonu** | 1.0.0+4 → 1.0.0+5 |

`+BUILD` je pořadové číslo, které **musí jen růst**. Android podle něj pozná,
že jde o novější instalaci; APK s nižším číslem odmítne nainstalovat přes vyšší.
Nemá vztah k MAJOR.MINOR.PATCH a nikdy se nevrací na začátek.

Migrace databáze má vlastní číslování (`schemaVersion` v `lib/data/database.dart`)
a s verzí aplikace se záměrně nespojuje — schéma se mění mnohem méně často.

---

## 0.9.0

První použitelná verze — nahrazuje papírovou mapu s kroužky.
Číslo 1.0.0 zůstává rezervované na podepsané release APK
nasazené na oba telefony.

**Mapa**
- 672 rozhleden z OpenStreetMap, kraje přiřazené přes QLever
- turistický podklad Mapy.com, přepínatelný na OpenStreetMap
- cache dlaždic, aby mapa fungovala i tam, kde není signál
- kompas se zámkem otáčení a měřítko
- vlastní poloha, přidání rozhledny dlouhým stiskem

**Návštěvy**
- opakované návštěvy jedné rozhledny, každá s vlastním datem
- hodnocení hvězdičkami, poznámka, vlastní fotky
- navigace do externí mapové aplikace

**Popisy a fotky**
- 257 popisů z české Wikipedie, 325 fotek z Wikimedia Commons
- autor a licence u každé fotky
- hromadné stažení fotek pro offline použití

**Seznam a statistiky**
- hledání, filtry podle stavu a kraje, čtyři způsoby řazení
- pokrok, rozpad po krajích a letech, žebříčky

**Přenos mezi telefony**
- export do ZIP a import se slučováním podle UUID
- upozornění na návštěvy, které oba telefony zapsaly zvlášť
