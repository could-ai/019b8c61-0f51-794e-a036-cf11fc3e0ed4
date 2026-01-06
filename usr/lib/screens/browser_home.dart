import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../providers/browser_provider.dart';
import '../models/web_tab.dart';

class BrowserHome extends StatefulWidget {
  const BrowserHome({super.key});

  @override
  State<BrowserHome> createState() => _BrowserHomeState();
}

class _BrowserHomeState extends State<BrowserHome> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleUrlSubmit(String value, BrowserProvider provider) {
    String url = value.trim();
    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Basic search engine integration (DuckDuckGo)
      if (!url.contains('.')) {
        url = 'https://duckduckgo.com/?q=${Uri.encodeComponent(url)}';
      } else {
        url = 'https://$url';
      }
    }

    provider.currentTab.controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BrowserProvider>(
      builder: (context, provider, child) {
        // Ensure we have at least one tab
        if (provider.tabs.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentTab = provider.currentTab;
        
        // Update text field if the URL changed externally (e.g. link click)
        if (_urlController.text != currentTab.url && !FocusScope.of(context).hasFocus) {
          _urlController.text = currentTab.url;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                // Top Bar (Address Bar)
                _buildAddressBar(context, provider),
                
                // Progress Bar
                if (currentTab.isLoading)
                  LinearProgressIndicator(
                    value: currentTab.progress,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),

                // Browser Content
                Expanded(
                  child: Container(
                    color: Colors.white, // Fallback background for WebView area
                    child: IndexedStack(
                      index: provider.currentIndex,
                      children: provider.tabs.map((tab) => _buildWebView(tab, provider)).toList(),
                    ),
                  ),
                ),
                
                // Bottom Toolbar
                _buildBottomBar(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressBar(BuildContext context, BrowserProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (provider.currentTab.isSecure)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.lock, color: Colors.green, size: 18),
            ),
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Search or enter address',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                prefixIcon: const Icon(Icons.search, size: 20),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (val) => _handleUrlSubmit(val, provider),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              provider.currentTab.controller?.reload();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebView(WebTab tab, BrowserProvider provider) {
    // Web-specific settings adjustments
    final initialSettings = InAppWebViewSettings(
      // PRIVACY SETTINGS
      isInspectable: kDebugMode, // Enable debug in dev mode
      incognito: !kIsWeb, // Incognito not fully supported on all web browsers via iframe
      cacheEnabled: false,
      clearCache: true,
      clearSessionCache: true,
      
      // Content Blocking
      javaScriptEnabled: !provider.blockScripts,
      
      // UI Settings
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: true,
      allowsInlineMediaPlayback: true,
      
      // Web Specific
      iframeAllow: "camera; microphone", // Example permissions
      iframeAllowFullscreen: true,
    );

    return InAppWebView(
      key: ValueKey(tab.id),
      initialUrlRequest: URLRequest(url: WebUri(tab.url)),
      initialSettings: initialSettings,
      onWebViewCreated: (controller) {
        provider.setController(tab.id, controller);
      },
      onLoadStart: (controller, url) {
        provider.updateTabLoading(tab.id, true);
        provider.updateTabUrl(tab.id, url.toString());
      },
      onLoadStop: (controller, url) async {
        provider.updateTabLoading(tab.id, false);
        provider.updateTabUrl(tab.id, url.toString());
        final title = await controller.getTitle();
        if (title != null) {
          provider.updateTabTitle(tab.id, title);
        }
      },
      onProgressChanged: (controller, progress) {
        provider.updateTabProgress(tab.id, progress / 100);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        // Here we can implement HTTPS enforcement
        var uri = navigationAction.request.url!;
        
        if (provider.httpsOnly && uri.scheme == 'http') {
           // Logic to upgrade to https would go here
           // For now, we allow it but show insecure icon
        }
        
        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, BrowserProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async {
              if (await provider.currentTab.controller?.canGoBack() ?? false) {
                provider.currentTab.controller?.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () async {
              if (await provider.currentTab.controller?.canGoForward() ?? false) {
                provider.currentTab.controller?.goForward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 32),
            onPressed: () {
              provider.addTab();
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_none),
                onPressed: () {
                  _showTabsSheet(context, provider);
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${provider.tabs.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            onPressed: () {
              _showPrivacyMenu(context, provider);
            },
          ),
        ],
      ),
    );
  }

  void _showTabsSheet(BuildContext context, BrowserProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Open Tabs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: provider.tabs.length,
                itemBuilder: (context, index) {
                  final tab = provider.tabs[index];
                  return ListTile(
                    title: Text(tab.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(tab.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: index == provider.currentIndex,
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        provider.closeTab(index);
                        Navigator.pop(context); // Close sheet to refresh or keep open
                      },
                    ),
                    onTap: () {
                      provider.switchTab(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyMenu(BuildContext context, BrowserProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Privacy Shield', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Clear Session Data'),
              subtitle: const Text('Close all tabs and wipe cookies'),
              onTap: () {
                provider.clearAllData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session data cleared')),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Block Trackers'),
              value: provider.blockTrackers,
              onChanged: (val) {
                // In a real app, this would trigger rule list reload
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              title: const Text('HTTPS Only'),
              value: provider.httpsOnly,
              onChanged: (val) {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
