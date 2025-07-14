import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class MemeHomePage extends StatefulWidget {
  @override
  _MemeHomePageState createState() => _MemeHomePageState();
}

class _MemeHomePageState extends State<MemeHomePage> {
  List memes = [];
  List filteredMemes = [];
  bool isLoading = false;
  bool isOfflineMode = false;
  bool isDark = themeNotifier.value == ThemeMode.dark;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMemes();
  }

  Future<void> fetchMemes() async {
    setState(() {
      isLoading = true;
    });

    List memesData = [];

    final response = await http.get(
      Uri.parse('https://api.imgflip.com/get_memes'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        memesData = data['data']['memes'];
        setState(() {
          memes = memesData;
          filteredMemes = memesData;
          isLoading = false;
        });
      } else {
        print("API response success=false");
      }
    } else {
      print("Failed to load memes. Status code: ${response.statusCode}");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('cached_memes', json.encode(memesData));
  }

  Future<void> loadFromCache() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString('cached_memes');
    if (cachedString != null) {
      final List cachedData = json.decode(cachedString);
      setState(() {
        memes = cachedData;
        filteredMemes = cachedData;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak ada data cache ditemukan')));
    }
  }

  void filterMemes(String query) {
    final result = memes.where((meme) {
      final nameLower = meme['name'].toString().toLowerCase();
      final searchLower = query.toLowerCase();
      return nameLower.contains(searchLower);
    }).toList();

    setState(() {
      filteredMemes = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Meme Editor"),
        centerTitle: true,
        actions: [
          Row(
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, mode, _) {
                  bool isDark = mode == ThemeMode.dark;
                  return Row(
                    children: [
                      Text("Offline", style: TextStyle(fontSize: 12)),
                      Switch(
                        value: isOfflineMode,
                        onChanged: (val) {
                          setState(() {
                            isOfflineMode = val;
                            if (val) {
                              loadFromCache();
                            } else {
                              fetchMemes();
                            }
                          });
                        },
                      ),
                      SizedBox(width: 8),
                      Text("Dark", style: TextStyle(fontSize: 12)),
                      Switch(
                        value: isDark,
                        onChanged: (val) {
                          themeNotifier.value = val
                              ? ThemeMode.dark
                              : ThemeMode.light;
                        },
                      ),
                      SizedBox(width: 8),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: fetchMemes,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: searchController,
                        onChanged: filterMemes,
                        decoration: InputDecoration(
                          hintText: 'Cari meme...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    filterMemes('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: GridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.65,
                          children: filteredMemes.map((meme) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x4C000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: meme['url'],
                                        placeholder: (context, url) =>
                                            Container(color: Colors.grey[300]),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    meme['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 4),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailPage(meme: meme),
                                        ),
                                      );
                                    },
                                    child: Text("Detail"),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
