import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/web_tab.dart';

class BrowserProvider extends ChangeNotifier {
  final List<WebTab> _tabs = [];
  int _currentIndex = 0;
  
  // Default privacy settings
  bool _httpsOnly = true;
  bool _blockScripts = false;
  bool _blockTrackers = true;

  BrowserProvider() {
    _addNewTab();
  }

  List<WebTab> get tabs => _tabs;
  int get currentIndex => _currentIndex;
  WebTab get currentTab => _tabs[_currentIndex];
  
  bool get httpsOnly => _httpsOnly;
  bool get blockScripts => _blockScripts;
  bool get blockTrackers => _blockTrackers;

  void _addNewTab() {
    final newTab = WebTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: 'https://duckduckgo.com', // Privacy default
      title: 'New Tab',
    );
    _tabs.add(newTab);
    _currentIndex = _tabs.length - 1;
    notifyListeners();
  }

  void addTab() {
    _addNewTab();
  }

  void closeTab(int index) {
    if (_tabs.length <= 1) {
      // Don't close the last tab, just reset it
      _tabs[0].url = 'https://duckduckgo.com';
      _tabs[0].title = 'New Tab';
      _tabs[0].controller?.loadUrl(urlRequest: URLRequest(url: WebUri('https://duckduckgo.com')));
    } else {
      _tabs.removeAt(index);
      if (_currentIndex >= _tabs.length) {
        _currentIndex = _tabs.length - 1;
      }
    }
    notifyListeners();
  }

  void switchTab(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void updateTabUrl(String id, String url) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tabs[index].url = url;
      _tabs[index].isSecure = url.startsWith('https://');
      notifyListeners();
    }
  }

  void updateTabTitle(String id, String title) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tabs[index].title = title;
      notifyListeners();
    }
  }

  void updateTabLoading(String id, bool isLoading) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tabs[index].isLoading = isLoading;
      notifyListeners();
    }
  }

  void updateTabProgress(String id, double progress) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tabs[index].progress = progress;
      notifyListeners();
    }
  }

  void setController(String id, InAppWebViewController controller) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tabs[index].controller = controller;
    }
  }

  // Privacy Actions
  void clearAllData() {
    // This will be connected to the WebView cookie manager
    // In a real app, we would also clear the tabs list
    _tabs.clear();
    _addNewTab();
    notifyListeners();
  }
}
