# Rozhledny

Android aplikace na sbírání rozhleden. Nahrazuje papírovou mapu, do které se
navštívené rozhledny kroužkovaly tužkou.

Na mapě je 672 rozhleden z OpenStreetMap. Každou jde označit za navštívenou —
opakovaně, protože na některé se jezdí pravidelně a každý výlet si zaslouží
vlastní záznam s datem, hodnocením, poznámkou a fotkami. Rozhlednu, která
v datech chybí, jde přidat ručně.

Aplikace **nemá server ani účty**. Data leží v telefonu a mezi telefony se
přenášejí exportem do souboru, který se na druhé straně slučuje.

## Co umí

- **Mapa** — turistický podklad Mapy.com (nebo OpenStreetMap), cache dlaždic
  pro cesty bez signálu, kompas se zámkem otáčení, měřítko, vlastní poloha
- **Návštěvy** — opakované, s datem i zpětně, hodnocením, poznámkou a fotkami
- **Popisy a fotky** — 257 popisů z české Wikipedie a 325 fotek z Wikimedia
  Commons, včetně autorů a licencí; fotky jde stáhnout dopředu pro offline
- **Seznam** — hledání, filtry podle stavu a kraje, řazení podle vzdálenosti,
  abecedy, poslední návštěvy nebo počtu návštěv
- **Statistiky** — pokrok, rozpad po krajích a letech, kam se vracíte
- **Přenos** — export do ZIP a import se slučováním podle UUID

## Sestavení

Potřeba je Flutter (vyvíjeno na 3.47) a Android SDK.

```bash
flutter pub get
dart run build_runner build          # vygeneruje kód pro drift
flutter build apk --debug
```

### API klíč k Mapy.com

Výchozí podklad je OpenStreetMap a funguje bez jakéhokoli klíče. Turistická
a letecká mapa Mapy.com vyžadují bezplatný klíč z
[developer.mapy.com](https://developer.mapy.com/); zadává se **v aplikaci
v Nastavení** a zůstává jen v telefonu.

Klíč se do buildu vědomě nezapéká, a to ani ve vývojové verzi. Z rozdistribuovaného
balíčku by šel vytáhnout a čerpat cizí free tier — a mít na to zvláštní cestu
jen pro vývoj by znamenalo dvě verze chování, z nichž ta riskantní se dřív nebo
později dostane do vydání omylem.

## Data

Rozhledny se negenerují za běhu — jsou zabalené v `assets/data/rozhledny.json`,
takže aplikace funguje offline a nezávisí na dostupnosti cizích služeb.
Asset staví dva skripty, pouštějí se ručně:

```bash
dart tools/fetch_osm.dart    # rozhledny z Overpassu + kraje z QLeveru
dart tools/fetch_wiki.dart   # popisy z Wikipedie + fotky z Commons
```

Oba cachují odpovědi do `.cache/`, takže opakovaný běh nestahuje nic zbytečně.
`--fresh` cache obejde.

Proč dvě různá rozhraní: Overpass po několika dotazech odřízne IP na desítky
minut, takže přiřazení čtrnácti krajů přes něj nikdy nedoběhlo. QLever to
zvládne jedním SPARQL dotazem.

## Testy

```bash
flutter test
```

Testy míří hlavně na to, co se ručně ověřuje špatně: slučování při importu
(kolize, smazané záznamy, duplicitní návštěvy), migrace databáze proti
skutečně postavenému starému schématu, a kvalita vygenerovaného assetu —
včetně kontroly, že se nikdy nepublikuje fotka bez autora a licence.

## Licence a zdroje

Aplikace © 2026 Stanislav Kouba.

Data uvnitř mají vlastní autory a licence:

- rozhledny © OpenStreetMap contributors, [ODbL](https://www.openstreetmap.org/copyright)
- popisy z Wikipedie, CC BY-SA
- fotky z Wikimedia Commons, licence a autor u každé zvlášť
- mapové podklady © Seznam.cz a.s. a další
