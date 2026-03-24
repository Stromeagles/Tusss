#!/usr/bin/env python3
"""
Add story_hint fields to the two remaining large JSON files.
Only adds story_hint where it doesn't already exist.
Does NOT modify any existing data.

Usage: python add_story_hints_remaining.py
"""

import json
import os

BASE = r"C:\Users\ceyla\Desktop\tus\tus_app_project\tus_asistani\assets\data"

# ============================================================
# STORY HINTS
# ============================================================

pathology_vaka_100_hints = {
    "path_vaka_1": "💡 HİKAYE: Sarhoş bir aşçı (alkolik pankreatit) mutfakta yağları eritirken kazanın içine kireç (kalsiyum) düşürdü — her yer tebeşir beyazı oldu! Lipaz yağı parçalar, kalsiyum sabunlaşır → saponifikasyon = yağ nekrozu.",
    "path_vaka_2": "💡 HİKAYE: HIV virüsü hücrenin enerji santralini (mitokondri) ele geçirip kapılarını açtı — sitokrom-c dışarı kaçtı ve kaspaz ordusu harekete geçti. Hücre sessizce büzüşerek öldü, kimse fark etmedi (inflamasyon yok = apoptoz).",
    "path_vaka_3": "💡 HİKAYE: Fabrikada elektrik kesildi (ATP↓), su pompaları durdu (Na/K ATPaz), bina su bastı (hücre şişmesi). Ama duvarlar hâlâ sağlam (membran bütün) — elektrik gelirse her şey düzelir! Reversibl hasar budur.",
    "path_vaka_4": "💡 HİKAYE: Mitokondri bir kale gibidir. Kalsiyum askerleri kaleye girip bomba (amorf cisimcikler) bıraktığında, surlar (membran) yıkılır — artık geri dönüş yok! İrreversibl hasarın en erken ultrayapısal kanıtı budur.",
    "path_vaka_5": "💡 HİKAYE: Prematüre bebek, oksijen odasında güneşlenirken (hiperoksi) serbest radikaller UV ışını gibi retinayı yakıyor. Bebeğin kalkanı (antioksidanlar: SOD, katalaz) henüz zayıf — ROS lipid peroksidasyonu ile hasarı başlatır.",
    "path_vaka_6": "💡 HİKAYE: Arı soktu, mast hücreleri panik düğmesine bastı — histamin bombası patladı! Venüllerdeki endotel hücreleri birbirinden ayrıldı (kontraksiyon), su dışarı aktı → dudaklar balon gibi şişti. İlk 30 dakikanın kahramanı histamindir.",
    "path_vaka_7": "💡 HİKAYE: Nötrofiller askerdir ama CD18 yapıştırıcıları bozuk — otobüse (endotel) yapışamıyorlar, savaş alanına gidemiyorlar! Göbek kordonu bile düşmüyor çünkü nötrofiller orada da işe yaramıyor. LAD-1'in hikayesi budur.",
    "path_vaka_8": "💡 HİKAYE: NADPH oksidaz bir silah fabrikasıdır — süperoksid mermileri üretir. KGH'da fabrika bozuk, nötrofiller silahsız kalır. Katalaz-pozitif bakteriler (Staph, Aspergillus) kendi H₂O₂'lerini yok ettikleri için savunmasız kalınır. NBT testi maviye dönmez = silah çalışmıyor.",
    "path_vaka_9": "💡 HİKAYE: Genç Afrikalı-Amerikalı kadının göğsünde iki hilal (bilateral hiler LAP) parlıyor, bacağında kırmızı düğmeler (eritema nodosum) çıkmış. Biyopside peynir yok (non-kazeifiye) ama yıldızlar (asteroid cisimcikler) var — Sarkoidoz galaksisi!",
    "path_vaka_10": "💡 HİKAYE: Diyabetik hastanın ayağındaki yara, şekerin boğduğu küçük damarlar (mikroanjiyopati) yüzünden kanlanamıyor. Lökositler de şekerli ortamda uyuşuk — ne düşman tanıyor ne yara kapanıyor. Küçük damar hastalığı + bozuk lökosit = geciken iyileşme.",
    "path_vaka_11": "💡 HİKAYE: Uzun uçak yolculuğunda bacaklar hareketsiz kaldı (staz), doğum kontrol hapı kanı koyu çorbaya çevirdi (hiperkoagülabilite). Virchow'un iki ayağı aktif — üçüncüsü (endotel hasarı) bu sefer katılmadı. DVT doğdu!",
    "path_vaka_12": "💡 HİKAYE: Bacaktaki pıhtı kopup venöz otobana çıktı, sağ kalbe uğradı ve pulmoner artere 'eyer gibi' oturdu (saddle embolus). Sağ ventrikül boğuldu, kan akamadı — ani ölüm! DVT'nin en korkunç yolculuğu budur.",
    "path_vaka_13": "💡 HİKAYE: İnce barsak gevşek bir sünger gibidir — tıkansa bile komşu damarlardan kan sızar. Ama bu kan nekrotik dokuyu kırmızıya boyar (hemorajik enfarktüs). Katı organlar (böbrek, dalak) ise sıkı oldukları için beyaz kalır.",
    "path_vaka_14": "💡 HİKAYE: Kaza sonrası 1.5 litre kan döküldü — vücudun su deposu boşaldı (hipovolemik). Kalp hızla pompaladı (taşikardi), damarlar büzüştü (soğuk cilt) ama yetmedi. Pompa (kardiyojenik) değil, hacim sorunu var!",
    "path_vaka_15": "💡 HİKAYE: Plasenta ayrıldı, doku faktörü kan nehrine döküldü — her yerde minik pıhtılar (mikrotrombi) oluştu. Pıhtılaşma faktörleri ve trombositler hepsi harcandı, paradoks olarak hasta kanamaya başladı. DIC = tüketim koagülopatisi.",
    "path_vaka_16": "💡 HİKAYE: 4 yaşında çocuğun gözleri şişmiş, karnı davul gibi — protein idrarda kaçıyor (nefrotik). Işık mikroskobu 'hiçbir şey görmüyor' ama elektron mikroskobu podositlerin ayaklarının silindiğini yakalar. Minimal değişiklik = maksimum steroid yanıtı!",
    "path_vaka_17": "💡 HİKAYE: Yaşlı hastanın dili büyümüş (makroglossi) — ağzına sığmıyor! Congo kırmızısı ile boyayınca polarize ışıkta elma yeşili parladı: amiloid! Dil büyümesi AL amiloidozun neredeyse patognomonik işareti — plazma hücreleri hafif zincirleri yanlış katlamış.",
    "path_vaka_18": "💡 HİKAYE: İyi diferansiye tümör, orijinal dokuya benzeyen 'uslu' bir tümördür — yavaş büyür ama 'iyi huylu' demek değildir! Düşük grade = az mitoz, az atipi. Prognozda asıl belirleyici stage'dir (yayılım).",
    "path_vaka_19": "💡 HİKAYE: Bebek doğduğunda tüm hücrelerinde bir RB geni zaten bozuk (germline — birinci vuruş). Retina hücrelerinden birinde ikinci gen de bozulunca (somatik — ikinci vuruş) iki göz birden tümör geliştirir. Knudson'un iki vuruşu: bir kalıtsal, bir edinsel!",
    "path_vaka_20": "💡 HİKAYE: 9. ve 22. kromozomlar birbirine karıştı → BCR-ABL füzyonu doğdu — bu sürekli çalışan bir tirozin kinaz motoru! KML hücreleri durmadan bölünüyor. İmatinib bu motoru kapatır — hedefe yönelik tedavinin zaferi!",
    "path_vaka_21": "💡 HİKAYE: Over seröz tümörü CA-125 bayrağını dalgalandırıyor — 'beni bulun!' diyor. Ama dikkat: endometriozis ve gebelik de bu bayrağı kaldırabilir. Takipte güvenilir, taramada tek başına yetmez!",
    "path_vaka_22": "💡 HİKAYE: Akciğer skuamöz karsinomu, PTHrP adlı sahte paratiroid hormonu salgılıyor — vücut 'kalsiyum lazım' sanıp kemiklerden kalsiyum çıkartıyor. Gerçek PTH ise 'ben yapmadım!' diye baskılanıyor. Humoral hiperkalsemi tuzağı!",
    "path_vaka_23": "💡 HİKAYE: 30 yıl boya fabrikasında çalışan adam, aromatik aminleri (beta-naftilamin) soluyarak mesane duvarına karsinojen biriktirdi. Karaciğer bunları aktive eder, idrarla atılırken mesane mukozasını boyar → ürotelyal karsinom!",
    "path_vaka_24": "💡 HİKAYE: HPV-16 iki suikastçı gönderdi: E6 p53'ü öldürdü (ubikuitin bıçağıyla), E7 Rb'yi etkisiz hale getirdi. Hem bekçi (p53) hem kapıcı (Rb) gitti — hücre kontrolsüz bölünmeye başladı! Servikal kanserin moleküler hikayesi.",
    "path_vaka_25": "💡 HİKAYE: Li-Fraumeni ailesi: TP53 geninde germline mutasyon taşıyorlar — 'genomun koruyucusu' doğuştan bozuk! Anne meme kanseri, baba osteosarkom, kardeş beyin tümörü. SBLA (Sarkom, Breast, Lösemi, Adrenal) ailenin kaderi.",
    "path_vaka_26": "💡 HİKAYE: Prostat kanseri kemiğe gidince inşaat başlatır (osteoblastik) — yeni kemik döker, ALP yükselir. Böbrek, akciğer ve tiroid kanserleri ise yıkım yapar (osteolitik). Meme mikst çalışır: hem yapar hem yıkar!",
    "path_vaka_27": "💡 HİKAYE: 3 yaşında çocuk soluyor, morluklar çıkmış. Blastlar TdT ile 'ben immatürüm!' diyor, CD10 (CALLA) ile 'ben common ALL'yim!' diyor, CD19/22 ile 'ben B hücresiyim!' diyor. Pre-B ALL = çocukluk çağının en sık lösemisi.",
    "path_vaka_28": "💡 HİKAYE: APC geni, Wnt yolağının freniydi — β-katenini yıkıma gönderirdi. Fren bozulunca (APC mutasyonu) β-katenin birikti, hücreler kontrolsüz çoğaldı → yüzlerce polip! FAP'ta kolektomi yapılmazsa 40 yaşına kadar kanser %100.",
    "path_vaka_29": "💡 HİKAYE: Kolon kanserinin merdiven hikayesi: APC kapıyı açtı (erken adenom), KRAS gaza bastı (intermediyer), SMAD4 freni kopardı (geç adenom), TP53 son duvarı yıktı → karsinom! Vogelstein'ın adenom-karsinom sekansı = A-K-S-T.",
    "path_vaka_30": "💡 HİKAYE: Lynch ailesinde DNA tamircileri (MMR genleri) bozuk — yazım hataları düzeltilemiyor, mikrosatellitler kaymaya başlıyor (MSI-H). Az polip ama yüksek kanser riski; kolon, endometrium ve over hedefte. Amsterdam kriterleriyle tanınır.",
    "path_vaka_31": "💡 HİKAYE: Sigara, HT ve DM endoteli yaraladı — LDL yaradan süzülüp oksitlendi. Makrofajlar 'temizleyelim' deyip LDL'yi yuttu ama şişip köpük hücresine dönüştü. Bu köpükler yığılınca fatty streak (yağlı çizgi) oluştu — aterosklerozun ilk adımı!",
    "path_vaka_32": "💡 HİKAYE: MI'ın saati: 24. saatte koagülatif nekroz tam oturmuş, nötrofiller savaş alanına akın etmiş. Daha erken saatlerde sadece dalgalı lifler görünür, daha geç saatlerde makrofajlar temizliğe başlar.",
    "path_vaka_33": "💡 HİKAYE: MI sonrası 4. günde nekrotik duvar en zayıf halinde — nötrofiller dokuyu sindirir ama granülasyon henüz oluşmamıştır. Duvar patlar, kan perikarda dolar, kalp sıkışır (tamponad). 3-7. gün = rüptür penceresi!",
    "path_vaka_34": "💡 HİKAYE: Streptokok boğaz ağrısı yaptı, 3 hafta sonra bağışıklık sistemi kalbi hedef aldı (moleküler taklit). Miyokardda Aschoff nodülleri oluştu — içlerinde tırtıl gibi kıvrılan Anitschkow hücreleri var. Romatizmal ateşin patognomonik imzası!",
    "path_vaka_35": "💡 HİKAYE: IV ilaç kullanıcısı iğneyle S. aureus'u damarına enjekte etti — bakteri venöz yoldan önce sağ kalbe ulaştı ve triküspid kapağa yerleşti. Tırnak altında splinter hemoraji = emboli parçacıkları. Sol kalp kapakları ise genellikle romatizmal hasarla ilişkili.",
    "path_vaka_36": "💡 HİKAYE: Ateroskleroz yıllarca sessizce aort duvarını kemirdi. İnfrarenal bölge en savunmasız (vasa vasorum en az burada). 5.5 cm'yi aşınca balon gibi patlar → retroperitoneal kanama → hemorajik şok. Batında pulsatil kitle = tik-tak bomba!",
    "path_vaka_37": "💡 HİKAYE: Genç Asyalı kadın kollarındaki nabzı hissetmiyor — 'nabızsız hastalık' (Takayasu arteriti). Arkus aorta ve dalları granülomatöz inflamasyonla tıkanmış. Dev hücreli arterit de benzer ama o 50 yaş üstü ve temporal arter sever.",
    "path_vaka_38": "💡 HİKAYE: Malign hipertansiyon böbrek arteriollerini soğan gibi dilimliyor (onion skinning) — her tabaka bir intimal hiperplazi katmanı. Fibrinoid nekroz eşlik ederse bu malign arterioloskleroz. Benign nefroskleroz ise sadece hyalen değişiklik gösterir.",
    "path_vaka_39": "💡 HİKAYE: Benign nefroskleroz = kronik HT'de arteriyollerde hyalen birikimi (pembe cam gibi). Malign nefroskleroz = acil HT'de soğan zarı intimal hiperplazi + fibrinoid nekroz. İki farklı basınç, iki farklı mikroskopi!",
    "path_vaka_40": "💡 HİKAYE: Rapidly progressive GN'de Bowman boşluğunda hilaller (crescents) oluşur — fibrin, makrofaj ve epitel hücreleri birikir. Goodpasture: anti-GBM (lineer IF), lupus nefrit: granüler IF, pauci-immün: ANCA pozitif ama IF negatif.",
    "path_vaka_41": "💡 HİKAYE: Berger (IgA nefropatisi) dünyada en sık glomerülonefrittir. Üst solunum yolu enfeksiyonu ile 'eş zamanlı' hematüri gelir — PSGN'deki 2-4 haftalık gecikme yok! Mezangiumda IgA birikimi IF'de parlak görünür.",
    "path_vaka_42": "💡 HİKAYE: Membranöz nefropati bazal membranı kalınlaştırır — 'spike and dome' (dikenli taç) görünümü subepitelyal IgG/C3 birikimidir. Erişkin nefrotik sendromun 2. en sık nedeni. Otoimmün veya HBV/malignite ilişkili olabilir.",
    "path_vaka_43": "💡 HİKAYE: PSGN'de streptokok 2-4 hafta önce boğazı yakıp gitti ama arkasında immün kompleksler bıraktı. Bu kompleksler glomerülde subepitelyal 'hörgüçler' (humps) oluşturur. C3↓, ASO↑. Çocuklarda genellikle kendiliğinden iyileşir.",
    "path_vaka_44": "💡 HİKAYE: Berrak hücreli RCC = böbreğin en sık karsinomu. VHL gen mutasyonu HIF-alfa'nın yıkılmasını engeller → VEGF artar → tümör damarlanması patlar. Sol renal vende tümör trombozu 'varikosel' ile kendini ele verir!",
    "path_vaka_45": "💡 HİKAYE: Wilms tümörü çocuğun böbreğinde 3 doku birden (blastem + stroma + epitel = trifazik) içerir. WAGR sendromunda aniridi (irissiz göz) eşlik eder. WT1 genindeki kayıp hem böbrek hem göz gelişimini bozar.",
    "path_vaka_46": "💡 HİKAYE: Amfizemde akciğer balonları patlamış — hava kesesicikleri genişlemiş ama elastikiyet kaybolmuş. Pink puffer (pembemsi, öne eğik, dudakları büzük nefes verir). Alfa-1 AT eksikliğinde genç yaşta, alt loblarda panasiner tip gelişir.",
    "path_vaka_47": "💡 HİKAYE: Astım = reversibl hava yolu obstrüksiyonu. Tip I hipersensitivite (IgE-mast hücresi) erken fazda, Tip IV (Th2-eozinofil) geç fazda aktif. Spirometride FEV1/FVC↓, bronkodilatöre yanıt verir. Eozinofilik inflamasyon = Charcot-Leyden kristalleri.",
    "path_vaka_48": "💡 HİKAYE: Akciğer adenokarsinomu periferde 'sessizce' büyür. EGFR mutasyonu varsa tirozin kinaz inhibitörleri ile hedefe atış yapılır. ALK translokasyonu başka bir hedef. Sigara içmeyenlerde bile en sık görülen akciğer kanseri budur.",
    "path_vaka_49": "💡 HİKAYE: Küçük hücreli karsinom nöroendokrin bir 'hormon fabrikası' — ACTH üretir (Cushing), ADH üretir (SIADH). Chromogranin ve sinaptofizin pozitif. Cerrahiye yanıtsız ama kemoterapi+radyoterapiye iyi yanıt verir.",
    "path_vaka_50": "💡 HİKAYE: Asbest lifler plevra mezotelini delip kanser başlatır. Ferruginous body (demir kaplı asbest lifi) = dambıl şekilli kahverengi yapılar. Kalretinin (+) = mezotelyom, CEA (+) = adenokarsinom ayrımı! Latent periyod 25-45 yıl.",
    "path_vaka_51": "💡 HİKAYE: Barrett'te mide asidi yıllar boyu özofagus squamöz epitelini yakar → hücreler goblet hücreli kolumnar epitele dönüşür (intestinal metaplazi). Bu metaplazi displaziye, displazi adenokarsinoma gider. PPI + endoskopik takip şart!",
    "path_vaka_52": "💡 HİKAYE: H. pylori midenin antrum duvarına üreaz kalkanıyla yerleşir — asidi nötralize edip ortamını kurar. CagA (+) suşlar kanser riskini artırır. Tedavi: PPI + klaritromisin + amoksisilin (üçlü tedavi). MALT lenfoma bile eradikasyonla gerileyebilir!",
    "path_vaka_53": "💡 HİKAYE: Crohn ve ÜK kardeştir ama çok farklı! Crohn: 'atlayan' transmural lezyon, fistül, granülom. ÜK: rektumdan yukarı 'sürekli' mukozal tutulum, kript absesi. Toksik megakolon ÜK'nin acil komplikasyonudur.",
    "path_vaka_54": "💡 HİKAYE: Çölyak hastası buğday yiyince bağırsakları isyan eder — gluten (gliadin) immün saldırıyı tetikler. Villüsler düzleşir, kriptler derinleşir. Anti-tTG IgA en iyi tarama testi. Glütensiz diyet = tam iyileşme!",
    "path_vaka_55": "💡 HİKAYE: Alkolik karaciğerde üç aşama: sarı yağlı karaciğer (steatoz) → nötrofil dolu iltihaplı karaciğer (steatohepatit, Mallory cisimcikleri) → sert, nodüler, çekilmiş karaciğer (siroz). Her adım geri dönüşsüze yaklaşır!",
    "path_vaka_56": "💡 HİKAYE: HBV hepatositi 'buzlu cam'a çevirir (HBsAg birikimi) ve DNA'sını entegre edip HCC'ye zemin hazırlar. HCV ise yağlanma + lenfoid kümelenme yapar ve %80 kronikleşir. İkisi de siroz ve HCC'ye gider ama yolları farklı.",
    "path_vaka_57": "💡 HİKAYE: Siroz karaciğerin final sahnesinde: portal basınç yükselir, özofagus varisleri kanar, karın sıvı dolar (asit), dalak büyür (hipersplenizm). Kaput medusa göbek etrafında yıldız gibi parlar — porto-sistemik şantların işareti!",
    "path_vaka_58": "💡 HİKAYE: Wilson'da bakır vücudu istila eder: karaciğerde siroz, beyinde bazal ganglia hasarı (hareket bozuklukları), gözde Kayser-Fleischer halkası. Seruloplazmin düşük, serbest bakır yüksek. Penisilamin bakırı şelatlar.",
    "path_vaka_59": "💡 HİKAYE: Hemokromatozda demir her yere yerleşir — 'bronz diyabet' (deride melanin + pankreas hasarı). HFE C282Y mutasyonu en sık neden. Ferritin ve transferrin satürasyonu çok yüksek. Flebotomi ile düzenli kan aldırma tedavinin temelidir.",
    "path_vaka_60": "💡 HİKAYE: Pankreasta enzimler isyan etti — tripsin tripsinojeni aktive etti, pankreas kendini sindirmeye başladı! Lipaz yağı sabunlaştırdı (tebeşir beyazı), kanama nekroz alanlarına yayıldı. Grey-Turner (bel) ve Cullen (göbek) morlukları tehlike sinyali!",
    "path_vaka_61": "💡 HİKAYE: Pankreas başı kanseri sessiz büyür — sarılık (koledoğu tıkar), ağrısız palpabl safra kesesi (Courvoisier bulgusu) ve migratuar tromboflebit (Trousseau sendromu). CA 19-9 yükselir. Whipple ameliyatı tek küratif şans.",
    "path_vaka_62": "💡 HİKAYE: İnvaziv duktal karsinom memenin en sık malignitesidir — sert, yıldızsı (stellat) kitle. Sentinel lenf nodu aksiller evrelemenin anahtarı. ER/PR pozitifse hormonal tedavi, HER2 pozitifse trastuzumab, triple negatifse agresif kemoterapi!",
    "path_vaka_63": "💡 HİKAYE: Meme başında inatçı egzama benzeri lezyon = Paget hastalığı! Alttaki duktal karsinom meme başı epidermine kadar sızmış. Paget hücreleri büyük, soluk, PAS pozitif. Meme başı lezyonlarında her zaman biyopsi düşün!",
    "path_vaka_64": "💡 HİKAYE: HPV serviksı ele geçirdi — E6 suikastçısı p53'ü öldürdü, E7 Rb'yi etkisiz bıraktı. Koilositler (çekirdek etrafında boşluk) enfeksiyonun imzası. PAP smear ile erken tanı, HPV aşısı ile önleme mümkün!",
    "path_vaka_65": "💡 HİKAYE: Postmenopozal kanama = endometrium kanseri düşün! Tip I östrojen bağımlı (obezite, nulliparite risk), iyi prognoz. Tip II (seröz) östrojenden bağımsız, agresif. Endometrial biyopsi altın standart tanı yöntemidir.",
    "path_vaka_66": "💡 HİKAYE: Seröz kistadenokarsinom overin en sık malign tümörü — psammom cisimcikleri (kum taneleri gibi kalsifikasyon) içinde parlar. CA-125 ile takip edilir. Bilateral tutulum sık. Peritoneal yayılım tipiktir.",
    "path_vaka_67": "💡 HİKAYE: Dermoid kist (matür kistik teratom) bir sürpriz kutusu — saç, diş, kemik, deri her şey çıkabilir! Overin en sık germ hücreli tümörü. Genelde benign. İmmatür olursa AFP yükselir ve malign kabul edilir.",
    "path_vaka_68": "💡 HİKAYE: Komplet mol = 46,XX (hepsi babadan), fetus yok, üzüm salkımı görünümü. β-hCG çok yüksek, koryokarsinom riski! Parsiyel mol = 69,XXY (triploid), kısmi fetus mevcut. Tahliye sonrası β-hCG takibi zorunlu!",
    "path_vaka_69": "💡 HİKAYE: Seminom testisin en sık germ hücreli tümörü — radyoterapiye mükemmel yanıt verir! 'Kızarmış yumurta' hücreleri (büyük çekirdek, berrak sitoplazma) ve PLAP pozitifliği tanıda yol gösterir. İnmemiş testis (kriptorşidizm) en büyük risk!",
    "path_vaka_70": "💡 HİKAYE: Reed-Sternberg hücresi iki gözüyle baykuş gibi bakıyor — Hodgkin lenfomanın patognomonik imzası! CD15 ve CD30 pozitif. Genç hastada boyunda ağrısız LAP. Alkol ile ağrıyan lenf nodu Hodgkin'in tuhaf ama klasik özelliği.",
    "path_vaka_71": "💡 HİKAYE: Burkitt lenfoma t(8;14) ile c-MYC'i sonuna kadar açar — dünyada en hızlı büyüyen tümörlerden biri! Makroskopide 'yıldızlı gökyüzü': karanlık tümör hücreleri arasında parlak makrofajlar yıldız gibi. Endemik formda EBV çenede, sporadik form ileosekal bölgede.",
    "path_vaka_72": "💡 HİKAYE: Foliküler lenfomada t(14;18) bcl-2'yi aşırı eksprese eder — hücreler ölmeyi reddeder! Yavaş büyüyen, ağrısız LAP ile gelen yaşlı hasta. Difüz büyük B hücreli lenfomaya dönüşüm (Richter benzeri) en korkulan komplikasyon.",
    "path_vaka_73": "💡 HİKAYE: KML'nin Philadelphia kromozomu [t(9;22)] sürekli çalışan bir motor — BCR-ABL tirozin kinaz. Periferik yaymada her evreden hücre var (sola kayma). Bazofili ve LAP skoru düşüklüğü KML'yi lökemoid reaksiyondan ayırır. İmatinib motoru kapatır!",
    "path_vaka_74": "💡 HİKAYE: KLL yaşlıların 'uslu' lösemisidir — olgun ama işlevsiz B lenfositler birikir. Smudge cells yaymada 'ezilmiş hücre' olarak görülür. CD5+ B hücreleri karakteristik. Richter transformasyonu (DLBCL'ye dönüşüm) beklenen en kötü senaryo.",
    "path_vaka_75": "💡 HİKAYE: Multipl miyelom kemik iliğinde plazma hücre istilasıdır — CRAB ile hatırla: Calcium↑, Renal failure, Anemia, Bone lesions (zımba deliği). M-spike protein elektroforezde, Bence-Jones idrarda. Rouleaux = bozuk para dizili eritrositler.",
    "path_vaka_76": "💡 HİKAYE: Demir eksikliği = mikrositer hipokrom aneminin en sık nedeni. Ferritin düşer (depo boş), TIBC artar (transferrin aç). Koilonychia (kaşık tırnak) ve Plummer-Vinson (disfaji + glossit + demir eksikliği) sorularda klasik ipuçları.",
    "path_vaka_77": "💡 HİKAYE: B12 eksikliğinde DNA sentezi bozulur — hücreler büyür ama bölünemez (megaloblastik). Hipersegmente nötrofiller (>5 lob) kan yaymasının imzası. Arka kordon dejenerasyonu (vibrasyon/propriyosepsiyon kaybı) nörolojik tablo. Folat eksikliğinde nöroloji YOKTUR!",
    "path_vaka_78": "💡 HİKAYE: Orak hücre anemisinde tek amino asit değişimi (Glu→Val) kaderimizi belirler — HbS düşük O₂'de polimerize olur, eritrosit orak şeklini alır. Dalak tekrarlayan infarktlarla küçülür (otosplenektomi). Kapsüllü bakterilere savunmasız kalınır!",
    "path_vaka_79": "💡 HİKAYE: Beta talasemi majörde beta globin zinciri üretilmez — HbF kompansatuar artar. Eritropoez çılgınca artar → kemik iliği genişler → 'crew cut' kafatası ve 'hair on end' görünümü. Kronik transfüzyon → demir yüklenmesi → desferioksamin gerekir.",
    "path_vaka_80": "💡 HİKAYE: Herediter sferositozda eritrosit iskeleti (spektrin/ankirin) bozuk — hücre küre şeklini alır ve dalak labirentinde sıkışıp yıkılır. Ozmotik frajilite testi pozitif, MCHC artmış. Splenektomi yapılırsa hücreler sağ kalır!",
    "path_vaka_81": "💡 HİKAYE: G6PD eksik hastaya oksidatif stres (bakla, naftalin, sulfonamid) gelince eritrositler patlar — Heinz cisimcikleri (denatüre Hb) ve bite cells (dalak ısırığı) oluşur. X-linked resesif → erkeklerde sık. Akut hemoliz atağı sonrasında düzey normal çıkabilir (genç hücreler sağlam)!",
    "path_vaka_82": "💡 HİKAYE: Sıcak AIHA'da IgG antikorları eritrositleri 37°C'de yakalayıp dalağa gönderir — orada fagositoz ile yıkılırlar. Direct Coombs (+). SLE ve KLL sıcak AIHA'yı tetikleyebilir. Soğuk AIHA'da ise IgM + kompleman soğukta hemoliz yapar.",
    "path_vaka_83": "💡 HİKAYE: Çocuk kanlı ishale yakalandı (E. coli O157:H7) → Shiga toksin böbrek damarlarını yıktı → schistositler (parçalanmış eritrositler) + trombositopeni + akut böbrek yetmezliği = HUS üçlüsü! Destek tedavisi ile çoğu çocuk iyileşir.",
    "path_vaka_84": "💡 HİKAYE: TTP'de ADAMTS13 makası bozuk — ultra-büyük vWF multimerleri kesilemiyor, küçük damarlarda tıkaç oluşturuyor. Beyin ve böbrek en çok etkilenir. Pentad: anemi + trombositopeni + böbrek + nöroloji + ateş. Plazma değişimi ACIL!",
    "path_vaka_85": "💡 HİKAYE: ITP'de anti-platelet antikorlar trombositleri dalakta yiyor — trombositopeni ama PT/aPTT normal! Çocuklarda viral enfeksiyon sonrası akut ve self-limited, erişkinlerde kronik. İlikte megakaryositler artmış (kompansasyon). Peteşi + purpura ama eklem kanaması yok!",
    "path_vaka_86": "💡 HİKAYE: vWF hem trombositi kollajena yapıştıran tutkal hem FVIII'in koruyucu meleği. von Willebrand hastalığında bu tutkal eksik/bozuk → mukokutanöz kanama (epistaksis, menoraji). Ristosetin kofaktör testi bozuk, PT normal. En sık kalıtsal kanama bozukluğu!",
    "path_vaka_87": "💡 HİKAYE: Hemofili A'da FVIII eksik, B'de FIX eksik — ikisi de X-linked resesif. aPTT uzar ama PT normal (ekstrinsik yol sağlam). Hemartroz (eklem içi kanama) ve derin doku hematomları tipik. Karışım çalışmasında aPTT düzelirse faktör eksikliği, düzelmezse inhibitör!",
    "path_vaka_88": "💡 HİKAYE: Tiroid papiller karsinomu = en sık tiroid kanseri. Orphan Annie gözleri (buzlu cam çekirdek) + psammom cisimcikleri + nükleer oluklar = üçlü imza! Lenfatik yayılım yapar ama 10 yıllık sağkalım %95+. Radyasyona maruz kalma risk faktörü.",
    "path_vaka_89": "💡 HİKAYE: Hashimoto = en sık otoimmün tiroidit. Anti-TPO ve anti-Tg antikorları tiroid bezini yavaşça yıkar → hipotiroidiye gider. Hürthle hücreleri (onkositik, granüler sitoplazmalı) ve germinal merkezli lenfoid foliküller biyopside karakteristik. Tiroid MALT lenfoma riski!",
    "path_vaka_90": "💡 HİKAYE: Graves'te TSI (TSH reseptör stimülan antikor) tiroidin gazını açar — hipertiroidi! Difüz guatr (tüm bez büyür), ekzoftalmus (göz fırlaması — orbital fibrozis), pretibial miksödem (bacakta kalınlaşma). Tip II hipersensitivite ama stimülatör tip!",
    "path_vaka_91": "💡 HİKAYE: Feokromositoma adrenal medullanın katekolamin bombası — epizodik HT atakları, çarpıntı, terleme, baş ağrısı! '10 kuralı' ile hatırla. VMA ve metanefrinler idrarda yükselir. Ameliyat öncesi alfa blokaj (fenoksibenzamin) şart — yoksa hipertansif kriz!",
    "path_vaka_92": "💡 HİKAYE: Addison hastalığında adrenal korteks yıkılmıştır — kortizol↓, aldosteron↓, ACTH↑. ACTH artışı MSH benzeri etki ile hiperpigmentasyona yol açar (avuç içi kıvrımları, mukoza). Hipotansiyon + hiperkalemi + hiponatremi triadı. Akut kriz (Addisonian kriz) hayatı tehdit eder!",
    "path_vaka_93": "💡 HİKAYE: Cushing'te kortizol fazlası vücudu dönüştürür — yüz ay gibi yuvarlaklaşır (moon facies), sırta yağ birikir (buffalo hump), karında mor çatlaklar (striae). En sık neden ekzojen steroid! Endojen en sık = hipofiz adenomu (Cushing hastalığı).",
    "path_vaka_94": "💡 HİKAYE: MEN sendromları aile içi tümör paketleridir. MEN1: 3P (Paratiroid + Pituiter + Pankreas). MEN2A: Medüller tiroid + Feokromositoma + Paratiroid. MEN2B: Medüller tiroid + Feokromositoma + Mukozal nöromalar. RET mutasyonu MEN2'nin anahtarı!",
    "path_vaka_95": "💡 HİKAYE: Tip 1 DM'de T hücreleri beta adacıklarını yıkar — insülin sıfır! Anti-GAD antikorları tanıda yol gösterir. DKA (ketoasidoz) ile acile gelebilir. Tip 2'de ise insülin var ama etkisiz (direnç). Adacıklarda amiloid (amilin) birikimi Tip 2'nin patolojik imzası.",
    "path_vaka_96": "💡 HİKAYE: GBM beynin en agresif tümörü — kelebek gibi corpus callosum'dan karşıya yayılır! Nekroz çevresinde pseudopalisading dizilim ve mikrovasküler proliferasyon tanıda kilit. MGMT metilasyonu temozolomide yanıtı öngörür.",
    "path_vaka_97": "💡 HİKAYE: Meningiom meninkslerden doğar — MR'da dural tail (kuyruk) işareti ile tanınır. Psammom cisimcikleri histolojide parlar. Genellikle benign ama lokalizasyona göre semptom verir. Gebelikte büyüyebilir (östrojen reseptörü taşır)!",
    "path_vaka_98": "💡 HİKAYE: Schwannom sinir kılıfından doğar — Antoni A (düzenli, Verocay) ve Antoni B (gevşek) alanları var. S-100 pozitif! Akustik schwannom (vestibüler) tek taraflı işitme kaybı yapar. Bilateral ise NF2 (Merlin/schwannomin mutasyonu) düşün!",
    "path_vaka_99": "💡 HİKAYE: Osteosarkom gençlerin kemik kanseri — distal femurda en sık! Codman üçgeni (periost kabarması) ve sunburst paterni (güneş ışını) radyolojide alarm verir. Alkalin fosfataz yükselir. Neoadjuvan kemoterapi + cerrahi standart tedavi.",
    "path_vaka_100": "💡 HİKAYE: Ewing sarkomu çocuklarda diyafizi seven küçük yuvarlak mavi hücreli tümördür. t(11;22) translokasyonu = EWS-FLI1. Soğan zarı (onion peel) periost reaksiyonu ve CD99 (MIC2) pozitifliği tanıda kilit. Kemoterapi + radyoterapi iyi yanıt verir.",
}

anatomi_hints = {
    "ant-001": "💡 HİKAYE: Femur başının 'göbek bağı' olan lig. capitis femoris içinden küçük bir arter geçer — arteria capitis femoris. Çocuklarda bu arter femur başını besler, erişkinlerde ise a. circumflexa femoris medialis görevi devralır.",
    "ant-011": "💡 HİKAYE: Sfenoid kemiğin ortasında 'Türk eğeri' (Sella turcica) var — hipofiz bezi bu eğere oturmuş bir süvari gibi. Önünde optik kiazma bekliyor. Hipofiz tümörü büyürse bu çaprazı sıkıştırıp bitemporal hemianopsi yapar!",
    "ant-023": "💡 HİKAYE: Biseps kasını 'tornavida çeviren güçlü kol' olarak düşün — ön kolda fleksiyon + supinasyon yapar. En güçlü supinatör! N. musculocutaneus (C5-C6) tarafından inerve edilir.",
    "ant-051": "💡 HİKAYE: Trigeminus üç dallı yüz siniridir: V1 ve V2 saf duyusal, V3 ise hem duyu hem motor (mikst). V3 foramen ovale'den geçer ve çiğneme kaslarını yönetir. 'Mandibula' = çene = çiğneme = motor!",
    "ant-074": "💡 HİKAYE: Willis poligonu beynin 'güvenlik çemberi'dir — bir arter tıkansa bile diğerlerinden kan gelir. A. cerebri anterior halkaya doğrudan katılır. A. cerebri media ise halkada değildir ama felçlerde en sık etkilenen damardır!",
    "ant-105": "💡 HİKAYE: Foramen jugulare'den üç sinir geçer: 9 (glossofaringeal), 10 (vagus), 11 (aksesuar). CN IX dilin arka 1/3 tadını alır ve yutkunma refleksinde rol oynar. 'Glosso' = dil, 'pharyngeus' = yutak — adı işlevini söylüyor!",
    "ant-126": "💡 HİKAYE: Fovea centralis retinanın 'altın noktası'dır — sadece koni hücreleri bulunur, en keskin ve renkli görme burada yapılır. Karanlıkta çubuk hücreleri devreye girer.",
    "ant-145": "💡 HİKAYE: M. levator ani pelvisin 'hamağı'dır — mesane, rahim ve rektumu alttan destekler. Zor doğumda hasar görürse organ sarkmaları (sistosel, prolapsus) başlar.",
    "ant-151": "💡 HİKAYE: Ampulla tuba uterinanın 'buluşma noktası'dır — sperm ve yumurta burada karşılaşır (fertilizasyon). Aynı zamanda ektopik gebeliklerin de en sık yaşandığı yer.",
    "ant-180": "💡 HİKAYE: Pars spongiosa erkek üretrasının en uzun parçasıdır (~15 cm) — penis içinde corpus spongiosum'da seyreder. Pars membranacea en dar ve en kısa — sonda takılırken en çok burada sorun çıkar!",
    "ant-193": "💡 HİKAYE: Moderator band (trabecula septomarginalis) sağ ventriküle özgü bir 'hızlı iletim kablosu'dur — His huzmesinin sağ dalını septumdan ön papiller kasa taşır.",
    "ant-200": "💡 HİKAYE: CN XII (hipoglossus) dili hareket ettiren saf motor sinirdir — parasempatik bileşeni yok! '1973' mnemoniği: CN 1, 9, 7, 3 parasempatik taşır. XII motor ama otonom lif içermez.",
    "ant-201": "💡 HİKAYE: Humerus gövdesi kırılınca spiral oluktaki n. radialis ve a. profunda brachii hasar görür → 'düşük el' (drop hand)!",
    "ant-202": "💡 HİKAYE: Pterion kafatasının 'Aşil topuğu'dur — dört kemiğin buluştuğu en ince nokta. Altından a. meningea media geçer. Şakağa darbe → pterion kırığı → arter yırtılır → epidural hematom!",
    "ant-203": "💡 HİKAYE: Diyaframın delikleri 'I ate 12 eggs at 8' ile ezberlenir: T8=IVC (8 harf), T10=esophagus, T12=aorta. Foramen venae cavae en üstte (T8), sağ n. phrenicus de buradan geçer.",
    "ant-204": "💡 HİKAYE: Vater ampullası safra ve pankreas suyunun 'kavşak noktası'dır — koledok + Wirsung kanalı birleşip duodenuma dökülür. Sfinkter Oddi bu kavşağın trafik polisi.",
    "ant-205": "💡 HİKAYE: Vagus siniri GIS'te Cannon-Böhm noktasına (splenik fleksura civarı) kadar parasempatik inervasyon sağlar. Buradan sonra S2-S4 devralır.",
    "ant-206": "💡 HİKAYE: N. facialis foramen stylomastoideum'dan çıkar ve parotis bezinin içine dalarak 5 uç dala ayrılır. Bell paralizisinde yüzün tüm yarısı felç olur.",
    "ant-207": "💡 HİKAYE: Tiroidektomide iki sinir tehlikede: Alt kutupta n. laryngeus recurrens (ses kısıklığı), üst kutupta n. laryngeus superior'un eksternal dalı (tiz ses kaybı). Bilateral recurrens hasarı = trakeotomi!",
    "ant-208": "💡 HİKAYE: ACL (ön çapraz bağ) tibianın öne kaymasını engeller — kopunca 'ön çekmece testi' pozitifleşir. Futbolcuların kabusu: ani dönüş hareketi → ACL yırtığı!",
    "ant-209": "💡 HİKAYE: Medial menisküs 'C' şeklinde ve MCL'ye yapışık → hareketsiz, burkulmada kolay yırtılır. Unhappy triad: ACL + MCL + Medial Menisküs!",
    "ant-210": "💡 HİKAYE: Mitral kapak apekste (sol 5. IKA mid-klavikular hat) dinlenir. Aort: sağ 2. İKA, pulmoner: sol 2. İKA, triküspid: sol 5. İKA sternum kenarı.",
    "ant-211": "💡 HİKAYE: Sağ ana bronş daha kısa, geniş ve dik — tıpkı geniş bir kaydırak gibi! Yabancı cisimler yerçekimiyle bu kaydıraktan aşağı kayar ve sağ alt loba gider.",
    "ant-212": "💡 HİKAYE: Gerota fasyası böbreğin 'zırh'ıdır — böbrek ve adrenal bezi bir torba gibi sarar. İçinde perirenal yağ tampon görevi yapar.",
    "ant-213": "💡 HİKAYE: Zor doğumda bebeğin boynu yana çekildi — C5-C6 koptu (Erb-Duchenne). Kol içe dönük asılı kalır: 'bahşiş bekleyen garson' pozisyonu!",
    "ant-214": "💡 HİKAYE: 'LR6 SO4 gerisi 3' şifresi: M. obliquus superior CN IV ile çalışır — gözü aşağı-dışa baktırır. Felcinde merdiven inerken çift görme olur.",
    "ant-215": "💡 HİKAYE: Akciğerin iki kan kaynağı var: fonksiyonel (pulmoner arterler) ve nutritif (bronşiyal arterler). Sol bronşiyal arterler direkt torasik aortadan çıkar.",
    "ant-216": "💡 HİKAYE: Corti organı koklea içindeki 'piyano'dur — membrana basilaris üzerindeki tüy hücreleri ses frekanslarına göre titreşir. İşitmenin elektriğe dönüştüğü nokta!",
    "ant-217": "💡 HİKAYE: Midenin küçük kurvaturunda iki gastrik arter dans eder: A. gastrica sinistra (truncus celiacus'tan direkt) ve A. gastrica dextra (hepatica propria'dan).",
    "ant-218": "💡 HİKAYE: Ductus thoracicus vücudun en büyük lenf kanalıdır — alt yarı + sol üst yarının lenfini toplar. Cisterna chyli'den başlar, sol venöz açıya dökülür.",
    "ant-219": "💡 HİKAYE: Funiculus spermaticus erkek inguinal kanalının 'ipi'dir — içinde ductus deferens ve plexus pampiniformis var. Kadınlarda aynı kanalda lig. teres uteri bulunur.",
    "ant-220": "💡 HİKAYE: Parotis bezi en büyük tükürük bezi ve tamamen seröz salgı yapar. İçinden n. facialis transit geçer — cerrahide en büyük risk yüz felci!",
    "ant-101": "💡 HİKAYE: Boyun fasyasının en derin tabakası lamina prevertebralis — omurgayı sarar, önünde retrofarengeal boşluk var. Enfeksiyonlar bu boşluktan mediastene süzülebilir!",
    "ant-102": "💡 HİKAYE: Kornea gözün 'ön camı'dır — ışığı en fazla kıran yapı (~42 diyoptri). Lens ise ince ayar yapar (akomodasyon).",
    "ant-103": "💡 HİKAYE: Östaki borusu orta kulağın 'havalandırma kanalı'dır — yutkunurken açılıp basıncı dengeler. Çocuklarda daha kısa ve yatay → otitis media!",
    "ant-104": "💡 HİKAYE: Üç sinir, üç el deformitesi: N. ulnaris = Pençe el, N. radialis = Düşük el, N. medianus = Maymun eli. 'URP-PMD' ile hatırla!",
    "ant-106": "💡 HİKAYE: Bell felcinde yüzün bir yarısı tamamen felç — alın bile kıpırdamaz (periferik). Santral felçte ise alın korunur. 'Alın kıpırdıyor mu?' sorusu ayrımın anahtarı!",
    "ant-107": "💡 HİKAYE: Vagina carotica boyun fasyasının üç yaprağının birleşimiyle oluşur — içinde 'VAJ': Ven (jugularis), Arter (carotis), sinir (vagus) barınır.",
    "ant-108": "💡 HİKAYE: Pulmoner venler temiz kanı akciğerlerden sol atriuma getirir — genellikle 4 adet. Sol atrium kalbin en arkadaki odası, özofagusla komşu.",
    "ant-109": "💡 HİKAYE: Mesenterium ince bağırsakların 'asılı köprüsü'dür — jejunum ve ileumu karın duvarına bağlar. İçinde SMA dalları seyreder.",
    "ant-150": "💡 HİKAYE: Broca alanı konuşma motoru (frontal lob), Wernicke alanı anlama merkezi (temporal lob). Exner alanı ise yazı motoru (frontal lob, orta girus).",
    "ant-152": "💡 HİKAYE: Pars membranacea üretranın en dar ve en az esnek bölümüdür — pelvik tabandan geçer. Sonda takılırken en çok burada direnç hissedilir.",
    "ant-153": "💡 HİKAYE: Kiazma optikumda nazal retina lifleri çapraz yapar. Hipofiz tümörü kiazmeyi sıkıştırınca her iki gözün dış yarısı kaybolur = bitemporal hemianopsi!",
    "ant-154": "💡 HİKAYE: Substantia nigra mesencephalon'daki 'siyah çekirdek'tir — dopamin üreten nöronlar burada yaşar. Parkinson'da bu nöronlar ölür → tremor + bradikinezi + rijidite.",
    "ant-155": "💡 HİKAYE: N. radialis kolun 'ekstansör generali'dir — triceps, el bileği ve parmak ekstansörlerini yönetir. Hasarında 'düşük el' (drop wrist) gelişir.",
    "ant-002": "💡 HİKAYE: Scapula'nın üç köşesi var: superior (üst-medial birleşim), inferior (8. kaburga hizası) ve lateralis (eklem yüzü). İncisura scapulae'den n. suprascapularis geçer.",
    "ant-003": "💡 HİKAYE: Rotator cuff kasları SITS olarak bilinir. Subscapularis tuberculum minus'a tutunan tek kas — iç rotasyonun patronu! Diğer üçü tuberculum majus'a gider.",
    "ant-004": "💡 HİKAYE: Triküspid kapak sağ atrium ile sağ ventrikül arasındaki 'üç yapraklı kapı'dır. Septal kapakçığına yakın His huzmesi geçer — cerrahide dikkat!",
    "ant-005": "💡 HİKAYE: Plexus choroideus BOS'un 'su fabrikası'dır — özellikle lateral ventriküllerde bol bulunur. Drenaj tıkalıysa hidrosefali gelişir.",
    "ant-006": "💡 HİKAYE: Dilin sinir haritası: Ön 2/3 genel duyu = V3, tat = VII. Arka 1/3 hem genel hem tat = IX. Motor = XII. IX, dilin arka kısmının hem doktoru hem aşçısı!",
    "ant-007": "💡 HİKAYE: Omuz eklemi küresel (spheroidea) tip — en hareketli eklem! Ama cavitas glenoidalis sığ olduğu için çıkık riski yüksek.",
    "ant-008": "💡 HİKAYE: Mide büyük kurvaturun sağ yarısını a. gastroomentalis dextra besler — bu da a. gastroduodenalis'in dalıdır.",
    "ant-009": "💡 HİKAYE: Sol akciğer hilumunda sıralama ABV: Arter üstte, Bronş ortada, Ven altta. Sağda ise BAV: Bronş üstte.",
    "ant-010": "💡 HİKAYE: Nefron böbreğin en küçük işlevsel birimidir — her böbrekte yaklaşık 1 milyon! Toplama kanalları nefrona dahil değildir.",
    "ant-012": "💡 HİKAYE: Os ethmoidale koku duyusunu taşıyan delikli kemidir (lamina cribrosa) — beyin kutusunun (neurocranium) elemanıdır. Yüz iskeleti değil!",
    "ant-013": "💡 HİKAYE: M. orbicularis oculi gözü kapatan 'halka kas'tır — n. facialis yönetir. Bell felcinde göz açık kalır (lagoftalmus).",
    "ant-014": "💡 HİKAYE: Karaciğerin alt yüzünde 'H' şeklinde oluklar var — tam ortasında porta hepatis bulunur. V. portae ve a. hepatica propria buradan girer.",
    "ant-015": "💡 HİKAYE: Omurilik L1-L2'de conus medullaris olarak sonlanır — altında cauda equina uzanır. Lomber ponksiyon L3-L4 aralığından yapılır.",
    "ant-052": "💡 HİKAYE: M. sartorius vücudun en uzun kasıdır — SIAS'tan tibianın iç yüzüne uzanır. Terzi oturuşu pozisyonunu verir: kalçada fleksiyon + abduksiyon + dış rotasyon.",
    "ant-053": "💡 HİKAYE: Koroner arterler Valsalva sinüsünden çıkar ve DİYASTOL sırasında dolar. Kalp vücudun aksine gevşerken beslenir!",
    "ant-054": "💡 HİKAYE: Wirsung kanalı koledokla birleşip Vater ampullasını oluşturur → Papilla duodeni major'dan duodenuma açılır. Sfinkter Oddi geçidi kontrol eder.",
    "ant-055": "💡 HİKAYE: Primer görme korteksi (Brodmann 17) oksipital lobun iç yüzünde sulcus calcarinus etrafındadır. Oksipital lob hasarı = kortikal körlük.",
    "ant-056": "💡 HİKAYE: Beyincik (cerebellum) motor hareketlerin 'kalite kontrol'üdür. Hasarında ataksi, dismetri ve nistagmus gelişir.",
    "ant-057": "💡 HİKAYE: Tiroid kıkırdak larenksin kalkanıdır — erkeklerde sivri açı (90°) yapar: Adem elması! Krikoid kıkırdak ise tam halka şeklindeki tek kıkırdak.",
    "ant-058": "💡 HİKAYE: Uterus normalde mesanenin üzerine yatmıştır (antefleksiyon + anteversiyon). Bu pozisyon doğum için idealdir.",
    "ant-059": "💡 HİKAYE: Vena cava superior sağ ve sol v. brachiocephalica'nın birleşmesiyle oluşur — üst gövdenin tüm kanını sağ atriuma getirir.",
    "ant-100": "💡 HİKAYE: Epididimis spermlerin 'okulu'dur — burada 12-20 gün boyunca olgunlaşır ve hareket yeteneği kazanırlar. Mezuniyet sonrası ductus deferens'e geçerler!",
}


def add_hints_to_cases(data, hints_dict):
    """Add story_hint after explanation in clinical_cases."""
    if isinstance(data, dict) and "clinical_cases" in data:
        for case in data["clinical_cases"]:
            cid = case.get("id", "")
            if cid in hints_dict and "story_hint" not in case:
                # Insert story_hint
                case["story_hint"] = hints_dict[cid]
    return data


def reorder_keys(obj, after_key, new_key):
    """Reorder dict so new_key comes right after after_key."""
    if new_key not in obj:
        return obj
    new_val = obj[new_key]
    result = {}
    for k, v in obj.items():
        if k == new_key:
            continue
        result[k] = v
        if k == after_key:
            result[new_key] = new_val
    if new_key not in result:
        result[new_key] = new_val
    return result


def process_file(filepath, hints):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    data = add_hints_to_cases(data, hints)

    # Reorder keys so story_hint comes after explanation
    if isinstance(data, dict) and "clinical_cases" in data:
        data["clinical_cases"] = [
            reorder_keys(c, "explanation", "story_hint")
            for c in data["clinical_cases"]
        ]

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    # Count how many story_hints were added
    count = sum(1 for c in data.get("clinical_cases", []) if "story_hint" in c)
    print(f"Done: {os.path.basename(filepath)} — {count} story_hints")


if __name__ == "__main__":
    print("Adding story_hints to remaining files...\n")

    process_file(
        os.path.join(BASE, "pathology_vaka_100.json"),
        pathology_vaka_100_hints
    )

    process_file(
        os.path.join(BASE, "anatomi_200_soru.json"),
        anatomi_hints
    )

    print("\nDone!")
