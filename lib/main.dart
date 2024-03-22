import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}



class HomePage extends StatelessWidget {
  Future<List<Article>> _getArticles() async {
    final response = await http.get(
        Uri.parse("https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=a162b06b746848ddaf817611270a819d"));
    if (response.statusCode == 200) {
      List<Article> articles = [];
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData['status'] == 'ok') {
        jsonData['articles'].forEach((article) {
          articles.add(Article.fromJson(article));
        });
      }
      return articles;
    } else {
      throw Exception('Failed to load articles');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News'),
      ),
      body: FutureBuilder(
        future: _getArticles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return Center(child: Text('No articles available'));
          } else {
            List<Article> articles = snapshot.data as List<Article>;
            return ListView.builder(
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(articles[index].title),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ArticleDetailPage(article: articles[index]),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.bookmark),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SavedArticlesPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class Article {
  final String title;
  final String description;
  final String url;
  final String imageUrl; // Trường mới để lưu trữ URL của ảnh

  Article({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      url: json['url'] ?? "",
      imageUrl: json['urlToImage'] ?? "", // Lấy URL của ảnh từ trường 'urlToImage'
    );
  }
}

class ArticleDetailPage extends StatelessWidget {
  final Article article;

  const ArticleDetailPage({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty)
              Image.network(article.imageUrl),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                article.description,
                style: TextStyle(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  List<String>? savedArticles =
                      prefs.getStringList('saved_articles');
                  if (savedArticles == null) savedArticles = [];
                  savedArticles.add(article.title);
                  prefs.setStringList('saved_articles', savedArticles);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Article saved'),
                  ));
                },
                child: Text('Save Article'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedArticlesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Articles'),
      ),
      body: FutureBuilder(
        future: _getSavedArticles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return Center(child: Text('No saved articles'));
          } else {
            List<String> savedArticles = snapshot.data as List<String>;
            return ListView.builder(
              itemCount: savedArticles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(savedArticles[index]),
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.bookmark),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _getSavedArticles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedArticles = prefs.getStringList('saved_articles');
    if (savedArticles == null) savedArticles = [];
    return savedArticles;
  }
}
