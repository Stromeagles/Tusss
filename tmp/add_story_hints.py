import json
import os

# Story hints for each file, keyed by card id
story_hints = {
    # ========== pathology_batch1A.json (51 cards) ==========
    "path_b1A_001": "💡 HİKAYE: Bir adam yıllarca mide asidini özofagusuna geri gönderdi (GÖRH). Özofagus sonunda 'Tamam, mide olmak istiyorsan ol' dedi ve hücreleri intestinal tipe dönüştü (Barrett). Ama bu dönüşüm kontrolden çıkınca adenokarsinom doğdu — reflünün intikamı!",
    "path_b1A_002": "💡 HİKAYE: Özofagus bir bina gibi düşünülürse, skuamöz karsinom orta katta (orta 1/3) oturmayı sever. Adeno ise bodrum katı (alt 1/3) tercih eder. 'S-O, A-A' diye kapıda yazılıdır: Skuamöz=Orta, Adeno=Alt.",
    "path_b1A_003": "💡 HİKAYE: Auerbach pleksusundaki NO üreten nöronlar, özofagusun kapısının kapıcılarıdır. Chagas hastalığı veya idiopatik nedenle kapıcılar öldüğünde, kapı (alt özofageal sfinkter) bir daha açılamaz — yemek yukarıda mahsur kalır.",
    "path_b1A_004": "💡 HİKAYE: Bir adam gece alkol partisinden sonra şiddetle kusmaya başladı. Her kusma, mide-özofagus bileşkesini bir fermuar gibi yırttı. Mallory ve Weiss adında iki doktor bu fermuarı keşfetti — şiddetli kusmanın bileşkeyi yırtmasını tarif ettiler.",
    "path_b1A_005": "💡 HİKAYE: Karaciğer sirozu olan bir hastada portal ven tıkandı. Kan alternatif yollar aradı ve özofagusun alt kısmındaki ince venlere doluştu. Bu venler balon gibi şişti (varis) ve patladığında masif hematemez — portal hipertansiyonun kanlı bedeli!",
    "path_b1A_006": "💡 HİKAYE: H. pylori ordusunun generali CagA, mide hücresine şırınga ile NF-κB bombası enjekte eder. NF-κB aktive olunca IL-8 sirenleri çalar ve nötrofil askerleri savaş alanına koşar — inflamasyon başlar!",
    "path_b1A_007": "💡 HİKAYE: H. pylori midede kamp kurduğunda, bağışıklık sistemi orada lenfoid foliküller (küçük kışlalar) inşa eder. Nötrofiller sürekli devriye gezer — bu aktif kronik gastrit manzarasıdır ve MALT lenfomasının zeminini hazırlar.",
    "path_b1A_008": "💡 HİKAYE: MALT lenfoma H. pylori'nin beslenme çiftliğidir. B hücreleri bu bakteri antijenine bağımlı büyür. Antibiyotikle H. pylori öldürüldüğünde, tarlayı besleyen su kesilmiş gibi olur — tümör besinsiz kalıp küçülür.",
    "path_b1A_009": "💡 HİKAYE: Otoimmün gastrit (Tip A) olan bir kadının vücudu kendi parietal hücrelerine saldırdı. Parietal hücreler öldüğünde intrinsik faktör üretimi durdu. B12 emilemeyen vücut, kocaman kırmızı hücreler üretti (megaloblastik) — pernisiyöz aneminin doğuşu!",
    "path_b1A_010": "💡 HİKAYE: Menetrier hastalığında mide duvarındaki rugalar dev boyuta ulaştı — sanki midede dağlar yükseldi. Bu devasa foveolar hiperplazi proteinleri dışarı sızdırdı ve hasta hipoalbüminemi ile şişmeye başladı. TGF-α'nın aşırı üretimi suçludur.",
    "path_b1A_011": "💡 HİKAYE: Diffüz tip mide kanserinde taşlı yüzük hücreleri mide duvarının her katmanına sızdı. Mide esnekliğini kaybedip sert bir deri çantaya dönüştü — buna linitis plastica denir. E-kaderin kaybı hücrelerin yapışkanlığını bozar.",
    "path_b1A_012": "💡 HİKAYE: Midedeki taşlı yüzük hücreli adenokarsinom gizlice kan yoluyla seyahat etti ve her iki overe yerleşti. Bilateral over metastazı yapan bu müsinöz tümöre Krukenberg tümörü dendi — mide kanserinin overe gizli göçü.",
    "path_b1A_013": "💡 HİKAYE: Duodenal ülserli hasta yemek yediğinde rahatladı — çünkü yemek asidi tamponladı. Mide ülserli hasta ise yemekle daha çok acı çekti. Duodenal ülser asla kanserleşmez — mide ülserinden farklı olarak masum kalır.",
    "path_b1A_014": "💡 HİKAYE: Çölyak hastasının bağırsağında glutene karşı T hücreleri savaş açtı. Villüsler eriyen buz dağları gibi atrofiye uğradı, kriptler telafi için uzadı. İntraepitelyal lenfositler 25'i aştığında tanı kesinleşti.",
    "path_b1A_015": "💡 HİKAYE: Anti-tTG IgA, çölyak hastalığının dedektifidir. Hem tanıyı koyar hem tedavi takibini yapar. Hasta glutensiz diyete geçtiğinde bu dedektifin raporu (titre) düşer — hastalık kontrol altında demektir.",
    "path_b1A_016": "💡 HİKAYE: Crohn hastalığı 'tam deli' gibi tüm duvar katmanlarını geçer (transmural) ve atlama lezyonları yapar. ÜK ise sadece yüzeyde kalır (mukoza-submukoza). Crohn granülom yapar, ÜK ise kript absesi — iki düşman kardeş.",
    "path_b1A_017": "💡 HİKAYE: Crohn hastalığı bağırsağın köşesine sıkışmayı sever — terminal ileum onun favori yeridir. Hastaların %85-90'ında bu bölge tutulur. Terminal ileum Crohn'un evi, rektum ise ÜK'nın evidir.",
    "path_b1A_018": "💡 HİKAYE: ÜK'lı bir hasta 10 yıldan fazla pankolitle yaşadıysa ve üstüne PSC de eklendiyse, kolon kanseri kapıyı çalıyor demektir. Bu üç faktör (süre + yaygınlık + PSC) bir araya geldiğinde displazi taraması şarttır.",
    "path_b1A_019": "💡 HİKAYE: Apandisitin histolojik tanısı için nötrofillerin muskularis propriaya (kas tabakasına) ulaşması gerekir. Sadece mukozada nötrofil görmek yeterli değildir — nötrofil kasa girmediyse apandisit denmez.",
    "path_b1A_020": "💡 HİKAYE: Hirschsprung bebeğinde rektosigmoid bölgedeki ganglion hücreleri hiç oluşmadı. Ganglion yoksa peristaltizm yok — bağırsak o bölgede kasılıp gevşeyemez. Proksimalde bağırsak şişer ama distal segment dar kalır.",
    "path_b1A_021": "💡 HİKAYE: APC geni 5q21'de oturan bir bekçidir. Bu bekçi mutasyona uğradığında kolonda yüzlerce adenom (polip) oluşur — FAP. Tedavi edilmezse 40 yaşında %100 kanser garantisi. Profilaktik kolektomi hayat kurtarır.",
    "path_b1A_022": "💡 HİKAYE: Lynch sendromu MMR genlerinde (MLH1, MSH2, PMS2) mutasyon taşır. DNA'daki yazım hatalarını düzeltemez, mikrosatellit instabilite oluşur. Kolon kanserinin yanında endometrium kanseri de en sık eşlikçisidir.",
    "path_b1A_023": "💡 HİKAYE: Serrated polip BRAF mutasyonuyla başlayan alternatif bir kanser yoludur. BRAF aktive olunca MLH1 geni metilasyonla susturulur ve MSI-H oluşur. Konvansiyonel adenom ise klasik APC/β-katenin yolunu izler — iki farklı kanser otoyolu.",
    "path_b1A_024": "💡 HİKAYE: Sol kolon kanseri bağırsağı sıkıştırarak 'elma çekirdeği' şeklinde tıkanma yapar — hasta kabızlıkla gelir. Sağ kolon kanseri ise gizlice kanar ve hasta fark etmeden anemiye girer. Sol=Tıkanma, Sağ=Anemi.",
    "path_b1A_025": "💡 HİKAYE: Meckel divertikülü '2'lerin prensidir: nüfusun %2'si, 2 feet mesafede, 2 yaşında semptom, 2 inches uzunluk, 2 tip heterotopi (gastrik ve pankreatik). Beş tane 2'yi hatırla!",
    "path_b1A_026": "💡 HİKAYE: Meckel divertikülünün içinde gizlice mide mukozası oluştu (gastrik heterotopi). Bu mide dokusu asit salgıladı ve bağırsak duvarını yaktı — ülser ve kanama! Çocuklarda alt GİS kanamasının gizli suçlusu.",
    "path_b1A_027": "💡 HİKAYE: Splenik fleksur, SMA ve İMA'nın beslenme alanları arasında 'su bölümü' (watershed) noktasıdır. Kan basıncı düştüğünde bu bölge en az beslenen yer olur — iskemik kolitin favori hedefi. Griffiths ve Sudek noktaları kritiktir.",
    "path_b1A_028": "💡 HİKAYE: Antibiyotik kullanan hastada C. difficile kolonda volkan gibi patladı. Kriptlerden fışkıran nötrofil, fibrin ve müsin karışımı psödomembranlar oluşturdu. Toksin A ve B ile tanı konur — vulkan patlaması histolojisi.",
    "path_b1A_029": "💡 HİKAYE: Dukes evreleme sistemi merdiven gibidir: A=Mukozada (en üst basamak), B=Kas geçildi (dışarı çıktı), C=Lenf noduna sıçradı, D=Uzak metastaz (en alt basamak). Her basamakta prognoz kötüleşir.",
    "path_b1A_030": "💡 HİKAYE: GİS'in pacemaker hücreleri olan Cajal hücrelerinden GIST tümörü doğar. Bu tümörün imzası CD117 (KIT) pozitifliğidir. İmatinib bu KIT mutasyonunu hedef alır — hedefe yönelik tedavinin güzel örneği.",
    "path_b1A_031": "💡 HİKAYE: GIST'in malignite potansiyelini iki kriter belirler: mitoz sayısı (>5/50 HPF) ve boyut (>5 cm). İkisi de yüksekse tümör agresif davranır. '5-5 kuralı' — beşin üstü tehlike demektir.",
    "path_b1A_032": "💡 HİKAYE: Karsinoid tümör en sık ileum ve appendikste görülür. Appendiksteki karsinoid genelde masum (benign) kalır, ama ileumdaki metastaz yapabilir. Yerleşim yeri kaderi belirler — appendiks=iyi, ileum=riskli.",
    "path_b1A_033": "💡 HİKAYE: Karsinoid tümör serotonin üretir ama karaciğer normalden temizler. Karaciğer metastazı olduğunda serotonin doğrudan sistemik dolaşıma girer — yüz kızarması (flushing), ishal ve bronkospazm üçlüsü başlar. Sağ kalp kapağı da hasar alır.",
    "path_b1A_034": "💡 HİKAYE: Zollinger-Ellison'da pankreas veya duodenumdaki gastrinoma aşırı gastrin salgılar. Mide asidi o kadar artar ki ülserler durmadan nüks eder. MEN-1 ile birlikteliğini unutma — 3P (Pitüiter, Paratiroid, Pankreas).",
    "path_b1A_035": "💡 HİKAYE: Whipple hastalığında Tropheryma whipplei bakterisi makrofajların içine yerleşir. PAS boyasıyla bu makrofajlar parlak pembe boyanır — lamina propriada PAS-pozitif makrofaj görmek Whipple'ın imzasıdır.",
    "path_b1A_036": "💡 HİKAYE: Alkol ve sigara, özofagus skuamöz karsinomun iki yakın arkadaşıdır. Birlikte olduklarında risk katlanarak artar. 'AS' ikilisi (Alkol+Sigara) özofagusun orta katını hedef alır.",
    "path_b1A_037": "💡 HİKAYE: Plummer-Vinson sendromlu kadın demir eksikliği anemisiyle solgun, yutma güçlüğü çekiyor (özofageal web) ve ağız köşeleri çatlamış. Bu üçlü birliktelik özofagusta skuamöz karsinom riskini artırır — demir eksikliğinin uzun vadeli bedeli.",
    "path_b1A_038": "💡 HİKAYE: İskemik kolitte submukozadaki ödem ve kanama, bağırsak duvarını kabarttı. Radyolojide sanki biri parmakla bastırmış gibi iz bıraktı — thumbprinting (parmak izi) bulgusu. Watershed bölgelerinde aranmalıdır.",
    "path_b1A_039": "💡 HİKAYE: 60 yaşından sonra sağ kolondaki (çekum/çıkan kolon) arteriovenöz malformasyonlar kanmaya başlar. Yaşlı hastada tekrarlayan alt GİS kanamasının gizli suçlusu anjiodisplazidir.",
    "path_b1A_040": "💡 HİKAYE: Divertikülozis sigmoid kolonu sever — çünkü sigmoid en dar ve en yüksek basınçlı bölgedir. Divertikülit geliştiğinde sol alt kadran ağrısı yapar, 'sol tarafın apandisiti' gibi davranır.",
    "path_b1A_041": "💡 HİKAYE: 6-18 aylık bir bebekte ileum kolonun içine girdi (ileokolik invajinasyon). Bağırsak sıkışıp kanlanması bozulunca 'currant jelly' (kırmızı jöle) görünümünde kanlı-mukuslu dışkı geldi. Pnömatik redüksiyon hayat kurtarır.",
    "path_b1A_042": "💡 HİKAYE: Sigmoid kolon uzun mezenteriyle kendi etrafında döndü — volvulus! Yaşlılarda ve Hirschsprung hastalarında sigmoid bu dönme hareketine yatkındır. 'Volandı sigmoid' deyip hatırla.",
    "path_b1A_043": "💡 HİKAYE: CEA kolorektal kanserin dedektifidir ama sadece nüks takibinde çalışır. Taramada güvenilmez çünkü spesifik değildir. Cerrahi sonrası CEA yükselirse nüks düşünülür — 'Cerrahi-Sonrası-Takip' ajanı.",
    "path_b1A_044": "💡 HİKAYE: Villöz adenom 'villain' (kötü adam) gibidir — %40 malignite riski taşır. Tubüler adenom ise daha masum kalır. Adenom ne kadar villöz ve büyükse kanser riski o kadar yüksek.",
    "path_b1A_045": "💡 HİKAYE: Peutz-Jeghers hastasının dudaklarında melanotik lekeler (frekler) ve bağırsaklarında hamartomatöz polipler vardır. STK11 gen mutasyonu sorumludur. Dudak lekesi + polip = Peutz-Jeghers tanısı.",
    "path_b1A_046": "💡 HİKAYE: Cowden sendromunda PTEN geni mutasyona uğradı. PTEN normalde hücre büyümesini frenler — fren bozulunca meme, tiroid ve endometrium kanseri riski artar. Yüzde trikilemlomalar ve bağırsakta hamartomlar tipiktir.",
    "path_b1A_047": "💡 HİKAYE: Prematüre bir bebeğin bağırsağında iskemi ve bakteriler el ele verdi. Transmural koagülatif nekroz gelişti — nekrotizan enterokolit (NEC). Pnömatozis intestinalis (bağırsak duvarında hava) radyolojik ipucudur.",
    "path_b1A_048": "💡 HİKAYE: Midedeki intestinal metaplazi, mide hücrelerinin bağırsak hücresine dönüşmesidir. Bu dönüşüm başlangıçta zararsız görünür ama stres devam ederse displazi ve sonunda intestinal tip adenokarsinom gelişir — metaplazinin karanlık yolu.",
    "path_b1A_049": "💡 HİKAYE: Tropikal sprue tropik bölgeden dönen gezginin hastalığıdır — antibiyotikle iyileşir. Çölyak ise glutene bağlıdır ve anti-tTG pozitiftir. İkisi de villöz atrofi yapar ama tedavileri tamamen farklıdır.",
    "path_b1A_050": "💡 HİKAYE: Midede MALT lenfomasını H. pylori tetikliyorsa, ince bağırsakta aynı rolü Campylobacter jejuni üstlenir. IPSID (immünoproliferatif ince bağırsak hastalığı) olarak bilinen bu lenfoma, alfa ağır zincir hastalığı ile ilişkilidir.",

    # ========== pathology_batch1B.json (49 cards) ==========
    "path_b1B_001": "💡 HİKAYE: Tip A otoimmün gastrit hipergastrinemiye yol açtı. Gastrin ECL hücrelerini sürekli uyardı ve ECL hücreleri kontrolsüz çoğaldı — mide karsinoid tümörü doğdu. Zollinger-Ellison'da da aynı mekanizma işler.",
    "path_b1B_002": "💡 HİKAYE: Hücre hasar aldığında ilk olarak su girişi olur — hücre şişer (hidropik değişiklik). ER ve mitokondri de şişer, yağ damlaları birikir. Ama nükleus hâlâ sağlamdır — bu geri dönüşümlü hasarın işaretidir.",
    "path_b1B_003": "💡 HİKAYE: Hücre öldüğünde nükleus üç farklı şekilde yıkılır: piknoz (küçülüp yoğunlaşır), karyoreksis (parçalanır), karyoliz (erir). Bu üç K, geri dönüşümsüz hasarın kesin kanıtıdır.",
    "path_b1B_004": "💡 HİKAYE: İskemi olduğunda mitokondri ilk çöken organeldir — ATP üretimi durur. Na/K-ATPaz pompası enerji bulamaz ve durur. Sodyum ve su hücreye dolar, hücre balon gibi şişer — iskeminin ilk perdesi.",
    "path_b1B_005": "💡 HİKAYE: Tıkalı damar açıldığında kan geri geldi ama beraberinde ROS patlaması getirdi. Kalsiyum hücreye doldu, kompleman aktive oldu — hücre kurtarılırken öldürüldü. Reperfüzyon hasarı, yangını söndürürken evi yıkmak gibidir.",
    "path_b1B_006": "💡 HİKAYE: Koagülatif nekrozda hücrenin iskeleti korunur, hayalet gibi şekli durur — miyokard enfarktüsündeki gibi. Liquefikatif nekrozda ise her şey erir — beyin enfarktüsünde doku sıvılaşır çünkü beyin lipidden zengindir.",
    "path_b1B_007": "💡 HİKAYE: Tüberküloz granülomlarının merkezinde peynir gibi beyaz-sarı bir madde birikir — kazeifiye nekroz. 'Kazein' peynir proteinidir, bu nekroz da peynire benzer. TBC'nin patognomonik bulgusudur.",
    "path_b1B_008": "💡 HİKAYE: Kuru gangrende doku mumyalaşır — kan gelmez ama bakteri de yoktur. Islak gangrende ise bakteriler işe karışır ve koagülatif nekroza liquefikatif bileşen eklenir. Islak gangren hayatı tehdit eder, acil müdahale gerekir.",
    "path_b1B_009": "💡 HİKAYE: Fibrinoid nekroz damar duvarlarına özeldir. Plazma proteinleri (fibrin dahil) damar duvarına sızar ve fibrin benzeri parlak pembe bir materyal birikir. Vaskülit ve malign hipertansiyonda damar duvarında görülen bu parlak birikim tipiktir.",
    "path_b1B_010": "💡 HİKAYE: Apoptoz sessiz bir intihar — hücre büzülür, parçalara ayrılır, komşular temizler, inflamasyon olmaz. Nekroz ise gürültülü bir patlama — hücre şişer, patlar ve etrafta yangın (inflamasyon) çıkar. İki farklı ölüm senaryosu.",
    "path_b1B_011": "💡 HİKAYE: Mitokondride BCL-2 ailesi savaşır: BAX/BAK (ölüm yanlısı) kapıları açmak, BCL-2 (yaşam yanlısı) kapatmak ister. BAX kazanırsa sitokrom C fırlar ve kaspaz-9 ile apoptoz başlar — mitokondri hayat-ölüm kapısıdır.",
    "path_b1B_012": "💡 HİKAYE: Folliküler lenfomada t(14;18) translokasyonu BCL-2'yi aşırı ürettirir. BCL-2 apoptozu engeller — hücreler ölmeyi reddeder. '14 ile 18 el sıkıştı, BCL-2 kaçtı, folliküler lenfoma doğdu'.",
    "path_b1B_013": "💡 HİKAYE: FAS reseptörü hücrenin kapısında asılı bir 'ölüm çanı'dır. FAS-L bağlandığında çan çalar, kaspaz-8 devreye girer ve hücre hızla apoptoza gider. Sitotoksik T hücreleri ise perforin ile kapıyı deler, granzim ile içeri girer.",
    "path_b1B_014": "💡 HİKAYE: Aç kalan hücre hayatta kalmak için kendi organellerini yemeye başlar — otofaji (self-eating). Lizozomlar bu organelleri sindiren mutfak olarak çalışır. Besin gelene kadar kendini idare etmenin yolu budur.",
    "path_b1B_015": "💡 HİKAYE: Hücresel adaptasyonlar bir sıra takip eder: Atrofi (küçülme), hipertrofi (büyüme), hiperplazi (sayı artışı), metaplazi (tip değişimi). Stres devam ederse displazi ve neoplazi kapıda bekler.",
    "path_b1B_016": "💡 HİKAYE: Hamile kadının uterusu büyür — hem hipertrofi hem hiperplazi. Ama hipertansiyonlu hastanın kalbi sadece büyür (hipertrofi) çünkü kardiyomiyositler bölünemez. Kalp hücresi mitoz yapamaz, sadece şişer.",
    "path_b1B_017": "💡 HİKAYE: Barrett özofagusunda reflü stresi altındaki skuamöz epitel, daha dirençli intestinal kolumnar epitele dönüştü (metaplazi). Bu adaptasyon tersinirdir ama stres devam ederse displazi → neoplazi zinciri başlar.",
    "path_b1B_018": "💡 HİKAYE: Serbest radikaller dört hedefi vurur: lipid membranları (peroksidasyonla), proteinleri (oksidasyonla), DNA'yı (mutasyonla) ve karbonhidratları. Glutatyon ve SOD enzimi bu saldırılara karşı savunma hattıdır.",
    "path_b1B_019": "💡 HİKAYE: CCl4 karaciğere girdiğinde P450 enzimi onu daha tehlikeli CCl3 radikaline dönüştürür. Bu radikal lipid peroksidasyonu yaparak ER'yi harap eder, protein sentezi durur ve karaciğer yağlanır — toksik hasarın klasik örneği.",
    "path_b1B_020": "💡 HİKAYE: Hücre içine kalsiyum dolduğunda üç yıkıcı enzim aktive olur: fosfolipaz A2 (membranı parçalar), proteaz (iskeleti yıkar), endonükleaz (DNA'yı keser). Kalsiyum fazlalığı hücrenin iç savaşını tetikler.",
    "path_b1B_021": "💡 HİKAYE: Her organ kendine özgü bir şey biriktirir: karaciğer yağ (steatoz), damar duvarı kolesterol (ateroskleroz), hemokromatozda organlar demir (hemosiderin) biriktirir. Birikim yeri hastalığın adresini verir.",
    "path_b1B_022": "💡 HİKAYE: Lipofusin yaşlanmanın pigmentidir — yıllar boyunca hücrede biriken sindirilememiş kalıntılar. Kalp ve karaciğer hücrelerinde kahverengi granüller olarak görülür. 'Eskime lekesi' zararsızdır ama yaşın kanıtıdır.",
    "path_b1B_023": "💡 HİKAYE: Hemosideroz ve hemokromatoz ikisi de demir biriktirme hastalığıdır ama farkları büyüktür. Hemosiderozda demir birikir ama organ hasarı yoktur. Hemokromatozda ise HFE mutasyonu nedeniyle demir organları harap eder — siroz, DM, kardiyomiyopati.",
    "path_b1B_024": "💡 HİKAYE: Distrofik kalsifikasyon hasarlı dokuya kalsiyum çökmesidir — serum kalsiyumu normaldir. Metastatik kalsifikasyon ise hiperkalsemide normal dokuya kalsiyum çökmesidir. 'Hasta doku + Normal Ca = Distrofik; Normal doku + Yüksek Ca = Metastatik'.",
    "path_b1B_025": "💡 HİKAYE: Amiloid yanlış katlanan proteinlerin beta-tabaka yapısıyla biriktiği bir hastalıktır. Congo red boyası ile boyanır ve polarize ışıkta elma yeşili parıltı verir — amiloidin patognomonik bulgusu bu yeşil parıltıdır.",
    "path_b1B_026": "💡 HİKAYE: AL amiloidozda multipl miyelom hücrelerinin ürettiği hafif zincirler (λ/κ) birikir — 'Aşırı Light chain'. AA amiloidozda ise kronik inflamasyon (RA, TBC) nedeniyle SAA proteini birikir — ateşli hastalıkların uzun vadeli bedeli.",
    "path_b1B_027": "💡 HİKAYE: Amiloid dalağın beyaz pulpasına (foliküllere) çöktüğünde pirinç tanesi gibi küçük beyaz noktalar oluşur — sago dalak. Tüm dalağa yayıldığında ise mumsu bir görünüm alır — balmumu dalak (waxy spleen).",
    "path_b1B_028": "💡 HİKAYE: Uzun yıllar hemodiyaliz yapılan hastada β2-mikroglobulin diyaliz membranından geçemedi ve birikti. Bu protein eklemlere çöktü ve karpal tünel sendromu yaptı — diyalizin amiloid bedeli.",
    "path_b1B_029": "💡 HİKAYE: Alzheimer'da APP geninden üretilen Aβ peptidi beyinde plaklar oluşturur. Tau proteini ise nörofibriler yumaklar yapar. Bu ikili — amiloid plaklar ve tau yumakları — Alzheimer'ın patolojik imzasıdır.",
    "path_b1B_030": "💡 HİKAYE: ATTR amiloidozunda transthyretin proteini sorun çıkarır. Mutant TTR genç yaşta nöropati yapar (familyal form). Wild-type TTR ise yaşlılıkta kalbe çöker — senile kardiyak amiloidoz. Aynı protein, iki farklı kader.",
    "path_b1B_031": "💡 HİKAYE: Hücre yaşlandıkça telomerleri kısalır — her bölünmede bir parça kaybolur. Telomer kritik uzunluğa indiğinde p21 ve p16 CDK inhibitörleri devreye girer ve hücreyi G1'de durdurur. Hücre artık bölünemez — yaşlanma (senescence).",
    "path_b1B_032": "💡 HİKAYE: Normal hücreler belli sayıda bölünüp durur (Hayflick limiti). Kanser hücresi ise telomerazı aktive ederek telomerleri sürekli uzatır — sonsuz bölünme kapasitesi kazanır. Telomeraz kanser hücresinin ölümsüzlük iksiridir.",
    "path_b1B_033": "💡 HİKAYE: P53 genomun polisidir — DNA hasarı olduğunda olay yerine gelir. Önce p21'i çağırarak hücre döngüsünü G1'de durdurur. Hasar onarılabilirse devam izni verir, onarılamazsa BAX'ı çağırıp apoptozu emreder.",
    "path_b1B_034": "💡 HİKAYE: Nekroptozis, kaspaz yolu bloke edildiğinde devreye giren yedek ölüm mekanizmasıdır. RIPK3 ve MLKL proteinleri hücre membranını deler — apoptoz gibi programlı ama nekroz gibi inflamatuar. Virüsler kaspazı bloke ettiğinde bu yol aktive olur.",
    "path_b1B_035": "💡 HİKAYE: Piroptoz inflamazom aracılı ateşli bir ölümdür. Kaspaz-1 aktive olur, IL-1β ve IL-18 salınır. Gasdermin D hücre membranında delikler açar — hücre hem ölür hem inflamasyon başlatır. Makrofajlarda özellikle önemlidir.",
    "path_b1B_036": "💡 HİKAYE: Ferroptoz demir bağımlı bir ölüm şeklidir. GPX4 enzimi lipid peroksidasyonunu engelleyen koruyucudur. GPX4 inaktive olduğunda demir katalizi ile lipid peroksidasyonu patlar ve hücre ölür — demirin karanlık yüzü.",
    "path_b1B_037": "💡 HİKAYE: ER'de proteinler yanlış katlandığında UPR alarm sistemi devreye girer. Önce protein üretimini yavaşlatır ve şaperonları artırır. Sorun çözülmezse alarm eşiği aşılır ve apoptoz tetiklenir — ER stresinin son çaresi.",
    "path_b1B_038": "💡 HİKAYE: Koagülatif nekroz alanında hücreler hayaletlere dönüşür — konturu var ama nükleusu kaybolmuş. Bu 'gölge hücreler' (ghost cells) miyokard enfarktüsünde tipiktir. Hücrenin iskeleti korunmuş ama ruhu gitmiştir.",
    "path_b1B_039": "💡 HİKAYE: BAX ve BAK mitokondri dış membranında porlar açtığında (MOMP), sitokrom C hücrenin sitozolüne fırlar. Sitokrom C kaspaz-9'u aktive eder ve apoptozom oluşur — mitokondri kapısı açıldığında geri dönüş yoktur.",
    "path_b1B_040": "💡 HİKAYE: Yüksek ateş proteinleri denatüre eder — yumurtayı kaynatmak gibi. Ama hücrelerin gizli silahı vardır: ısı şok proteinleri (HSP). Bu şaperonlar proteinleri koruyarak hücreyi ısı hasarından kurtarır.",
    "path_b1B_043": "💡 HİKAYE: Displazi 'sınırda duran suçlu' gibidir — hücreler bozuk ama bazal membranı geçmemiştir. Neoplazi ise sınırı aşmış suçludur — otonom büyüme ve invazyon mümkündür. Displazi tersinir olabilir, neoplazi ise kontrolden çıkmıştır.",
    "path_b1B_044": "💡 HİKAYE: Non-immün hidrops fetalisin en sık nedeni kardiyak anomalilerdir. Kalp yetersizliği venöz basıncı artırır ve sıvı dokulara sızar. Parvovirus B19 ise fetal eritropoezi baskılayarak anemiye ve ikincil olarak hidropsa neden olur.",
    "path_b1B_045": "💡 HİKAYE: Hiperplazi bir parti gibidir — çok aileden hücreler gelir (poliklonal). Neoplazi ise tek bir hücrenin diktatörlüğüdür — tüm tümör tek bir klondan türer (monoklonal). Klonalite, neoplazinin ayırt edici özelliğidir.",
    "path_b1B_046": "💡 HİKAYE: APC proteini normalde β-katenini yakalar ve yıkıma gönderir. APC mutasyona uğrayınca β-katenin serbest kalır, nükleusa girer ve MYC genini aktive eder — kolorektal kanserin başlangıç noktası. Wnt yolunun freni bozulmuştur.",
    "path_b1B_047": "💡 HİKAYE: ROS üretiminin endojen kaynakları: mitokondri (elektron taşıma zinciri sızıntısı), NADPH oksidaz (fagositlerde mikrop öldürücü), sitokrom P450 (ilaç metabolizması) ve myeloperoksidaz. Hücre kendi silahını üretir.",
    "path_b1B_048": "💡 HİKAYE: Hücrenin ROS'a karşı üçlü savunma hattı: SOD (süperoksidi H2O2'ye), katalaz (H2O2'yi suya), glutatyon peroksidaz (lipid peroksidleri nötralize eder). Vitamin E membranı, Vitamin C sitozolü korur.",
    "path_b1B_049": "💡 HİKAYE: iNOS aktive olduğunda aşırı NO üretilir. NO, süperoksitle birleşerek peroksinitrit (ONOO-) oluşturur — bu güçlü oksidan DNA'yı ve membranları harap eder. iNOS inflamasyon sırasında en çok zarar veren NO kaynağıdır.",
    "path_b1B_050": "💡 HİKAYE: Hücre hasarlandığında enzimler kana sızar. CK-MB miyokardın, CK-MM kasın, CK-BB beynin imzasıdır. LDH ise genel bir hasar belirtecidir. 'M=Miyokard, M=Muscle, B=Brain' diye hatırla.",

    # ========== pathology_batch2A.json (34 cards) ==========
    "path_b2A_001": "💡 HİKAYE: Bir tümörün malign olup olmadığını anlamak için iki kritik soru sorulur: Bazal membranı geçti mi (invazyon)? Uzak organa gitti mi (metastaz)? Metastaz kesin malignite kanıtıdır — benign tümör asla metastaz yapmaz.",
    "path_b2A_002": "💡 HİKAYE: Karsinogenez üç basamaklı bir merdivendir: İnisyasyon (DNA'ya kalıcı hasar), promosyon (hasarlı hücrenin çoğalması, tersinir), progresyon (invazyon ve metastaz). 'İPP yolu' — her basamakta tehlike artar.",
    "path_b2A_003": "💡 HİKAYE: Proto-onkogen arabanın gaz pedalıdır — tek bir mutasyon yeterli (dominant). Tümör süpresör ise frendir — her iki frenin de bozulması gerekir (resesif, Knudson 2-hit). Kanser = gaz pedalı takılı + fren bozuk.",
    "path_b2A_004": "💡 HİKAYE: RAS proteini normalde GTP'yi hızla GDP'ye çevirir (kapatır). Mutasyonda GTPaz aktivitesi bozulur ve RAS sürekli açık kalır — gaz pedalı takılmış araba gibi. Pankreas kanserinin %95'inde KRAS mutasyonu vardır.",
    "path_b2A_005": "💡 HİKAYE: MYC ailesi transkripsiyon faktörleridir. c-MYC Burkitt lenfomada t(8;14) ile aktive olur, N-MYC nöroblastomda amplifikasyon ile kötü prognoz gösterir, L-MYC küçük hücreli akciğer kanserinde bulunur. Her MYC'in bir hedefi var.",
    "path_b2A_006": "💡 HİKAYE: HER2 meme kanserinin %20-25'inde amplifikasyonla aşırı eksprese olur. Trastuzumab (Herceptin) bu reseptörü hedef alan monoklonal antikordur. 'HER-ki (2) = HERCEPTIN ile tedavi' diye hatırla.",
    "path_b2A_007": "💡 HİKAYE: Rb proteini hücre döngüsünün G1 kapısında bekleyen güvenlik görevlisidir. E2F transkripsiyon faktörünü tutarak S fazına geçişi engeller. Rb mutasyona uğrayınca kapı açık kalır ve hücre kontrolsüz S fazına girer.",
    "path_b2A_008": "💡 HİKAYE: Herediter retinoblastomda çocuk bir aleli mutant olarak doğar (1. hit). Tek bir somatik mutasyon daha yeter (2. hit). Sporadikte ise iki hit de sonradan olmalıdır — bu yüzden herediter form daha erken ve bilateral ortaya çıkar.",
    "path_b2A_009": "💡 HİKAYE: Li-Fraumeni ailesi TP53 germ hatlı mutasyonu taşır. P53 genomun polisi olduğu için bu mutasyon vücudu korumasız bırakır — sarkom, meme, beyin ve adrenal tümörleri genç yaşta gelişir. Polisin yokluğunda suçlular cirit atar.",
    "path_b2A_010": "💡 HİKAYE: E-kaderin epitel hücrelerinin yapıştırıcısıdır. Bu yapıştırıcı kaybolduğunda hücreler serbest kalır (EMT) ve invazyon başlar. Mide diffüz tip (taşlı yüzük hücreli) karsinomda E-kaderin kaybı tipiktir.",
    "path_b2A_011": "💡 HİKAYE: Tümör büyüdükçe oksijensiz kalır (hipoksi). Hipoksi VEGF salgılatır ve yeni damarlar oluşur (anjiyogenez). Bevacizumab (Avastin) bu VEGF'yi bloke ederek tümörün kan kaynağını keser — aç bırakma stratejisi.",
    "path_b2A_012": "💡 HİKAYE: Tümör PD-L1 kalkanını kuşanarak T hücrelerini uyutur (immün kaçış). PD-1/PD-L1 blokajı bu kalkanı kırar ve T hücreleri uyanıp tümöre saldırır — immünoterapinin temel mantığı budur.",
    "path_b2A_013": "💡 HİKAYE: Tümör belirteçleri kesin tanı koyamaz ama tedavi yanıtını ve nüksü takip etmekte altın değerindedir. Tek başına yükselmiş bir belirteç 'kanser var' demez — klinikle birlikte değerlendirilmelidir.",
    "path_b2A_014": "💡 HİKAYE: AFP (alfa-fetoprotein) fetüs döneminde yüksek olan bir proteindir. Hepatoselüler karsinomda ve yolk sac tümöründe yeniden yükselir — sanki hücre embriyonik döneme geri dönmüş gibi. 'Fetüs proteini geri döndü' = Kanser.",
    "path_b2A_015": "💡 HİKAYE: Her organın tümör belirteci farklıdır: CA 15-3 memenin, CA-125 overin, PSA prostatın takipçisidir. CEA ise kolonu izler. 'Her organın bir dedektifi var' diye düşün.",
    "path_b2A_016": "💡 HİKAYE: Yüksek büyüme fraksiyonlu tümörler hızla bölünür — bu yüzden kemoterapiye duyarlıdır (DNA replikasyonunda yakalanırlar). Düşük büyüme fraksiyonlu tümörler yavaş bölünür ve kemoya dirençlidir. Hız = Hassasiyet.",
    "path_b2A_017": "💡 HİKAYE: Kanser hücresi oksijen olsa bile glikolizi tercih eder (Warburg etkisi). Verimsiz gibi görünse de hızlı biyokütle sentezi için gerekli yapı taşlarını sağlar. 'Şeker bağımlısı hücre' — PET/CT bu şeker açlığını görüntüler.",
    "path_b2A_018": "💡 HİKAYE: Karsinoma in situ'da atipik hücreler epitelin tüm kalınlığını kaplar ama bazal membran sağlamdır. 'Kötü adam çitin içinde' — invazyon henüz yok. Erken teşhis edilirse tam kür mümkündür.",
    "path_b2A_019": "💡 HİKAYE: Desmoplazi tümörün etrafında oluşan yoğun fibroz reaksiyondur — tümörün çelik kafesi gibi. Pankreas adenokarsinomunda en belirgindir, tümörü sert ve taş gibi yapar. Bu fibroz ilaçların tümöre ulaşmasını da zorlaştırır.",
    "path_b2A_020": "💡 HİKAYE: Hodgkin lenfomanın imzası Reed-Sternberg hücresidir — baykuş gözlü dev hücre (çift nükleus). CD15 ve CD30 pozitiftir. Non-Hodgkin lenfomada RS hücresi yoktur — bu ikisini ayıran en önemli histolojik bulgudur.",
    "path_b2A_023": "💡 HİKAYE: Burkitt lenfomada t(8;14) MYC'i aktive eder. Histolojide makrofajların arasında lenfoma hücreleri 'yıldızlı gökyüzü' görünümü verir. Endemik (Afrika) formunda EBV %100 pozitiftir — çocuklarda çene kitlesi tipiktir.",
    "path_b2A_025": "💡 HİKAYE: Multipl myelom tanısı için CRAB kriterlerini hatırla: Calcium (hiperkalsemi), Renal yetmezlik, Anemia, Bone (kemik lytik lezyonları). Kemik iliğinde >%10 plazma hücresi + M-protein = Myelom tanısı.",
    "path_b2A_026": "💡 HİKAYE: Myelomda plazma hücreleri kemikleri eritir (lytik lezyonlar) — röntgende delikli peynir gibi görünür. Böbrekten hafif zincirler (Bence Jones) sızar ve tübülleri tıkar. 'Kemik deler, böbrek tıkar' — myelomun iki yüzü.",
    "path_b2A_027": "💡 HİKAYE: Waldenström makroglobulinemisinde IgM tipi M-protein üretilir. IgM büyük bir molekül olduğu için kanı koyulaştırır (hiperviskozite). Myelomda ise IgG veya IgA baskındır ve kemik lezyonları ön plandadır.",
    "path_b2A_028": "💡 HİKAYE: MALT lenfoma H. pylori antijenine bağımlı büyür — antijen giderse tümör gerileyebilir. Bu yüzden erken evre mide MALT lenfomasında ilk tedavi antibiyotiktir. 'Antijene bağımlı tümör' kavramının en güzel örneği.",
    "path_b2A_029": "💡 HİKAYE: Mantle hücre lenfomada t(11;14) translokasyonu Cyclin D1'i aktive eder. Cyclin D1 hücre döngüsünü G1'den S'ye iter. Agresif seyirlidir ve orta yaş erkekleri tercih eder. '11+14=25' diye hatırla.",
    "path_b2A_034": "💡 HİKAYE: MMR genleri DNA'daki yazım hatalarını düzeltir. Bu sistem bozulduğunda mikrosatellit instabilite (MSI-H) oluşur. MSI-H tümörler neoantijenler ürettiği için immünoterapiye (pembrolizumab) çok iyi yanıt verir — bozukluk tedaviye kapı açar.",
    "path_b2A_035": "💡 HİKAYE: BRCA1/2 DNA çift zincir kırıklarını homolog rekombinasyonla onarır. Mutasyonda onarım yapılamaz ve meme/over kanseri riski artar. PARP inhibitörleri bu onarım eksikliğini istismar ederek kanser hücrelerini öldürür — sentetik letalite.",
    "path_b2A_040": "💡 HİKAYE: ALK füzyon geni genç, sigara içmeyen akciğer adenokarsinomu hastalarında bulunur. EML4-ALK füzyonu krizotinib ile hedef alınır. ALCL lenfomada da ALK pozitifliği görülür — ALK iki farklı kanserin ortak hedefi.",
    "path_b2A_043": "💡 HİKAYE: İHK tümörün kökenini bulmak için kullanılan moleküler dedektiftir. Pan-sitokeratin 'Karsinom mu?' sorusunu, LCA 'Lenfoma mı?' sorusunu, S100 ise 'Melanom mu?' sorusunu yanıtlar. Her antikor farklı bir suçluyu işaret eder.",
    "path_b2A_044": "💡 HİKAYE: Çocuklarda malign tümör sıralaması: 1) Lösemi (en sık), 2) Beyin tümörleri, 3) Lenfomalar. 'L-B-L' kısaltmasıyla hatırla. Yetişkinlerden farklı olarak çocuklarda lösemi açık ara birincidır.",
    "path_b2A_045": "💡 HİKAYE: Wilms tümörü (nefroblastom) WT1 genindeki (11p13) mutasyonla ilişkilidir. WAGR sendromunda dört bulgu bir arada gelir: Wilms tümörü + Aniridia (iris yokluğu) + Genitoüriner anomali + Retardasyon. 'WAGR' kısaltması tanıyı verir.",
    "path_b2A_046": "💡 HİKAYE: Nöroblastom adrenal medulladan köken alır ve çocukluk çağının en sık ekstrakraniyal solid tümörüdür. N-MYC amplifikasyonu kötü prognoz göstergesidir. Ancak 1 yaş altı 4S evresinde spontan regresyon görülebilir — nöroblastomun şaşırtıcı yüzü.",

    # ========== pathology_batch2B.json (33 cards) ==========
    "path_b2B_001": "💡 HİKAYE: KOAH'ın iki yüzü: Amfizem hastasında elastik doku yıkılıp hava hapsolur (pembe üfleyici). Kronik bronşitli hastada mukus bezleri şişer (Reid indeksi >0.5) ve mavi şişkin görünüm oluşur. İkisi aynı çatı altında farklı odalar.",
    "path_b2B_002": "💡 HİKAYE: Sentriasiner amfizem sigaranın eseridir — üst loblarda görülür çünkü duman oraya ulaşır. Panasiner amfizem ise α1-antitripsin eksikliğinden olur ve alt lobları tutar — enzim yokluğunda tüm asiner harap olur.",
    "path_b2B_003": "💡 HİKAYE: Astımda Th2 hücreleri orkestra şefi gibidir. IL-4 IgE ürettirir, IL-5 eozinofilleri çağırır, IL-13 mukus artırır. Mast hücrelerinden lökotrienler salınır ve bronkospazm başlar — Th2'nin senfonisi.",
    "path_b2B_004": "💡 HİKAYE: Akciğer adenokarsinomunda EGFR mutasyonu genç, sigara içmeyen, Asyalı kadınlarda sık görülür. Erlotinib ve gefitinib bu mutasyonu hedef alır. 'EGFR = Genç-Kadın-Sigara(-) = TKI tedavisi' formülü.",
    "path_b2B_005": "💡 HİKAYE: SCLC küçük yulaf tanesi şeklinde hücreleriyle tanınır — nöroendokrin markerlar pozitiftir. LCNEC de nöroendokrin ama hücreleri büyüktür. İkisi de agresiftir ama SCLC çok daha sık paraneoplastik sendrom yapar.",
    "path_b2B_006": "💡 HİKAYE: Küçük hücreli akciğer kanseri 'küçük ama büyük sorun çıkarır'. SIADH (ADH salgılar), Cushing (ACTH salgılar) ve Lambert-Eaton (antikorlarla nöromüsküler blok) — üç farklı paraneoplastik sendromun tek kaynağı.",
    "path_b2B_007": "💡 HİKAYE: Skuamöz hücreli akciğer karsinomu PTHrP salgılayarak vücudu 'hiperkalsemi' moduna sokar. PTHrP paratiroid hormonu gibi davranır ve kemikten kalsiyum çeker — humoral hiperkalseminin en sık tümöral nedeni.",
    "path_b2B_008": "💡 HİKAYE: Mezotelyoma ile adenokarsinom ayrımında İHK altın standarttır. Mezotelyoma calretinin, WT1 ve CK5/6 ile boyanır. Adenokarsinom ise TTF-1 ve CEA pozitiftir. 'Calretinin = Mezo, TTF-1 = Adeno' formülü.",
    "path_b2B_009": "💡 HİKAYE: Sarkoidozda granülomlar 'kuru'dur — kazeifikasyon yoktur (TBC'den farklı). Granülom içinde Schaumann cisimcikleri (konsantrik kalsifiye) ve asteroid cisimcikleri (yıldız şekli) görülür. Non-kazeifiye granülom = Sarkoidoz düşün.",
    "path_b2B_010": "💡 HİKAYE: Astım Tip I (IgE aracılı) reaksiyondur — hemen gelir. Hipersensitivite pnömonisi ise Tip III (immün kompleks) ve Tip IV (granülomatöz) reaksiyon yapar. Çiftçi akciğeri ve güvercin akciğeri tipik örneklerdir.",
    "path_b2B_011": "💡 HİKAYE: PCP'de alveollerde köpüklü bir eksüda birikir — sanki köpük banyosu yapılmış gibi. GMS (gümüş) boyası ile kistler görülür. HIV hastalarında CD4 sayısı 200'ün altına düştüğünde bu fırsatçı enfeksiyon kapıyı çalar.",
    "path_b2B_012": "💡 HİKAYE: Akciğer karsinoidi düzenli organoid patern gösteren düşük mitotik aktiviteli nöroendokrin tümördür. Tipik karsinoid iyi prognozludur, atipik karsinoid ise (2-10 mitoz) daha agresiftir. Merkezi yerleşim ve genç yaş tipiktir.",
    "path_b2B_013": "💡 HİKAYE: Primer TBC'de bakteri ilk kez akciğere geldiğinde alt-orta lobda bir odak oluşturur (Ghon odağı). Aynı taraftaki hiler lenf nodları da şişer. Bu ikisine birlikte 'Ghon kompleksi' denir — TBC'nin ilk ayak izi.",
    "path_b2B_014": "💡 HİKAYE: ARDS'de difüz alveoler hasar sonucu hiyalin membranlar oluşur — alveolleri kaplayan pembe cam benzeri tabakalar. Tip II pnömositler hasarı onarmaya çalışarak hiperplaziye uğrar. 'Akciğer yangını' sonucu hiyalin membran = ARDS.",
    "path_b2B_015": "💡 HİKAYE: Primer pulmoner hipertansiyonda BMPR2 geni mutasyona uğrar. Pulmoner arteriollerde pleksiform lezyonlar (damar içinde damar oluşumu) gelişir. BMPR2 damar düz kasının aşırı proliferasyonunu engelleyen frendir — fren bozulunca damarlar daralır.",
    "path_b2B_016": "💡 HİKAYE: Prematüre bebeğin akciğerinde yeterli sürfaktan yoktur. Sürfaktan olmadan alveol yüzey gerilimi artar ve atelektazi gelişir. Hiyalin membranlar oluşur — neonatal RDS'nin patolojik imzası. Antenatal steroid hayat kurtarır.",
    "path_b2B_017": "💡 HİKAYE: Berrak hücreli RCC'nin suçlusu VHL geni mutasyonudur (3p25). VHL normalde HIF'i yıkar — mutasyonda HIF birikir ve VEGF artar, anjiyogenez tetiklenir. Papiller RCC'de ise MET mutasyonu sorumludur — iki farklı gen, iki farklı alt tip.",
    "path_b2B_018": "💡 HİKAYE: VHL sendromu birçok organı etkiler: berrak hücreli RCC (böbrek), hemanjioblastom (serebellum/retina), feokromositoma (adrenal) ve pankreas NET. VHL mutasyonu taşıyanlarda bu tümörler genç yaşta ve bilateral ortaya çıkar.",
    "path_b2B_019": "💡 HİKAYE: Nefrotik sendromun en sık nedenleri yaşa göre değişir: çocuklarda minimal değişiklik hastalığı (steroid mucizesi), yetişkinlerde membranöz nefropati (primer) veya diyabet (sekonder). Her yaşın kendine özgü düşmanı var.",
    "path_b2B_020": "💡 HİKAYE: MCD'de ışık mikroskopunda glomerül tamamen normal görünür ama elektron mikroskopla bakınca podositlerin ayaksı çıkıntıları (pedisel) silinmiştir. Steroid tedavisine dramatik yanıt verir — çocuğun iyi huylu nefrotiği.",
    "path_b2B_021": "💡 HİKAYE: FSGS fokal (bazı glomerüller) ve segmental (glomerülün bir kısmı) skleroz gösterir. MCD'den farklı olarak steroide dirençlidir. HIV'de kollapsan varyant görülür — glomerül çöker ve progresyon hızlıdır.",
    "path_b2B_022": "💡 HİKAYE: Membranöz nefropatide anti-PLA2R antikorları subepitelyal bölgede birikerek bazal membranda çivi (spike) görünümü oluşturur. Gümüş boyası ile bu çiviler net görülür — 'membranda çivi çakan hastalık'.",
    "path_b2B_023": "💡 HİKAYE: IgA nefropatisinde (Berger hastalığı) ÜSYE'den 1-2 gün sonra makroskopik hematüri başlar — 'sinfaringitik hematüri'. İmmünfloresan (IF) mezangiumda IgA birikimini gösterir. En sık glomerülonefrit tipidir.",
    "path_b2B_024": "💡 HİKAYE: Streptokok boğaz enfeksiyonundan 2-3 hafta sonra nefritik sendrom gelişir (PSGN). IF'de subepitelyal 'hörgüç' (hump) şeklinde depozitler görülür. C3 düşüktür çünkü kompleman tüketilmiştir — streptokok intikamını geç alır.",
    "path_b2B_025": "💡 HİKAYE: Lupus nefriti sınıf IV'te (diffüz proliferatif) bazal membranda 'tel bant' (wire loop) görünümü oluşur. IF'de 'full house' paterni vardır — IgG, IgM, IgA, C3, C1q hepsi pozitif. Lupusun en ağır böbrek tutulumu.",
    "path_b2B_026": "💡 HİKAYE: Goodpasture sendromunda anti-GBM antikorları bazal membrana lineer şekilde yapışır (IF'de düz çizgi). Böbrekte ay hilali (crescent) şeklinde RPGN gelişir. Hem böbrek hem akciğer tutulur — pulmorenal sendrom.",
    "path_b2B_028": "💡 HİKAYE: Diyabetik nefropatide en erken bulgu GBM kalınlaşmasıdır. En spesifik bulgu ise Kimmelstiel-Wilson nodülüdür — mezangiumda eozinofilik nodüler skleroz. 'KW nodülü = Diyabetin böbrek imzası' diye hatırla.",
    "path_b2B_029": "💡 HİKAYE: Mesane kanserinin iki büyük suçlusu sigara ve aromatik aminlerdir (boya endüstrisi). S. haematobium ise mesanede skuamöz metaplazi yaparak skuamöz karsinoma yol açar — parazitik kanserin klasik örneği.",
    "path_b2B_030": "💡 HİKAYE: Renal papiller nekrozun üç büyük nedeni: NSAID kullanımı, diyabet ve orak hücreli anemi. Her üçü de papilla kan akışını bozar. 'Papil ACÜ-N' (Analjezik, Diabet, Orak hücre) diye kodla.",
    "path_b2B_031": "💡 HİKAYE: ATN'de proksimal tübül hücreleri ölür — ya iskemi (şok) ya da toksin (aminoglikozid, cisplatin) nedeniyle. Oligürik veya non-oligürik olabilir. Tübül hücreleri rejenere olabildiği için prognoz iyidir — AKI'nin en sık intrinsik nedeni.",
    "path_b2B_032": "💡 HİKAYE: HÜS'te EHEC (özellikle O157:H7) Shiga toksinini salgılar. Bu toksin endotel hücrelerini hasar eder ve trombotik mikroanjiopati (TMA) başlar. Böbrekte trombüsler birikir, eritrositler parçalanır — kanlı ishal sonrası böbrek yetmezliği.",
    "path_b2B_033": "💡 HİKAYE: Böbrek taşlarının %80'i kalsiyum oksalattır — en sık görülen taş. Strüvit taşı (amonyum magnezyum fosfat) enfeksiyonla ilişkilidir (Proteus). Ürik asit taşı gut hastalarında, sistin taşı ise genetik sistinüride görülür.",
}

base_dir = "C:/Users/ceyla/Desktop/tus/tus_app_project/tus_asistani/assets/data"

files = [
    "pathology_batch1A.json",
    "pathology_batch1B.json",
    "pathology_batch2A.json",
    "pathology_batch2B.json",
]

for fname in files:
    fpath = os.path.join(base_dir, fname)
    with open(fpath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    modified = 0
    for card in data.get("flashcards", []):
        card_id = card.get("id", "")
        if "story_hint" not in card and card_id in story_hints:
            # Insert story_hint after tags
            new_card = {}
            for key, value in card.items():
                new_card[key] = value
                if key == "tags":
                    new_card["story_hint"] = story_hints[card_id]
            card.clear()
            card.update(new_card)
            modified += 1

    with open(fpath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"{fname}: {modified} cards updated out of {len(data.get('flashcards', []))} total")

print("\nDone!")
