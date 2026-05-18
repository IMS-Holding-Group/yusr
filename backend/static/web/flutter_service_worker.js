'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "9049e42e16d74f813f76b57501940dec",
"assets/AssetManifest.bin.json": "19d684a75096859539f3b39768deaf1b",
"assets/AssetManifest.json": "cdf75d28e98a85376f18eda14daa5fc0",
"assets/assets/fonts/IBMPlexSansArabic-Bold.ttf": "3b112e6aa65695f31fa1e1a8fb0589a9",
"assets/assets/fonts/IBMPlexSansArabic-ExtraLight.ttf": "2ac69265ef57c13e2bf7d71f0d86e30b",
"assets/assets/fonts/IBMPlexSansArabic-Light.ttf": "fc8d66d7803c5703326895c99f36aa39",
"assets/assets/fonts/IBMPlexSansArabic-Medium.ttf": "5fb42fdbaf9db9218cd8b43c4f53cae1",
"assets/assets/fonts/IBMPlexSansArabic-Regular.ttf": "bf7497338196d1ed6c36ea4d010f12a8",
"assets/assets/fonts/IBMPlexSansArabic-SemiBold.ttf": "c6da47ef5746d5af5a7bca3f07a444c3",
"assets/assets/fonts/IBMPlexSansArabic-Thin.ttf": "454434ea7b20d86b0b52f4c8a9e772d9",
"assets/assets/images/321.jpg": "1e0634dfdca342e9f75233eb154d1775",
"assets/assets/images/40128f8318bafaee7241f3f4c044df3a_d9f10d67-27c4-4dd3-8a48-c05c1d7f94a5.webp": "dbd65137c19bdf3729017765dc7685b5",
"assets/assets/images/41olzVIB+lL._SL500_._AC_SL500_.jpg": "652657a2be5c7736d99f56424fbe63b6",
"assets/assets/images/71lxCY6LgVL._AC_SL1500_.jpg": "02295c1a48e48a31e5e982f8f571cf67",
"assets/assets/images/Air-conditioner.jpeg": "1b3f79dc03f8a5b711b75b1d6d5c2475",
"assets/assets/images/Airpods.webp": "3aef178c0104a3623d3dae04b26905f9",
"assets/assets/images/Arabic-coffee.webp": "8ccdebb9754158cc7808eeb894e2f011",
"assets/assets/images/Book.png": "4368e052fb6721536f59b7298d0d77ca",
"assets/assets/images/bug.webp": "9ca59d33d872d5ab21d83383e25850aa",
"assets/assets/images/Chair.webp": "28543e2da1c8adcfaf25f5f3dc70ddc9",
"assets/assets/images/Charger.jpg": "a3bf5ab29d883e316c43e5ee45a8f5ed",
"assets/assets/images/Chess.webp": "f445eef19abe2293df81ff05183c043a",
"assets/assets/images/Clothing.webp": "87b35869b038eadc2b92c6ff03bf2716",
"assets/assets/images/Coffee-machine.webp": "551a65ecc6d289049c014e9391a02793",
"assets/assets/images/foods.jpg": "fa54a5e90afdcb15336cfa83e7bbe562",
"assets/assets/images/games.jpg": "16572f778e368ceeb1ba6d606df05cea",
"assets/assets/images/Hony.jpg": "c2145a3c3ea3bf2a3cc5cbf2a72547b0",
"assets/assets/images/iPhone-16-green.jpg": "f9a2150934ccd789da2e3649211b23e2",
"assets/assets/images/IPhone-16.jpg": "8511f0577770ee9ea729e03fea5c8ddd",
"assets/assets/images/Laptop.jpg": "03d09d54abf60149c47b45c286967765",
"assets/assets/images/laptops.jpg": "6ad4167abe3750b8702c253c6100a377",
"assets/assets/images/novel.png": "c4567628eb4abd7ff6a73095ab68b17e",
"assets/assets/images/nuevo-MacBook-pro.webp": "997608abf67dece1b039309af06e6150",
"assets/assets/images/Olive-oil.jpg": "22505f9dbc69d7cc312e160206f59a9d",
"assets/assets/images/Pazel.jpg": "2b6ec71ed29e5c1dedc01646f775ad95",
"assets/assets/images/Phone.jpg": "877ddcfc4cc2b40cbe580145405c6d09",
"assets/assets/images/Refrigerator.jpg": "23c720bfacb57f547639c18e1f0a3d19",
"assets/assets/images/Shose.jpg": "a82575c0cf99dc4c2df95295abe10449",
"assets/assets/images/Sofa.jpg": "ceff9055d717d02ca3793f12ce09a0f0",
"assets/assets/images/Sony-headphones.jpg": "42f99978357329412286dbcc8040626a",
"assets/assets/images/Sony5.jpg": "91ac6b3335d3bf22fee90fa12e888d1b",
"assets/assets/images/Table.jpg": "4d364a9246811fcd54b1f26522979eca",
"assets/assets/images/Tablet.jpg": "499d10da623b9afd513133bd4f568d3c",
"assets/assets/images/Tea%2520Master.jpg": "5b2bcada966b255ace8c7a44cf0a3a42",
"assets/assets/images/Washing-machine.jpg": "370df88d94253df9308cb12cf69c723c",
"assets/FontManifest.json": "0b7b73ca3320fd3e1eff300058003c50",
"assets/fonts/MaterialIcons-Regular.otf": "901222932f9d0b5434bbb2d52b5b84c1",
"assets/NOTICES": "43a14ed42cf69baae64327b23ab8191f",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "d0a4fa9befb694fbc9ff4e22223d99dd",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "1ef442db4370603f4c1168d2e47b0001",
"/": "1ef442db4370603f4c1168d2e47b0001",
"main.dart.js": "385f401904f9236f2554d1778627493d",
"manifest.json": "0b54befb0d6ac0f507d5c60969c60e48",
"version.json": "224f63b6b69bc6ab191c645203f68fd3"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
