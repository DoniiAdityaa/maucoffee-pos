const String productionPackageName =
    "id.garda.mobile"; // Bisa diupdate ke package berita nanti
const String sandboxPackageName = "id.garda.mobile";
const String appId = "6478091723";

/// Network Config
const String baseUrlProduction = "https://newsapi.org/v2";
const String baseUrlSandbox = "https://newsapi.org/v2/";
const String baseUrl = isProduction ? baseUrlProduction : baseUrlSandbox;
const String baseApi = baseUrl;

/// is production
const bool isProduction = false;

/// Timeout Duration (Digunakan di service_locator.dart)
const int timeOutDuration = 30;
