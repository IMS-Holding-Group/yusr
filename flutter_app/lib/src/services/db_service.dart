import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yusr_database.db');

    return await openDatabase(
      path,
      version: 11,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            name_ar TEXT NOT NULL,
            price REAL NOT NULL,
            description TEXT,
            description_ar TEXT,
            image_url TEXT,
            stock INTEGER DEFAULT 0,
            category TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            product_name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            total REAL NOT NULL,
            status TEXT DEFAULT 'pending',
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE cart (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            selected_image_url TEXT,
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE addresses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            street TEXT NOT NULL,
            city TEXT NOT NULL,
            district TEXT,
            building_number TEXT,
            apartment_number TEXT,
            postal_code TEXT,
            is_default INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE payment_methods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            payment_type TEXT NOT NULL,
            card_number TEXT,
            card_holder TEXT,
            expiry_month INTEGER,
            expiry_year INTEGER,
            cvv TEXT,
            wallet_provider TEXT,
            bank_name TEXT,
            is_default INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE user_product_interactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            weight REAL NOT NULL,
            interaction_type TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_upi_user ON user_product_interactions(user_id)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_upi_product ON user_product_interactions(product_id)');

        await _insertDefaultProducts(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS addresses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              title TEXT NOT NULL,
              street TEXT NOT NULL,
              city TEXT NOT NULL,
              district TEXT,
              building_number TEXT,
              apartment_number TEXT,
              postal_code TEXT,
              is_default INTEGER DEFAULT 0,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS payment_methods (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              payment_type TEXT NOT NULL,
              card_number TEXT,
              card_holder TEXT,
              expiry_month INTEGER,
              expiry_year INTEGER,
              cvv TEXT,
              wallet_provider TEXT,
              bank_name TEXT,
              is_default INTEGER DEFAULT 0,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');
        }

        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_product_interactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              product_id INTEGER NOT NULL,
              weight REAL NOT NULL,
              interaction_type TEXT NOT NULL,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_upi_user ON user_product_interactions(user_id)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_upi_product ON user_product_interactions(product_id)');
          await _ensureV10Products(db);
        }
        if (oldVersion < 11) {
          await _applyV11ProductMediaAndDescriptions(db);
        }
        
        final productCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products'));
        if (productCount == 0) {
          await _insertDefaultProducts(db);
        }
      },
    );
  }

  static Future<void> _insertDefaultProducts(Database db) async {
    final products = [
      // إلكترونيات
      {
        'name': 'iPhone 16 128GB',
        'name_ar': 'آيفون 16 - 128 جيجا',
        'price': 4800.0,
        'description': 'Latest iPhone 16 with 128GB storage',
        'description_ar':
            'هاتف آيفون 16 بذاكرة تخزين 128 جيجا، أحدث إصدار من آبل بمواصفات استثنائية وفريدة من نوعها. شاشة Super Retina XDR بحجم 6.1 بوصة بدقة 2556×1179 بكسل مع تقنية ProMotion 120 هرتز لسلاسة فائقة، كاميرا رئيسية 48 ميجابكسل مع نظام التصوير الحاسوبي المتقدم وعدسة زووم 2x و5x، كاميرا أمامية TrueDepth 12 ميجابكسل مع Face ID الأسرع والأدق، معالج A18 Pro بستة أنوية بسرعة 3.46 جيجا هرتز مع معالج رسوميات 6 أنوية، بطارية ليثيوم أيون بسعة 3274 مللي أمبير تدوم طوال اليوم مع دعم الشحن السريع 20 واط والشحن اللاسلكي MagSafe، مقاوم للماء والغبار بمعيار IP68 حتى عمق 6 أمتار لمدة 30 دقيقة، نظام iOS 18 مع ميزات ذكية متقدمة مثل Siri المحسّن والذكاء الاصطناعي، تصميم أنيق ومتين من التيتانيوم الخالص بوزن 187 جرام، متوفر بألوان متعددة، ضمان شامل لمدة عام مع دعم فني متميز',
        'image_url': 'IPhone-16.jpg',
        'stock': 20,
        'category': 'إلكترونيات'
      },
      {
        'name': 'Sony Headphones',
        'name_ar': 'سماعات سوني',
        'price': 1200.0,
        'description': 'Premium Sony wireless headphones',
        'description_ar':
            'سماعات سوني لاسلكية فاخرة بجودة صوت استثنائية وتقنيات متقدمة. تقنية إلغاء الضوضاء النشط المتقدمة V1 مع معالج QN1 المخصص الذي يمنحك تجربة صوتية نقية 100%، صوت Hi-Res Audio بجودة عالية الدقة 40 ميجا هرتز مع دعم LDAC لنقل الصوت بجودة استوديو، بطارية ليثيوم أيون تدوم حتى 30 ساعة مع شحن سريع 10 دقائق تعطيك 5 ساعات كاملة، مريحة للاستخدام لفترات طويلة بوسائد أذن ناعمة من الجلد الصناعي الفاخر، مقاومة للماء والعرق بمعيار IPX4، ميكروفونات مدمجة عالية الجودة مع تقنية Clear Voice للمكالمات الواضحة حتى في الأماكن الصاخبة، تحكم لمسي سهل على الأذن اليمنى واليسرى، تصميم أنيق ومتين من البلاستيك عالي الجودة، وزن خفيف 250 جرام، متوافقة مع جميع الأجهزة عبر Bluetooth 5.0، ضمان شامل لمدة عامين',
        'image_url': 'Sony-headphones.jpg',
        'stock': 25,
        'category': 'إلكترونيات'
      },
      {
        'name': 'PlayStation 5',
        'name_ar': 'جهاز بلايستيشن 5',
        'price': 2500.0,
        'description': 'Sony PlayStation 5 Gaming Console',
        'description_ar':
            'جهاز بلايستيشن 5 من سوني - أحدث جيل من أجهزة الألعاب بمواصفات استثنائية. معالج AMD Zen 2 بسرعة 3.5 جيجا هرتز مع معالج رسوميات AMD RDNA 2 بسرعة 2.23 جيجا هرتز، ذاكرة GDDR6 بسعة 16 جيجا، تخزين SSD سريع بسعة 825 جيجا بسرعة قراءة 5.5 جيجابايت/ثانية، دعم دقة 4K حتى 120 إطار في الثانية مع دعم Ray Tracing، دعم HDR و3D Audio، متوافق مع جميع ألعاب PS4، تحكم DualSense المتطور مع ردود فعل لمسية، تصميم أنيق ومبتكر، مناسب لجميع محبي الألعاب، تجربة ألعاب استثنائية بجودة فائقة، ضمان شامل لمدة عام',
        'image_url': 'Sony5.jpg',
        'stock': 15,
        'category': 'إلكترونيات'
      },
      {
        'name': 'Wireless AirPods',
        'name_ar': 'سماعات آيربودز لاسلكية',
        'price': 650.0,
        'description': 'Apple AirPods wireless earbuds',
        'description_ar':
            'سماعات آيربودز لاسلكية من آبل بجودة صوت ممتازة وتقنيات متطورة. تقنية Spatial Audio للصوت المحيطي الواقعي مع تتبع حركة الرأس للحصول على تجربة سينمائية، إلغاء الضوضاء النشط المتقدم مع معالج H2 المخصص، وضع الشفافية Adaptive Transparency الذي يسمح بسماع الأصوات الخارجية بشكل طبيعي، بطارية تدوم حتى 6 ساعات مع علبة شحن MagSafe تعطي 30 ساعة إضافية، شحن سريع 5 دقائق تعطيك ساعة واحدة كاملة، مقاومة للماء والعرق بمعيار IPX4، ميكروفونات عالية الجودة مع تقنية Voice Isolation للمكالمات الواضحة، تحكم باللمس على الساق مع دعم Siri، تصميم مريح وخفيف الوزن 5.4 جرام لكل سماعة، متوافقة مع جميع أجهزة آبل عبر Bluetooth 5.3، ضمان شامل لمدة عام',
        'image_url': 'Airpods.webp',
        'stock': 35,
        'category': 'إلكترونيات'
      },
      {
        'name': 'MacBook Pro',
        'name_ar': 'لابتوب ماك بوك برو',
        'price': 8500.0,
        'description': 'Professional MacBook Pro laptop',
        'description_ar':
            'حاسوب ماك بوك برو الاحترافي للأعمال والتصميم والبرمجة بمواصفات استثنائية. معالج Apple M3 Pro ب12 أنوية (6 أداء + 6 كفاءة) بسرعة تصل إلى 4.05 جيجا هرتز مع معالج رسوميات 18 أنوية، شاشة Liquid Retina XDR بحجم 14.2 بوصة بدقة 3024×1964 بكسل مع دعم P3 Wide Color وTrue Tone، ذاكرة وصول عشوائي موحدة 18 جيجا بسرعة فائقة، تخزين SSD سريع يصل إلى 1 تيرابايت بسرعة قراءة 7000 ميجابايت/ثانية، بطارية ليثيوم بوليمر بسعة 70 واط/ساعة تدوم حتى 18 ساعة من الاستخدام المستمر، كاميرا FaceTime HD 1080p مع معالج إشارة صورة متقدم، ميكروفونات استوديو ثلاثية المصفوفة مع تقنية Voice Isolation، مكبرات صوت عالية الجودة 6 مكبرات مع Spatial Audio، منافذ متعددة: 3 منافذ Thunderbolt 4، منفذ HDMI، منفذ SDXC، منفذ 3.5 مم، تصميم أنيق ومتين من الألومنيوم بوزن 1.6 كيلو جرام، لوحة مفاتيح Magic Keyboard مع Touch ID، ضمان شامل لمدة عام',
        'image_url': 'nuevo-MacBook-pro.webp',
        'stock': 12,
        'category': 'إلكترونيات'
      },
      {
        'name': 'HP Laptop',
        'name_ar': 'لابتوب HP',
        'price': 3200.0,
        'description': 'HP Professional Laptop',
        'description_ar':
            'لابتوب HP احترافي بمواصفات ممتازة وسعر مناسب. معالج Intel Core i7 بسرعة عالية، شاشة 15.6 بوصة بدقة Full HD واضحة، ذاكرة وصول عشوائي 16 جيجا، تخزين SSD 512 جيجا سريع، بطارية تدوم حتى 8 ساعات، كاميرا HD، ميكروفونات عالية الجودة، منافذ متعددة USB وHDMI، تصميم أنيق ومتين، مناسب للأعمال والدراسة، نظام تشغيل Windows 11، ضمان شامل لمدة عام',
        'image_url': 'Laptop.jpg',
        'stock': 18,
        'category': 'إلكترونيات'
      },
      {
        'name': 'Smartphone',
        'name_ar': 'هاتف ذكي',
        'price': 2200.0,
        'description': 'Modern smartphone',
        'description_ar':
            'هاتف ذكي حديث بمواصفات متقدمة وسعر مناسب للجميع. شاشة AMOLED كبيرة بحجم 6.7 بوصة بدقة Full HD+ 2400×1080 بكسل مع معدل تحديث 120 هرتز، كاميرا متعددة العدسات: كاميرا رئيسية 64 ميجابكسل، كاميرا واسعة الزاوية 12 ميجابكسل، كاميرا تقريب 5 ميجابكسل، كاميرا أمامية 32 ميجابكسل، معالج ثماني الأنوية بسرعة 2.4 جيجا هرتز مع معالج رسوميات متقدم، ذاكرة تخزين 128 جيجا مع إمكانية التوسع حتى 1 تيرابايت، بطارية 5000 مللي أمبير تدوم طويلاً مع شحن سريع 33 واط وشحن لاسلكي 15 واط، مقاوم للماء والغبار بمعيار IP68، نظام تشغيل حديث وسلس مع تحديثات أمنية دورية، تصميم أنيق ومتين من الزجاج والألومنيوم، متوفر بألوان متعددة، ضمان شامل لمدة عام',
        'image_url': 'Phone.jpg',
        'stock': 30,
        'category': 'إلكترونيات'
      },
      // ملابس
      {
        'name': 'Sports Shoes',
        'name_ar': 'حذاء رياضي',
        'price': 450.0,
        'description': 'High-quality sports shoes',
        'description_ar':
            'حذاء رياضي احترافي عالي الجودة مصمم للراحة والأداء المتميز من أفضل العلامات التجارية. نعل خارجي مطاطي متين من المطاط الطبيعي يوفر قبضة ممتازة على جميع الأسطح حتى المبتلة، نعل داخلي مريح وممتص للصدمات من مادة EVA المتقدمة يقلل من الإجهاد على القدمين والركبتين بنسبة 40%، مادة علوية قابلة للتنفس من النسيج المطاطي المتطور تمنع التعرق وتحافظ على القدم جافة وباردة، تصميم أنيق وعصري بألوان متنوعة وجذابة، مناسب للجري والمشي والرياضات المختلفة مثل كرة القدم والجري لمسافات طويلة، خفيف الوزن 280 جرام وسهل الحركة، متوفر بمقاسات مختلفة من 38 إلى 48، ضمان على الجودة لمدة 6 أشهر، مصنوع من مواد صديقة للبيئة',
        'image_url': 'Shose.jpg',
        'stock': 45,
        'category': 'ملابس'
      },
      {
        'name': 'Laptop Bag',
        'name_ar': 'حقيبة لابتوب',
        'price': 180.0,
        'description': 'Durable laptop bag',
        'description_ar':
            'حقيبة لابتوب متينة وعملية مصممة لحماية أجهزتك بأعلى معايير الجودة. جيوب متعددة منظمة: جيب رئيسي للابتوب حتى 17 بوصة، جيب منفصل للشاحن والكابلات، جيب للأوراق والملفات، جيب أمامي للهاتف والمفاتيح، حشو واقي من الصدمات من مادة EVA المتقدمة بسماكة 1.5 سم يحمي الجهاز من الكسر حتى عند السقوط من ارتفاع متر، حزام كتف قابل للتعديل بعرض 5 سم مريح للاستخدام مع وسادة كتف ناعمة، جيوب جانبية للهاتف والمفاتيح مع إغلاق بسحاب، مادة مقاومة للماء من البوليستر عالي الجودة تحمي المحتويات من المطر والرطوبة، تصميم أنيق ومناسب للعمل والسفر بألوان احترافية، متينة وعالية الجودة تدوم طويلاً مع ضمان لمدة عام، وزن خفيف 800 جرام، أبعاد 40×30×5 سم',
        'image_url': 'bug.webp',
        'stock': 60,
        'category': 'ملابس'
      },
      // أجهزة
      {
        'name': 'Coffee Maker',
        'name_ar': 'آلة قهوة أوتوماتيكية',
        'price': 750.0,
        'description': 'Automatic coffee maker machine',
        'description_ar':
            'آلة قهوة أوتوماتيكية متطورة تحضر قهوة لذيذة بضغطة زر واحدة بجودة استثنائية. سعة كبيرة لتحضير حتى 12 كوب في المرة الواحدة، نظام تنظيف تلقائي متقدم مع إزالة الترسبات والكلس، إعدادات متعددة لدرجة القوة (خفيفة، متوسطة، قوية) والحجم (صغير، متوسط، كبير)، سخان ماء سريع بدرجة حرارة قابلة للتعديل من 85 إلى 95 درجة مئوية، فلتر قابل للإزالة والتنظيف من الستانلس ستيل المقاوم للصدأ، مؤشر مستوى الماء الرقمي مع تنبيه عند الحاجة للتعبئة، تصميم أنيق وحديث بألوان عصرية، موفرة للطاقة بمعيار A+ مع استهلاك 1200 واط فقط أثناء التشغيل، سهلة الاستخدام والصيانة مع دليل شامل بالعربية، ضمان شامل لمدة عامين',
        'image_url': 'Coffee-machine.webp',
        'stock': 18,
        'category': 'أجهزة'
      },
      {
        'name': 'Air Conditioner',
        'name_ar': 'مكيف هواء ذكي',
        'price': 2800.0,
        'description': 'Smart energy efficient air conditioner',
        'description_ar':
            'مكيف هواء ذكي موفر للطاقة بمواصفات متقدمة وتقنيات حديثة. تبريد سريع وفعال بقدرة 18000 وحدة حرارية بريطانية BTU يبرد مساحة حتى 50 متر مربع في 10 دقائق، نظام فلترة الهواء المتقدم مع فلتر HEPA يزيل 99.97% من الجراثيم والغبار وحبوب اللقاح، تحكم عن بعد عبر التطبيق الذكي مع دعم Alexa وGoogle Assistant، وضع توفير الطاقة الذكي Inverter يقلل استهلاك الطاقة بنسبة 40%، مؤشر LED واضح يعرض درجة الحرارة والوضع الحالي، تشغيل صامت بضجيج أقل من 20 ديسيبل، مناسب للمنازل والمكاتب بمساحات متوسطة وكبيرة، ضمان شامل لمدة 5 سنوات على الضاغط و3 سنوات على الأجزاء مع خدمة صيانة مجانية سنوياً، موفر للطاقة بمعيار A+++',
        'image_url': 'Air-conditioner.jpeg',
        'stock': 12,
        'category': 'أجهزة'
      },
      {
        'name': 'Washing Machine',
        'name_ar': 'غسالة ملابس أوتوماتيكية',
        'price': 2200.0,
        'description': 'Automatic washing machine',
        'description_ar':
            'غسالة ملابس أوتوماتيكية بمواصفات عالية الجودة وتقنيات متطورة. سعة كبيرة 10 كيلو جرام مناسبة للعائلات الكبيرة، برامج متعددة 16 برنامج للأنواع المختلفة من الأقمشة (قطن، صوف، حرير، سريع، مكثف، اقتصادي)، موفرة للطاقة والماء بمعايير A+++ مع استهلاك 0.8 كيلو واط/ساعة و45 لتر ماء فقط، نظام تعقيم وتنظيف متقدم Steam Clean يزيل 99.9% من البكتيريا والجراثيم، شاشة LCD واضحة تعرض الوقت المتبقي والبرنامج الحالي، تشغيل صامت بضجيج أقل من 52 ديسيبل، مقاومة للاهتزاز مع نظام Balance Control الذكي، تصميم أنيق وحديث بألوان عصرية، سهلة الاستخدام مع دليل شامل، ضمان شامل لمدة 5 سنوات على المحرك و3 سنوات على الأجزاء',
        'image_url': 'Washing-machine.jpg',
        'stock': 15,
        'category': 'أجهزة'
      },
      {
        'name': 'Refrigerator',
        'name_ar': 'ثلاجة ذكية كبيرة',
        'price': 4200.0,
        'description': 'Large capacity smart refrigerator',
        'description_ar':
            'ثلاجة ذكية بسعة كبيرة 600 لتر مناسبة للعائلات الكبيرة بمواصفات استثنائية. موفرة للطاقة بمعايير A+++ مع استهلاك 280 كيلو واط/ساعة سنوياً فقط، تبريد موحد في جميع الأرفف مع نظام Multi Air Flow يوزع الهواء البارد بشكل متساوي، نظام No Frost المتقدم يمنع تكون الثلج نهائياً مع توفير الوقت والجهد، أرفف قابلة للتعديل في الارتفاع والعمق لتناسب جميع الأطعمة، درج للخضروات والفواكه مع نظام Fresh Zone يحافظ على النضارة لمدة أطول، فريزر كبير منفصل بسعة 200 لتر مع تبريد سريع حتى -24 درجة مئوية، شاشة لمس ذكية تعرض درجة الحرارة والوضع الحالي مع تحكم كامل، تنبيهات صوتية عند فتح الباب أو ارتفاع درجة الحرارة، تصميم أنيق وحديث بألوان عصرية، ضمان شامل لمدة 5 سنوات على الضاغط و3 سنوات على الأجزاء',
        'image_url': 'Refrigerator.jpg',
        'stock': 10,
        'category': 'أجهزة'
      },
      // أطعمة
      {
        'name': 'Organic Honey',
        'name_ar': 'عسل طبيعي عضوي',
        'price': 150.0,
        'description': 'Pure organic natural honey',
        'description_ar':
            'عسل طبيعي عضوي 100% من مصدر موثوق ومناحل معتمدة. غني بالفيتامينات والمعادن الطبيعية مثل فيتامين B1, B2, B6, C والحديد والكالسيوم والمغنيسيوم، مضاد للبكتيريا والالتهابات مع خصائص علاجية مذهلة، لذيذ المذاق الحلو الطبيعي ورائحة عطرية طبيعية مميزة، معبأ في عبوات زجاجية نظيفة ومعقمة بسعة 500 جرام، مناسب للاستخدام اليومي والعلاج الطبيعي للكحة والتهاب الحلق ومشاكل الجهاز الهضمي، خالي تماماً من المواد الحافظة والإضافات والسكر الصناعي، منتج طبيعي خالص معتمد من وزارة الصحة، تاريخ إنتاج وتاريخ انتهاء واضح، يحافظ على جودته لمدة 3 سنوات عند التخزين الصحيح',
        'image_url': 'Hony.jpg',
        'stock': 80,
        'category': 'أطعمة'
      },
      {
        'name': 'Premium Coffee',
        'name_ar': 'قهوة عربية فاخرة',
        'price': 180.0,
        'description': 'Premium Arabic coffee beans',
        'description_ar':
            'قهوة عربية فاخرة من أجود أنواع البن المختارة بعناية من أفضل المزارع. حبوب أرابيكا محمصة حديثاً على درجة حرارة مثالية للحفاظ على النكهة والرائحة، طعم غني ونكهة مميزة قوية مع حموضة متوازنة، ورائحة عطرة تملأ المكان، معبأة في عبوات محكمة الإغلاق من الألومنيوم تحافظ على النكهة والطزاجة لمدة 18 شهراً، مناسبة للاستخدام اليومي والضيافة مع إمكانية تحضيرها بطرق مختلفة (تركية، إسبريسو، أمريكية)، منتج طبيعي 100% خالي من المواد الحافظة، جودة عالية معتمدة من أفضل المعايير الدولية، وزن 500 جرام، تحافظ على جودتها عند التخزين في مكان جاف وبارد',
        'image_url': 'Arabic-coffee.webp',
        'stock': 55,
        'category': 'أطعمة'
      },
      {
        'name': 'Olive Oil',
        'name_ar': 'زيت زيتون بكر ممتاز',
        'price': 110.0,
        'description': 'Extra virgin olive oil',
        'description_ar':
            'زيت زيتون بكر ممتاز من أجود أنواع الزيتون المعتمدة من أفضل المزارع. طبيعي 100% معصور على البارد بدرجة حرارة أقل من 27 مئوية للحفاظ على جميع العناصر الغذائية، غني بالفيتامينات E و K ومضادات الأكسدة الطبيعية مثل البوليفينول، لون ذهبي جميل وشفاف يدل على الجودة العالية، طعم لذيذ خفيف مع حموضة أقل من 0.8% ورائحة عطرة مميزة، مناسب للطبخ والسلطات والاستخدام الطبي والعلاج الطبيعي للبشرة والشعر، معبأ في عبوات زجاجية داكنة تحافظ على الجودة من الضوء والأكسدة، سعة 500 مل، يحافظ على جودته لمدة 24 شهراً عند التخزين في مكان بارد ومظلم، معتمد من أفضل المعايير الدولية',
        'image_url': 'Olive-oil.jpg',
        'stock': 70,
        'category': 'أطعمة'
      },
      // أثاث
      {
        'name': 'Modern Sofa',
        'name_ar': 'أريكة عصرية فاخرة',
        'price': 3200.0,
        'description': 'Luxury modern sofa',
        'description_ar':
            'أريكة عصرية فاخرة بتصميم أنيق ومريح بجودة استثنائية. قماش عالي الجودة من البوليستر المقاوم للبقع والماء مع معالجة خاصة، حشو ناعم ومريح من الإسفنج عالي الكثافة مع ريش الإوز الطبيعي، إطار خشبي متين من خشب الزان الطبيعي المعالج يتحمل الأوزان الثقيلة حتى 300 كيلو جرام، متعددة المقاعد 3+2 مناسبة للصالة الكبيرة بأبعاد 280×220×90 سم، ألوان متنوعة تناسب جميع الديكورات (رمادي، بيج، أزرق، بني)، سهلة التنظيف مع إمكانية إزالة الأغطية للغسيل، متينة وعالية الجودة تدوم طويلاً مع ضمان لمدة 5 سنوات، مصنوعة يدوياً باهتمام بالتفاصيل، هدية مثالية للبيوت الجديدة',
        'image_url': 'Sofa.jpg',
        'stock': 6,
        'category': 'أثاث'
      },
      {
        'name': 'Dining Table',
        'name_ar': 'طاولة طعام خشبية',
        'price': 2400.0,
        'description': 'Wooden dining table',
        'description_ar':
            'طاولة طعام خشبية أنيقة بتصميم كلاسيكي عصري بجودة استثنائية. خشب طبيعي عالي الجودة من خشب الماهوجني الصلب المعالج بزيت طبيعي، سطح أملس ومقاوم للخدوش مع طبقة حماية من الورنيش الشفاف، متينة وقوية تتحمل الاستخدام اليومي والأوزان الثقيلة حتى 150 كيلو جرام، مناسبة للعائلات الكبيرة بأبعاد 200×100×75 سم تتسع لـ 8 أشخاص، تصميم أنيق يضفي لمسة جمالية على المكان مع أرجل منحنية أنيقة، سهلة التنظيف والصيانة مع إمكانية إعادة التلميع، مصنوعة يدوياً باهتمام بالتفاصيل، ضمان لمدة 3 سنوات، هدية مثالية للبيوت الجديدة',
        'image_url': 'Table.jpg',
        'stock': 8,
        'category': 'أثاث'
      },
      {
        'name': 'Office Chair',
        'name_ar': 'كرسي مكتب مريح',
        'price': 850.0,
        'description': 'Ergonomic office chair',
        'description_ar':
            'كرسي مكتب مريح بتصميم هندسي متقدم يمنحك الراحة الكاملة. دعم ممتاز للظهر والرقبة مع منحنى طبي يتبع شكل العمود الفقري، قابل للتعديل في الارتفاع من 45 إلى 55 سم والزاوية حتى 135 درجة مع قفل في 5 أوضاع، مساند ذراعين مريحة قابلة للتعديل في الارتفاع والعمق، عجلات سلسة للحركة من البلاستيك عالي الجودة على جميع أنواع الأرضيات، مادة قابلة للتنفس من شبكة Mesh Mesh مع حشو إسفنجي عالي الكثافة، مناسب للعمل لساعات طويلة مع تقليل إجهاد الظهر والرقبة بنسبة 60%، تصميم أنيق وعصري بألوان احترافية، يحمل وزن حتى 120 كيلو جرام، ضمان لمدة 3 سنوات، مناسب للمكاتب والمنازل',
        'image_url': 'Chair.webp',
        'stock': 25,
        'category': 'أثاث'
      },
      // كتب
      {
        'name': 'Python Programming Book',
        'name_ar': 'كتاب تعليم لغة Python',
        'price': 120.0,
        'description': 'Learn Python programming language',
        'description_ar':
            'كتاب تعليم لغة Python الشامل للمبتدئين والمتقدمين بمنهجية علمية متقدمة. شرح واضح ومبسط للمفاهيم الأساسية في Python مع رسوم توضيحية وأمثلة عملية، أمثلة عملية وتطبيقات واقعية من الحياة اليومية مع أكواد Python جاهزة للاستخدام، تمارين متنوعة لتعزيز الفهم مع حلول مفصلة في نهاية الكتاب، لغة عربية واضحة وسلسة مع ترجمة المصطلحات التقنية، مناسب لجميع الأعمار من 12 سنة فما فوق، غلاف أنيق وطباعة عالية الجودة على ورق فاخر، 500 صفحة من المعلومات القيمة، يتضمن 20 مشروعاً عملياً باستخدام Python، يغطي جميع أساسيات Python من المتغيرات والدوال إلى البرمجة الكائنية وقواعد البيانات، مناسب لتعلم Python من الصفر حتى الاحتراف، هدية مثالية للطلاب والمهتمين بالبرمجة بلغة Python',
        'image_url': 'Book.png',
        'stock': 40,
        'category': 'كتب'
      },
      {
        'name': 'Arabic Novel',
        'name_ar': 'رواية عربية كلاسيكية',
        'price': 75.0,
        'description': 'Classic Arabic novel',
        'description_ar':
            'رواية عربية كلاسيكية من الأدب العربي الأصيل لأحد أشهر الكتاب العرب. قصة مشوقة ومثيرة تجذب القارئ من الصفحة الأولى، أسلوب أدبي راقي مع لغة عربية فصيحة جميلة، شخصيات متطورة ومعقدة تتفاعل مع الأحداث بشكل طبيعي، أحداث متسلسلة ومشوقة مع مفاجآت غير متوقعة، طباعة عالية الجودة على ورق فاخر، غلاف أنيق بتصميم فني جميل، مناسبة لجميع محبي الأدب العربي من جميع الأعمار، 400 صفحة من المتعة الأدبية، تتضمن رسائل إنسانية عميقة، هدية مثالية لعشاق القراءة، تحافظ على قيمتها الأدبية عبر الزمن',
        'image_url': 'novel.png',
        'stock': 50,
        'category': 'كتب'
      },
      // ألعاب
      {
        'name': 'Chess Set',
        'name_ar': 'طقم شطرنج فاخر',
        'price': 280.0,
        'description': 'Premium chess set',
        'description_ar':
            'طقم شطرنج فاخر بجودة استثنائية من أفضل العلامات التجارية. قطع خشبية مصنوعة يدوياً بدقة عالية من خشب الأبنوس والقيقب الطبيعي مع وزن مثالي، لوحة شطرنج أنيقة من الخشب الطبيعي بحجم 50×50 سم مع مربعات واضحة، تصميم كلاسيكي راقي مع تفاصيل دقيقة على كل قطعة، مناسب للهواة والمحترفين مع مواصفات قياسية دولية، هدية مثالية لعشاق الشطرنج من جميع الأعمار، متين وعالي الجودة مع علبة تخزين فاخرة من الخشب، قطع الملك بارتفاع 9.5 سم مع قاعدة عريضة، متوافق مع معايير FIDE الدولية، يحافظ على جودته لسنوات طويلة',
        'image_url': 'Chess.webp',
        'stock': 30,
        'category': 'ألعاب'
      },
      {
        'name': 'Puzzle Game',
        'name_ar': 'لعبة بازل 1000 قطعة',
        'price': 95.0,
        'description': '1000 pieces jigsaw puzzle',
        'description_ar':
            'لعبة بازل تحدي 1000 قطعة بجودة عالية من أفضل العلامات التجارية. صورة جميلة وواضحة بدقة عالية مطبوعة على ورق فاخر مقاوم للماء، قطع متقنة الصنع تتناسب بسهولة مع أشكال فريدة تمنع الخطأ، مناسبة للكبار والصغار من 8 سنوات فما فوق، تساعد على تطوير المهارات العقلية والتركيز والذاكرة البصرية، وقت ممتع ومفيد يقضي ساعات من المتعة والتعلم، هدية مثالية للعائلة والأصدقاء، حجم الصورة النهائية 70×50 سم، تتضمن صورة مرجعية كاملة، قطع سميكة ومتينة لا تنكسر بسهولة، تحافظ على جودتها لسنوات طويلة، مناسبة للإطار والعرض بعد الانتهاء',
        'image_url': 'Pazel.jpg',
        'stock': 45,
        'category': 'ألعاب'
      },
      ..._v10ExtraProducts(),
    ];

    for (var product in products) {
      await db.insert('products', product);
    }
  }

  /// منتجات إضافية (نسخة قاعدة 10+) — صور مخصصة وأوصاف مفصلة
  static List<Map<String, dynamic>> _v10ExtraProducts() {
    return [
      {
        'name': 'iPhone 16 Green',
        'name_ar': 'آيفون 16 بلون أخضر',
        'price': 4950.0,
        'description': 'iPhone 16 green finish',
        'description_ar':
            'هاتف آيفون 16 بلون أخضر مميز، شاشة سوبر ريتنا، كاميرا 48 ميجابكسل، معالج A18، مناسب لمن يفضل لوناً مميزاً.',
        'image_url': 'iPhone-16-green.jpg',
        'stock': 14,
        'category': 'إلكترونيات'
      },
      ..._v11StyledTabletToBikeProducts(),
    ];
  }

  /// السبعة منتجات التي حُدّثت بصور وأوصاف تفصيلية (ترقية v11)
  static List<Map<String, dynamic>> _v11StyledTabletToBikeProducts() {
    return [
      {
        'name': 'Android Tablet 10',
        'name_ar': 'تابلت أندرويد 10 بوصة',
        'price': 899.0,
        'description':
            '10.1" Android tablet IPS HD, quad-core, 4GB RAM, 64GB storage, Wi-Fi, Bluetooth, dual speakers, 6000mAh battery',
        'description_ar':
            'تابلت أندرويد بشاشة IPS عالية الوضوح بحجم 10.1 بوصة بدقة HD مريحة للقراءة والأفلام والدروس عن بُعد، معالج رباعي النواة بتردد عالٍ يضمن تشغيل التطبيقات والألعاب الخفيفة بسلاسة، ذاكرة وصول عشوائي 4 جيجابايت وتخزين داخلي 64 جيجابايت قابل للتوسعة عبر بطاقة ذاكرة، اتصال Wi-Fi ثنائي النطاق وبلوتوث 5.0 لمكبرات الصوت وسماعات الرأس، مكبرات صوت ستيريو بجهير واضح، كاميرا أمامية وخلفية للمكالمات والتصوير البسيط، بطارية ليثيوم كبيرة تدوم طوال يوم الدراسة أو السفر مع شحن سريع عبر USB-C، هيكل معدني أنيق وخفيف الوزن مع زوايا مدورة آمنة للأطفال، منفذ سماعات 3.5 مم، نظام أندرويد حديث مع دعم العربية الكامل، مناسب للترفيه والقراءة الإلكترونية والتعليم الرقمي لجميع أفراد العائلة',
        'image_url': 'Tablet.jpg',
        'stock': 22,
        'category': 'إلكترونيات'
      },
      {
        'name': 'Fast Wireless Charger',
        'name_ar': 'شاحن لاسلكي سريع',
        'price': 199.0,
        'description':
            'Qi wireless fast charging pad, 15W max, USB-C input, LED status, non-slip ring, case-friendly',
        'description_ar':
            'شاحن لاسلكي سريع بتقنية Qi متوافق مع معظم الهواتف الذكية التي تدعم الشحن اللاسلكي، يصل إلى 15 واط للهواتف المدعومة مع إدارة حرارية ذكية تقلل ارتفاع الحرارة أثناء الشحن، مدخل USB-C عالمي مع كابل عالي الجودة، حلقة سيليكون مضادة للانزلاق تحافظ على ثبات الهاتف، مؤشر LED يوضح حالة الشحن دون إزعاج ليلي، تصميم نحيف ومسطح يعمل مع معظم الأغطية الرفيعة دون إزالة الجراب، حماية متعددة من التيار الزائد والحرارة والدائرة القصيرة، مناسب للمكتب وغرفة النوم والسيارة مع محول مناسب، يقلل تآكل منفذ الشحن السلكي ويطيل عمر المنفذ',
        'image_url': 'Charger.jpg',
        'stock': 40,
        'category': 'إلكترونيات'
      },
      {
        'name': 'Electric Kettle',
        'name_ar': 'غلاية كهربائية',
        'price': 129.0,
        'description':
            'Tea Master electric kettle 1.7L, 1850-2200W, stainless steel, auto shut-off, 360° base',
        'description_ar':
            'غلاية كهربائية من سلسلة تي ماستر بسعة 1.7 لتر تناسب تحضير الشاي والقهوة والمشروبات الساخنة للعائلة، هيكل داخلي من الستانلس ستيل الغذائي الصحي مقاوم للصدأ والروائح، قاعدة دوارة 360 درجة تسمح بوضع الإناء بأي اتجاه، قوة تسخين عالية تغلي الماء بسرعة مع استهلاك كهربائي معقول، إطفاء تلقائي عند الغليان وحماية من التشغيل الجاف لأمان إضافي، نافذة مياه شفافة لمعرفة المستوى، مقبض عازل للحرارة ومفتاح تشغيل واضح، فتحة تبخير واسعة يسهل تنظيفها، قاعدة تخزين للسلك، تصميم عصري يناسب المطبخ العربي والمكاتب، ضمان على العيوب الصناعية',
        'image_url': 'Tea Master.jpg',
        'stock': 28,
        'category': 'أجهزة'
      },
      {
        'name': 'Smart Ceiling Fan',
        'name_ar': 'مروحة سقف ذكية',
        'price': 650.0,
        'description':
            '321 series ceiling fan, DC motor, 6 speeds, remote control, timer, quiet operation',
        'description_ar':
            'مروحة سقف من سلسلة 321 بمحرك تيار مستمر موفر للطاقة يوفر استهلاكاً أقل من المحركات التقليدية مع تدفق هواء قوي ومنتظم، ست سرعات للتحكم الدقيق في البرودة، جهاز تحكم لاسلكي يدوي مع مؤقت إيقاف حتى 8 ساعات لراحة النوم، تشغيل هادئ جداً يقلل الضوضاء في غرف النوم وصالات الجلوس، ريش عالية التوازن تقلل الاهتزاز، إضاءة LED اختيارية في بعض الطرازات لإنارة المكان، قابلية للتركيب على أسقف بارتفاعات مختلفة مع قضيب تمديد، مناسبة للمنازل والمكاتب والمحلات، تصميم عصري يتناسب مع الديكور الحديث، ضمان على المحرك والقطع الأساسية',
        'image_url': '321.jpg',
        'stock': 11,
        'category': 'أجهزة'
      },
      {
        'name': 'Spice Gift Set',
        'name_ar': 'طقم توابل فاخرة',
        'price': 89.0,
        'description':
            'Premium Arabic spice gift set in glass jars, curated blend, airtight lids, gift-ready',
        'description_ar':
            'طقم توابل فاخرة مختارة بعناية للمطبخ العربي يتضمن مزيجاً من البهارات الأساسية مثل الكمون والكزبرة والفلفل الأسود والبابريكا والكركم والقرفة والهيل والقرنفل وغيرها حسب التعبئة، معبأة في برطمانات زجاجية شفافة محكمة الإغلاق تحافظ على النكهة والرائحة الطازجة وتمنع الرطوبة والحشرات، أغطية معدنية أو بلاستيكية بسحاب محكم، تسميات واضحة بالعربية لسهولة التعرف للمكفوفين مع وصف استخدام مختصر، علبة هدايا أنيقة مناسبة للمناسبات والعيد والضيافة، منتجات طبيعية بجودة عالية خالية من المواد المالئة الاصطناعية، وزن إجمالي مناسب للاستخدام العائلي لعدة أشهر، يحفظ في مكان جاف بعيداً عن الشمس المباشرة',
        'image_url':
            '40128f8318bafaee7241f3f4c044df3a_d9f10d67-27c4-4dd3-8a48-c05c1d7f94a5.webp',
        'stock': 60,
        'category': 'أطعمة'
      },
      {
        'name': 'Wooden Bookshelf',
        'name_ar': 'رف كتب خشبي',
        'price': 420.0,
        'description':
            '4-tier wooden bookshelf, engineered wood, high load capacity, anti-tip, easy assembly',
        'description_ar':
            'رف كتب خشبي متعدد المستويات بأربعة أرفف واسعة تستوعب كتباً ومجلدات وألعاباً وتزييناً، مصنوع من خشب هندسي عالي الجودة بطلاء مقاوم للخدوش ولون متجانس، أرجل متينة توزع الوزن على الأرضية، سعة تحميل جيدة لكل رف عند توزيع الكتب بالتساوي، حواف ملساء ومفصولة بأمان للأطفال، تصميم محايد يناسب غرف النوم والمكتب والصالة، تعليمات تجميع واضحة مع مسامير وقطع مرقمة، يمكن تثبيته على الحائط برباط مضاد للانقلاب لزيادة الأمان عند وجود أطفال، سهل التنظيف بقطعة قماش جافة، أبعاد مناسبة للمساحات المتوسطة، يعطي طابعاً دافئاً للمكتبة المنزلية',
        'image_url': '71lxCY6LgVL._AC_SL1500_.jpg',
        'stock': 9,
        'category': 'أثاث'
      },
      {
        'name': 'Balance Bike Kids',
        'name_ar': 'دراجة توازن للأطفال',
        'price': 310.0,
        'description':
            'Kids balance bike EVA tires, steel frame, adjustable seat, ages 2-5, lightweight',
        'description_ar':
            'دراجة توازن للأطفال بدون دواسات لتعلم التوازن والدفع بالقدمين قبل الانتقال لدراجة ذات دواسات، إطارات إيفا خفيفة وناعمة لا تحتاج هواء وتقلل خطر البنشر، هيكل فولاذي أو ألمنيوم مقوّى بدهان مقاوم للخدوش، مقعد قابل للرفع والخفض ليتناسب مع طول الطفل من عمر حوالي سنتين حتى خمس سنوات، مقود بزاوية مريحة ومقابض مطاطية مريحة للأيدي الصغيرة، وزن خفيف يسهل على الوالدين حمله، موانع واقية للركبتين اختيارية، مناسبة للحدائق الداخلية والممرات المسطحة والمدارس، تساعد على تطوير الإحساس بالتوازن والثقة بالنفس، تتبع معايير السلامة الأساسية مع زوايا دائرية، دليل استخدام بالعربية',
        'image_url': '41olzVIB+lL._SL500_._AC_SL500_.jpg',
        'stock': 18,
        'category': 'ألعاب'
      },
    ];
  }

  static Future<void> _applyV11ProductMediaAndDescriptions(Database db) async {
    for (final p in _v11StyledTabletToBikeProducts()) {
      await db.update(
        'products',
        {
          'image_url': p['image_url'],
          'description_ar': p['description_ar'],
          'description': p['description'],
        },
        where: 'name_ar = ?',
        whereArgs: [p['name_ar']],
      );
    }
  }

  static Future<void> _ensureV10Products(Database db) async {
    for (final p in _v10ExtraProducts()) {
      final nameAr = p['name_ar'] as String;
      final c = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM products WHERE name_ar = ?',
        [nameAr],
      ));
      if (c == 0) {
        await db.insert('products', p);
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'id ASC');
  }

  static Future<Map<String, dynamic>?> getProduct(int id) async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'name_ar LIKE ? OR description_ar LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
  }

  static Future<List<Map<String, dynamic>>> getProductsByCategory(
      String category) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'id ASC',
    );
  }

  static Future<int> addToCart(int productId, int quantity, {String? selectedImageUrl}) async {
    final db = await database;
    final existing = await db.query(
      'cart',
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    if (existing.isEmpty) {
      return await db.insert('cart', {
        'product_id': productId,
        'quantity': quantity,
        'selected_image_url': selectedImageUrl,
      });
    } else {
      return await db.update(
        'cart',
        {
          'quantity': (existing.first['quantity'] as int) + quantity,
          'selected_image_url': selectedImageUrl ?? existing.first['selected_image_url'],
        },
        where: 'product_id = ?',
        whereArgs: [productId],
      );
    }
  }

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.id, c.product_id, c.quantity, c.selected_image_url,
             p.name_ar, p.price, p.description_ar, p.image_url
      FROM cart c
      INNER JOIN products p ON c.product_id = p.id
    ''');
  }

  static Future<int> updateCartQuantity(int cartId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      return await db.delete('cart', where: 'id = ?', whereArgs: [cartId]);
    }
    return await db.update(
      'cart',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [cartId],
    );
  }

  static Future<int> removeFromCart(int cartId) async {
    final db = await database;
    return await db.delete('cart', where: 'id = ?', whereArgs: [cartId]);
  }

  static Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart');
  }

  static Future<int> createOrder(List<Map<String, dynamic>> cartItems) async {
    final db = await database;
    int orderId = 0;

    await db.transaction((txn) async {
      for (var item in cartItems) {
        final orderData = {
          'product_id': item['product_id'],
          'product_name': item['name_ar'],
          'quantity': item['quantity'],
          'total': (item['price'] as double) * (item['quantity'] as int),
          'status': 'pending',
        };
        orderId = await txn.insert('orders', orderData);
      }
      await txn.delete('cart');
    });

    return orderId;
  }

  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await database;
    return await db.query('orders', orderBy: 'created_at DESC');
  }

  static Future<Map<String, dynamic>?> getOrder(int orderId) async {
    final db = await database;
    final results = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  static Future<int> updateOrderStatus(int orderId, String status) async {
    final db = await database;
    return await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  static Future<int> deleteOrder(int orderId) async {
    final db = await database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [orderId]);
  }

  static Future<int> addAddress({
    required int userId,
    required String title,
    required String street,
    required String city,
    String? district,
    String? buildingNumber,
    String? apartmentNumber,
    String? postalCode,
    bool isDefault = false,
  }) async {
    final db = await database;
    if (isDefault) {
      await db.update('addresses', {'is_default': 0}, where: 'user_id = ?', whereArgs: [userId]);
    }
    return await db.insert('addresses', {
      'user_id': userId,
      'title': title,
      'street': street,
      'city': city,
      'district': district,
      'building_number': buildingNumber,
      'apartment_number': apartmentNumber,
      'postal_code': postalCode,
      'is_default': isDefault ? 1 : 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getAddresses(int userId) async {
    final db = await database;
    return await db.query(
      'addresses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_default DESC, created_at DESC',
    );
  }

  static Future<Map<String, dynamic>?> getAddress(int addressId) async {
    final db = await database;
    final results = await db.query('addresses', where: 'id = ?', whereArgs: [addressId]);
    if (results.isEmpty) return null;
    return results.first;
  }

  static Future<int> deleteAddress(int addressId) async {
    final db = await database;
    return await db.delete('addresses', where: 'id = ?', whereArgs: [addressId]);
  }

  static Future<int> addPaymentMethod({
    required int userId,
    required String paymentType,
    String? cardNumber,
    String? cardHolder,
    int? expiryMonth,
    int? expiryYear,
    String? cvv,
    String? walletProvider,
    String? bankName,
    bool isDefault = false,
  }) async {
    final db = await database;
    if (isDefault) {
      await db.update('payment_methods', {'is_default': 0}, where: 'user_id = ?', whereArgs: [userId]);
    }
    return await db.insert('payment_methods', {
      'user_id': userId,
      'payment_type': paymentType,
      'card_number': cardNumber,
      'card_holder': cardHolder,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'cvv': cvv,
      'wallet_provider': walletProvider,
      'bank_name': bankName,
      'is_default': isDefault ? 1 : 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getPaymentMethods(int userId) async {
    final db = await database;
    return await db.query(
      'payment_methods',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_default DESC, created_at DESC',
    );
  }

  static Future<Map<String, dynamic>?> getPaymentMethod(int paymentMethodId) async {
    final db = await database;
    final results = await db.query('payment_methods', where: 'id = ?', whereArgs: [paymentMethodId]);
    if (results.isEmpty) return null;
    return results.first;
  }

  static Future<int> deletePaymentMethod(int paymentMethodId) async {
    final db = await database;
    return await db.delete('payment_methods', where: 'id = ?', whereArgs: [paymentMethodId]);
  }

  static Future<void> ensureProductsExist() async {
    final db = await database;
    final productCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products'));
    if (productCount == 0) {
      await _insertDefaultProducts(db);
    }
  }
}
