import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

void main() {
  runApp(const GoldUsdApp());
}

class GoldUsdApp extends StatelessWidget {
  const GoldUsdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نبض طلا و دلار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1218),
      ),
      home: const HomeScreen(),
    );
  }
}

class TelegramPost {
  final String text;
  final String date;
  final String? imageUrl;
  final String category;

  TelegramPost({
    required this.text,
    required this.date,
    this.imageUrl,
    required this.category,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // کانال تلگرام شما
  final String channelUsername = "ounce00";

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.candlestick_chart, color: Color(0xFFFFD700), size: 32),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "نبض طلا و دلار",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          "مرجع قیمت‌های لحظه‌ای و تحلیل‌های استراتژیک",
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 2.5,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, Color(0xFFE65100), Colors.transparent],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMenuButton(
                        context: context,
                        title: "قیمت",
                        icon: Icons.price_check,
                        color: const Color(0xFFFFD700),
                        category: "price",
                        pageTitle: "قیمت‌های روز طلا و دلار",
                      ),
                      const SizedBox(height: 24),
                      _buildMenuButton(
                        context: context,
                        title: "تحلیل",
                        icon: Icons.analytics_outlined,
                        color: const Color(0xFF00E676),
                        category: "analysis",
                        pageTitle: "دیدگاه و تحلیل‌های روزانه",
                      ),
                      const SizedBox(height: 24),
                      _buildMenuButton(
                        context: context,
                        title: "اخبار",
                        icon: Icons.newspaper_outlined,
                        color: const Color(0xFF29B6F6),
                        category: "news",
                        pageTitle: "اخبار و رویدادهای بازار",
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text("نسخه ۱.۰.۰", style: TextStyle(color: Colors.white24, fontSize: 11)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String category,
    required String pageTitle,
  }) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryPostsScreen(
                  category: category,
                  pageTitle: pageTitle,
                  channelUsername: channelUsername,
                  accentColor: color,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.6), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryPostsScreen extends StatefulWidget {
  final String category;
  final String pageTitle;
  final String channelUsername;
  final Color accentColor;

  const CategoryPostsScreen({
    super.key,
    required this.category,
    required this.pageTitle,
    required this.channelUsername,
    required this.accentColor,
  });

  @override
  State<CategoryPostsScreen> createState() => _CategoryPostsScreenState();
}

class _CategoryPostsScreenState extends State<CategoryPostsScreen> {
  List<TelegramPost> filteredPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    setState(() => isLoading = true);
    final url = "https://t.me/s/${widget.channelUsername}";

    try {
      final response = await http.get(Uri.parse(url), headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
      });

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final messageElements = document.querySelectorAll('.tgme_widget_message_wrap');

        List<TelegramPost> allPosts = [];

        for (var el in messageElements) {
          final textElement = el.querySelector('.tgme_widget_message_text');
          final timeElement = el.querySelector('time');
          final photoElement = el.querySelector('.tgme_widget_message_photo_wrap');

          String text = textElement?.text.trim() ?? '';
          String date = timeElement?.attributes['datetime']?.split('T').first ?? '';

          String? imageUrl;
          if (photoElement != null) {
            String style = photoElement.attributes['style'] ?? '';
            final regExp = RegExp(r"background-image:url\('(.+?)'\)");
            final match = regExp.firstMatch(style);
            if (match != null) {
              imageUrl = match.group(1);
            }
          }

          if (text.isNotEmpty || imageUrl != null) {
            String postCategory = "analysis";
            if (text.contains("#قیمت") || text.contains("مظنه") || text.contains("قیمت لحظه‌ای")) {
              postCategory = "price";
            } else if (text.contains("#خبر") || text.contains("#اخبار") || text.contains("فوری")) {
              postCategory = "news";
            } else if (text.contains("#تحلیل") || text.contains("سناریو")) {
              postCategory = "analysis";
            }

            allPosts.add(TelegramPost(
              text: text,
              date: date,
              imageUrl: imageUrl,
              category: postCategory,
            ));
          }
        }

        setState(() {
          filteredPosts = allPosts
              .where((p) => p.category == widget.category)
              .toList()
              .reversed
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load channel");
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF161B22),
          elevation: 0,
          title: Text(widget.pageTitle, style: const TextStyle(fontSize: 16)),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: widget.accentColor),
              onPressed: fetchPosts,
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: widget.accentColor))
            : filteredPosts.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        "هیچ پستی در این دسته‌بندی یافت نشد.\n\n(در کانال تلگرام برای دسته‌بندی از هشتگ‌های #قیمت ، #تحلیل یا #اخبار استفاده کنید)",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, height: 1.7),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: widget.accentColor,
                    onRefresh: fetchPosts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (post.imageUrl != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(post.imageUrl!, fit: BoxFit.cover),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.text,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.7),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.white38),
                                        const SizedBox(width: 4),
                                        Text(post.date, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
