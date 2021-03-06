import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:fehviewer/common/global.dart';
import 'package:fehviewer/const/const.dart';
import 'package:fehviewer/utils/time.dart';
import 'package:fehviewer/utils/toast.dart';
import 'package:flutter/cupertino.dart';

import 'logger.dart';

class HttpManager {
  //构造函数
  HttpManager(String _baseUrl, {bool cache = true}) {
    _options = BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        //设置请求头
        headers: <String, String>{
          'User-Agent': EHConst.CHROME_USER_AGENT,
          'Accept': EHConst.CHROME_ACCEPT,
          'Accept-Language': EHConst.CHROME_ACCEPT_LANGUAGE,
        },
        //默认值是"application/json; charset=utf-8",Headers.formUrlEncodedContentType会自动编码请求体.
        contentType: Headers.formUrlEncodedContentType,
        //共有三种方式json,bytes(响应字节),stream（响应流）,plain
        responseType: ResponseType.json);
    _dio = Dio(_options);

    //设置Cookie管理
    _dio.interceptors.add(Global.cookieManager);

    //添加拦截器
    if (cache) {
      _dio.interceptors.add(DioCacheManager(
        CacheConfig(
          databasePath: Global.appSupportPath,
          baseUrl: _baseUrl,
        ),
      ).interceptor);
    }

    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      final HttpClient httpClient = HttpClient();
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return true;
      };
      return httpClient;
    };
  }

  final int connectTimeout = 20000;
  final int receiveTimeout = 10000;

  //单例模式
  static final Map<String, HttpManager> _instanceMap = <String, HttpManager>{};

  Dio _dio;
  BaseOptions _options;

  //单例模式，一个baseUrl只创建一次实例
  static HttpManager getInstance({String baseUrl = '', bool cache = true}) {
    final String _key = '${baseUrl}_$cache';
    if (null == _instanceMap[_key]) {
      _instanceMap[_key] = HttpManager(baseUrl, cache: cache);
    }
    return _instanceMap[_key];
  }

  //get请求方法
  Future<String> get(
    String url, {
    Map<String, dynamic> params,
    Options options,
    CancelToken cancelToken,
  }) async {
    Response<String> response;

    time.showTime('get $url start');
    try {
      response = await _dio.get<String>(url,
          queryParameters: params, options: options, cancelToken: cancelToken);
    } on DioError catch (e, stack) {
      logger.e('getHttp exception: $e\n$stack');
      formatError(e);
      rethrow;
    }
    time.showTime('get $url end');

    // print('getHttp statusCode: ${response.statusCode}');
    return response.data;
  }

  Future<Response<dynamic>> getAll(String url,
      {Map<String, dynamic> params,
      Options options,
      CancelToken cancelToken}) async {
    Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(url,
          queryParameters: params, options: options, cancelToken: cancelToken);
    } on DioError catch (e) {
      print('getHttp exception: $e');
//      formatError(e);
      return response;
//      throw e;
    }
    return response;
  }

  //post请求
  Future<Response<dynamic>> post(String url,
      {Map<String, dynamic> params,
      Options options,
      CancelToken cancelToken}) async {
    Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(url,
          queryParameters: params, options: options, cancelToken: cancelToken);
      debugPrint('postHttp response: $response');
    } on DioError catch (e) {
      print('postHttp exception: $e');
      formatError(e);
//      throw e;
    }
    return response;
  }

  //post Form请求
  Future<Response<dynamic>> postForm(
    String url, {
    Object data,
    Options options,
    CancelToken cancelToken,
  }) async {
    Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(url,
          options: options, cancelToken: cancelToken, data: data);
//      debugPrint('postHttp response: $response');
    } on DioError catch (e) {
//      print('postHttp exception: $e');
      formatError(e);
      rethrow;
//      throw e;
    }
    return response;
  }

  //下载文件
  Future<Response<dynamic>> downLoadFile(
      String urlPath, String savePath) async {
    Response<dynamic> response;
    try {
      response = await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: (int count, int total) {
          print('$count $total');
        },
        options: Options(
          receiveTimeout: 0,
        ),
      );
      print('downLoadFile response: $response');
    } on DioError catch (e) {
      print('downLoadFile exception: $e');
      formatError(e);
    }
    return response;
  }

  //取消请求
  void cancleRequests(CancelToken token) {
    token.cancel('cancelled');
  }

  void formatError(DioError e) {
    if (e.type == DioErrorType.CONNECT_TIMEOUT) {
      showToast('连接超时');
    } else if (e.type == DioErrorType.SEND_TIMEOUT) {
      showToast('请求超时');
    } else if (e.type == DioErrorType.RECEIVE_TIMEOUT) {
      showToast('响应超时');
    } else if (e.type == DioErrorType.RESPONSE) {
      showToast('响应异常');
    } else if (e.type == DioErrorType.CANCEL) {
      showToast('请求取消');
    } else {
      showToast('网络好像出问题了');
    }
  }
}
