import 'package:demo/constants/dimens.dart';
import 'package:demo/services/download_manager.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DownloadListPage extends StatefulWidget {
  const DownloadListPage({super.key});

  @override
  _DownloadListPageState createState() => _DownloadListPageState();
}

class _DownloadListPageState extends State<DownloadListPage> {
  late DownloadManager downloadManager;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final _urlTextController = TextEditingController();
 


  @override
  void initState() {
    super.initState();
    downloadManager = Provider.of<DownloadManager>(context, listen: false);
    downloadManager.initDatabase().then((_) {
      _loadDownloads();
      downloadManager.addListener(_loadDownloads);
    });
  }

  @override
  void dispose() {
    // final downloadManager = Provider.of<DownloadManager>(context, listen: false);
    downloadManager.removeListener(_loadDownloads);
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    try {
      final downloadManager = Provider.of<DownloadManager>(context, listen: false);
      final downloads = await downloadManager.getDownloads();
      setState(() {
        downloadManager.downloads = downloads;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading downloads: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDownload(int id) async {
    try {
      await downloadManager.deleteDownload(id);
      // await _loadDownloads();
    } catch (e) {
      debugPrint('Error deleting download: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadDownloads();
    final downloadManager = Provider.of<DownloadManager>(context, listen: true);
    final downloads = downloadManager.downloads;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(
          'DOWNLOADS',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge
          )
          
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.only(bottom: 100),
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final download = downloads[index];
                final id = download['id'];
                final title = download['title'] ?? download['originalUrl'];
                // final originalUrl = download['originalUrl'];
                final downloadedBytes = download['downloadedBytes'] ?? 0;
                final totalBytes = download['totalBytes'] ?? 0;
                final isPaused = download['isPaused'] == 1;
                
                // calculate progress
                double progress = totalBytes > 0 
                    ? (downloadedBytes / totalBytes) * 100 
                    : 0;
                
                return Card(
                  color: Theme.of(context).colorScheme.primary,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      title, 
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Dimens.fontSizeSmall
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // display progress bar
                        LinearProgressIndicator(
                          value: totalBytes > 0 ? downloadedBytes / totalBytes : 0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isPaused ? Colors.grey : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // display download progress text (formatted MB/GB)
                        Text(
                          '${_formatBytes(downloadedBytes)}/${_formatBytes(totalBytes)}'
                          ' (${progress.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: Dimens.fontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            if (isPaused) {
                              await downloadManager.resumeDownload(id);
                            } else {
                              await downloadManager.pauseDownload(id);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPaused ? Colors.green : Colors.red,
                          ),
                          child: Text(
                            isPaused ? 'Resume' : 'Pause',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                            )
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteDownload(id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
      drawer: const MyDrawer(),

      bottomSheet: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Flexible(
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _urlTextController,
                  decoration: const InputDecoration(
                    labelText: 'Enter URL',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a URL';
                    }
                    return null;
                  },
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) {
                  // _formKey.currentState!.reset();
                  return;
                }
                downloadManager.addDownload(context, _urlTextController.text);
                // print(_urlTextController.text);
              },
              icon: const Icon(Icons.download),
            ),
          ],
        ),
      ),
    );
  }

  // helper method: format bytes to MB/GB display
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
    