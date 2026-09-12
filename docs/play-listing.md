# Podklady pro Google Play

Texty ke zkopírování do Play Console. Uložené v repozitáři, aby se daly
upravovat a bylo v historii vidět, co se kdy v obchodě změnilo.

---

## Název aplikace

*(max 30 znaků)*

```
Rozhledny
```

## Krátký popis

*(max 80 znaků — zobrazuje se pod názvem ve výsledcích hledání)*

```
Mapa 701 rozhleden a evidence navštívených. Bez účtu, data zůstávají u vás.
```

## Úplný popis

*(max 4000 znaků)*

```
Chodíte po rozhlednách a navštívené si odškrtáváte do papírové mapy?
Rozhledny dělají totéž, jen v telefonu — a přidají popisy, fotky a přehled,
kam jste se vlastně dostali.

CO APLIKACE UMÍ

• 701 rozhleden z OpenStreetMap na mapě celé republiky
• Turistický podklad se značenými trasami, nebo OpenStreetMap
• Hledání rovnou nad mapou: napíšete jméno a mapa skočí k rozhledně,
  diakritiku psát nemusíte
• Na přiblížené mapě je u značky jméno rozhledny, nemusíte otevírat detail
• Návštěvu zapíšete tlačítkem „Byl jsem tu“, datum je předvyplněné
• Opakované návštěvy — na některé rozhledny se jezdí pravidelně a každý
  výlet má vlastní záznam s datem, hodnocením a poznámkou
• Datum je nepovinné. Rozhledny nasbírané před aplikací se dají zapsat
  zpětně i bez něj — vymýšlet si datum nemá smysl
• Popisy z české Wikipedie a fotografie z Wikimedia Commons
• Vlastní rozhledna: co na mapě chybí, přidáte dlouhým stiskem
• Rozhledny, které ani v mapách nemají jméno, jdou v nastavení skrýt
• Hledání a filtry v seznamu — co mi ještě chybí, co je nejblíž, kam jsem
  se vracel
• Statistiky: pokrok, rozpad po krajích a letech, nejnavštěvovanější
• Navigace do vaší oblíbené mapové aplikace

BEZ ÚČTU A BEZ SERVERU

Aplikace nemá přihlašování ani cloud. Všechno zůstává ve vašem telefonu.

Jezdíte ve dvou? Po výletu pošlete návštěvy druhému telefonu jako soubor —
mailem, messengerem, jak chcete. Má jen desítky kilobajtů. Příjemce na něj
klepne a záznamy se sloučí s jeho: nic se nepřepíše a co má navíc, o to
nepřijde.

FUNGUJE I BEZ SIGNÁLU

Rozhledny, popisy i vaše návštěvy jsou uložené v telefonu, takže se v lese
bez signálu nic neztratí. Prohlédnuté mapové dlaždice se ukládají do mezipaměti
a fotky si můžete stáhnout dopředu.

TURISTICKÁ MAPA

Výchozí podklad je OpenStreetMap a funguje hned. Turistická mapa Mapy.com
vyžaduje bezplatný klíč, který si zdarma vytvoříte na developer.mapy.com
a zadáte v nastavení. V aplikaci žádný klíč není, aby se nedal zneužít.

ŽÁDNÁ REKLAMA, ŽÁDNÉ SLEDOVÁNÍ

Aplikace neobsahuje reklamu ani analytické nástroje a nesdílí data
s třetími stranami.

ZDROJE DAT

Rozhledny © přispěvatelé OpenStreetMap (ODbL). Popisy z Wikipedie (CC BY-SA),
fotografie z Wikimedia Commons — u každé je uveden autor a licence.
Mapové podklady © Seznam.cz a.s. a další.
```

## Poznámky k verzi

*(max 500 znaků na jazyk, pole „What's new" u každého vydání)*

### 0.16.0 — hledání nad mapou a víc rozhleden

```
Hledání rovnou nad mapou — napíšete jméno a mapa skočí k rozhledně.
Diakritiku psát nemusíte, „jested“ najde Ještěd.

Na přiblížené mapě je u značek vidět jméno rozhledny.

Rozhleden je 701, o 29 víc: přibyly věže, které dotaz do dat míjel,
a třináct jmen jsme opravili přímo v OpenStreetMap. Data se nově
aktualizují i v aplikaci, která už běží; dřív je dostaly jen nové
instalace.

Novou rozhlednu přidáte dlouhým podržením mapy.
```

### 0.14.0 — konec fotek u návštěv

```
Vlastní fotky u návštěv končí.

Nešly zvětšit, takže z náhledu stejně nebylo nic poznat. Přidat je už nejde
a ty stávající se při aktualizaci smažou. Fotky rozhleden z Wikimedia Commons
v detailu zůstávají.

Sdílení a záloha jsou zase jedna položka — bez fotek má soubor desítky
kilobajtů a projde messengerem vždycky.

Soubor poslaný ze starší verze se načte dál.
```

### 0.13.0 — sdílení návštěv

```
Sdílení návštěv s druhým telefonem.

Nově jde poslat jen návštěvy bez fotek. Soubor má desítky kilobajtů, takže
projde messengerem po každém výletu — druhý telefon na něj klepne a data se
sloučí. Nic se nepřepíše.

Úplná záloha včetně fotek zůstává na přechod na nový telefon.

Navštívené rozhledny mají na mapě fajfku a výraznější zelenou.

Návštěvu jde zapsat i bez data, když si po letech nevzpomenete.
```

### 0.12.2 — první testovací verze

```
První testovací verze.

Mapa 672 rozhleden z OpenStreetMap, evidence navštívených včetně opakovaných
návštěv s datem, hodnocením, poznámkou a fotkami. Popisy z Wikipedie a fotky
z Wikimedia Commons. Funguje i bez signálu.

Data zůstávají ve vašem telefonu — bez účtu a bez serveru. Na druhý telefon
se přenášejí exportem do souboru.
```

---

## Ostatní pole v konzoli

| Pole | Hodnota |
|---|---|
| Kategorie | Cestování a místní informace |
| Kontaktní e-mail | rozhledny.app@gmail.com |
| Zásady ochrany údajů | https://standakouba.github.io/rozhledny/privacy.html |
| Obsahuje reklamu | ne |
| Nákupy v aplikaci | ne |

## Formulář Data safety

Vyplňuje se pravdivě — Play deklarace namátkově ověřuje.

| Otázka | Odpověď |
|---|---|
| Shromažďuje aplikace data? | **Ne** |
| Sdílí data s třetími stranami? | **Ne** |
| Poloha | Zpracovává se pouze v zařízení, neodesílá se a neukládá do historie |
| Fotografie | Aplikace k fotkám v telefonu nepřistupuje |
| Šifrování při přenosu | Netýká se — žádná uživatelská data se nepřenášejí |
| Mohou uživatelé požádat o smazání dat? | Data jsou jen v zařízení, smaže je odinstalace nebo vymazání dat aplikace |

**Pozor na obvyklý omyl:** stahování mapových dlaždic a fotek *není* sběr dat
uživatele. Poskytovatel obsahu ovšem uvidí IP adresu — to je popsané
v zásadách ochrany údajů.

**Návrh do dat** je jediné místo, kde z aplikace odchází něco, co uživatel
vytvořil. Aplikace ho neodesílá: připraví e-mail a předá ho poštovnímu
programu, odesílá ho uživatel sám a předem vidí jeho přesné znění. Play tenhle
případ řadí k „přenosu, který spustil uživatel“, a jako sběr dat se
nedeklaruje — proto zůstává **Ne**. Kdyby se odesílání někdy dělo samo nebo
na pozadí, odpověď se musí změnit a doplnit se typ „Ostatní údaje vytvořené
uživatelem“. Popsané je to v zásadách ochrany údajů.

## Grafika

| Co | Soubor | Rozměr |
|---|---|---|
| Ikona | `assets/play/icon-512.png` | 512×512 |
| Titulní grafika | `assets/play/feature-1024x500.png` | 1024×500 |
| Snímky obrazovky | `docs/screenshots/` | min. 2, telefon |
