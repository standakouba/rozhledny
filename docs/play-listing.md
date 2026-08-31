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
Mapa 672 rozhleden a evidence navštívených. Bez účtu, data zůstávají u vás.
```

## Úplný popis

*(max 4000 znaků)*

```
Chodíte po rozhlednách a navštívené si odškrtáváte do papírové mapy?
Rozhledny dělají totéž, jen v telefonu — a přidají popisy, fotky a přehled,
kam jste se vlastně dostali.

CO APLIKACE UMÍ

• 672 rozhleden z OpenStreetMap na mapě celé republiky
• Turistický podklad se značenými trasami, nebo OpenStreetMap
• Označení navštívené rozhledny jedním klepnutím
• Opakované návštěvy — na některé rozhledny se jezdí pravidelně a každý
  výlet má vlastní záznam s datem, hodnocením, poznámkou a fotkami
• Datum je nepovinné. Rozhledny nasbírané před aplikací se dají zapsat
  zpětně i bez něj — vymýšlet si datum nemá smysl
• Popisy z české Wikipedie a fotografie z Wikimedia Commons
• Vlastní rozhledna: co na mapě chybí, přidáte dlouhým stiskem
• Hledání a filtry — co mi ještě chybí, co je nejblíž, kam jsem se vracel
• Statistiky: pokrok, rozpad po krajích a letech, nejnavštěvovanější
• Navigace do vaší oblíbené mapové aplikace

BEZ ÚČTU A BEZ SERVERU

Aplikace nemá přihlašování ani cloud. Všechno zůstává ve vašem telefonu.
Když chcete data sdílet s druhým telefonem, vyexportujete je do souboru
a na druhé straně naimportujete — záznamy se sloučí, nic se nepřepíše.

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
| Kontaktní e-mail | standa.kouba@gmail.com |
| Zásady ochrany údajů | *(URL na docs/privacy.html po zapnutí GitHub Pages)* |
| Obsahuje reklamu | ne |
| Nákupy v aplikaci | ne |

## Formulář Data safety

Vyplňuje se pravdivě — Play deklarace namátkově ověřuje.

| Otázka | Odpověď |
|---|---|
| Shromažďuje aplikace data? | **Ne** |
| Sdílí data s třetími stranami? | **Ne** |
| Poloha | Zpracovává se pouze v zařízení, neodesílá se a neukládá do historie |
| Fotografie | Zůstávají v zařízení |
| Šifrování při přenosu | Netýká se — žádná uživatelská data se nepřenášejí |
| Mohou uživatelé požádat o smazání dat? | Data jsou jen v zařízení, smaže je odinstalace nebo vymazání dat aplikace |

**Pozor na obvyklý omyl:** stahování mapových dlaždic a fotek *není* sběr dat
uživatele. Poskytovatel obsahu ovšem uvidí IP adresu — to je popsané
v zásadách ochrany údajů.

## Grafika

| Co | Soubor | Rozměr |
|---|---|---|
| Ikona | `assets/play/icon-512.png` | 512×512 |
| Titulní grafika | `assets/play/feature-1024x500.png` | 1024×500 |
| Snímky obrazovky | `docs/screenshots/` | min. 2, telefon |
