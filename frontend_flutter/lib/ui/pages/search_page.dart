import 'dart:convert';

import 'package:demo/constants/cookies.dart';
import 'package:demo/constants/dimens.dart';
import 'package:demo/services/download_manager.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:demo/utils/show_notes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final DownloadManager _downloadManager = DownloadManager();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _results = [];
  int _currentPage = 1;
  bool _isLoading = false;


  Future<void> _searchBilibili(BuildContext context, String keyword, {int page = 1}) async {
    if(!_formKey.currentState!.validate()){
      return;
    }

    // increase search count
    AppCookies.incrementSearchCount();

    // get search cookies
    final cookie = AppCookies.getCurrentCookie();
    debugPrint('cookie: $cookie');
    
    // Max page size 
    if (page > 50) {
      showMySnackBar(context, 'Reached max page size', Colors.red, 1000);
      return;
    }

    setState(() {
      _currentPage = page;
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.bilibili.com/x/web-interface/wbi/search/type?search_type=video&keyword=$keyword&page=$page&page_size=20'),
        // https://api.bilibili.com/x/web-interface/wbi/search/type
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': 'https://www.bilibili.com/',
          'Cookie': cookie,
          // 'Cookie': "buvid3=0AE3917F-D4B5-1EDB-620C-5322E444AEF951418infoc; b_nut=1743924151; _uuid=514E6A74-DCBF-FC1D-14105-9C8B548451E851902infoc; enable_web_push=DISABLE; enable_feed_channel=ENABLE; buvid4=F6459903-14DF-8E6A-BE01-84C9AE91E7C652708-025040607-2WN7LHA2bldvaP5pzJCwGw%3D%3D; buvid_fp=6bc7a29f174b8cdab833be5c836bf95c; DedeUserID=272017820; DedeUserID__ckMd5=cdccea0d7b714ab4; rpdid=|(umYJm~RmJY0J'u~RJmkRk)m; header_theme_version=CLOSE; CURRENT_QUALITY=112; PVID=1; home_feed_column=5; browser_resolution=1492-800; bili_ticket=eyJhbGciOiJIUzI1NiIsImtpZCI6InMwMyIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDgzOTEyOTcsImlhdCI6MTc0ODEzMjAzNywicGx0IjotMX0.LAIBJhq3aCSyovQPA39N0d8P2LCLLE1_fhjGeYNIGhs; bili_ticket_expires=1748391237; SESSDATA=d94cb20f%2C1763684098%2C53937%2A51CjCT5qLFpFx5xelZ7Mu_LU6L51Zl84Cn6ZJjydycRtabXH3_MQPhPNmuTvsrLFL0Bi8SVndya3JKcHEtYzFDYm5iN3k1bExEVUVvQU5lR2JEVVM3M0tqMkxxTV9obEtER0dmbHFGX1d4YWxYTWx5UGQyYlhTRWpicFVaZFpvYUd1MzFvalUya1R3IIEC; bili_jct=d3353c93304c13f0e07438e5afbbc7ec; bp_t_offset_272017820=1071271058163630080; b_lsid=1DAFF8DA_19710AA026B; CURRENT_FNVAL=2000; sid=8vmgiwhf"
          // 'Cookie':"buvid3=17A69985-9692-2F49-0DB5-44F53023E20131144infoc; b_nut=1743336731; _uuid=ADA10BD31-3DDA-DA67-FFF9-95FC973461BB32150infoc; buvid4=22098B6D-1A06-5780-BD42-857F8F99DD5340967-025033012-iCFhtLPnDV02rb39dtI1Uw%3D%3D; rpdid=|(J~k|~JlJ)u0J'u~RJJJY~Rk; header_theme_version=CLOSE; enable_web_push=DISABLE; enable_feed_channel=ENABLE; buvid_fp_plain=undefined; home_feed_column=5; PVID=1; CURRENT_QUALITY=112; browser_resolution=1482-780; bili_ticket=eyJhbGciOiJIUzI1NiIsImtpZCI6InMwMyIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NTEyOTE4ODQsImlhdCI6MTc1MTAzMjYyNCwicGx0IjotMX0.SSOZ7cgitDIbsXU7amOvfcBQLkTptpcwLG_tyeoas6w; bili_ticket_expires=1751291824; bsource=search_bing; fingerprint=3cdc12449b9b2e21203e461d8aaf703e; b_lsid=B55ACFF3_197BB68BF04; buvid_fp=3cdc12449b9b2e21203e461d8aaf703e; sid=4xq12e4r; bmg_af_switch=1; bmg_src_def_domain=i0.hdslb.com; bp_t_offset_272017820=1083873630376427520; CURRENT_FNVAL=2000"
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['data']['result'] ?? [];

        // filter out non-video results
        results.removeWhere((element) => element['type'] != 'video');

        setState(() {
          _results = results;
        }); 
       
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      showMySnackBar(context, 'error: $e', Colors.red, 1000);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _downloadManager.initDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
          // Home Button
          IconButton(
            icon: Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),

      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(context),
          // Search Results
          _buildSearchResults(),
        ],
      ),
   
      drawer: const MyDrawer(),

      persistentFooterButtons: 
        _results.isEmpty ? [] : // No search results
        [
          // Page number
          Text(
            'Page $_currentPage',
            style: const TextStyle(
              color: Colors.black
            ),
          ),
          // Prev Page Button
          if (_currentPage > 1)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                _searchBilibili(context, _searchController.text, page: _currentPage-1);
                _buildSearchResults();
              },
              child: const Text(
                'Prev Page',
                style: TextStyle(
                  color: Colors.black
                ),
              ),
            ),
          // Next Page Button
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            onPressed: () {
              _searchBilibili(context, _searchController.text, page: _currentPage+1);
              _buildSearchResults();
            },
            child: const Text(
              'Next Page',
              style: TextStyle(
                color: Colors.black
              ),
            ),
          ),
        ],
      
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Flexible(
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'search for videos',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a keyword';
                  }
                  return null;
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _searchBilibili(context, _searchController.text);
              // _downloadManager.addDownload(_urlController.text);
            },
          ), 
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No results found'));
    }
    return Expanded(
      child: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          if (index == _results.length) {
            return const Center(child: CircularProgressIndicator());
          } else if (index < _results.length) {
            final item = _results[index];
            String rawTitle = item['title'].replaceAll(RegExp(r'<[^>]*>'), '');
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),

              margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            
              child: ListTile(
                leading: Image.network(
                  'https:${item['pic']}',
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                ),
                title: SizedBox(
                  height: 35,
                  child: Text(
                    rawTitle,
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                subtitle: Text(
                  'UP: ${item['author']} \nPLAY: ${item['play']} \nDURATION: ${item['duration']}',
                  style: const TextStyle(
                    fontSize: 8,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // print('download video ${item['arcurl']}');
                    String url = item['arcurl'];
                    // print(url);
                    _downloadManager.addDownload(context, url);
                  },
                ),
                onTap: () async{
                  String url = item['arcurl'];
                  final Uri uri = Uri.parse(url);
                  await launchUrl(uri);
                },
              )
            );    
          } else {
            return const Center(child: Text('No more results'));
          }
        },
             
      ),
    );
  }

}
    