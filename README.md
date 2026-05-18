# يُسر - منصة التسوق الصوتية

## جدول المحتويات

1. [نظرة عامة على المشروع](#نظرة-عامة-على-المشروع)
2. [الهندسة المعمارية التقنية](#الهندسة-المعمارية-التقنية)
3. [المتطلبات والتثبيت](#المتطلبات-والتثبيت)
4. [هيكل المشروع](#هيكل-المشروع)
5. [تشغيل التطبيق](#تشغيل-التطبيق)
6. [الميزات](#الميزات)
7. [المكونات التقنية](#المكونات-التقنية)
8. [هيكل قاعدة البيانات](#هيكل-قاعدة-البيانات)
9. [توثيق واجهة البرمجة](#توثيق-واجهة-البرمجة)
10. [شرح الأكواد المهمة](#شرح-الأكواد-المهمة)
11. [استكشاف الأخطاء وحلها](#استكشاف-الأخطاء-وحلها)

---

## نظرة عامة على المشروع

### ما هو يُسر؟

يُسر هو منصة تسوق ذكية تعمل بالتحكم الصوتي مصممة خصيصاً لذوي الإعاقة البصرية والحركية. يتيح التطبيق للمستخدمين التسوق بالكامل باستخدام الأوامر الصوتية العربية دون الحاجة للمس الشاشة.

### أهداف المشروع

- تمكين البحث عن المنتجات وإدارتها بالصوت
- دعم كامل للغة العربية (اللهجة السعودية)
- فهم اللغة الطبيعية المتقدم (NLU) للأوامر الصوتية
- إمكانية الوصول الكاملة لذوي الإعاقة البصرية والحركية
- عمل بدون إنترنت مع قاعدة بيانات محلية

### المستخدمون المستهدفون

- ذوو الإعاقة البصرية
- ذوو الإعاقة الحركية
- كبار السن الذين يفضلون التفاعل الصوتي
- أي شخص يبحث عن تجربة تسوق بدون لمس

---

## الهندسة المعمارية التقنية

### مكونات النظام

يتكون المشروع من مكونين رئيسيين:

1. **تطبيق Flutter المحمول** (الواجهة الأمامية)
   - تطبيق متعدد المنصات (Android/iOS)
   - واجهة تفاعل صوتية
   - قاعدة بيانات SQLite محلية
   - تكامل تحويل النص إلى كلام (TTS) والكلام إلى نص (STT)

2. **خادم Flask الخلفي** (الخلفية)
   - واجهة برمجة REST API مبنية على Python
   - محرك فهم اللغة الطبيعية (NLU)
   - نموذج تعلم آلي للتعرف على النوايا
   - معالجة النصوص العربية

### التقنيات المستخدمة

**الواجهة الأمامية:**
- Flutter SDK (لغة Dart)
- SQLite للتخزين المحلي
- flutter_tts لتحويل النص إلى كلام
- speech_to_text للتعرف على الصوت

**الخلفية:**
- Python 3.10 أو أحدث
- إطار عمل Flask
- scikit-learn للتعلم الآلي
- Transformers (اختياري) لفهم اللغة الطبيعية المتقدم

### كيف يعمل النظام

1. المستخدم يتحدث أمراً بالعربية
2. التطبيق المحمول يلتقط الصوت ويحوله إلى نص (STT)
3. النص يُرسل إلى خدمة NLU في الخادم
4. الخادم يحلل النية ويستخرج الكيانات
5. الاستجابة تُرسل مرة أخرى للتطبيق المحمول
6. التطبيق ينفذ الإجراء ويقدم ردود فعل صوتية (TTS)

---

## المتطلبات والتثبيت

### الفصل الأول: تثبيت Python

#### ما هو Python؟

Python هي لغة برمجة تُستخدم لبناء خادم الخلفية. يمكنك التفكير فيها كـ"الدماغ" الذي يعالج الأوامر الصوتية.

#### خطوات تثبيت Python خطوة بخطوة

**لنظام Windows:**

1. زر الموقع: https://www.python.org/downloads/
2. حمّل Python 3.10 أو أحدث (أحدث إصدار مستقر)
3. شغّل المثبت
4. **مهم:** ضع علامة على المربع "Add Python to PATH" أثناء التثبيت
5. اضغط "Install Now"
6. انتظر حتى يكتمل التثبيت
7. تحقق من التثبيت:
   - افتح موجه الأوامر (ابحث عن "cmd" في قائمة البدء)
   - اكتب: `python --version`
   - يجب أن ترى: `Python 3.10.x` أو ما شابه

**لنظام macOS:**

1. افتح تطبيق Terminal
2. تحقق من تثبيت Python: `python3 --version`
3. إذا لم يكن مثبتاً، ثبّت Homebrew أولاً:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
4. ثبّت Python:
   ```bash
   brew install python3
   ```

**لنظام Linux (Ubuntu/Debian):**

```bash
sudo apt update
sudo apt install python3 python3-pip
```

#### التحقق من تثبيت Python

افتح Terminal أو موجه الأوامر وشغّل:
```bash
python --version
```
أو
```bash
python3 --version
```

يجب أن ترى رقم إصدار مثل `Python 3.10.6` أو أعلى.

---

### الفصل الثاني: تثبيت Flutter

#### ما هو Flutter؟

Flutter هو إطار عمل من Google لبناء تطبيقات المحمول. يتيح لك إنشاء تطبيقات لكل من Android و iOS باستخدام كود واحد.

#### خطوات تثبيت Flutter خطوة بخطوة

**لنظام Windows:**

1. تحميل Flutter SDK:
   - زر الموقع: https://docs.flutter.dev/get-started/install/windows
   - حمّل أحدث ملف ZIP لـ Flutter SDK المستقر
   - استخرج ملف ZIP إلى موقع مثل `C:\src\flutter`
   - **لا** تستخرج إلى مجلد يحتوي على مسافات أو أحرف خاصة

2. إضافة Flutter إلى PATH:
   - ابحث عن "Environment Variables" في بحث Windows
   - اضغط "Edit the system environment variables"
   - اضغط زر "Environment Variables"
   - تحت "System variables"، ابحث عن "Path" واضغط "Edit"
   - اضغط "New" وأضف: `C:\src\flutter\bin` (أو مسار Flutter الخاص بك)
   - اضغط "OK" على جميع النوافذ

3. تثبيت Git:
   - حمّل من https://git-scm.com/download/win
   - ثبّت بالإعدادات الافتراضية

4. التحقق من تثبيت Flutter:
   - افتح موجه أوامر جديد
   - شغّل: `flutter doctor`
   - سيفحص هذا الإعداد ويعرض ما هو مفقود

**لنظام macOS:**

1. تحميل Flutter SDK:
   ```bash
   cd ~/development
   git clone https://github.com/flutter/flutter.git -b stable
   ```

2. إضافة إلى PATH:
   ```bash
   export PATH="$PATH:`pwd`/flutter/bin"
   ```
   أضف هذا السطر إلى `~/.zshrc` أو `~/.bash_profile` لجعله دائماً

3. التحقق:
   ```bash
   flutter doctor
   ```

**لنظام Linux:**

```bash
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

#### تثبيت الأدوات الإضافية

**Android Studio (مطلوب لتطوير Android):**

1. حمّل من https://developer.android.com/studio
2. ثبّت Android Studio
3. افتح Android Studio
4. اذهب إلى "More Actions" > "SDK Manager"
5. ثبّت Android SDK (مستوى API 33 أو أعلى)
6. ثبّت Android SDK Command-line Tools
7. اقبل جميع التراخيص عند المطالبة

**Xcode (مطلوب لتطوير iOS - macOS فقط):**

1. ثبّت من Mac App Store
2. افتح Xcode واقبل اتفاقية الترخيص
3. ثبّت المكونات الإضافية عند المطالبة

#### التحقق من إعداد Flutter

شغّل هذا الأمر:
```bash
flutter doctor
```

يجب أن ترى علامات صح بجانب:
- Flutter (SDK)
- Android toolchain (لتطوير Android)
- Xcode (لتطوير iOS، macOS فقط)
- VS Code أو Android Studio (بيئة التطوير الخاصة بك)

---

### الفصل الثالث: تثبيت أدوات التطوير

#### Visual Studio Code (بيئة التطوير الموصى بها)

1. حمّل من https://code.visualstudio.com/
2. ثبّت VS Code
3. افتح VS Code
4. ثبّت امتداد Flutter:
   - اضغط أيقونة Extensions (الشريط الجانبي الأيسر)
   - ابحث عن "Flutter"
   - اضغط "Install" على امتداد Flutter من Dart Code
   - سيتم تثبيت امتداد Dart تلقائياً

#### Android Studio (بيئة تطوير بديلة)

1. حمّل من https://developer.android.com/studio
2. ثبّت Android Studio
3. افتح Android Studio
4. اذهب إلى "Plugins"
5. ابحث عن "Flutter" وثبّته
6. أعد تشغيل Android Studio

---

## هيكل المشروع

```
yusr/
├── backend/                    # خادم Python الخلفي
│   ├── app.py                 # تطبيق Flask الرئيسي
│   ├── train_nlu_model.py     # سكريبت تدريب نموذج NLU
│   ├── advanced_training.py   # أدوات التدريب المتقدمة
│   ├── requirements.txt       # تبعيات Python
│   ├── data/                  # ملفات البيانات
│   │   ├── nlu_dataset.json   # مجموعة بيانات التدريب
│   │   ├── nlu_model.pkl      # النموذج المدرب
│   │   └── yusr.db            # قاعدة بيانات SQLite
│   └── modules/               # وحدات الخلفية
│       ├── db.py              # عمليات قاعدة البيانات
│       ├── nlu.py             # معالجة NLU
│       └── stt_tts.py         # معالجة الصوت
│
├── flutter_app/               # تطبيق Flutter المحمول
│   ├── lib/                   # الكود المصدري
│   │   ├── main.dart         # نقطة دخول التطبيق
│   │   └── src/
│   │       ├── services/     # خدمات منطق الأعمال
│   │       │   ├── voice_service.dart
│   │       │   ├── voice_navigation_service.dart
│   │       │   ├── db_service.dart
│   │       │   └── api_client.dart
│   │       ├── ui/            # واجهة المستخدم
│   │       │   ├── screens/   # شاشات التطبيق
│   │       │   └── widgets/  # مكونات قابلة لإعادة الاستخدام
│   │       └── theme/         # تصميم التطبيق
│   ├── assets/               # الصور، الخطوط، إلخ
│   └── pubspec.yaml          # تبعيات Flutter
│
└── README.md                 # هذا الملف
```

### شرح الملفات الرئيسية

**ملفات الخلفية:**
- `app.py`: ملف الخادم الرئيسي الذي يتعامل مع طلبات HTTP
- `train_nlu_model.py`: سكريبت لتدريب نموذج الذكاء الاصطناعي لفهم الأوامر العربية
- `requirements.txt`: قائمة حزم Python المطلوبة

**ملفات Flutter:**
- `main.dart`: نقطة البداية للتطبيق المحمول
- `voice_service.dart`: يتعامل مع تحويل النص إلى كلام والكلام إلى نص
- `db_service.dart`: يدير عمليات قاعدة البيانات المحلية
- `pubspec.yaml`: يسرد جميع حزم Flutter المستخدمة في التطبيق

---

## تشغيل التطبيق

### الجزء الأول: إعداد خادم الخلفية

#### الخطوة 1: الانتقال إلى مجلد الخلفية

افتح موجه الأوامر (Windows) أو Terminal (Mac/Linux) وانتقل إلى مجلد الخلفية:

```bash
cd path/to/yusr/backend
```

على سبيل المثال:
```bash
cd C:\Users\MoSh\VSCode\Projects\flutterprojects\yusr\backend
```

#### الخطوة 2: تثبيت تبعيات Python

**ما هي التبعيات؟**

التبعيات هي مكتبات خارجية (حزم) يحتاجها المشروع للعمل. فكر فيها كأدوات يحتاجها Python لأداء مهام محددة.

ثبّت جميع الحزم المطلوبة:

```bash
pip install -r requirements.txt
```

**ما يفعله هذا:**
- يقرأ ملف `requirements.txt`
- يحمّل ويثبّت جميع الحزم المدرجة
- قد يستغرق 5-10 دقائق حسب سرعة الإنترنت

**الحزم الرئيسية المثبتة:**
- Flask: إطار عمل الويب لإنشاء خادم API
- scikit-learn: مكتبة التعلم الآلي لـ NLU
- numpy: العمليات الرياضية
- pandas: معالجة البيانات

#### الخطوة 3: تدريب نموذج NLU (للمرة الأولى فقط)

**ما هو نموذج NLU؟**

نموذج NLU (فهم اللغة الطبيعية) هو مكون ذكاء اصطناعي يفهم الأوامر الصوتية العربية. يحتاج إلى التدريب قبل الاستخدام.

درّب النموذج:

```bash
python train_nlu_model.py
```

**ما يحدث:**
1. ينشئ مجموعة بيانات تدريب مع أمثلة عربية
2. يدرّب نموذج تعلم آلي
3. يحفظ النموذج المدرب في `data/nlu_model.pkl`
4. تستغرق هذه العملية 1-5 دقائق

**عند المطالبة:**
- اكتب `n` لاستخدام Ensemble Model (موصى به - أسرع)
- اكتب `y` لاستخدام Transformer Model (أبطأ لكن أكثر دقة)

#### الخطوة 4: بدء خادم الخلفية

ابدأ خادم Flask:

```bash
python app.py
```

**ما يجب أن تراه:**
```
 * Running on http://127.0.0.1:5000
 * Running on http://localhost:5000
```

**مهم:**
- أبقِ نافذة Terminal هذه مفتوحة أثناء استخدام التطبيق
- يجب أن يكون الخادم يعمل حتى تعمل الأوامر الصوتية
- اضغط `Ctrl+C` لإيقاف الخادم

#### الخطوة 5: التحقق من أن الخلفية تعمل

افتح متصفح الويب وزر:
```
http://localhost:5000/health
```

يجب أن ترى استجابة JSON تؤكد أن الخادم يعمل.

---

### الجزء الثاني: إعداد تطبيق Flutter

#### الخطوة 1: الانتقال إلى مجلد تطبيق Flutter

افتح نافذة Terminal أو موجه أوامر جديدة وانتقل إلى:

```bash
cd path/to/yusr/flutter_app
```

على سبيل المثال:
```bash
cd C:\Users\MoSh\VSCode\Projects\flutterprojects\yusr\flutter_app
```

#### الخطوة 2: تثبيت تبعيات Flutter

**ما هي تبعيات Flutter؟**

مشابه لحزم Python، Flutter يستخدم "حزم" (تُسمى أيضاً تبعيات) توفر وظائف مثل التعرف على الصوت، قاعدة البيانات، إلخ.

ثبّت التبعيات:

```bash
flutter pub get
```

**ما يفعله هذا:**
- يقرأ ملف `pubspec.yaml`
- يحمّل جميع حزم Flutter المطلوبة
- يربطها بمشروعك
- يستغرق 2-5 دقائق

**الحزم الرئيسية المثبتة:**
- flutter_tts: تحويل النص إلى كلام
- speech_to_text: تحويل الكلام إلى نص
- sqflite: قاعدة بيانات SQLite المحلية
- http: للتواصل مع API

#### الخطوة 3: فحص الأجهزة المتصلة

قبل التشغيل، تحقق من الأجهزة المتاحة:

```bash
flutter devices
```

**المخرجات المحتملة:**

1. **لم يتم العثور على أجهزة:**
   - تحتاج لبدء محاكي أو توصيل جهاز حقيقي

2. **المحاكي مدرج:**
   - مثال: `sdk gphone64 arm64 (mobile) • emulator-5554`
   - يمكنك استخدام هذا المحاكي

3. **جهاز حقيقي مدرج:**
   - مثال: `SM-G991B (mobile) • R58M12345678`
   - هاتفك متصل وجاهز

#### الخطوة 4: بدء محاكي Android (إذا لزم الأمر)

**الخيار أ: استخدام Android Studio**

1. افتح Android Studio
2. اضغط "More Actions" > "Virtual Device Manager"
3. اضغط "Create Device"
4. اختر نموذج هاتف (مثلاً Pixel 5)
5. اضغط "Next"
6. اختر صورة نظام (API 33 أو أعلى)
7. اضغط "Next" > "Finish"
8. اضغط زر التشغيل بجانب جهازك لبدء تشغيله
9. انتظر حتى يبدأ المحاكي بالكامل (يظهر شاشة الرئيسية)

**الخيار ب: استخدام سطر الأوامر**

اعرض المحاكيات المتاحة:
```bash
flutter emulators
```

شغّل محاكي:
```bash
flutter emulators --launch <emulator_id>
```

على سبيل المثال:
```bash
flutter emulators --launch Pixel_5_API_33
```

#### الخطوة 5: توصيل جهاز حقيقي (بديل)

**لـ Android:**

1. فعّل خيارات المطور على هاتفك:
   - اذهب إلى الإعدادات > حول الهاتف
   - اضغط "رقم الإصدار" 7 مرات
   - سترى "أنت الآن مطور"

2. فعّل تصحيح USB:
   - اذهب إلى الإعدادات > خيارات المطور
   - فعّل "تصحيح USB"

3. وصّل الهاتف بالكمبيوتر عبر كيبل USB

4. على هاتفك، عند المطالبة، اسمح بتصحيح USB

5. تحقق من الاتصال:
```bash
   flutter devices
   ```
   يجب أن يظهر هاتفك في القائمة

**لـ iOS (macOS فقط):**

1. وصّل iPhone عبر USB
2. ثق بالكمبيوتر على iPhone
3. افتح Xcode > Window > Devices and Simulators
4. اختر جهازك واضغط "Use for Development"
5. تحقق:
```bash
   flutter devices
```

#### الخطوة 6: تشغيل تطبيق Flutter

**أمر التشغيل الأساسي:**

```bash
flutter run
```

**ما يحدث:**
1. Flutter يبني التطبيق (يترجم الكود)
2. يثبّت التطبيق على الجهاز/المحاكي
3. يطلق التطبيق
4. يعرض وحدة تحكم التصحيح مع السجلات

**التشغيل على جهاز محدد:**

إذا كانت عدة أجهزة متصلة:
```bash
flutter run -d <device_id>
```

على سبيل المثال:
```bash
flutter run -d emulator-5554
```

**ملاحظات التشغيل الأول:**
- البناء الأول يستغرق 5-10 دقائق (تحميل التبعيات)
- البناءات اللاحقة أسرع (1-2 دقيقة)
- سترى تقدم "Building..." في Terminal

#### الخطوة 7: التحقق من أن التطبيق يعمل

يجب أن ترى:
1. شاشة البداية مع شعار "يُسر"
2. شاشة تسجيل الدخول/التسجيل
3. التطبيق جاهز للاستخدام

---

### الجزء الثالث: التحقق الكامل من الإعداد

#### قائمة التحقق

قبل استخدام التطبيق، تحقق من:

- [ ] Python مثبت (`python --version` يعمل)
- [ ] Flutter مثبت (`flutter doctor` لا يظهر مشاكل حرجة)
- [ ] خادم الخلفية يعمل (`python app.py` في مجلد backend)
- [ ] الخلفية تعرض "Running on http://127.0.0.1:5000"
- [ ] تطبيق Flutter يعمل (`flutter run` في مجلد flutter_app)
- [ ] التطبيق يظهر على الجهاز/المحاكي
- [ ] يمكنك رؤية شاشة تسجيل الدخول

#### اختبار الميزات الصوتية

1. في التطبيق، اضغط زر الميكروفون
2. امنح إذن الميكروفون عند المطالبة
3. قل: "ابحث عن هاتف"
4. يجب أن يستجيب التطبيق بردود فعل صوتية

---

## الميزات

### الميزات الأساسية

#### 1. التسوق بالتحكم الصوتي

**ما يفعله:**
يمكن للمستخدمين البحث عن المنتجات وإضافتها للسلة وإتمام المشتريات باستخدام الأوامر الصوتية العربية فقط.

**كيفية الاستخدام:**
- اضغط زر الميكروفون
- تحدث الأمر بالعربية
- التطبيق يعالج ويستجيب بصوت

**أمثلة على الأوامر:**
- "ابحث عن هاتف" - البحث عن هاتف
- "أضف للسلة" - إضافة للسلة
- "عرض السلة" - عرض السلة
- "إتمام الشراء" - إتمام الشراء

#### 2. فهم اللغة الطبيعية

**ما هو:**
نظام ذكاء اصطناعي متقدم يفهم الأوامر العربية بلهجات وتنويعات مختلفة.

**كيف يعمل:**
- المستخدم يتحدث أمراً
- الكلام يُحوّل إلى نص
- نموذج NLU يحلل النية
- التطبيق ينفذ الإجراء المناسب

**اللهجات المدعومة:**
- العربية السعودية
- العربية المصرية
- العربية الشامية

#### 3. إدارة العناوين

**الميزة:**
إضافة وعرض وإدارة عناوين التوصيل باستخدام الأوامر الصوتية.

**الأوامر الصوتية:**
- "أضف عنوان جديد" - إضافة عنوان جديد
- اتبع المطالبات الصوتية لإدخال تفاصيل العنوان

**الخطوات:**
1. قل "أضف عنوان جديد"
2. التطبيق يسأل عن عنوان العنوان (مثلاً "المنزل")
3. التطبيق يسأل عن اسم الشارع
4. التطبيق يسأل عن المدينة
5. التطبيق يسأل عن الحي
6. التطبيق يسأل عن رقم المبنى
7. التطبيق يسأل عن رقم الشقة
8. العنوان يُحفظ

#### 4. إدارة طرق الدفع

**الميزة:**
إضافة وإدارة طرق الدفع (بطاقات الائتمان، المحافظ الرقمية، التحويلات البنكية) باستخدام الصوت.

**الأوامر الصوتية:**
- "أضف طريقة دفع" - إضافة طريقة دفع
- التطبيق يرشدك خلال جمع تفاصيل الدفع

**أنواع الدفع المدعومة:**
- بطاقة ائتمان
- محفظة رقمية (Samsung Pay، Google Pay، Apple Pay)
- تحويل بنكي

#### 5. إدارة الطلبات

**الميزة:**
عرض الطلبات والتحقق من الحالة وحذف الطلبات باستخدام الأوامر الصوتية.

**الأوامر الصوتية:**
- "احذف الطلب رقم 5" - حذف الطلب رقم 5
- "عرض الطلبات" - عرض الطلبات

#### 6. وصف الصور (Image Captioning)

**الميزة:**
الضغط مطولاً على أي صورة منتج لسماع وصف صوتي لما في الصورة.

**كيفية الاستخدام:**
1. انتقل إلى شاشة المنتج
2. اضغط مطولاً على صورة المنتج
3. التطبيق يصف الصورة بالعربية

**الغرض:**
يساعد ذوي الإعاقة البصرية على فهم صور المنتجات.

#### 7. التنقل الصوتي

**الميزة:**
التنقل بين شاشات التطبيق باستخدام الأوامر الصوتية.

**مثال:**
- قل "اذهب إلى الحساب" - اذهب إلى الحساب
- التطبيق ينتقل إلى شاشة الملف الشخصي

---

## المكونات التقنية

### مكونات الخلفية

#### 1. خادم Flask (`app.py`)

**ما هو Flask؟**

Flask هو إطار عمل ويب خفيف لـ Python. ينشئ خادم HTTP يستقبل الطلبات ويرسل الاستجابات.

**نقاط النهاية الرئيسية:**

- `POST /nlu`: معالجة الأوامر الصوتية
  - المدخل: `{"text": "ابحث عن هاتف"}`
  - المخرج: `{"intent": "search", "confidence": 0.95}`

- `POST /auth/register`: تسجيل المستخدم
- `POST /auth/login`: تسجيل دخول المستخدم
- `GET /health`: فحص صحة الخادم

**كيف يعمل:**
1. يستقبل طلب HTTP من التطبيق المحمول
2. يعالج الطلب باستخدام نموذج NLU
3. يُرجع استجابة JSON
4. التطبيق المحمول يستقبل الاستجابة ويتصرف وفقاً لذلك

#### 2. نموذج NLU (`train_nlu_model.py`)

**ما هو NLU؟**

فهم اللغة الطبيعية (NLU) هو فرع من الذكاء الاصطناعي يساعد أجهزة الكمبيوتر على فهم اللغة البشرية.

**أنواع النماذج:**

1. **نموذج Ensemble** (الافتراضي):
   - يجمع عدة خوارزميات تعلم آلي
   - تدريب سريع (دقيقة واحدة)
   - تنبؤ سريع (< 10ms)
   - الدقة: 85-95%
   - حجم النموذج: < 50MB

2. **نموذج Transformer** (اختياري):
   - يستخدم نموذج BERT العربي المدرب مسبقاً
   - تدريب بطيء (5-15 دقيقة)
   - تنبؤ أبطأ (50-100ms)
   - الدقة: 90-98%
   - حجم النموذج: > 500MB

**عملية التدريب:**

1. تحميل مجموعة بيانات التدريب (500+ مثال عربي)
2. معالجة مسبقة للنص (تطبيع الأحرف العربية)
3. تحويل النص إلى متجهات رقمية (TF-IDF)
4. تدريب نموذج التعلم الآلي
5. تقييم أداء النموذج
6. حفظ النموذج المدرب على القرص

**المصطلحات الرئيسية:**

- **النية (Intent):** الإجراء الذي يريد المستخدم تنفيذه (مثلاً "search"، "add_to_cart")
- **الكيان (Entity):** معلومات محددة مستخرجة (مثلاً اسم المنتج "هاتف")
- **الثقة (Confidence):** مدى تأكد النموذج (0.0 إلى 1.0)

#### 3. وحدة قاعدة البيانات (`modules/db.py`)

**ما تفعله:**
تدير عمليات قاعدة بيانات SQLite للخلفية.

**الوظائف:**
- مصادقة المستخدم
- إدارة الجلسات
- تخزين البيانات

### مكونات الواجهة الأمامية

#### 1. خدمة الصوت (`voice_service.dart`)

**ما تفعله:**
تتعامل مع جميع العمليات المتعلقة بالصوت.

**الوظائف الرئيسية:**

- **تحويل النص إلى كلام (TTS):**
   - يحول النص إلى كلام عربي منطوق
   - يستخدم محرك TTS المدمج في الجهاز
   - قابل للتكوين (السرعة، الحجم، النبرة)

- **تحويل الكلام إلى نص (STT):**
   - يحول الكلام العربي إلى نص
   - يستخدم التعرف على الكلام في الجهاز
   - يدعم الاستماع المستمر

**كيفية الاستخدام:**

```dart
final voiceService = VoiceService();
await voiceService.initialize();
await voiceService.speak("مرحبا بك");
await voiceService.startListening();
```

#### 2. خدمة التنقل الصوتي (`voice_navigation_service.dart`)

**ما تفعله:**
الخدمة الرئيسية التي تعالج الأوامر الصوتية وتنفذ الإجراءات.

**الوظائف الرئيسية:**

- معالجة الأوامر الصوتية
- إدارة تدفق المحادثة
- التعامل مع العمليات متعددة الخطوات (مثل إضافة عنوان)
- التنسيق بين شاشات التطبيق

**مثال على التدفق:**

1. المستخدم يقول "أضف عنوان جديد"
2. الخدمة تتعرف على النية: "add_address"
3. الخدمة تبدأ جمع البيانات خطوة بخطوة:
   - تسأل عن عنوان العنوان
   - تنتظر رد المستخدم
   - تسأل عن الشارع
   - تستمر حتى جمع جميع البيانات
4. تحفظ العنوان في قاعدة البيانات
5. تؤكد بردود فعل صوتية

#### 3. خدمة قاعدة البيانات (`db_service.dart`)

**ما تفعله:**
تدير قاعدة بيانات SQLite المحلية على الجهاز المحمول.

**الوظائف الرئيسية:**

- إدارة المنتجات (الحصول، البحث، التصفية)
- عمليات السلة (إضافة، إزالة، تحديث)
- إدارة الطلبات (إنشاء، قائمة، حذف)
- إدارة العناوين (إضافة، قائمة، حذف)
- إدارة طرق الدفع (إضافة، قائمة، حذف)

**موقع قاعدة البيانات:**

- Android: `/data/data/com.yusr.app/databases/yusr_database.db`
- iOS: داخل مجلد Documents للتطبيق

**التهيئة:**

يتم إنشاء قاعدة البيانات تلقائياً عند أول تشغيل للتطبيق مع المنتجات الافتراضية.

---

## هيكل قاعدة البيانات

### نظرة عامة على الجداول

يستخدم التطبيق قاعدة بيانات SQLite مع الجداول التالية:

#### 1. جدول المنتجات

يخزن معلومات المنتجات.

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,              -- الاسم بالإنجليزية
    name_ar TEXT NOT NULL,           -- الاسم بالعربية
    price REAL NOT NULL,              -- السعر بالريال
    description TEXT,                -- الوصف بالإنجليزية
    description_ar TEXT,             -- الوصف بالعربية
    image_url TEXT,                  -- اسم ملف الصورة
    stock INTEGER DEFAULT 0,         -- الكمية المتاحة
    category TEXT                     -- فئة المنتج
);
```

**مثال على البيانات:**
```
id: 1
name: "iPhone 16"
name_ar: "آيفون 16"
price: 4800.0
description_ar: "هاتف آيفون 16 بمواصفات حديثة..."
category: "إلكترونيات"
```

#### 2. جدول السلة

يخزن العناصر في سلة التسوق.

```sql
CREATE TABLE cart (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,      -- مرجع للمنتج
    quantity INTEGER NOT NULL DEFAULT 1,
    selected_image_url TEXT,          -- صورة متغير محدد
    FOREIGN KEY (product_id) REFERENCES products(id)
);
```

#### 3. جدول الطلبات

يخزن الطلبات المكتملة.

```sql
CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    total REAL NOT NULL,
    status TEXT DEFAULT 'pending',     -- pending, completed, cancelled
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id)
);
```

#### 4. جدول العناوين

يخزن عناوين توصيل المستخدمين.

```sql
CREATE TABLE addresses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,              -- مثلاً "المنزل"، "العمل"
    street TEXT NOT NULL,
    city TEXT NOT NULL,
    district TEXT,                     -- الحي
    building_number TEXT,
    apartment_number TEXT,
    postal_code TEXT,
    is_default INTEGER DEFAULT 0,      -- 1 إذا كان العنوان الافتراضي
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

#### 5. جدول طرق الدفع

يخزن طرق دفع المستخدمين.

```sql
CREATE TABLE payment_methods (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    payment_type TEXT NOT NULL,        -- بطاقة ائتمان، محفظة رقمية، إلخ
    card_number TEXT,                  -- رقم البطاقة المشفر
    card_holder TEXT,
    expiry_month INTEGER,
    expiry_year INTEGER,
    cvv TEXT,                          -- CVV مشفر
    wallet_provider TEXT,              -- Samsung Pay، Google Pay، إلخ
    bank_name TEXT,                     -- للتحويلات البنكية
    is_default INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### عمليات قاعدة البيانات

**استخدام DBService في الكود:**

```dart
// الحصول على جميع المنتجات
List<Map<String, dynamic>> products = await DBService.getAllProducts();

// البحث عن منتجات
List<Map<String, dynamic>> results = await DBService.searchProducts("هاتف");

// إضافة للسلة
await DBService.addToCart(productId: 1, quantity: 2);

// الحصول على عناصر السلة
List<Map<String, dynamic>> cartItems = await DBService.getCartItems();

// إنشاء طلب
int orderId = await DBService.createOrder(cartItems);

// إضافة عنوان
await DBService.addAddress(
    userId: 1,
    title: "المنزل",
    street: "شارع الملك فهد",
    city: "الرياض"
);

// إضافة طريقة دفع
await DBService.addPaymentMethod(
    userId: 1,
    paymentType: "بطاقة ائتمان",
    cardNumber: "1234567890123456",
    cardHolder: "أحمد محمد"
);
```

---

## توثيق واجهة البرمجة

### عنوان URL الأساسي

- التطوير المحلي: `http://127.0.0.1:5000`
- محاكي Android: `http://10.0.2.2:5000`
- محاكي iOS: `http://127.0.0.1:5000`

### نقاط النهاية

#### 1. فحص الصحة

**نقطة النهاية:** `GET /health`

**الغرض:** التحقق من أن الخادم يعمل

**الطلب:**
```bash
curl http://localhost:5000/health
```

**الاستجابة:**
```json
{
  "status": "ok",
  "message": "الخادم يعمل بشكل طبيعي"
}
```

#### 2. فهم اللغة الطبيعية

**نقطة النهاية:** `POST /nlu`

**الغرض:** معالجة الأمر الصوتي العربي وإرجاع النية

**الطلب:**
```json
{
  "text": "ابحث عن هاتف"
}
```

**الاستجابة:**
```json
{
  "intent": "search",
  "confidence": 0.95,
  "entities": {
    "product": "هاتف"
  },
  "speak_text": "جاري البحث عن هاتف"
}
```

**النيات المحتملة:**
- `search`: البحث عن المنتجات
- `add_to_cart`: إضافة عنصر للسلة
- `view_cart`: عرض محتويات السلة
- `checkout`: إتمام الشراء
- `navigate_to_account`: الانتقال إلى شاشة الحساب
- `add_address`: إضافة عنوان جديد
- `add_payment_method`: إضافة طريقة دفع
- `delete_order`: حذف طلب
- `read_description`: قراءة وصف المنتج
- `view_products`: عرض جميع المنتجات
- `remove_from_cart`: إزالة عنصر من السلة
- `unknown`: الأمر غير مفهوم

#### 3. تسجيل المستخدم

**نقطة النهاية:** `POST /auth/register`

**الطلب:**
```json
{
  "name": "أحمد محمد",
  "email": "ahmed@example.com",
  "phone": "0501234567",
  "password": "password123"
}
```

**الاستجابة:**
```json
{
  "success": true,
  "user_id": 1,
  "message": "تم إنشاء الحساب بنجاح"
}
```

#### 4. تسجيل دخول المستخدم

**نقطة النهاية:** `POST /auth/login`

**الطلب:**
```json
{
  "identifier": "ahmed@example.com",
  "password": "password123"
}
```

**الاستجابة:**
```json
{
  "success": true,
  "user_id": 1,
  "name": "أحمد محمد",
  "email": "ahmed@example.com",
  "phone": "0501234567"
}
```

---

## شرح الأكواد المهمة

### نظرة عامة

هذا القسم يشرح الأكواد الأساسية في المشروع وكيف تعمل. سيساعدك على فهم البنية الداخلية للتطبيق وتعديلها حسب احتياجاتك.

---

### الكود الأول: معالجة النص العربي (`AdvancedTextPreprocessor`)

**الموقع:** `backend/train_nlu_model.py`

**الغرض:** معالجة وتطبيع النصوص العربية قبل إرسالها لنموذج NLU.

**الكود:**

```python
class AdvancedTextPreprocessor:
    def __init__(self):
        # خريطة لتوحيد الأحرف العربية المختلفة
        self.normalization_map = {
            'أ': 'ا', 'إ': 'ا', 'آ': 'ا',  # توحيد جميع أشكال الألف
            'ى': 'ي', 'ة': 'ه',            # توحيد الياء والتاء المربوطة
            'ُ': '', 'ِ': '', 'ً': '',     # إزالة الحركات
            'ٍ': '', 'ٌ': '', 'ْ': '', 'ّ': ''
        }
    
    def normalize_arabic(self, text: str) -> str:
        # تحويل جميع أشكال الحرف إلى شكل واحد
        for old, new in self.normalization_map.items():
            text = text.replace(old, new)
        return text
    
    def preprocess(self, text: str, normalize: bool = True) -> str:
        text = text.strip().lower()  # تحويل لحروف صغيرة وإزالة المسافات
        if normalize:
            text = self.normalize_arabic(text)  # تطبيع الأحرف
        # إزالة أي حرف غير عربي أو رقم
        text = re.sub(r'[^\u0600-\u06FF\s\d]', '', text)
        # تقليل المسافات المتعددة إلى مسافة واحدة
        text = re.sub(r'\s+', ' ', text)
        return text
```

**شرح الكود:**

1. **`normalization_map`**: قاموس يحول أشكال الحرف المختلفة إلى شكل موحد (مثلاً: أ، إ، آ → ا)
2. **`normalize_arabic`**: تمر على النص وتحول كل حرف حسب الخريطة
3. **`preprocess`**: تنظف النص وتزيل الحركات والأحرف غير العربية

**لماذا مهم؟**

- يحسن دقة النموذج بتوحيد أشكال الحروف
- يجعل النموذج يفهم اللهجات المختلفة (مثلاً: "أريد" و "أبي" و "عايز")

---

### الكود الثاني: نموذج NLU (`ArabicNLUModel`)

**الموقع:** `backend/train_nlu_model.py`

**الغرض:** نموذج ذكاء اصطناعي يفهم الأوامر العربية ويحدد النية.

**الكود الأساسي:**

```python
class ArabicNLUModel:
    def __init__(self, use_transformer: bool = False):
        self.use_transformer = use_transformer
        self.model = None
        self.vectorizer = None
        self.preprocessor = AdvancedTextPreprocessor()
    
    def train(self, dataset_path: str):
        # قراءة البيانات
        with open(dataset_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        texts = [item['text'] for item in data]
        intents = [item['intent'] for item in data]
        
        # معالجة النصوص
        processed_texts = [self.preprocessor.preprocess(text) for text in texts]
        
        if self.use_transformer:
            return self.train_transformer(processed_texts, intents)
        else:
            return self.train_sklearn_ensemble(processed_texts, intents)
    
    def predict(self, text: str):
        # معالجة النص المدخل
        processed = self.preprocessor.preprocess(text)
        
        if self.use_transformer:
            # استخدام نموذج Transformer
            inputs = self.tokenizer(processed, return_tensors='pt')
            outputs = self.model(**inputs)
            predicted_id = outputs.logits.argmax().item()
        else:
            # استخدام نموذج Ensemble
            vector = self.vectorizer.transform([processed])
            predicted_id = self.model.predict(vector)[0]
        
        intent = self.intent_labels[predicted_id]
        confidence = self.model.predict_proba(vector)[0][predicted_id]
        
        return {
            'intent': intent,
            'confidence': confidence,
            'entities': self._extract_entities(text)
        }
```

**شرح الكود:**

1. **`__init__`**: تهيئة النموذج واختيار نوعه (Ensemble أو Transformer)
2. **`train`**: قراءة البيانات ومعالجتها ثم تدريب النموذج
3. **`predict`**: أخذ نص عربي وإرجاع النية والثقة

**كيف يعمل:**

- **التدريب**: يأخذ أمثلة (نص + نية) ويدرب النموذج على التعرف على الأنماط
- **التنبؤ**: يأخذ نص جديد ويحاول معرفة النية بناءً على ما تعلمه

---

### الكود الثالث: خدمة التنقل الصوتي (`VoiceNavigationService`)

**الموقع:** `flutter_app/lib/src/services/voice_navigation_service.dart`

**الغرض:** معالجة الأوامر الصوتية وتنفيذ الإجراءات في التطبيق.

**الكود الأساسي:**

```dart
class VoiceNavigationService {
  final VoiceService _voiceService = VoiceService();
  final ApiClient _apiClient = ApiClient();
  
  // معالجة الأمر الصوتي
  Future<void> _processVoiceCommand(String text) async {
    // إرسال النص لخادم NLU
    final result = await _apiClient.processNLU(text);
    final intent = result['intent'] ?? 'unknown';
    
    // تنفيذ الإجراء حسب النية
    switch (intent) {
      case 'search':
        await _handleSearch(result['query'] ?? text);
        break;
      case 'add_to_cart':
        await _handleAddToCart();
        break;
      case 'add_address':
        await _handleAddAddress();
        break;
      // ... المزيد من الحالات
    }
  }
  
  // مثال: معالجة البحث
  Future<void> _handleSearch(String query) async {
    await _voiceService.speak('جاري البحث عن $query');
    final products = await DBService.searchProducts(query);
    // عرض النتائج صوتياً
    for (var product in products) {
      await _voiceService.speak('${product['name_ar']} بسعر ${product['price']} ريال');
    }
  }
}
```

**شرح الكود:**

1. **`_processVoiceCommand`**: تأخذ النص الصوتي وتحوله لنية ثم تنفذ الإجراء
2. **`switch`**: يختار الإجراء المناسب حسب النية
3. **`_handleSearch`**: مثال على معالجة نية محددة (البحث)

**كيف يعمل:**

1. المستخدم يتحدث → `VoiceService` يحول للصوت لنص
2. النص يُرسل لـ `_processVoiceCommand`
3. النص يُرسل لخادم NLU للحصول على النية
4. حسب النية، يتم تنفيذ الإجراء المناسب
5. التطبيق يرد صوتياً للمستخدم

---

### الكود الرابع: نقطة النهاية NLU في Flask (`app.py`)

**الموقع:** `backend/app.py`

**الغرض:** استقبال طلبات NLU من التطبيق المحمول وإرجاع النية.

**الكود:**

```python
@app.route('/nlu', methods=['POST'])
def nlu():
    try:
        data = request.json
        text = data.get('text', '').strip()
        
        if not text:
            return jsonify({
                'intent': 'unknown',
                'message': 'لم يتم إرسال نص'
            }), 400
        
        # استخدام النموذج المدرب
        if nlu_model_loaded and nlu_model:
            result = nlu_model.predict(text)
            confidence_threshold = 0.3 if not nlu_model.use_transformer else 0.5
            
            if result['confidence'] > confidence_threshold:
                return jsonify({
                    'intent': result['intent'],
                    'entities': result.get('entities', {}),
                    'confidence': float(result['confidence']),
                    'speak_text': _generate_speak_text(result['intent'], result.get('entities', {}))
                })
        
        # نظام احتياطي إذا فشل النموذج
        text_lower = text.lower()
        if 'ابحث عن' in text_lower:
            return jsonify({
                'intent': 'search',
                'query': text,
                'speak_text': f'جاري البحث عن {text}'
            })
        
        return jsonify({
            'intent': 'unknown',
            'speak_text': 'لم أفهم الأمر'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500
```

**شرح الكود:**

1. **`@app.route('/nlu')`**: يحدد عنوان URL الذي يستقبل الطلبات
2. **`request.json`**: يحصل على النص من الطلب
3. **`nlu_model.predict`**: يستخدم النموذج المدرب للتنبؤ بالنية
4. **`confidence_threshold`**: يتحقق من ثقة النموذج قبل إرجاع النتيجة
5. **النظام الاحتياطي**: إذا فشل النموذج، يستخدم قواعد بسيطة

**كيف يعمل:**

1. التطبيق المحمول يرسل POST request مع النص
2. Flask يستقبل الطلب ويستخرج النص
3. النص يُمرر لنموذج NLU
4. النموذج يُرجع النية والثقة
5. Flask يُرجع JSON response للتطبيق

---

### الكود الخامس: خدمة قاعدة البيانات (`DBService`)

**الموقع:** `flutter_app/lib/src/services/db_service.dart`

**الغرض:** إدارة قاعدة بيانات SQLite المحلية على الجهاز.

**الكود الأساسي:**

```dart
class DBService {
  static Database? _db;
  
  // تهيئة قاعدة البيانات
  static Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'yusr_database.db');
    
    return await openDatabase(
      path,
      version: 9,
      onCreate: (db, version) async {
        // إنشاء جدول المنتجات
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            name_ar TEXT NOT NULL,
            price REAL NOT NULL,
            description_ar TEXT,
            image_url TEXT,
            stock INTEGER DEFAULT 0,
            category TEXT
          )
        ''');
        
        // إنشاء جداول أخرى...
        await _insertDefaultProducts(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // تحديث قاعدة البيانات عند تغيير الإصدار
        if (oldVersion < 9) {
          await db.execute('CREATE TABLE IF NOT EXISTS addresses (...)');
        }
      }
    );
  }
  
  // البحث عن منتجات
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'name_ar LIKE ? OR description_ar LIKE ?',
      whereArgs: ['%$query%', '%$query%']
    );
  }
  
  // إضافة للسلة
  static Future<void> addToCart({
    required int productId,
    required int quantity,
  }) async {
    final db = await database;
    await db.insert('cart', {
      'product_id': productId,
      'quantity': quantity,
    });
  }
}
```

**شرح الكود:**

1. **`initDB`**: تهيئة قاعدة البيانات وإنشاء الجداول عند أول تشغيل
2. **`onCreate`**: يُنفذ مرة واحدة عند إنشاء قاعدة البيانات
3. **`onUpgrade`**: يُنفذ عند تحديث إصدار قاعدة البيانات
4. **`searchProducts`**: مثال على استعلام SQL للبحث
5. **`addToCart`**: مثال على إدراج بيانات في قاعدة البيانات

**كيف يعمل:**

- **التهيئة**: عند أول تشغيل، يتم إنشاء ملف قاعدة البيانات والجداول
- **الاستعلامات**: استخدام SQL للبحث والإدراج والتحديث والحذف
- **التخزين المحلي**: جميع البيانات تُحفظ محلياً على الجهاز

---

### الكود السادس: معالجة العمليات متعددة الخطوات

**الموقع:** `flutter_app/lib/src/services/voice_navigation_service.dart`

**الغرض:** جمع بيانات العنوان أو طريقة الدفع خطوة بخطوة عبر الصوت.

**الكود:**

```dart
// بدء عملية إضافة عنوان
Future<void> _handleAddAddress() async {
  _currentStep = 'address_title';
  await _voiceService.speak('ما هو عنوان العنوان؟ مثلاً المنزل أو العمل');
  // انتظار رد المستخدم
}

// معالجة البيانات المجمعة
Future<void> _handleCollectAddressData(String text) async {
  switch (_currentStep) {
    case 'address_title':
      _currentAddressTitle = text;
      _currentStep = 'address_street';
      await _voiceService.speak('ما هو اسم الشارع؟');
      break;
      
    case 'address_street':
      _currentAddressStreet = text;
      _currentStep = 'address_city';
      await _voiceService.speak('ما هي المدينة؟');
      break;
      
    case 'address_city':
      _currentAddressCity = text;
      await _saveAddress();  // حفظ العنوان
      break;
  }
}

// حفظ العنوان في قاعدة البيانات
Future<void> _saveAddress() async {
  await DBService.addAddress(
    userId: _currentUserId,
    title: _currentAddressTitle!,
    street: _currentAddressStreet!,
    city: _currentAddressCity!,
  );
  await _voiceService.speak('تم حفظ العنوان بنجاح');
  // إعادة تعيين المتغيرات
  _resetAddressData();
}
```

**شرح الكود:**

1. **`_currentStep`**: متغير يخزن الخطوة الحالية في العملية
2. **`_handleCollectAddressData`**: تأخذ رد المستخدم وتحفظه ثم تنتقل للخطوة التالية
3. **`switch`**: يحدد ما يجب فعله حسب الخطوة الحالية
4. **`_saveAddress`**: تحفظ جميع البيانات المجمعة في قاعدة البيانات

**كيف يعمل:**

1. المستخدم يقول "أضف عنوان جديد"
2. التطبيق يسأل عن عنوان العنوان
3. المستخدم يجيب (مثلاً "المنزل")
4. التطبيق يحفظ الجواب ويسأل عن السؤال التالي
5. تستمر العملية حتى جمع جميع البيانات
6. التطبيق يحفظ العنوان في قاعدة البيانات

---

### نصائح للتعديل

**لإضافة نية جديدة:**

1. أضف أمثلة في `create_massive_dataset()` في `train_nlu_model.py`
2. أضف حالة جديدة في `switch` في `voice_navigation_service.dart`
3. أعد تدريب النموذج

**لإضافة جدول جديد:**

1. أضف `CREATE TABLE` في `onCreate` في `db_service.dart`
2. أضف `onUpgrade` إذا كان التحديث لقاعدة بيانات موجودة
3. زد رقم الإصدار في `version`

**لتحسين دقة NLU:**

1. أضف المزيد من الأمثلة في مجموعة البيانات
2. جرب نموذج Transformer بدلاً من Ensemble
3. عدّل معاملات النموذج (مثلاً `C` في SVM)

---

## استكشاف الأخطاء وحلها

### المشاكل الشائعة والحلول

#### المشكلة 1: Python غير موجود

**الخطأ:** `'python' is not recognized as an internal or external command`

**الحل:**
1. Python غير مثبت أو غير موجود في PATH
2. أعد تثبيت Python وضع علامة على "Add to PATH"
3. أو استخدم `python3` بدلاً من `python`

#### المشكلة 2: أمر Flutter غير موجود

**الخطأ:** `'flutter' is not recognized as an internal or external command`

**الحل:**
1. Flutter غير موجود في PATH
2. أضف مجلد Flutter bin إلى PATH في النظام
3. أعد تشغيل Terminal أو موجه الأوامر

#### المشكلة 3: خادم الخلفية لا يبدأ

**الخطأ:** `Address already in use` أو `Port 5000 is already in use`

**الحل:**
1. عملية أخرى تستخدم المنفذ 5000
2. ابحث عن العملية وأغلقها:
   ```bash
   # Windows
   netstat -ano | findstr :5000
   taskkill /PID <process_id> /F
   
   # Mac/Linux
   lsof -ti:5000 | xargs kill
   ```
3. أو غيّر المنفذ في `app.py`:
   ```python
   app.run(host='0.0.0.0', port=5001)  # استخدم منفذ مختلف
   ```

#### المشكلة 4: فشل تثبيت تبعيات Flutter

**الخطأ:** `Failed to install dependencies`

**الحل:**
1. تحقق من اتصال الإنترنت
2. امسح ذاكرة التخزين المؤقت لـ Flutter:
   ```bash
   flutter clean
   flutter pub get
   ```
3. حدّث Flutter:
   ```bash
   flutter upgrade
   ```

#### المشكلة 5: لم يتم العثور على أجهزة

**الخطأ:** `No devices found` عند تشغيل `flutter devices`

**الحل:**
1. ابدأ محاكي Android من Android Studio
2. أو وصّل جهاز حقيقي عبر USB
3. فعّل تصحيح USB على جهاز Android
4. تحقق باستخدام `flutter devices`

#### المشكلة 6: التعرف على الصوت لا يعمل

**الخطأ:** رفض إذن الميكروفون أو لا يوجد تعرف على الصوت

**الحل:**
1. امنح إذن الميكروفون في إعدادات الجهاز
2. تحقق من أذونات التطبيق:
   - Android: الإعدادات > التطبيقات > يُسر > الأذونات > الميكروفون
   - iOS: الإعدادات > يُسر > الميكروفون
3. أعد تشغيل التطبيق

#### المشكلة 7: نموذج NLU لا يُحمّل

**الخطأ:** ملف النموذج غير موجود أو خطأ في التحميل

**الحل:**
1. درّب النموذج أولاً:
   ```bash
   cd backend
   python train_nlu_model.py
   ```
2. تحقق من وجود ملف النموذج: `backend/data/nlu_model.pkl`
3. تحقق من أذونات الملف

#### المشكلة 8: أخطاء قاعدة البيانات

**الخطأ:** قاعدة البيانات مقفلة أو أخطاء SQLite

**الحل:**
1. أغلق التطبيق بالكامل
2. امسح بيانات التطبيق:
   ```bash
   flutter clean
   ```
3. أعد تشغيل التطبيق (سيتم إعادة إنشاء قاعدة البيانات)

#### المشكلة 9: فشل الاتصال بالخلفية

**الخطأ:** لا يمكن الاتصال بخادم الخلفية

**الحل:**
1. تحقق من أن الخلفية تعمل (`python app.py`)
2. تحقق من URL في `api_client.dart`:
   - محاكي Android: `http://10.0.2.2:5000`
   - محاكي iOS: `http://127.0.0.1:5000`
   - جهاز حقيقي: استخدم عنوان IP للكمبيوتر
3. تحقق من إعدادات الجدار الناري
4. تحقق من أن كلا الجهازين على نفس الشبكة

#### المشكلة 10: أخطاء البناء

**الخطأ:** فشل بناء Gradle أو أخطاء الترجمة

**الحل:**
1. نظف البناء:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
2. حدّث التبعيات:
   ```bash
   flutter pub upgrade
   ```
3. تحقق من تعارضات الإصدارات في `pubspec.yaml`

---

## التكوين المتقدم

### تغيير منفذ الخلفية

عدّل `backend/app.py`:

```python
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)  # غيّر المنفذ هنا
```

حدّث `flutter_app/lib/src/services/api_client.dart`:

```dart
static String get baseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:5001';  // طابق منفذ الخلفية
  } else {
    return 'http://127.0.0.1:5001';
  }
}
```

### استخدام جهاز حقيقي مع الخلفية

**لـ Android:**

1. ابحث عن عنوان IP لجهازك:
   ```bash
   # Windows
   ipconfig
   
   # Mac/Linux
   ifconfig
   ```
   ابحث عن عنوان IPv4 (مثلاً `192.168.1.100`)

2. حدّث `api_client.dart`:
   ```dart
   static String get baseUrl {
     return 'http://192.168.1.100:5000';  // عنوان IP لجهازك
   }
   ```

3. تأكد من أن الهاتف والكمبيوتر على نفس شبكة Wi-Fi

**لـ iOS:**

نفس Android، لكن تأكد من أن الجدار الناري يسمح بالاتصالات.

### تدريب نموذج NLU مخصص

1. عدّل `backend/train_nlu_model.py`
2. غيّر دالة `create_massive_dataset()`
3. أضف أمثلة عربية مخصصة
4. شغّل التدريب:
   ```bash
   python train_nlu_model.py
   ```

### إضافة أوامر صوتية جديدة

1. أضف أمثلة إلى مجموعة البيانات في `train_nlu_model.py`
2. أضف معالج نية في `voice_navigation_service.dart`
3. أضف معالج خلفية في `app.py`
4. أعد تدريب النموذج

---

## سير العمل التطويري

### التطوير اليومي

1. **ابدأ الخلفية:**
   ```bash
   cd backend
   python app.py
   ```

2. **ابدأ تطبيق Flutter:**
   ```bash
   cd flutter_app
   flutter run
   ```

3. **قم بالتغييرات:**
   - عدّل ملفات الكود
   - Flutter hot reload يحدّث الواجهة تلقائياً
   - الخلفية تحتاج إعادة تشغيل للتغييرات

4. **اختبر الميزات:**
   - استخدم الأوامر الصوتية
   - تحقق من عمليات قاعدة البيانات
   - تحقق من استجابات API

### البناء للإنتاج

**APK لـ Android:**
```bash
cd flutter_app
flutter build apk --release
```
ملف APK: `build/app/outputs/flutter-apk/app-release.apk`

**IPA لـ iOS (macOS فقط):**
```bash
cd flutter_app
flutter build ios --release
```
ثم استخدم Xcode لإنشاء ملف IPA.

---

## مسرد المصطلحات التقنية

**API (واجهة برمجة التطبيقات):**
طريقة للتواصل بين مكونات البرمجيات المختلفة. في هذا المشروع، يتواصل التطبيق المحمول مع خادم الخلفية عبر API.

**الخلفية (Backend):**
الجزء من التطبيق الذي يعمل على الخادم ويعالج الطلبات ويدير البيانات.

**قاعدة البيانات (Database):**
مجموعة منظمة من البيانات. SQLite هي قاعدة بيانات قائمة على الملفات تخزن البيانات محلياً على الجهاز.

**التبعيات (Dependencies):**
مكتبات أو حزم خارجية يحتاجها مشروعك للعمل.

**المحاكي (Emulator):**
جهاز افتراضي يحاكي هاتف حقيقي على جهازك للاختبار.

**Flutter:**
إطار عمل Google لبناء تطبيقات المحمول لـ Android و iOS.

**الواجهة الأمامية (Frontend):**
الجزء الموجه للمستخدم من التطبيق (واجهة التطبيق المحمول).

**النية (Intent):**
في NLU، الإجراء أو الهدف الذي يريد المستخدم تحقيقه (مثلاً "search"، "add_to_cart").

**NLU (فهم اللغة الطبيعية):**
تقنية ذكاء اصطناعي تساعد أجهزة الكمبيوتر على فهم اللغة البشرية.

**SDK (مجموعة أدوات التطوير):**
مجموعة من الأدوات والمكتبات لتطوير البرمجيات.

**SQLite:**
نظام قاعدة بيانات خفيف يخزن البيانات في ملف واحد.

**STT (الكلام إلى النص):**
تقنية تحول الكلمات المنطوقة إلى نص مكتوب.

**TTS (النص إلى الكلام):**
تقنية تحول النص المكتوب إلى كلام منطوق.

**المتجه (Vector):**
في التعلم الآلي، تمثيل رقمي للنص يمكن لأجهزة الكمبيوتر معالجته.

---

## الدعم والموارد

### التوثيق الرسمي

- Flutter: https://docs.flutter.dev/
- Python: https://docs.python.org/
- Flask: https://flask.palletsprojects.com/
- SQLite: https://www.sqlite.org/docs.html

### ملفات المشروع

- تطبيق Flutter الرئيسي: `flutter_app/lib/main.dart`
- خادم الخلفية: `backend/app.py`
- تدريب NLU: `backend/train_nlu_model.py`

### الحصول على المساعدة

1. راجع هذا README أولاً
2. راجع رسائل الخطأ بعناية
3. راجع توثيق Flutter/Python
4. تحقق من تثبيت جميع المتطلبات بشكل صحيح
---

**آخر تحديث:** يناير 2026
