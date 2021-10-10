import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:wordpress_api/src/constants.dart';
import 'package:wordpress_api/src/helpers.dart';
import 'package:wordpress_api/wordpress_api.dart' as wp;

class WordPressAPI {
  /// WordPress website base url
  String site;

  /// Initialize a custom dio instance.
  ///
  /// Useful if you want to customize `Dio`
  final Dio _dio;

  /// WooCommerce API credentials
  // final WooCredentials? wooCredentials;

  WordPressAPI(
    this.site, {
    Dio? dio,
  }) : _dio = dio ??= Dio();

  // GET DATA FROM CUSTOM ENDPOINT //
  /// Retrieves data from a given endpoint and resturns a [WPResponse]
  Future<WPResponse> fetch(
    /// Provide an API endpoint
    String endpoint, {

    /// REST API namespace
    String namespace = wpNamespace,

    /// Additional wordpress arguments
    Map<String, dynamic>? args,
  }) async {
    final uri = await _discover(site);

    //***************************** */
    // Remove any starting '/' if any
    //****************************** */
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    if (uri.contains('?') && endpoint.contains('?')) {
      endpoint = endpoint.replaceAll('?', '&');
    }

    // NAMESPACE DISCOVERY
    // Check if the provided namespace has a trailing `/`
    if (namespace.endsWith('/')) {
      namespace = namespace.substring(0, namespace.length - 1).toLowerCase();
    }

    // Set [Dio] base Url
    _dio.options.baseUrl = uri;

    // **********************************************
    //  SET WOOCOMMERCE CREDENTIALS
    // **********************************************
    WooCredentials wooCredentials = await getKeys();
    if (wooCredentials != null) {
      // _dio.options.queryParameters ??= {};
      _dio.options.queryParameters.addAll({
        "consumer_key": wooCredentials.consumerKey,
        "consumer_secret": wooCredentials.consumerSecret
      });
    }

    //******************************************* */
    // FETCH REQUESTED DATA AND RETURN WP A RESPONSE
    //******************************************* */
    try {
      int? total, totalPages;
      final res = await _dio.get(
        '/$namespace/$endpoint',
        queryParameters: args,
      );

      if (res.headers.value('x-wp-total') != null) {
        total = int.tryParse(res.headers.value('x-wp-total')!);
        totalPages = int.tryParse(res.headers.value('x-wp-totalpages')!);
      }

      return WPResponse(
        data: res.data,
        meta: WPMeta(
          total: total,
          totalPages: totalPages,
        ),
        statusCode: res.statusCode!,
      );
    } on DioError catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> put(
      /// Provide an API endpoint
      String endpoint, {

        /// REST API namespace
        String namespace = wpNamespace,

        /// Additional wordpress arguments
        Map<String, dynamic>? args,
      }) async {
    final uri = await _discover(site);

    //***************************** */
    // Remove any starting '/' if any
    //****************************** */
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    if (uri.contains('?') && endpoint.contains('?')) {
      endpoint = endpoint.replaceAll('?', '&');
    }

    // NAMESPACE DISCOVERY
    // Check if the provided namespace has a trailing `/`
    if (namespace.endsWith('/')) {
      namespace = namespace.substring(0, namespace.length - 1).toLowerCase();
    }

    // Set [Dio] base Url
    _dio.options.baseUrl = uri;

    // **********************************************
    //  SET WOOCOMMERCE CREDENTIALS
    // **********************************************
    WooCredentials wooCredentials = await getKeys();
    if (wooCredentials != null) {
      // _dio.options.queryParameters ??= {};
      _dio.options.queryParameters.addAll({
        "consumer_key": wooCredentials.consumerKey,
        "consumer_secret": wooCredentials.consumerSecret
      });
    }

    //******************************************* */
    // FETCH REQUESTED DATA AND RETURN WP A RESPONSE
    //******************************************* */
    print("enter");
    try {
      int? total, totalPages;
      final res = await _dio.put(
        '/$namespace/$endpoint',
        data: args,
      );

      print("done");
      return true;
    } on DioError catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Wordpress `REST API Discovery` from Link Header
  Future<String> _discover(String site) async {
    String _site = site;
    final Dio dio = Dio(
      BaseOptions(
        contentType: "application/json",
        headers: {
          "accept": "application/json",
        },
      ),
    );

    if (!site.startsWith('http')) {
      _site = 'http://$site'.toLowerCase();
    }

    try {
      final res = await dio.head(_site);
      // : Change logger to comment. Used only to debug
      // Utils.logger.i("HEADER: ${res.headers}");
      if (res.headers['link'] != null) {
        final link = res.headers['link']!.first.split(';').first;
        return link.substring(1, link.length - 1);
      }
      return "$_site/wp-json";
    } catch (e) {
      rethrow;
    }
  }

  Future<WooCredentials> getKeys() async {
    var collection = FirebaseFirestore.instance.collection('wpKeys');

    var doc = await collection.doc("wpKey").get();

    return wp.WooCredentials(doc.get("client"), doc.get("secret"));
  }
}
