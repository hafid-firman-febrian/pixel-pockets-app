/// All API URL string constants live here.
///
/// Base URL selection:
/// - Production: the deployed Vercel URL.
/// - Dev (Android emulator): http://10.0.2.2:3000
/// - Dev (iOS simulator):    http://localhost:3000
///
/// [ApiClient] decides which base URL to use; this file only holds paths.
class ApiEndpoints {
  ApiEndpoints._();

  // ---- Base URLs ----
  static const String prodBaseUrl = 'https://pixel-pocket.vercel.app';
  static const String androidDevBaseUrl = 'http://10.0.2.2:3000';
  static const String iosDevBaseUrl = 'http://localhost:3000';

  // ---- Categories ----
  static const String categories = '/api/categories';
  static const String categoriesSeed = '/api/categories/seed';

  // ---- Salary periods ----
  static const String salaryPeriods = '/api/salary-periods';
  static const String salaryPeriodsSeed = '/api/salary-periods/seed';

  // ---- Transactions ----
  static const String transactions = '/api/transactions';
  static String transactionById(int id) => '/api/transactions/$id';

  // ---- Summary ----
  static const String summary = '/api/summary';
  static const String summaryByCategory = '/api/summary/by-category';
  static const String summaryChart = '/api/summary/chart';

  // ---- Backup ----
  static const String backupSpreadsheet = '/api/backup/spreadsheet';
}
