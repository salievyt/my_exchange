import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

/// NBKR exchange rate data
class NbkrRate {
  final String currencyCode;
  final int nominal;
  final double value;

  const NbkrRate({
    required this.currencyCode,
    required this.nominal,
    required this.value,
  });

  /// Rate for 1 unit of currency in KGS
  double get rate => value / nominal;

  @override
  String toString() => '$currencyCode: $rate KGS';
}

/// Service to fetch official exchange rates from NBKR (National Bank of Kyrgyzstan)
class NbkrService {
  final Dio _dio;
  final String dailyUrl = 'https://www.nbkr.kg/XML/daily.xml';

  NbkrService() : _dio = Dio();

  /// Fetch daily exchange rates from NBKR.
  /// Returns a map of currency code to NbkrRate.
  Future<Map<String, NbkrRate>> fetchDailyRates() async {
    try {
      final response = await _dio.get(
        dailyUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Accept': 'application/xml, text/xml, */*',
          },
        ),
      );

      final xmlString = response.data as String;
      return _parseXmlRates(xmlString);
    } catch (e) {
      throw Exception('Ошибка загрузки курсов НБ КР: $e');
    }
  }

  Map<String, NbkrRate> _parseXmlRates(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final rates = <String, NbkrRate>{};

    final currencyNodes = document.findAllElements('Currency');
    for (final node in currencyNodes) {
      final isoCode = node.findElements('ISOCode').firstOrNull?.innerText;
      final nominalStr = node.findElements('Nominal').firstOrNull?.innerText;
      final valueStr = node.findElements('Value').firstOrNull?.innerText;

      if (isoCode == null || nominalStr == null || valueStr == null) continue;

      final nominal = int.tryParse(nominalStr) ?? 1;
      final value = double.tryParse(valueStr.replaceAll(',', '.')) ?? 0.0;

      if (value > 0) {
        rates[isoCode] = NbkrRate(
          currencyCode: isoCode,
          nominal: nominal,
          value: value,
        );
      }
    }

    return rates;
  }
}
