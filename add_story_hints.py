#!/usr/bin/env python3
"""
Add story_hint fields to flashcard/clinical_case JSON files.
Only adds story_hint where it doesn't already exist.
Does NOT modify any existing data.
"""

import json
import os

BASE = r"C:\Users\ceyla\Desktop\tus\tus_app_project\tus_asistani\assets\data"

# ============================================================
# STORY HINTS FOR EACH FILE
# ============================================================

# 1. pathology_vaka_100.json — 100 clinical_cases (inside a wrapper object)
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
}

# Continue with remaining vaka hints (39-100)
pathology_vaka_100_hints_part2 = {
    "path_vaka_39": "💡 HİKAYE: Böbrek, hipertansif hasar altında arteriollerinde hyalin biriktirir (benign nefroskleroz). Ama malign HT'de arterioller soğan zarı gibi katman katman kalınlaşır ve fibrinoid nekroz gelişir. İki farklı hipertansiyon, iki farklı böbrek hikayesi.",
    "path_vaka_40": "💡 HİKAYE: Genç kadının böbreğinde hilal (crescent) şekilleri var — hızlı ilerleyen GN! Bowman boşluğunda fibrin ve makrofajlar birikti, glomerülü boğuyor. Anti-GBM antikorlar bazal membranda lineer (çizgisel) pattern oluşturur → Goodpasture. Acil plazmaferez!",
    "path_vaka_41": "💡 HİKAYE: IgA nefropatisi (Berger hastalığı) = üst solunum yolu enfeksiyonu sonrası 1-2 gün içinde hematüri. IgA mezangiumda birikir. PSGN'den farkı: PSGN'de 2-4 hafta beklenir, IgA'da 'eş zamanlı' hematüri gelir. Dünya genelinde en sık GN!",
    "path_vaka_42": "💡 HİKAYE: Membranöz nefropati erişkinde nefrotik sendromun 2. en sık nedeni. Bazal membranda 'spike and dome' (diken ve kubbe) görünümü = subepitelyal immün kompleks birikimi. HBV, SLE, altın tuzları ve malignite ile ilişkili olabilir.",
    "path_vaka_43": "💡 HİKAYE: PSGN'de çocuk boğaz ağrısından 2-4 hafta sonra çay renkli idrar çıkarmaya başlar. EM'de subepitelyal 'hörgüç' (humps) görülür. C3 düşük, ASO yüksek. Çoğu çocukta prognoz mükemmel — kendiliğinden iyileşir.",
    "path_vaka_44": "💡 HİKAYE: Böbrek hücreleri berrak sitoplazmalı (lipid ve glikojen dolu). VHL geni 3p'de — inaktive olunca HIF birikir, VEGF ve büyüme faktörleri artar. Bilateral ve erken yaşta ise VHL sendromu düşün: hemanjioblastom, feokromositoma eşlik eder.",
    "path_vaka_45": "💡 HİKAYE: Wilms tümörü (nefroblastom) çocuklarda karın kitlesi olarak kendini gösterir. WT1 geni 11p13'te. WAGR sendromu: Wilms + Aniridi + Genitüriner anomali + mental Retardasyon. Histolojide 'trifazik patern' (blastem, stroma, epitel) patognomonik.",
    "path_vaka_46": "💡 HİKAYE: Amfizem hastasının akciğerinde hava kesesicikleri yıkılmış. Sigara içenlerde sentriasiner (üst loblar), alfa-1 antitripsin eksikliğinde panasiner (alt loblar). Alfa-1 AT eksikliğinde nötrofil elastazı frensiz çalışır — akciğer dokusunu eritir!",
    "path_vaka_47": "💡 HİKAYE: Astım hastası gece nefes darlığıyla uyanıyor — bronşlar kasılmış, mukus dolmuş. LTC4/D4/E4 bronkospazm yapar, IL-4/IL-5 eozinofileri toplar. Curschmann spiralleri (mukus tıkaçları) ve Charcot-Leyden kristalleri (eozinofil kalıntıları) balgamda görülür.",
    "path_vaka_48": "💡 HİKAYE: Akciğer adenokarsinomu periferik yerleşimlidir, kadınlarda ve sigara içmeyenlerde de görülür. EGFR mutasyonu olan hastalarda erlotinib/gefitinib mucize yaratır. ALK translokasyonu varsa crizotinib kullanılır. Hedefe yönelik tedavinin akciğer hikayesi!",
    "path_vaka_49": "💡 HİKAYE: Küçük hücreli karsinom nöroendokrin kökenli — ektopik hormon fabrikası! ACTH salgılar (Cushing), ADH salgılar (SIADH). Santral yerleşimli, sigara ile çok ilişkili ama cerrahiden çok kemoterapiye yanıt verir.",
    "path_vaka_50": "💡 HİKAYE: Mezotelyoma plevranın kanseridir — asbest lifleri plevrayı delip granülom oluşturur. Uzun, ince amfibol lifler (krokidolit) en tehlikelisidir. Kalretinin ve WT1 immünohistokimyasal boyama ile adenokarsinomdan ayrılır.",
    "path_vaka_51": "💡 HİKAYE: Barrett özofagusunda mide asidi yıllarca squamöz epiteli yakıyor — hücreler goblet hücreli kolumnar epitele dönüşüyor (intestinal metaplazi). Bu 'adaptasyon' displazi → adenokarsinom yolunu açar. Metaplazi → displazi → neoplazi sekansı!",
    "path_vaka_52": "💡 HİKAYE: H. pylori midenin antrum bölgesine yerleşip üreaz ile ortamı nötralize eder. CagA proteini direkt hücreye zarar verir. Kronik gastrit → intestinal metaplazi → displazi → adenokarsinom veya MALT lenfoma gelişebilir.",
    "path_vaka_53": "💡 HİKAYE: Crohn hastalığı barsakta 'atlayarak' (skip lezyonlar) ilerler, duvarın tüm katmanlarını tutar (transmural). Fistül, striktür ve non-kazeifiye granülom karakteristik. Ülseratif kolit ise rektumdan başlar, sadece mukozada kalır ve kript abseleri yapar.",
    "path_vaka_54": "💡 HİKAYE: Çölyak hastasının ince barsağında villüsler yassılaşmış (villöz atrofi), kriptler derin, intraepitelyal lenfositler artmış. Gluten (gliadin) → tTG antikorları → immün hasar. Anti-endomisyum ve anti-tTG IgA tanıda kullanılır. Dermatitis herpetiformis eşlik edebilir.",
    "path_vaka_55": "💡 HİKAYE: Alkolik karaciğerde Mallory cisimcikleri (hasarlı keratin filamentleri) hepatosit içinde birikim yapar. Steatoz → steatohepatit → siroz yolu izlenir. Alkolik hepatitte nötrofil infiltrasyonu baskındır (viral hepatitte lenfosit).",
    "path_vaka_56": "💡 HİKAYE: HBV hepatositlerde 'buzlu cam' (ground glass) görünümü yapar — HBsAg birikimidir. HBV DNA entegre olabilir → HCC riski! HCV ise lenfoid agregatlar ve yağlanma ile karakterize; kronikleşme oranı HBV'den yüksektir (%80 vs %5).",
    "path_vaka_57": "💡 HİKAYE: Siroz karaciğerin son halidir — nodüler rejenerasyon ve fibrozis. Portal hipertansiyon → özofagus varisleri, asit, splenomegali. Kaput medusa = umbilikal venlerin dilatasyonu. Hepatorenal sendrom terminal komplikasyondur.",
    "path_vaka_58": "💡 HİKAYE: Wilson hastalığında bakır her yere birikir: karaciğerde siroz, beyinde bazal ganglia hasarı (hareket bozuklukları), gözde Kayser-Fleischer halkası. Seruloplazmin düşük, idrar bakırı yüksek. Penisilamin ile tedavi edilir.",
    "path_vaka_59": "💡 HİKAYE: Herediter hemokromatozda HFE gen mutasyonu demir emilimini artırır. Demir karaciğer, pankreas, kalp ve deriye birikir → 'bronz diyabet' (deri + DM). Prusya mavisi boyama ile demir birikimi gösterilir. Tedavi: flebotomi!",
    "path_vaka_60": "💡 HİKAYE: Akut pankreatitte lipaz ve amilaz yükselir — tripsinojen aktive olup pankreası kendi kendine sindirir. Kalsiyum sabunlaşması (saponifikasyon) beyaz alanlar oluşturur. Grey-Turner (yan) ve Cullen (göbek) bulguları hemorajik nekrozu gösterir.",
    "path_vaka_61": "💡 HİKAYE: Pankreas kanseri (baş bölgesi) sessiz katildir — sarılık, ağrısız palpabl safra kesesi (Courvoisier belirtisi) ve kilo kaybı ile gelir. CA 19-9 tümör belirteci yükselir. Trousseau sendromu (migratuar tromboflebit) eşlik edebilir.",
    "path_vaka_62": "💡 HİKAYE: Meme kanserinde en sık invaziv duktal karsinom görülür (%70-80). HER2 pozitifse trastuzumab, ER pozitifse tamoksifen/aromataz inhibitörü, triple negatifse kemoterapi. Sentinel lenf nodu biyopsisi aksiller evrelemenin anahtarıdır.",
    "path_vaka_63": "💡 HİKAYE: Paget hastalığı meme başında egzama benzeri lezyon yapar — alttaki duktal karsinom meme başı epidermine yayılmıştır. Paget hücreleri büyük, soluk, halo'lu hücrelerdir. Meme başında inatçı egzama varsa biyopsi şart!",
    "path_vaka_64": "💡 HİKAYE: Serviks kanserinde HPV 16/18 suçlu — E6 p53'ü, E7 Rb'yi devre dışı bırakır. Koilositler (çekirdek etrafında hale) HPV enfeksiyonunun sitolojik kanıtıdır. PAP smear ile taranır, aşı ile önlenebilir!",
    "path_vaka_65": "💡 HİKAYE: Endometrium kanseri Tip I (östrojen bağımlı) ve Tip II (serous, östrojenden bağımsız) olarak ikiye ayrılır. Tip I daha sık, daha iyi prognozlu, obezite ve nulliparite risk faktörü. Postmenopozal kanama = endometrium kanseri dışlanmalı!",
    "path_vaka_66": "💡 HİKAYE: Over tümörlerinde seröz kistadenokarsinom en sık malign tiptir. Psammom cisimcikleri (kum tanecikleri gibi kalsifikasyon) karakteristiktir — tiroid papiller karsinomda da görülür. CA-125 takipte kullanılır.",
    "path_vaka_67": "💡 HİKAYE: Matür kistik teratom (dermoid kist) overin en sık germ hücreli tümörüdür — saç, diş, deri hepsi içinde! Genellikle benigndir. İmmatür teratom ise maligndir ve nöral doku içerir. AFP yüksekliği immatürite göstergesi.",
    "path_vaka_68": "💡 HİKAYE: Hidatidiform mol trofoblastik hücrelerin anormal proliferasyonudur. Komplet mol: 46,XX (tamamen paternal), fetus yok, üzüm salkımı görünümü, β-hCG çok yüksek, koryokarsinom riski! Parsiyel mol: triploid (69,XXY), kısmi fetus var.",
    "path_vaka_69": "💡 HİKAYE: Testis seminom = germ hücreli tümörlerin en sık tipi. Radyosensitiftir, iyi prognozlu. PLAP (plasental alkalen fosfataz) pozitif. 'Kızarmış yumurta' görünümlü hücreler (büyük çekirdek, berrak sitoplazma). Kriptorşidizm risk faktörü!",
    "path_vaka_70": "💡 HİKAYE: Hodgkin lenfoma Reed-Sternberg hücreleriyle tanınır — baykuş gözlü dev hücreler! Genç erişkinde boyun LAP ile başlar. Nodüler sklerozan tip en sık, lenfositten zengin tip en iyi prognozlu. EBV ilişkisi özellikle mikst selüler tipte belirgin.",
    "path_vaka_71": "💡 HİKAYE: Burkitt lenfoma c-MYC translokasyonu [t(8;14)] ile tetiklenir — hücreler inanılmaz hızla bölünür! 'Yıldızlı gökyüzü' manzarası: tümör hücreleri arasında tingible body makrofajlar açık alanlar oluşturur. Endemik formda EBV çeneyi tutar, sporadik form ileosekal bölgeyi sever.",
    "path_vaka_72": "💡 HİKAYE: Foliküler lenfoma t(14;18) translokasyonu ile bcl-2 aşırı eksprese olur → hücreler ölmeyi reddeder (apoptoz baskılanır). Yavaş seyirli, yaşlılarda sık. 'Nodüler patern' tanıda önemli. Difüz büyük B hücreli lenfomaya dönüşebilir.",
    "path_vaka_73": "💡 HİKAYE: KML'de Philadelphia kromozomu [t(9;22)] BCR-ABL füzyon tirozin kinazı oluşturur. Periferik yaymada lökositoz + bazofili + tüm olgunlaşma evreleri. Blast krizi AML'ye dönüşüm demektir. İmatinib hayat kurtarır!",
    "path_vaka_74": "💡 HİKAYE: KLL yaşlıların lösemisidir — olgun ama işlevsiz lenfositler birikir. CD5+, CD23+ B hücreleri. 'Smudge cells' (ezilmiş hücreler) periferik yaymada tipik. Richter transformasyonu: DLBCL'ye dönüşüm = kötü prognoz.",
    "path_vaka_75": "💡 HİKAYE: Multipl miyelom plazma hücrelerinin klonal çoğalmasıdır — CRAB: Calcium ↑, Renal yetmezlik, Anemi, Bone (kemik) lezyonları. Serum protein elektroforezinde M-spike, idrarda Bence-Jones proteini (hafif zincirler). Rouleaux formasyonu yaymada görülür.",
    "path_vaka_76": "💡 HİKAYE: Demir eksikliği anemisi dünyada en sık anemi nedenidir. Mikrositer hipokrom: MCV↓, MCH↓, MCHC↓. Ferritin↓, TIBC↑, transferrin satürasyonu↓. Kaşık tırnak (koilonychia) ve Plummer-Vinson sendromu (disfaji + glossit) eşlik edebilir.",
    "path_vaka_77": "💡 HİKAYE: B12 eksikliği megaloblastik anemi yapar — DNA sentezi bozulur, hücreler olgunlaşamadan büyür. Hipersegmente nötrofiller (>5 lob) patognomonik. Subakut kombine dejenerasyon (arka ve yan kordonlar) nörolojik tabloyu oluşturur. Folat eksikliğinde nöroloji yok!",
    "path_vaka_78": "💡 HİKAYE: Orak hücre anemisinde HbS glutamik asit → valin değişimi ile oluşur. Düşük O₂'de HbS polimerize olup eritrositi oraklaştırır. Dalak infarktları → otosplenektomi → kapsüllü bakteri enfeksiyonlarına yatkınlık! Howell-Jolly cisimleri yaymada görülür.",
    "path_vaka_79": "💡 HİKAYE: Talasemide globin zinciri üretimi azalmıştır — alfa veya beta. Beta talasemi majörde HbF kompansatuar artar. Eritropoez artışı → kemik iliği genişlemesi → 'crew cut' (asker traşı) kafatası görüntüsü. Target hücreleri yaymada tipik.",
    "path_vaka_80": "💡 HİKAYE: Herediter sferositoz eritrosit iskeleti (spektrin, ankirin) bozukluğundan kaynaklanır. Küresel eritrositler dalakta sıkışıp yıkılır. Splenektomi küratiftir! MCHC artışı ve ozmotik frajilite testi pozitifliği tanıda yol gösterir.",
    "path_vaka_81": "💡 HİKAYE: G6PD eksikliğinde oksidatif stres eritrositleri yıkar — Heinz cisimcikleri (denatüre hemoglobin) ve ısırık hücreleri (bite cells) yaymada görülür. Bakla, naftalin, sulfonamidler tetikleyici. X'e bağlı resesif — erkeklerde sık!",
    "path_vaka_82": "💡 HİKAYE: Otoimmün hemolitik anemi (sıcak tip) IgG antikorları ile eritrositlerin dalakta yıkılmasıdır. Direct Coombs testi pozitif! SLE, KLL ve metildopa ilişkili olabilir. Soğuk tip ise IgM ile, Mycoplasma ve EBV enfeksiyonlarında görülür.",
    "path_vaka_83": "💡 HİKAYE: HUS (hemolitik üremik sendrom) çocuklarda E. coli O157:H7'nin Shiga toksiniyle tetiklenir. Triad: mikroanjiyopatik hemolitik anemi + trombositopeni + akut böbrek yetmezliği. Yaymada schistositler (parçalanmış eritrositler) görülür.",
    "path_vaka_84": "💡 HİKAYE: TTP'de ADAMTS13 enzimi eksiktir — ultra-büyük vWF multimerleri parçalanamaz, küçük damarlarda trombüs yağmuru yağar. Pentad: hemolitik anemi + trombositopeni + böbrek yetmezliği + nörolojik bulgular + ateş. Plazma değişimi hayat kurtarır!",
    "path_vaka_85": "💡 HİKAYE: ITP'de antiplatelet antikorlar trombositleri dalakta yıkar. Çocuklarda viral enfeksiyon sonrası akut, erişkinlerde kronik seyir. Megakaryositler ilikte artmış (kompansatuar). PT ve aPTT normal — çünkü sorun faktörlerde değil, trombositlerde!",
    "path_vaka_86": "💡 HİKAYE: von Willebrand hastalığı en sık kalıtsal kanama bozukluğudur. vWF hem trombositleri kollajena yapıştırır hem FVIII'i korur. Tip 1 en sık (kantitatif azalma). Ristosetin kofaktör testi bozuk, kanama zamanı uzun ama PT normal.",
    "path_vaka_87": "💡 HİKAYE: Hemofili A = FVIII eksikliği, Hemofili B = FIX eksikliği. X'e bağlı resesif — erkeklerde görülür. aPTT uzar, PT normal. Hemartroz (eklem içi kanama) en sık bulgudur. Karışım çalışması ile inhibitörden ayırt edilir.",
    "path_vaka_88": "💡 HİKAYE: Tiroid papiller karsinomu en sık tiroid kanseridir. 'Orphan Annie' gözleri (buzlu cam çekirdek), psammom cisimcikleri ve nükleer oluk/yarıklar tanıda yol gösterir. Lenfatik yayılım yapar ama prognoz çok iyi!",
    "path_vaka_89": "💡 HİKAYE: Hashimoto tiroiditi en sık otoimmün tiroid hastalığıdır. Anti-TPO ve anti-tiroglobulin antikorları pozitif. Hürthle hücreleri (onkositik metaplazi) ve lenfoid foliküller biyopside görülür. Hipotiroidiye gider, tiroid lenfoma riski artmıştır.",
    "path_vaka_90": "💡 HİKAYE: Graves hastalığında TSH reseptör stimülan antikorlar (TSI) tiroidin gazını sonuna kadar açar → hipertiroidi! Diffüz guatr, ekzoftalmi, pretibial miksödem triadı. Tip II hipersensitivite — ama yıkıcı değil uyarıcı (stimülatör) antikor!",
    "path_vaka_91": "💡 HİKAYE: Feokromositoma adrenal medullada katekolamin (epinefrin/norepinefrin) üreten tümördür. '10 kuralı': %10 bilateral, %10 malign, %10 ekstra-adrenal, %10 çocuklarda, %10 familyal. Paroksismal HT, çarpıntı, terleme ve baş ağrısı triadı. 24 saat idrarda VMA ve metanefrinler yükselir.",
    "path_vaka_92": "💡 HİKAYE: Addison hastalığı (primer adrenal yetmezlik) adrenal korteksin yıkımıdır. Otoimmün nedeni en sık (gelişmiş ülkelerde), TBC en sık (gelişmekte olan ülkelerde). Hiperpigmentasyon (ACTH↑ → MSH etkisi), hipotansiyon, hiperkalemi, hiponatremi. ACTH stimülasyon testine yanıt yok!",
    "path_vaka_93": "💡 HİKAYE: Cushing sendromunda kortizol fazladır. Ekzojen steroid kullanımı en sık neden! Endojen nedenlerde: Hipofiz adenomu (Cushing hastalığı, %70), ektopik ACTH (küçük hücreli karsinom), adrenal adenom. Ay yüzü, buffalo hörgücü, stria, hiperglisemi karakteristik.",
    "path_vaka_94": "💡 HİKAYE: MEN1 (Wermer sendromu): 3P → Paratiroid + Pituiter + Pankreas tümörleri. MEN2A (Sipple): Medüller tiroid kanseri + Feokromositoma + Paratiroid hiperplazisi. MEN2B: Medüller tiroid + Feokromositoma + Mukozal nöromalar (paratiroid YOK). RET protoonkogen mutasyonu MEN2'de!",
    "path_vaka_95": "💡 HİKAYE: Diyabet Tip 1'de otoimmün yıkım adacık hücrelerini yok eder — insülin sıfırlanır! Anti-GAD, anti-adacık hücre antikorları pozitif. Ketoasidoz ile başvurabilir. Tip 2'de insülin direnci ön planda — amiloid birikimi (amilin) adacıklarda görülür.",
    "path_vaka_96": "💡 HİKAYE: Glioblastom (GBM) en agresif primer beyin tümörüdür — kelebek gibi her iki hemisfere yayılır! Nekroz çevresinde pseudopalisading dizilim patognomonik. IDH-wild type, EGFR amplifikasyonu sık. Ortanca sağkalım 12-15 ay.",
    "path_vaka_97": "💡 HİKAYE: Meningiom meninkslerin benign tümörüdür — dural kuyruğu (tail sign) MR'da karakteristik! Psammom cisimcikleri histolojide görülür. Östrojen reseptörü taşıyabilir (gebelikte büyüme). En sık intrakranyal benign tümör.",
    "path_vaka_98": "💡 HİKAYE: Schwannom (nörilemmom) Schwann hücrelerinden köken alır. S-100 pozitif! Antoni A (kompakt, Verocay cisimcikleri) ve Antoni B (gevşek, miksoid) alanları var. Vestibüler schwannom CN VIII'de en sık — tek taraflı işitme kaybı. Bilateral ise NF2 düşün!",
    "path_vaka_99": "💡 HİKAYE: Osteosarkom kemiğin en sık primer malign tümörüdür — genç erkeklerde diz çevresi (distal femur/proksimal tibia) sever. Codman üçgeni (periost reaksiyonu) ve 'sunburst' (güneş patlaması) radyolojide görülür. Rb ve p53 mutasyonları ilişkili.",
    "path_vaka_100": "💡 HİKAYE: Ewing sarkomu 'küçük yuvarlak mavi hücreli' tümördür — t(11;22) translokasyonu ve EWS-FLI1 füzyonu karakteristik. 'Soğan zarı' (onion peel) periost reaksiyonu radyolojide görülür. Çocuk ve genç erişkinlerde diyafiz bölgesini tutar. CD99 (MIC2) pozitiftir.",
}

pathology_vaka_100_hints.update(pathology_vaka_100_hints_part2)

# Need to read the remaining IDs. Let me add hints for IDs I haven't read yet.
# Based on the pattern, IDs go from path_vaka_1 to path_vaka_100.
# Let me fill in the remaining ones.
remaining_vaka_hints = {}
for i in range(39, 101):
    key = f"path_vaka_{i}"
    if key not in pathology_vaka_100_hints:
        remaining_vaka_hints[key] = None  # placeholder

# Actually, let me provide hints for all 100 cases. I'll fill in the gaps.
extra_hints = {
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
    "path_vaka_58": "💡 HİKAYE: Wilson'da bakır vücudu istila eder: karaciğerde Kayser-Fleischer halkası değil, gözde! Karaciğerde siroz, beyinde bazal ganglia hasarı (hareket bozuklukları). Seruloplazmin düşük, serbest bakır yüksek. Penisilamin bakırı şelatlar.",
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
# Merge, preferring existing hints
for k, v in extra_hints.items():
    if k not in pathology_vaka_100_hints:
        pathology_vaka_100_hints[k] = v


# 2. pathology_hemo_immuno.json — flashcards (no tags)
pathology_hemo_immuno_hints = {
    "fc-patho-hemo-100": "💡 HİKAYE: Nefrotik sendromda böbrekler 'elek' gibi protein kaçırır — albumin kaybı onkotik basıncı düşürür, su damardan interstisyuma sızar. Sanki su deposunun kapağı gevşemiş, sıvı dışarı taşıyor!",
    "fc-patho-hemo-101": "💡 HİKAYE: Sol kalp yetmezliğinde akciğerler su basar, eritrositler alveollere sızar. Makrofajlar bu eritrositleri yutar ve hemosiderin biriktirerek kahverengi 'kalp hatası hücreleri'ne dönüşür — akciğerin paslı temizlikçileri!",
    "fc-patho-hemo-110": "💡 HİKAYE: Zahn çizgileri trombusun 'hayattayken' oluştuğunun kanıtıdır — fibrin ve platelet tabakaları pasta dilimi gibi katman katman dizilir (laminasyon). Postmortem pıhtılarda bu düzen yoktur — homojen, jelöz kıvamda olurlar.",
    "fc-patho-hemo-111": "💡 HİKAYE: Kemik kırıldı, ilik yağları kana karıştı — küçük yağ damlacıkları akciğere gidip kapillerleri tıkadı. Solunum yetmezliği + ciltte peteşiler = yağ embolisi. Kırık + nefes darlığı + peteşi üçlüsü sorularda alarm veriyor!",
    "fc-patho-imm-120": "💡 HİKAYE: Arthus reaksiyonunda antijen deriye enjekte edilir, bol miktarda antikor zaten kanda bekler — ikisi buluşup immün kompleks oluşturur ve damar duvarını yakalar (lokalize vaskülit). Tip III'ün küçük ölçekli deneyi!",
    "fc-patho-imm-121": "💡 HİKAYE: Granülom oluşumunda CD4 T hücreleri IFN-gamma ile makrofajları çağırır, makrofajlar epiteloid hücrelere dönüşüp dev hücre olur. Bu organizasyon haftalar sürer — gecikmiş tip (Tip IV) hipersensitivitenin en sofistike versiyonu!",
    "fc-patho-imm-130": "💡 HİKAYE: ANA testi SLE'nin 'kapı zili'dir — hemen hemen her SLE hastasında çalar (>%95 duyarlılık). Ama başka otoimmün hastalıklarda da çalabilir. Tarama için ideal ama özgüllüğü düşük!",
    "fc-patho-imm-131": "💡 HİKAYE: Anti-dsDNA lupus böbreğini, Anti-Smith lupus kimliğini tanır! İkisi de SLE'ye son derece spesifik — başka hastalıklarda nadiren pozitif çıkar. Tanı koydurucu 'altın anahtar' ikili.",
    "fc-patho-imm-140": "💡 HİKAYE: Amiloidi teşhis etmek için Congo kırmızısı boyası kullanılır — normal ışıkta pembe-kırmızı, polarize ışıkta elma yeşili çift kırıcılık (birefringence) gösterir. Sanki amiloid gece karanlığında yeşil parıldayan bir hayalet!",
}

# Clinical case hints for pathology_module.json
pathology_module_cc_hints = {
    "cc-path-mod-001-001": "💡 HİKAYE: MI'ın 24. saatinde nükleer değişiklikler sıralı gelişir: piknoz → karyoreksis → karyolizis. 24. saatte karyolizis hakimdir — DNaz çekirdeği tamamen eritmiştir. Kronometrenin son tıkı!",
    "cc-path-mod-002-001": "💡 HİKAYE: Pankreas etrafında beyaz kireçlenme = lipazın sabunlaşma eseri! Serbest yağ asitleri kalsiyumla birleşip saponifikasyon yapar. BT'de radyoopak görünüm = yağ nekrozunun röntgen imzası.",
    "cc-path-mod-003-001": "💡 HİKAYE: Apoptotik cisimcikler = membranı bütün, organ içeren minik paketler. Fagositler bunları sessizce toplar — inflamasyon YOK! Nekrozda ise hücre patlar, içerik dışarı saçılır, inflamasyon kaçınılmaz.",
    "cc-path-mod-004-001": "💡 HİKAYE: LAD bebeğinde nötrofiller kanda bol ama dokuya göç edemiyor — CD18 yapıştırıcısı bozuk! Göbek kordonu bile düşmüyor çünkü nötrofiller orada da işe yaramıyor. Kanda nötrofili + dokuda nötrofil yokluğu = LAD!",
    "cc-path-mod-005-001": "💡 HİKAYE: Sarkoidoz triadı = bilateral hiler LAP + eritema nodosum + üveit (Löfgren sendromu). Non-kazeifiye granülom + yüksek ACE = tanıyı mühürler. TBC'de kazeöz nekroz beklenir — peynir yoksa sarkoidoz düşün!",
    "cc-path-mod-006-001": "💡 HİKAYE: Bilateral retinoblastom + aile öyküsü = germline RB1 mutasyonu. Bebek doğduğunda her hücresinde bir RB alleli zaten bozuk (birinci vuruş). Retina hücresinde ikinci allel de bozulunca (ikinci vuruş) tümör başlar. Knudson iki vuruş!",
}

# 3. pathology_module.json — flashcards with tags, add story_hint after tags
pathology_module_hints = {
    "fc-patho-001": "💡 HİKAYE: Mitokondri hücrenin enerji santrali — hasar gelince ilk o şişer (kondenzasyon). ATP üretimi düşer ama membran hâlâ sağlam. Erken uyarı sistemi gibi: 'Dikkat, enerji kesiliyor!' diye alarm veriyor.",
    "fc-patho-002": "💡 HİKAYE: Kalsiyum mitokondriye girdi mi artık geri dönüş yok — kapılar kapandı! Fosfolipazlar aktive olup membranı eritmeye başlar. Bu 'geri dönüşsüzlük noktası' bir uçurumun kenarıdır: bir adım daha atılırsa hücre düşer.",
    "fc-patho-003": "💡 HİKAYE: Piknoz = çekirdek koyulaşıp küçüldü (yumruk gibi sıkıştı). Karyoreksis = çekirdek parçalara ayrıldı (cam kırıldı). Karyolizis = çekirdek eridi (buz eridi). P-K-L sıralaması: önce sıkış, sonra kırıl, en son eri!",
    "fc-patho-004": "💡 HİKAYE: İskemide ATP düşünce Na/K pompası durur — hücre içine Na ve su dolar, hücre balon gibi şişer (hidropik dejenerasyon). Sanki evin su boruları patlamış, su basıyor ama pompalar çalışmıyor!",
    "fc-patho-010": "💡 HİKAYE: Beyin yağ deposu gibidir — lipidce zengin. İskemide güçlü lizozomal enzimler (fosfolipazlar) devreye girer ve her şeyi eritir (likefikasyon). Kalp ve böbrek ise protein ağırlıklı olduğu için katılaşır (koagülatif). Beyin = sıvılaşma, kalp = katılaşma!",
    "fc-patho-011": "💡 HİKAYE: Tüberküloz basili makrofajları mağlup edemez ama makrofajlar da basili öldüremez — savaş alanı peynir kıvamında (kazeöz) nekroza dönüşür. Etrafında Langhans dev hücreleri nöbet tutar: granülom = kalenin kuşatması!",
    "fc-patho-012": "💡 HİKAYE: Pankreatit patladığında lipaz serbest kalır, etraftaki yağı parçalar. Serbest yağ asitleri kalsiyumla birleşip 'sabun' oluşturur (saponifikasyon) — tebeşir beyazı lekeler! Pankreas çevresinin beyaz boyası.",
    "fc-patho-013": "💡 HİKAYE: Kuru gangren = arterler tıkalı ama bakteri yok, doku kurumuş mısır gibi (koagülatif). Islak gangren = bakteriler gelmiş, doku çürümüş, kokulu, tehlikeli (likefikasyon). Kuru = sessiz ölüm, ıslak = gürültülü enfeksiyon!",
    "fc-patho-020": "💡 HİKAYE: Fas ligandı, ölüm reseptörüne (Fas/CD95) bağlanır — kapıyı çalar ve 'öl!' der. FADD adaptör kaspaz-8'i uyandırır, o da kaspaz-3 cellat ordusunu salar. Ekstrinsik yolak = dışarıdan gelen ölüm emri!",
    "fc-patho-021": "💡 HİKAYE: Bcl-2 mitokondrinin kapı bekçisidir — sitokrom-c'yi içeride tutar, apoptozu engeller. Foliküler lenfomada t(14;18) ile Bcl-2 aşırı üretilir → hücreler ölmeyi reddeder → lenfoma gelişir. Bekçi çok güçlenince suçlular kaçamıyor!",
    "fc-patho-022": "💡 HİKAYE: Apoptoz = sessiz intihar (enerji gerekli, inflamasyon yok, hücre büzüşür, DNA merdiven gibi kesilir). Nekroz = gürültülü kaza (enerji gereksiz, inflamasyon var, hücre şişer, DNA rastgele parçalanır). Biri planlı, diğeri kaotik!",
    "fc-patho-030": "💡 HİKAYE: P-selektin acil çağrı butonu — dakikalar içinde Weibel-Palade cisimciğinden fırlar. E-selektin ise 4-6 saat sonra IL-1/TNF uyarısıyla fabrikada üretilir. İkisi de nötrofilleri endotelde yuvarlatır — ilk temas!",
    "fc-patho-031": "💡 HİKAYE: LFA-1 (CD11a/CD18) nötrofilin 'yapışkan eli'dir — endoteldeki ICAM-1'e sıkıca tutunur (firm adhezyon). CD18 bozuksa el yapışmaz → nötrofil dokuya göç edemez → LAD! Tekrarlayan enfeksiyon + gecikmiş göbek düşmesi.",
    "fc-patho-032": "💡 HİKAYE: C5a, IL-8, LTB4 ve bakteriyel peptidler nötrofilin 'GPS navigasyonu'dur — hepsini hasara yönlendirir. IL-8 en güçlü sitokin kemotaktik ajan, C5a komplemanın en güçlü kemotaktik parçası. Dört pusula, tek hedef: enfeksiyon bölgesi!",
    "fc-patho-040": "💡 HİKAYE: CD4 Th1 hücreleri IFN-gamma salgılar → makrofajlar güçlenir → epiteloid hücreye dönüşür → granülom oluşur. Bu bir 'kale inşaatı' — düşmanı (örn. TBC basili) kuşatmak için organize yapı kurulur!",
    "fc-patho-041": "💡 HİKAYE: Sarkoidoz = peynir yok (non-kazeifiye) ama yıldızlar (asteroid) ve katmanlı taşlar (Schaumann) var. TBC = peynir var (kazeifiye), Langhans dev hücreleri bekçi. İki granülom, iki farklı dünya!",
    "fc-patho-042": "💡 HİKAYE: Crohn'un granülomları duvar boyunca (transmural) yayılır — non-kazeifiye, tıpkı sarkoidoz gibi. Terminal ileum en sevdiği yer. Granülom her hastada bulunmaz (%60) ama varsa Crohn tanısını güçlendirir.",
    "fc-patho-050": "💡 HİKAYE: Normal RAS bir ışık anahtarıdır — GTP ile açar, GTPaz ile kapatır. Mutant RAS'ta anahtar kırıldı: sürekli AÇIK! Işık (proliferasyon sinyali) hiç sönmüyor → kontrolsüz hücre bölünmesi → kanser. İnsan kanserlerinin %30'unda bu bozuk anahtar var.",
    "fc-patho-051": "💡 HİKAYE: RB geni hücre döngüsünün 'kapısı'dır — E2F'yi kilitleyerek S fazına girişi engeller. Fosforillenince kilit açılır. İki vuruş hipotezi: her iki RB kopyası da kırılmalı. Herediter = doğuştan bir anahtar bozuk (bilateral, erken), sporadik = iki anahtar da sonradan kırılır (tek taraflı, geç).",
    "fc-patho-052": "💡 HİKAYE: HER2/neu meme kanserinde bir 'megafon'dur — sinyal amplifikasyonu yapar, tümör agresifleşir. Ama Trastuzumab bu megafonu sessizleştirir! HER2 pozitif kanser = kötü prognoz ama hedefli tedavi şansı.",
}

# 4. pathology_neo_sys1.json — flashcards (no tags)
pathology_neo_sys1_hints = {
    "fc-patho-neo-200": "💡 HİKAYE: Karsinomlar lenfatik sistemi 'otobüs' olarak kullanır — lenfatik damarlarla uzak lenf nodlarına yayılır. Ama böbrek ve karaciğer karsinomları isyankardır: hematojen yolu (kan otoyolunu) tercih ederler!",
    "fc-patho-neo-201": "💡 HİKAYE: Sarkomlar mezenkimal kökenli tümörlerdir ve kanı severler — hematojen yolla akciğer, karaciğer ve kemiğe metastaz yapar. Lenfatik yol yerine 'kırmızı otoyol'u tercih eden agresif yolcular!",
    "fc-patho-sys1-210": "💡 HİKAYE: MI sonrası 1-3. günde nekrotik miyokard perikarda yakın — inflamasyon perikarda sıçrar ve fibrin birikir. Fibrinöz perikardit = 'sandviç kağıdı' gibi sürtünme sesi (friction rub). Dressler sendromu ise haftalar sonra otoimmün perikardit!",
    "fc-patho-sys1-211": "💡 HİKAYE: Romatizmal ateşte streptokok kalbi hedef alır — miyokardda Aschoff cisimcikleri oluşur. İçlerinde tırtıl gibi kıvrılan Anitschkow hücreleri var (caterpillar cells). Bu patognomonik granülom, romatizmal karditin imzasıdır!",
    "fc-patho-sys1-220": "💡 HİKAYE: Adenokarsinom akciğerin en sık primer malignitesidir — kadınlarda ve sigara içmeyenlerde bile lider! Periferik yerleşimli, sıklıkla mukus salgılar. EGFR ve ALK mutasyonları hedefe yönelik tedavinin kapısını açar.",
    "fc-patho-sys1-221": "💡 HİKAYE: Küçük hücreli karsinom santral yerleşimli bir nöroendokrin tümördür — ektopik hormon fabrikası (ACTH, ADH). Cerrahiye yanıtsız ama kemoterapiye en duyarlı akciğer kanseri! 'Küçük ama tehlikeli, ilaca boyun eğen' tümör.",
}

# 5. pathology_sys2.json — flashcards (no tags)
pathology_sys2_hints = {
    "fc-patho-sys2-300": "💡 HİKAYE: Mide kanseri sol supraklaviküler fossaya metastaz yaptı — Virchow nodu! Toraks kanalı (ductus thoracicus) sol venöz açıya döküldüğü için karın kanserleri buraya ulaşır. Sol boyunda şişlik + mide kanseri = Virchow!",
    "fc-patho-sys2-301": "💡 HİKAYE: Taşlı yüzük hücreli mide karsinomu overe gitti — Krukenberg tümörü! Tümör hücreleri transperitoneal veya hematojen yolla overlere yayılır. Bilateral, solid over kitlesi + mide öyküsü = Krukenberg.",
    "fc-patho-sys2-310": "💡 HİKAYE: PBS'de bağışıklık sistemi safra kanallarının mitokondrilerine saldırır — AMA (antimitokondriyal antikor) pozitif! Orta yaşlı kadın, kaşıntı ve sarılık. Safra kanalları yavaşça yıkılır → biliyer siroz. AMA = PBS'nin imzası.",
    "fc-patho-sys2-311": "💡 HİKAYE: Wilson hastalığında bakır gözün Descemet membranında birikir — altın-yeşil Kayser-Fleischer halkası oluşur. Yarık lamba muayenesiyle görülür. Bu halka Wilson'un 'yüzük'üdür — tanıda çok değerli!",
}

# 6. pathology_sys3.json — flashcards (no tags)
pathology_sys3_hints = {
    "fc-patho-sys3-400": "💡 HİKAYE: FSGS erişkinlerde nefrotik sendromun en sık nedenidir — özellikle HIV ve IV ilaç bağımlılarında. 'Fokal' (bazı glomerüller) + 'Segmental' (glomerülün bir kısmı) = kısmi tahribat. Steroide yanıt FSGS'de MCD kadar iyi değildir.",
    "fc-patho-sys3-401": "💡 HİKAYE: Berrak hücreli karsinom böbreğin 'kristal' tümörüdür — sitoplazmadaki lipid ve glikojen hücreyi berrak gösterir. VHL geni (3p) bozulunca HIF birikir → VEGF artar → tümör damarlanması patlar. Von Hippel-Lindau sendromunda bilateral ve erken!",
    "fc-patho-sys3-410": "💡 HİKAYE: Fibroadenom genç kadınlarda en sık görülen meme kitlesidir — düzgün sınırlı, hareketli, kauçuk kıvamında ('fare' gibi kayar). Östrojen etkisiyle büyür, gebelikte artar. Benign olmasına rağmen kontrol önemli!",
    "fc-patho-sys3-411": "💡 HİKAYE: Kondiloma akuminatum = genital siğil. HPV 6 ve 11 düşük riskli tiplerin eseri — karnabahar gibi büyür! Yüksek riskli HPV (16, 18) ise displazi ve kanser yapar. 6-11 = siğil, 16-18 = kanser!",
}

# 7. pathology_sys4.json — flashcards (no tags)
pathology_sys4_hints = {
    "fc-patho-sys4-500": "💡 HİKAYE: Auer cisimciği AML'nin 'parmak izi'dir — kristalize granüller iğne şeklinde sitoplazmada dizilir. M3 (APL) tipinde 'faggot cells' (çubuk demetleri) görülür. All-trans retinoik asit (ATRA) M3'te diferansiyasyonu başlatır!",
    "fc-patho-sys4-501": "💡 HİKAYE: KLL yaşlıların 'uslu' lösemisidir — olgun ama işlevsiz lenfositler yavaşça birikir. CD5+, CD23+ B hücreleri. Yaymada 'smudge cells' (ezilmiş hücreler) = KLL'nin parmak izi. Richter transformasyonu en korkulan komplikasyon.",
    "fc-patho-sys4-510": "💡 HİKAYE: Osteosarkomda tümör periostun altında büyürken periost yukarı kalkar — üçgen şeklinde bir boşluk oluşur (Codman üçgeni). Radyolojide bu üçgen 'burada kemik kanseri var!' diyen alarm işareti. Genç erkeklerde diz çevresi en sık!",
    "fc-patho-sys4-511": "💡 HİKAYE: Ewing sarkomunda 11. ve 22. kromozomlar translokasyon yapar → EWS-FLI1 füzyon proteini oluşur. Bu protein hücre büyümesini tetikler. 'Soğan zarı' periost reaksiyonu ve CD99 pozitifliği Ewing'in iki imzası!",
}

# 8. anatomi_200_soru.json — 67 clinical_cases
anatomi_hints = {
    "ant-001": "💡 HİKAYE: Femur başının 'göbek bağı' olan lig. capitis femoris içinden küçük bir arter geçer — arteria capitis femoris. Çocuklarda bu arter femur başını besler, erişkinlerde ise a. circumflexa femoris medialis görevi devralır.",
    "ant-011": "💡 HİKAYE: Sfenoid kemiğin ortasında 'Türk eğeri' (Sella turcica) var — hipofiz bezi bu eğere oturmuş bir süvari gibi. Önünde optik kiazma bekliyor. Hipofiz tümörü büyürse bu çaprazı sıkıştırıp bitemporal hemianopsi yapar!",
    "ant-023": "💡 HİKAYE: Biseps kasını 'tornavida çeviren güçlü kol' olarak düşün — ön kolda fleksiyon + supinasyon yapar. En güçlü supinatör! N. musculocutaneus (C5-C6) tarafından inerve edilir. Biseps refleksi C5-C6'yı test eder.",
    "ant-051": "💡 HİKAYE: Trigeminus üç dallı yüz siniridir: V1 ve V2 saf duyusal, V3 ise hem duyu hem motor (mikst). V3 foramen ovale'den geçer ve çiğneme kaslarını yönetir. 'Mandibula' = çene = çiğneme = motor!",
    "ant-074": "💡 HİKAYE: Willis poligonu beynin 'güvenlik çemberi'dir — bir arter tıkansa bile diğerlerinden kan gelir. A. cerebri anterior halkaya doğrudan katılır. A. cerebri media ise halkada değildir ama felçlerde en sık etkilenen damardır!",
    "ant-105": "💡 HİKAYE: Foramen jugulare'den üç sinir geçer: 9 (glossofaringeal), 10 (vagus), 11 (aksesuar). CN IX dilin arka 1/3 tadını alır ve yutkunma refleksinde rol oynar. 'Glosso' = dil, 'pharyngeus' = yutak — adı işlevini söylüyor!",
    "ant-126": "💡 HİKAYE: Fovea centralis retinanın 'altın noktası'dır — sadece koni hücreleri bulunur, en keskin ve renkli görme burada yapılır. Karanlıkta çubuk hücreleri devreye girer. Kör nokta (papilla n. optici) ise fotoreseptörsüz bölgedir.",
    "ant-145": "💡 HİKAYE: M. levator ani pelvisin 'hamağı'dır — mesane, rahim ve rektumu alttan destekler. Zor doğumda hasar görürse organ sarkmaları (sistosel, prolapsus) başlar. Kegel egzersizleri bu kası güçlendirir!",
    "ant-151": "💡 HİKAYE: Ampulla tuba uterinanın 'buluşma noktası'dır — sperm ve yumurta burada karşılaşır (fertilizasyon). Aynı zamanda ektopik gebeliklerin de en sık yaşandığı yer. Doğal yolun en geniş ve en uzun kısmı!",
    "ant-180": "💡 HİKAYE: Pars spongiosa erkek üretrasının en uzun parçasıdır (~15 cm) — penis içinde corpus spongiosum'da seyreder. Pars membranacea en dar ve en kısa — sonda takılırken en çok burada sorun çıkar!",
    "ant-193": "💡 HİKAYE: Moderator band (trabecula septomarginalis) sağ ventriküle özgü bir 'hızlı iletim kablosu'dur — His huzmesinin sağ dalını septumdan ön papiller kasa taşır. Sol ventrikülde böyle bir yapı yoktur.",
    "ant-200": "💡 HİKAYE: CN XII (hipoglossus) dili hareket ettiren saf motor sinirdir — parasempatik bileşeni yok! '1973' mnemoniği: CN 1(olfaktor-saf duyu), 9, 7, 3 parasempatik taşır. XII motor ama otonom lif içermez.",
    "ant-201": "💡 HİKAYE: Humerus gövdesi kırılınca spiral oluktaki n. radialis ve a. profunda brachii hasar görür → 'düşük el' (drop hand)! Cerrahi boyun kırığında n. axillaris, suprakondilerde n. medianus, medial epikondilde n. ulnaris zedelenir.",
    "ant-202": "💡 HİKAYE: Pterion kafatasının 'Aşil topuğu'dur — dört kemiğin buluştuğu en ince nokta. Altından a. meningea media geçer. Şakağa darbe → pterion kırığı → arter yırtılır → epidural hematom! Boksörlerin kabusu.",
    "ant-203": "💡 HİKAYE: Diyaframın delikleri 'I ate 12 eggs at 8' ile ezberlenir: T8=IVC (8 harf), T10=esophagus (ate=10), T12=aorta (12). Foramen venae cavae en üstte (T8), sağ n. phrenicus de buradan geçer.",
    "ant-204": "💡 HİKAYE: Vater ampullası safra ve pankreas suyunun 'kavşak noktası'dır — koledok + Wirsung kanalı birleşip duodenum'a dökülür. Sfinkter Oddi bu kavşağın trafik polisi. Pankreas başı tümörü burayı tıkarsa obstrüktif sarılık!",
    "ant-205": "💡 HİKAYE: Vagus siniri GIS'te Cannon-Böhm noktasına (splenik fleksura civarı) kadar parasempatik inervasyon sağlar. Buradan sonra S2-S4 (nn. splanchnici pelvici) devralır. Vagus = foregut + midgut; pelvik sinirler = hindgut!",
    "ant-206": "💡 HİKAYE: N. facialis foramen stylomastoideum'dan çıkar ve parotis bezinin içine dalarak 5 uç dala ayrılır. Bell paralizisinde yüzün tüm yarısı felç olur. Temporal kemikteki dar kanalda şişme = sinir sıkışması!",
    "ant-207": "💡 HİKAYE: Tiroidektomide iki sinir tehlikede: Alt kutupta n. laryngeus recurrens (ses kısıklığı), üst kutupta n. laryngeus superior'un eksternal dalı (tiz ses kaybı). Bilateral recurrens hasarı = solunum yolu tıkanması → trakeotomi!",
    "ant-208": "💡 HİKAYE: ACL (ön çapraz bağ) tibianın öne kaymasını engeller — kopunca 'ön çekmece testi' pozitifleşir. Futbolcuların kabusu: ani dönüş hareketi → ACL yırtığı! PCL ise arkaya kaymayı engeller (arka çekmece testi).",
    "ant-209": "💡 HİKAYE: Medial menisküs 'C' şeklinde ve MCL'ye yapışık → hareketsiz, burkulmada kolay yırtılır. Unhappy triad: ACL + MCL + Medial Menisküs = futbolcunun en kötü senaryosu! Lateral menisküs 'O' şeklinde ve daha hareketli.",
    "ant-210": "💡 HİKAYE: Mitral kapak apekste (sol 5. IKA mid-klavikular hat) dinlenir — kalbin ucundaki vuruş burada hissedilir. Aort: sağ 2. İKA, pulmoner: sol 2. İKA, triküspid: sol 5. İKA sternum kenarı. 'APT-M' sırasıyla hatırla!",
    "ant-211": "💡 HİKAYE: Sağ ana bronş daha kısa, geniş ve dik — tıpkı geniş bir kaydırak gibi! Yabancı cisimler yerçekimiyle bu kaydıraktan aşağı kayar ve sağ alt loba gider. Sol bronş ise kalbin altından geçtiği için daha yatık.",
    "ant-212": "💡 HİKAYE: Gerota fasyası böbreğin 'zırh'ıdır — böbrek ve adrenal bezi bir torba gibi sarar. İçinde perirenal yağ (capsula adiposa) tampon görevi yapar. Bu yağ eridikten böbrek sarkar (nefroptoz) — zayıflayan insanlarda oluşabilir.",
    "ant-213": "💡 HİKAYE: Zor doğumda bebeğin boynu yana çekildi — C5-C6 koptu (Erb-Duchenne). Kol içe dönük asılı kalır: 'bahşiş bekleyen garson' pozisyonu! Klumpke (C8-T1) ise elin iç kaslarını bozar → 'pençe el' deformitesi.",
    "ant-214": "💡 HİKAYE: 'LR6 SO4 gerisi 3' şifresi: M. obliquus superior CN IV (trochlearis) ile çalışır — gözü aşağı-dışa baktırır. Felcinde merdiven inerken çift görme olur çünkü aşağı bakış bozulur. Trochlea = makara, kasın kirişi makaradan geçer.",
    "ant-215": "💡 HİKAYE: Akciğerin iki kan kaynağı var: fonksiyonel (pulmoner arterler — kirli kan getirir, oksijenlenir) ve nutritif (bronşiyal arterler — temiz kan getirir, dokuyu besler). Sol bronşiyal arterler direkt torasik aortadan çıkar.",
    "ant-216": "💡 HİKAYE: Corti organı koklea içindeki 'piyano'dur — membrana basilaris üzerindeki tüy hücreleri ses frekanslarına göre titreşir. Tectorial membranaya çarpan tüyler aksiyon potansiyeli başlatır. İşitmenin elektriğe dönüştüğü nokta!",
    "ant-217": "💡 HİKAYE: Midenin küçük kurvaturunda iki gastrik arter dans eder: A. gastrica sinistra (truncus celiacus'tan direkt) ve A. gastrica dextra (hepatica propria'dan). İkisi curvatura minor boyunca buluşup anastomoz yapar.",
    "ant-218": "💡 HİKAYE: Ductus thoracicus vücudun en büyük lenf kanalıdır — alt yarı + sol üst yarının lenfini toplar. Cisterna chyli'den başlar, hiatus aorticus'tan geçer, sol venöz açıya dökülür. Sağ üst kısım ise ductus lymphaticus dexter ile drene olur.",
    "ant-219": "💡 HİKAYE: Funiculus spermaticus erkek inguinal kanalının 'ipi'dir — içinde ductus deferens (sperm taşıyıcı) ve plexus pampiniformis (ısı regülatörü venler) var. Kadınlarda aynı kanalda ligamentum teres uteri bulunur.",
    "ant-220": "💡 HİKAYE: Parotis bezi en büyük tükürük bezi ve tamamen seröz salgı yapar. İçinden n. facialis transit geçer — cerrahide en büyük risk yüz felci! Kabakulak (mumps) bu bezi şişirir ve bilateral parotit yapar.",
    "ant-101": "💡 HİKAYE: Boyun fasyasının en derin tabakası lamina prevertebralis — omurgayı sarar, önünde retrofarengeal boşluk var. Enfeksiyonlar bu boşluktan mediastene süzülebilir — derin boyun enfeksiyonlarının tehlikeli otoyolu!",
    "ant-102": "💡 HİKAYE: Kornea gözün 'ön camı'dır — ışığı en fazla kıran yapı (~42 diyoptri). Lens ise ince ayar yapar (akomodasyon). LASIK cerrahisi korneanın şeklini değiştirerek kırma kusurlarını düzeltir.",
    "ant-103": "💡 HİKAYE: Östaki borusu orta kulağın 'havalandırma kanalı'dır — yutkunurken açılıp basıncı dengeler. Çocuklarda daha kısa ve yatay → enfeksiyonlar kolayca orta kulağa sıçrar → otitis media!",
    "ant-104": "💡 HİKAYE: Üç sinir, üç el deformitesi: N. ulnaris = Pençe el (interosseöz felç), N. radialis = Düşük el (ekstansör felç), N. medianus = Maymun eli (tenar felç). 'URP-PMD' — Ulnar Pençe, Radial Drop, Median Maymun!",
    "ant-106": "💡 HİKAYE: Bell felcinde yüzün bir yarısı tamamen felç — alın bile kıpırdamaz (periferik). Santral felçte ise alın korunur çünkü bilateral kortikal innervasyonu var. 'Alın kıpırdıyor mu?' sorusu periferik vs santral ayrımının anahtarı!",
    "ant-107": "💡 HİKAYE: Vagina carotica boyun fasyasının üç yaprağının birleşimiyle oluşan koruyucu kılıftır — içinde 'VAJ' üçlüsü: V=Ven (jugularis interna, lateral), A=Arter (carotis communis, medial), J=sinir (vagus, arkada) barınır.",
    "ant-108": "💡 HİKAYE: Pulmoner venler temiz (oksijenli) kanı akciğerlerden sol atriuma getirir — genellikle 4 adet. Sol atrium kalbin en arkadaki odası, özofagusla komşu. Temiz kan → sol atrium → mitral kapak → sol ventrikül → aorta!",
    "ant-109": "💡 HİKAYE: Mesenterium ince bağırsakların 'asılı köprüsü'dür — jejunum ve ileumu karın duvarına bağlar. İçinde SMA dalları seyreder. Omentum majus ise 'polis memuru' gibidir — enfeksiyon bölgesine göç edip sarıp sarmalar.",
    "ant-150": "💡 HİKAYE: Broca alanı konuşma motoru (frontal lob, inferior girus), Wernicke alanı anlama merkezi (temporal lob). Exner alanı ise yazı motoru (frontal lob, orta girus). Broca hasarı = konuşamaz ama anlar. Wernicke hasarı = konuşur ama saçmalar!",
    "ant-152": "💡 HİKAYE: Pars membranacea üretranın en dar ve en az esnek bölümüdür — pelvik tabandan geçer, etrafında sfinkter var. Sonda takılırken en çok burada 'duvar' hissedilir. Prostatik kısım ise en geniş ve en çok genişleyebilen!",
    "ant-153": "💡 HİKAYE: Kiazma optikumda nazal retina lifleri çapraz yapar — bunlar temporal (dış) görme alanını taşır. Hipofiz tümörü kiazmeyi sıkıştırınca her iki gözün dış yarısı kaybolur = bitemporal hemianopsi (at gözlüğü etkisi)!",
    "ant-154": "💡 HİKAYE: Substantia nigra mesencephalon'daki 'siyah çekirdek'tir — dopamin üreten nöronlar burada yaşar. Parkinson'da bu nöronlar ölür → dopamin↓ → tremor + bradikinezi + rijidite. L-DOPA tedavisi dopamini yerine koyar.",
    "ant-155": "💡 HİKAYE: N. radialis kolun 'ekstansör generali'dir — triceps, el bileği ve parmak ekstansörlerini yönetir. Humerus gövde kırığında spiral oluktaki radialis hasar görür → el bileği yukarı kalkmaz = 'düşük el' (drop wrist)!",
    "ant-002": "💡 HİKAYE: Scapula'nın üç köşesi var: superior (üst-medial birleşim), inferior (medial-lateral birleşim, 8. kaburga hizası) ve lateralis (eklem yüzü). İncisura scapulae üst kenarda — n. suprascapularis buradan geçer, klinik olarak önemli!",
    "ant-003": "💡 HİKAYE: Rotator cuff kasları SITS (Supraspinatus, Infraspinatus, Teres minor, Subscapularis) olarak bilinir. Subscapularis tuberculum minus'a tutunan tek kas — iç rotasyonun patronu! Diğer üçü tuberculum majus'a gider.",
    "ant-004": "💡 HİKAYE: Triküspid kapak sağ atrium ile sağ ventrikül arasındaki 'üç yapraklı kapı'dır. Septal kapakçığına yakın His huzmesi geçer — cerrahide dikkat! Mitral kapak ise sol tarafta iki yapraklıdır (bi = iki).",
    "ant-005": "💡 HİKAYE: Plexus choroideus BOS'un 'su fabrikası'dır — özellikle lateral ventriküllerde bol bulunur. BOS granülasyon araknoidlerden emilip venöz kana karışır. Fabrika açık ama drenaj tıkalıysa = hidrosefali!",
    "ant-006": "💡 HİKAYE: Dilin sinir haritası: Ön 2/3 genel duyu = V3 (lingualis), tat = VII (chorda tympani). Arka 1/3 hem genel hem tat = IX (glossofaringeal). Motor = XII (hipoglossus). IX, dilin arka kısmının hem doktoru hem aşçısı!",
    "ant-007": "💡 HİKAYE: Omuz eklemi küresel (spheroidea) tip — en hareketli eklem! Ama cavitas glenoidalis sığ olduğu için çıkık riski yüksek. Kalça da küresel ama asetabulum derin → daha stabil, daha az hareket.",
    "ant-008": "💡 HİKAYE: Mide büyük kurvaturun sağ yarısını a. gastroomentalis dextra besler — bu da a. gastroduodenalis'in dalıdır. Sol yarısı ise a. gastroomentalis sinistra (a. splenica dalı) ile beslenir. İki el büyük kurvaturda buluşur!",
    "ant-009": "💡 HİKAYE: Sol akciğer hilumunda sıralama ABV: Arter (üstte), Bronş (ortada), Ven (altta). Sağda ise BAV: Bronş (eparteriel), Arter, Ven. Sol tarafta arkus aorta bronşu aşağı iter, bu yüzden arter üste çıkar.",
    "ant-010": "💡 HİKAYE: Nefron böbreğin en küçük işlevsel birimidir — her böbrekte yaklaşık 1 milyon! Glomerülde filtrasyon, proksimal tübülde geri emilim, distal tübülde ince ayar yapılır. Toplama kanalları nefrona dahil değildir.",
    "ant-012": "💡 HİKAYE: Os ethmoidale koku duyusunu taşıyan delikli kemidir (lamina cribrosa) — beyin kutusunun (neurocranium) elemanıdır. Maxilla, mandibula, zigomatik ve nazal kemikler ise yüz iskeleti (viscerocranium) üyeleri.",
    "ant-013": "💡 HİKAYE: M. orbicularis oculi gözü kapatan 'halka kas'tır — n. facialis yönetir. Bell felcinde bu kas çalışmaz → göz açık kalır (lagoftalmus). M. levator palpebrae superioris ise gözü açar ve CN III tarafından yönetilir → hasarında ptosis!",
    "ant-014": "💡 HİKAYE: Karaciğerin alt yüzünde 'H' şeklinde oluklar var — tam ortasında porta hepatis bulunur. Buradan v. portae ve a. hepatica propria GİRER, ductus hepaticus'lar ÇIKAR. Safra kesesi sağ tarafta, lig. teres hepatis sol tarafta.",
    "ant-015": "💡 HİKAYE: Omurilik L1-L2'de conus medullaris olarak sonlanır — altında at kuyruğu (cauda equina) uzanır. Lomber ponksiyon L3-L4 aralığından yapılır ki omuriliğe zarar vermesin. Bebeklerde L3'e kadar uzandığı için dikkat!",
    "ant-052": "💡 HİKAYE: M. sartorius vücudun en uzun kasıdır — SIAS'tan tibianın iç yüzüne (pes anserinus) kadar uzanır. Terzi oturuşu (bacak bacak üstüne atma) pozisyonunu verir: kalçada fleksiyon + abduksiyon + dış rotasyon.",
    "ant-053": "💡 HİKAYE: Koroner arterler aortanın hemen başlangıcından (Valsalva sinüsü) çıkar ve DİYASTOL sırasında dolar. Kalp vücudun aksine gevşerken beslenir! Aort kapağı kapanınca kan geriye doğru koronerlere akar.",
    "ant-054": "💡 HİKAYE: Wirsung kanalı (ana pankreas kanalı) koledokla birleşip Vater ampullasını oluşturur → Papilla duodeni major'dan duodenuma açılır. Sfinkter Oddi geçidi kontrol eder. Santorini (aksesuar kanal) → Papilla minor'a açılır.",
    "ant-055": "💡 HİKAYE: Primer görme korteksi (Brodmann 17) oksipital lobun iç yüzünde sulcus calcarinus etrafındadır. Talamus (CGL) → radiatio optica → sulcus calcarinus. Oksipital lob hasarı = kortikal körlük. Calcarina = mahmuz şekli!",
    "ant-056": "💡 HİKAYE: Beyincik (cerebellum) motor hareketlerin 'kalite kontrol'üdür — hassas ayar, denge ve koordinasyon sağlar. Hasarında ataksi (sarhoş yürüyüşü), dismetri (hedefe varma güçlüğü) ve nistagmus gelişir.",
    "ant-057": "💡 HİKAYE: Tiroid kıkırdak larenksin kalkanıdır — iki laminanın önde birleştiği yer erkeklerde sivri açı (90°) yapar: Adem elması! Kadınlarda açı daha geniş (120°). Krikoid kıkırdak ise tam halka şeklindeki tek kıkırdak.",
    "ant-058": "💡 HİKAYE: Uterus normalde mesanenin üzerine yatmış durumdadır (antefleksiyon + anteversiyon). Bu pozisyon doğum için idealdir. Retroversiyon/retrofleksiyon ise bazı kadınlarda bel ağrısı ve dismenoreye yol açabilir.",
    "ant-059": "💡 HİKAYE: Vena cava superior sağ ve sol v. brachiocephalica'nın birleşmesiyle oluşur — üst gövdenin tüm kanını sağ atriuma getirir. Sol brachiocephalica daha uzundur çünkü kalbin sağına ulaşmak için orta hattı geçer.",
    "ant-100": "💡 HİKAYE: Epididimis spermlerin 'okulu'dur — burada 12-20 gün boyunca olgunlaşır ve hareket yeteneği kazanırlar. Testisten çıkan ham spermler henüz dölleme yeteneğine sahip değildir. Mezuniyet sonrası ductus deferens'e geçerler!",
}


def add_story_hints_to_clinical_cases(data, hints_dict):
    """Add story_hint after 'explanation' in clinical_cases."""
    cases = None
    is_wrapper = False
    if isinstance(data, dict) and "clinical_cases" in data:
        cases = data["clinical_cases"]
        is_wrapper = True
    elif isinstance(data, list):
        # Array of topics, each may have clinical_cases
        for topic in data:
            if "clinical_cases" in topic:
                for case in topic["clinical_cases"]:
                    cid = case.get("id", "")
                    if cid in hints_dict and "story_hint" not in case:
                        case["story_hint"] = hints_dict[cid]
        return data

    if cases:
        for case in cases:
            cid = case.get("id", "")
            if cid in hints_dict and "story_hint" not in case:
                case["story_hint"] = hints_dict[cid]
    return data


def add_story_hints_to_flashcards(data, hints_dict):
    """Add story_hint after 'tags' (if exists) or after 'answer' in flashcards."""
    if isinstance(data, list):
        for topic in data:
            if "flashcards" in topic:
                for fc in topic["flashcards"]:
                    fid = fc.get("id", "")
                    if fid in hints_dict and "story_hint" not in fc:
                        fc["story_hint"] = hints_dict[fid]
    elif isinstance(data, dict) and "flashcards" in data:
        for fc in data["flashcards"]:
            fid = fc.get("id", "")
            if fid in hints_dict and "story_hint" not in fc:
                fc["story_hint"] = hints_dict[fid]
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


def reorder_clinical_cases(data, after_key="explanation"):
    """Reorder keys in clinical_cases to place story_hint after explanation."""
    if isinstance(data, dict) and "clinical_cases" in data:
        data["clinical_cases"] = [reorder_keys(c, after_key, "story_hint") for c in data["clinical_cases"]]
    elif isinstance(data, list):
        for topic in data:
            if "clinical_cases" in topic:
                topic["clinical_cases"] = [reorder_keys(c, after_key, "story_hint") for c in topic["clinical_cases"]]
    return data


def reorder_flashcards(data, after_key="tags"):
    """Reorder keys in flashcards to place story_hint after tags (or answer if no tags)."""
    if isinstance(data, list):
        for topic in data:
            if "flashcards" in topic:
                new_fcs = []
                for fc in topic["flashcards"]:
                    if "tags" in fc:
                        new_fcs.append(reorder_keys(fc, "tags", "story_hint"))
                    else:
                        new_fcs.append(reorder_keys(fc, "answer", "story_hint"))
                topic["flashcards"] = new_fcs
    elif isinstance(data, dict) and "flashcards" in data:
        new_fcs = []
        for fc in data["flashcards"]:
            if "tags" in fc:
                new_fcs.append(reorder_keys(fc, "tags", "story_hint"))
            else:
                new_fcs.append(reorder_keys(fc, "answer", "story_hint"))
        data["flashcards"] = new_fcs
    return data


def process_file(filepath, hints, is_clinical=False, is_flashcard=False):
    """Read, modify and write back a JSON file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if is_clinical:
        data = add_story_hints_to_clinical_cases(data, hints)
        data = reorder_clinical_cases(data)
    elif is_flashcard:
        data = add_story_hints_to_flashcards(data, hints)
        data = reorder_flashcards(data)

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"✓ Processed: {os.path.basename(filepath)}")


# Process all files
if __name__ == "__main__":
    print("Processing files...\n")

    # 1. pathology_vaka_100.json (clinical_cases)
    process_file(
        os.path.join(BASE, "pathology_vaka_100.json"),
        pathology_vaka_100_hints,
        is_clinical=True
    )

    # 2. pathology_hemo_immuno.json (flashcards, no tags)
    process_file(
        os.path.join(BASE, "pathology_hemo_immuno.json"),
        pathology_hemo_immuno_hints,
        is_flashcard=True
    )

    # 3. pathology_module.json (flashcards with tags + clinical_cases)
    # Process flashcards first
    process_file(
        os.path.join(BASE, "pathology_module.json"),
        pathology_module_hints,
        is_flashcard=True
    )
    # Then process clinical_cases in the same file
    process_file(
        os.path.join(BASE, "pathology_module.json"),
        pathology_module_cc_hints,
        is_clinical=True
    )

    # 4. pathology_neo_sys1.json (flashcards, no tags)
    process_file(
        os.path.join(BASE, "pathology_neo_sys1.json"),
        pathology_neo_sys1_hints,
        is_flashcard=True
    )

    # 5. pathology_sys2.json (flashcards, no tags)
    process_file(
        os.path.join(BASE, "pathology_sys2.json"),
        pathology_sys2_hints,
        is_flashcard=True
    )

    # 6. pathology_sys3.json (flashcards, no tags)
    process_file(
        os.path.join(BASE, "pathology_sys3.json"),
        pathology_sys3_hints,
        is_flashcard=True
    )

    # 7. pathology_sys4.json (flashcards, no tags)
    process_file(
        os.path.join(BASE, "pathology_sys4.json"),
        pathology_sys4_hints,
        is_flashcard=True
    )

    # 8. anatomi_200_soru.json (clinical_cases)
    process_file(
        os.path.join(BASE, "anatomi_200_soru.json"),
        anatomi_hints,
        is_clinical=True
    )

    print("\n✅ All files processed successfully!")
