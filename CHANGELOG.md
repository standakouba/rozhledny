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

## 0.14.0

- vlastní fotky u návštěv zrušeny. Nešly zvětšit, takže se z nich stejně
  nedalo nic poznat; přidat je už nejde a stávající se při aktualizaci
  smažou i se soubory v telefonu
- sdílení a záloha jsou zase jedna položka. Rozdělení mělo smysl jen kvůli
  fotkám — bez nich má soubor desítky kilobajtů a projde messengerem vždycky
- fotka rozhledny z Wikimedia Commons v detailu zůstává beze změny
- záloha z verze 0.13.0 se načte dál, fotky se z ní jen přeskočí

## 0.13.0

- sdílení návštěv rozděleno od úplné zálohy. Sdílení posílá jen data
  (desítky kB), takže projde messengerem po každém výletu; úplná záloha
  včetně fotek zůstává na přechod na nový telefon
- aplikace přijímá zálohu poslanou přes systémové sdílení. Druhý telefon
  na soubor jen klepne a data se sloučí — místo ukládání souboru a hledání
  v Nastavení. Nabízí se u všech ZIP souborů; zúžit filtr na jméno souboru
  nejde, protože `pathPattern` vyžaduje shodu `host`, kterou content URI
  od messengerů nesplňují. Cizí archiv aplikace odmítne s vysvětlením.

## 0.12.3

- navštívené rozhledny mají na mapě fajfku místo oka, nenavštívené oko dál.
  Liší se tak tvarem, ne jen barvou — čitelné na slunci i pro toho, kdo
  zelenou od šedé rozliší hůř
- jasnější zeleň: tmavý odstín se na turistickém podkladu ztrácel v lese
- na odzoomované mapě jsou navštívené tečky větší, protože ikona se tam
  nevykreslí čitelně

## 0.12.2

- „volně přístupná“ přejmenováno na „přístupná veřejnosti“. OSM tag access
  říká, kdo smí dovnitř, ne jestli se platí — u placených rozhleden si dva
  sousední řádky protiřečily

## 0.12.1

- opraveno skloňování ve statistikách („Na 3 výletů“ -> „Na 3 výlety“)
- název balíčku sjednocen na cz.standakouba.rozhledny před vydáním do Play

## 0.12.0

- API klíč k Mapy.com se do aplikace už nezapéká, ani ve vývojovém buildu.
  Z rozdistribuovaného balíčku by šel vytáhnout a čerpat cizí free tier.
- výchozí podklad je OpenStreetMap; na Mapy.com jde přepnout, teprve když si
  uživatel v Nastavení zadá vlastní klíč

## 0.11.0

- návštěvu jde zapsat bez data. U rozhleden nasbíraných před aplikací si
  po letech nikdo nevzpomene, kdy tam byl, a vynucené datum by vedlo
  k vymýšlení. Nedatovaná návštěva se počítá do pokořených rozhleden
  i do celkového počtu, jen nejde do rozpadu po letech — ten ji vykáže
  zvlášť, aby se součet nerozešel.
- formát zálohy zvýšen na 2: starší verze aplikace by na návštěvě bez data
  spadla, takže ji teď odmítne srozumitelnou hláškou

## 0.10.0

- mapa se po startu vycentruje na aktuální polohu místo pohledu na celou ČR;
  jen jednou a jen dokud uživatel sám nepohne mapou, aby opožděný GPS fix
  netrhal rozkoukaným výřezem

## 0.9.2

- vlastní ikona aplikace: silueta rozhledny místo výchozí flutterovské
  (kreslí ji tools/make_icon.dart, adaptivní i klasická varianta)

## 0.9.1

- spodní část detailu rozhledny se schovávala pod systémovou lištu telefonu;
  modální panely bezpečnou zónu samy neřeší a odsazení ji nepočítalo

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
