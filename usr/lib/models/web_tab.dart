import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebTab {
  final String id;
  String url;
  String title;
  InAppWebViewController? controller;
  Uint8List? favicon;
  bool isLoading;
  double progress;
  bool isSecure;

  WebTab({
    required this.id,
    this.url = 'about:blank',
    this.title = 'New Tab',
    this.isLoading = false,
    this.progress = 0.0,
    this.isSecure = false,
  });
}
