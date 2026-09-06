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

## 0.16.0

- **hledání rovnou nad mapou.** Dosud vedla cesta ke konkrétní rozhledně
  přes záložku Seznam a zpátky na mapu přes její detail — čtyři klepnutí za
  to, aby se člověk podíval, kde ta věž vlastně je. Pole je nahoře nad mapou,
  pod ním se ukážou nálezy a klepnutí na jeden z nich mapu přesune a značku
  označí. Text v poli zůstane, ať je vidět, co se hledalo
- **hledání si nevšímá diakritiky.** „klet“ najde Kleť, „nadeje“ Naději —
  psát na mobilní klávesnici háčky a čárky je zdržení, které při hledání
  nikdo nechce řešit. Platí to i pro hledání v seznamu, je to tentýž kód
- nálezy jsou seřazené podle toho, jak dobře sedí: napřed jména začínající
  hledaným textem, pak ta, kde jím začíná některé slovo, a nakonec shoda
  uvnitř. Kdo napíše „klet“, myslí Kleť, ne „Rozhlednu nad Kletí“ — a ta by
  podle abecedy vyšla dřív
- u nálezu je vidět kraj a vzdálenost, protože samotné jméno nestačí:
  rozhledna Chlum je v Česku několikrát
- počítadlo rozhleden v rohu mapy se přesunulo pod vyhledávací pole
- klávesnice se nad mapou vysouvá přes ni, ne že by mapu zmenšila. Scaffold
  by ji jinak vykreslil jen nad klávesnicí, flutter_map by si podržel střed
  toho menšího výřezu a celá mapa by při psaní poskočila
- klepnutí do mapy zavírá klávesnici i seznam nálezů; hledaný text v poli
  zůstává, smaže ho křížek. Zavírá se přitom zaměření samotného pole, ne
  scope — ten si totiž pole pamatuje jako svoje poslední a po zavření detailu
  rozhledny mu zaměření vracel, takže klávesnice i nálezy naskočily znovu

## 0.15.0

- na přiblížené mapě (zoom 13 a víc) se pod značkou vypisuje jméno rozhledny.
  Není tak potřeba otevírat detail, jen aby člověk zjistil, na co se dívá.
  Text sedí na světlé plošce se zaoblenými rohy — první pokus s bílým obrysem
  písmen se nad turistickou mapou v terénu nedal přečíst
- nenavštívené rozhledny mají místo oka **siluetu rozhledny z ikony
  aplikace**. Kreslí se kódem podle stejných proporcí jako ikona
  (`tools/make_icon.dart`), jen zesílených — ve 14 px se původní tvar slil
  do zvonu. Navštívené mají fajfku dál
- jmenovka, která by překryla sousední, se vynechá — z blízké dvojice ji
  dostane jen jedna, aby z textů nebyla kaše. Která, se řídí `uuid`, takže
  se jmenovky nepřehazují při posunu mapy
- rozhledny bez názvu v datech zůstávají jen jako puntík, ubylo jich ale:
  kde jméno chybí v OSM a víme ho z Wikipedie, doplní ho
  do dat generátor (`nameFromWikipedia`), takže s ním umí pracovat jmenovka
  na mapě, hledání i řazení. Odsud má jméno třeba Praděd, Val nebo Řežabinec
- **rozhledny bez názvu jdou v Nastavení skrýt.** Výchozí stav je ukazovat
  je; po vypnutí zůstanou na mapě i ve statistikách jen pojmenované — a k tomu
  ty bezejmenné, které už máte navštívené. Vlastní záznam kvůli nastavení
  zobrazení zmizet nesmí
- statistiky i seznam se řídí týmž nastavením, takže ukazatel pokroku počítá
  jen s body, které jsou vidět i na mapě. Stejně tak počítadlo v rohu mapy
  a počet nad seznamem. Skrývání se netýká vlastních rozhleden — ty nemusí
  mít jméno hned, špendlíkem se zapíchnou cestou a pojmenují doma
- **v datech přibylo pět rozhleden, které tam patřily celou dobu.** Dotaz do
  OSM porovnával `tower:type` na přesnou shodu, jenže věž bývá zároveň
  vysílač a tag pak nese víc hodnot — `communication;observation` i
  `bell_tower, observation`. Takové věže filtr míjel. Přibyly Drahoušek,
  Hořický chlum, Ládví, Čestice u Volyně a vyhlídková věž na Vysočině.
  Stejná chyba byla i v dotazu na kraje, takže by nové body zůstaly bez
  kraje
- **a dalších patnáct, které mapeři zapsali jen jako vyhlídku, ale
  pojmenovali „rozhledna“.** Tak je v OSM veden Hněvín, Hard u Sokolova,
  liberecké Lidové sady nebo Doubravka — bez `man_made=tower`, zato
  s jménem, které nenechává nikoho na pochybách. Brát všechny vyhlídky
  nejde, těch jsou tisíce a většina je skála nebo lavička
- **a sedm staveb, které se do žádného filtru nevejdou** — Ještěd, Hasištejn,
  Starý Herštejn, Vítkův Hrádek, templ v Krásném Dvoře, Zámeček u Chebu
  a vyhlídka Karla IV. Jsou to hrady, vysílač a zámecká drobnost, u nichž
  je výhled až druhá funkce; filtr by kvůli nim musel pustit dovnitř všechny
  hrady v zemi, takže se v generátoru jmenují jednotlivě
- **a nakonec tři, které na papírové mapě byly a v datech se nedaly najít.**
  Vyhlídka Puclice (na návrší Křižatka) a Vachatova rozhledna (nad Novou Vsí
  u Kdyně) v datech celou dobu byly, jen jako bezejmenný puntík — v OSM
  jméno nemají, takže je nešlo najít ani hledáním. Rozhledna Na horách
  u Rohatců chyběla docela: v OSM je jen vyhlídka a v názvu nemá slovo
  „rozhledna“, takže ji minuly všechny tři řádky filtru
- **Třasák v Útvině v OSM nebyl vůbec**, tak jsme ho tam zanesli — tagy sedí
  na budovu z RUIANu, která je ta věž. Generátor si ho vzal sám, jen kraj
  musel dostat ručně: ten se přiřazuje dotazem do QLeveru a jeho snímek OSM
  je starý týdny, takže dnešní zápis v něm ještě není. Až se snímek posune,
  hodnota se přestane používat sama. Rozhleden je teď 701
- popisy a fotky dostaly i věže, které Wikidata neřadí pod rozhlednu.
  Generátor si položku dohledával podle třídy a vzdálenosti a přehlížel
  přitom `wikidata` tag, který u bodu rovnou stojí v OSM — teď ho bere jako
  primární klíč. Přibylo 18 věží (Bílá věž v Českých Budějovicích,
  Bismarckova rozhledna, Jeřabina, Tanečnice, Prašná brána a další).
  Popis má nakonec 280 rozhleden a fotku 347
- nad pootočenou mapou zůstávají značky i s texty vodorovné
- **nová rozhledna se přidává špendlíkem, ne tlačítkem.** Dlouhé podržení
  zapíchne do mapy šedý špendlík se zeleným plusem a formulář se otevře až
  klepnutím na něj — je tak vidět, kam prst doopravdy mířil, a dá se to
  opravit dalším podržením. Tlačítko „přidat rozhlednu“ zmizelo; souřadnice
  nikdo přepisovat nebude
- tlačítko „moje poloha“ vypadá stejně jako kompas: bílé kolečko místo
  barevného FABu. Vzhled je nově v `MapRoundButton`, aby se prvky nad mapou
  nemohly rozejít
- **třináct jmen putovalo zpátky do OpenStreetMap.** Tři byly v OSM
  přepsané — Hoslovice jako „Hostovice“, Alainova věž jako „Allainova“
  a Boiika jako „Boika“ (jméno je od keltských Bójů, Boii); rozhodčím byl
  článek na Wikipedii, na který ukazuje `wikidataId` téhož bodu. Deset
  dalších věží `name` nemělo vůbec a jméno jsme jim odvozovali z okolí:
  Vrškamýk, Šibeník, Čermná, Rudíkov, Helfenburk u Bavorova, Vachatova
  rozhledna, Vyhlídka Puclice, Vyhlídka Radovič a Vávrova lávka. Tabulka
  ručních oprav v generátoru se tím smrskla na tři řádky — jméno teď drží
  mapa sama a pozdější upřesnění se k nám dostane bez zásahu do kódu
- **základní data rozhleden se aktualizují i v telefonu, kde aplikace už
  běží.** Dosud se asset naléval jen do prázdné databáze, takže oprava názvu
  nebo nově přibylá rozhledna se k nikomu nedostaly. Nově se po každé změně
  assetu data srovnají — pozná se to podle otisku souboru, ne podle verze
  aplikace, aby to fungovalo i při ruční opravě dat a při vývoji
- aktualizace **nesahá** na vlastní rozhledny, na ručně upravené body z OSM
  ani na smazané. Poznámka u rozhledny je uživatelova a přepis ji nechává být
- **bod, který z dat vypadl a nikdo si ho nepřivlastnil, se smaže.** Vzniká
  to při přegenerování: slučování duplicit dá přednost jinému ze dvou zápisů
  téhož místa a po tom předchozím zbyde v telefonu mrtvý puntík pár metrů
  vedle. Smí zmizet jen bod z OSM, který nikdo neupravil, nesmazal a nemá
  na sobě návštěvu — a to ani smazanou, protože na druhém telefonu může být
  pořád živá a po importu by neměla na co navázat. Cokoli z toho ho drží
  naživu a dostane jen příznak `osmMissing`
- **mapa po startu zůstávala rozmazaná, dokud s ní člověk nepohnul.**
  Podklad se skládá z dlaždic a ta, která se nestáhne, zůstane ve
  flutter_map nepovedená napořád — na jejím místě se roztáhne dlaždice
  z nižšího zoomu a nikdo ji sám nezkusí znovu. Aplikace přitom stihla první
  dávku vyžádat dřív, než telefon po startu zvedl síť. Nově se podklad kreslí,
  teprve až je připravená cache dlaždic (do té doby šly požadavky mimo ni
  rovnou na síť, takže je bez signálu nemělo co obsloužit), a nepovedená
  dávka se do tří pokusů zopakuje sama. Posun mapy pokusy vrací zpátky,
  bez signálu se ale nezkouší donekonečna
- poskytovatel dlaždic se vyrábí jednou, ne při každém překreslení mapy.
  `CachedTileProvider` si v konstruktoru zakládá vlastního HTTP klienta —
  dosud tak vznikal nový, s prázdným poolem spojení, na každý snímek posunu
- po aktualizaci základních dat se ukáže, co se změnilo: „Aktualizace dat:
  přibylo 5 rozhleden, zmizely 3 rozhledny.“ Dosud se počet rozhleden změnil
  sám od sebe a nedalo se poznat proč
- srovnání se spouští i po **změně pravidel**, nejen po změně dat. Otisk
  assetu sám nestačí — telefon má data srovnaná z minula, takže by nové
  pravidlo (třeba to mazání výš) čekalo na nejbližší opravu dat a do té doby
  se tvářilo, že nefunguje. Vedle otisku se proto pamatuje i verze pravidel

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
