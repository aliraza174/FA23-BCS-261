import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/openai_service.dart';
import '../theme/app_theme.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  List<String> previousQuestions = [];
  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Welcome message for the AI Assistant
  final String welcomeMessage = '''
🤖 Welcome to Torbaaz AI Assistant! 🍽

I'm powered by ChatGPT and have real-time knowledge about all restaurants, menus, and deals in Jahanian!

💬 Just ask me anything about:
• Restaurant recommendations
• Menu items and prices  
• Current deals and offers
• Food delivery options
• Ratings and reviews
• Contact information

🍕 Try these sample questions:
• "What are the best pizza places?"
• "Show me deals under Rs. 800"
• "Which restaurant has the fastest delivery?"
• "What's the most popular item at Meet N Eat?"
• "Compare burger prices across restaurants"

🚀 I'm here to help you discover amazing food! Just type your question below and I'll give you personalized, up-to-date recommendations.

What are you craving today? 😊
''';

  // Adding keyword triggers for food category responses
  List<String> pizzaKeywords = [
    'pizza',
    'Pizza',
    'pizzas',
    'peri peri pizza',
    'chicken supreme pizza',
    'cheese lover pizza',
    'malai boti pizza',
    'extreme pizza',
    'crust bros pizza',
    'pizza slice',
    'large pizza',
    'medium pizza',
    'small pizza',
    'pizza prices'
  ];
  List<String> burgerKeywords = [
    'burger',
    'burgers',
    'crispy zinger',
    'mighty zinger',
    'patty burger',
    'meet n eat special beef burger',
    'classic beef burger',
    'smoked beef burger',
    'zinger stacker'
  ];
  List<String> friesKeywords = [
    'fries',
    'french fries',
    'loaded fries',
    'pizza fries',
    'garlic mayo fries'
  ];
  List<String> wrapsKeywords = [
    'wraps',
    'wrap',
    'crispy wrap',
    'kababish wrap',
    'cheetos wrap',
    'meet n eat special wrap'
  ];
  List<String> mainCourseKeywords = [
    'biryani',
    'karahi',
    'chicken handi',
    'mutton karahi',
    'beef nihari',
    'nihari',
    'curry',
    'chicken korma'
  ];
  List<String> pastaKeywords = [
    'pasta',
    'fettuccine pasta',
    'flaming pasta',
    'fajita pasta',
    'crunchy pasta',
    'cheese pasta',
    'arabic pasta',
    'peri peri pasta',
    'white sauce pasta',
    'lasagna'
  ];
  List<String> wingsKeywords = [
    'wings',
    'oven baked wings',
    'fried wings',
    'crispy wings',
    'juicy wings',
    'bbq wings',
    'hot wings',
    'creamy baked wings',
    'mayo wings',
    'honey wings'
  ];
  List<String> nuggetsKeywords = [
    'nuggets',
    'chicken nuggets',
    'hot shots',
    'crunchy hot shots',
    'crispy nuggets'
  ];
  List<String> sandwichKeywords = [
    'sandwich',
    'club sandwich',
    'grilled chicken sandwich',
    'beef grilled sandwich',
    'grilled tikka sandwich',
    'meet n eat special sandwich',
    'mexican sandwich',
    'tikka sandwich',
    'bbq sandwich',
    'malai boti sandwich',
    'arabic sandwich'
  ];
  List<String> grilledKeywords = [
    'grilled',
    'mushroom steak',
    'jalapeno steak',
    'tarragon steak',
    'black pepper steak',
    'mexican steak',
    'classic grilled chicken burger',
    'smoked grilled chicken burger',
    'meet n eat special grilled burger'
  ];
  List<String> khanaKhazanaTandoorKeywords = [
    'khana khazana tandoor',
    'tandoor contact',
    'tandoor location',
    'tandoor details'
  ];
  List<String> dessertKeywords = [
    'desserts',
    'fruit trifle',
    'gajar halwa',
    'brownie',
    'hot gulab jamun',
    'labe sheere',
    'sizzling brownie'
  ];
  List<String> beverageKeywords = [
    'drinks',
    'soft drink',
    'water',
    'green tea',
    'chai',
    'doodh pati',
    'kashmiri chai',
    'fresh lime',
    'sting',
    'mineral water'
  ];
  List<String> bbqKeywords = [
    'bbq',
    'malai boti',
    'tikka boti',
    'reshmi kabab',
    'gola kabab',
    'green boti',
    'afghani boti',
    'qalmi tikka',
    'bbq leg piece'
  ];
  List<String> chineseKeywords = [
    'chowmein',
    'chinese',
    'kk special rice',
    'fried rice',
    'garlic rice',
    'plain rice',
    'vegetable rice',
    'american chopsuey',
    'kk special chopsuey'
  ];
  List<String> appetizerKeywords = [
    'appetizers',
    'chicken pakora',
    'crispy wings',
    'dhaka chicken',
    'sousey chicken',
    'fish crackers',
    'spin roll',
    'calzone chunks',
    'cheese sticks',
    'kabab bites',
    'arabic roll'
  ];
  List<String> sidesKeywords = [
    'sides',
    'garlic bread',
    'cheesy sticks',
    'mozzarella sticks',
    'chicken wings',
    'wings'
  ];
  List<String> dessertsKeywords = [
    'dessert',
    'gulab jamun',
    'rasmalai',
    'kheer',
    'sweets'
  ];
  List<String> drinksKeywords = [
    'drinks',
    'drink',
    'soft drinks',
    'soda',
    'juice',
    'fresh juice',
    'iced coffee',
    'cold coffee',
    'milkshake'
  ];
  List<String> generalFoodKeywords = [
    'food',
    'cuisine',
    'dish',
    'meal',
    'recipe',
    'ingredient',
    'flavor',
    'taste',
    'healthy food',
    'junk food',
    'fast food',
    'organic food',
    'vegetarian food',
    'vegan food',
    'halal food',
    'kosher food',
    'gluten-free food',
    'dairy-free food',
    'sugar-free food',
    'spicy food',
    'sweet food',
    'savory food',
    'salty food',
    'sour food',
    'bitter food',
    'appetizer',
    'main course',
    'dessert',
    'snack',
    'beverage',
    'drink',
    'coffee',
    'tea',
    'juice',
    'soda',
    'beer',
    'wine',
    'cocktail',
    'smoothie',
    'milkshake',
    'water',
    'pizza',
    'burger',
    'sandwich',
    'soup',
    'salad',
    'curry',
    'sushi',
    'taco',
    'burrito',
    'noodle'
  ];
  List<String> foodItemKeywords = [
    'pizza',
    'burger',
    'fries',
    'wings',
    'nuggets',
    'pasta',
    'sandwich',
    'wrap',
    'roll',
    'steak',
    'soup',
    'salad',
    'rice',
    'noodles',
    'dessert',
    'oven baked wings',
    'fried wings',
    'chicken nuggets',
    'loaded fries',
    'pizza fries',
    'garlic mayo fries',
    'french fries',
    'hot shots',
    'drum stick',
    'crispy zinger',
    'mighty zinger',
    'patty burger',
    'zinger stacker',
    'meet n eat special beef burger',
    'classic beef burger',
    'smoked beef burger',
    'crispy wrap',
    'kababish wrap',
    'cheetos wrap',
    'meet n eat special wrap',
    'mushroom steak',
    'jalapeno steak',
    'taragon steak',
    'black pepper steak',
    'mexican steak',
    'classic grilled chicken burger',
    'smoked grilled chicken burger',
    'meet n eat special grilled burger',
    'grilled chicken wrap',
    'grilled beef wrap',
    'grilled chicken sandwich',
    'beef grilled sandwich',
    'peri peri pizza',
    'chicken supreme pizza',
    'chicken tikka pizza',
    'chicken fajita pizza',
    'cheese lover pizza',
    'bonfire pizza',
    'veggie lover pizza',
    'malai boti pizza',
    'lazanai pizza',
    'tikka pizza',
    'fajita pizza',
    'creamy sandwich',
    'spin roll',
    'calzone chunks',
    'mexican sandwich',
    'pizza stacker',
    'juicy wings',
    'bbq wings',
    'hot wings',
    'crunchy pasta',
    'cheese pasta',
    'bbq fries',
    'hot shots',
    'nuggets',
    'mexican wrap',
    'chicken tikka pizza',
    'chicken fajita pizza',
    'hot & spicy pizza',
    'chicken supreme pizza',
    'american hot pizza',
    'tandoori chicken pizza',
    'cheesy pizza',
    'deep pan pizza',
    'stuff crust pizza',
    'square pizza',
    'extreme peri peri pizza',
    'pizza paratha',
    'pizza stick (cheese stick)'
  ];
  List<String> foodDealKeywords = [
    'food deal',
    'food offer',
    'food discount',
    'food promotion',
    'food special',
    'food combo',
    'meal deal',
    'dine-in deal',
    'takeaway deal',
    'delivery deal',
    'buy one get one',
    'BOGOF',
    'half price',
    'discount code',
    'voucher',
    'coupon',
    'promotion code',
    'special offer',
    'limited time offer',
    'seasonal offer',
    'festive offer',
    'pizza deal',
    'burger deal',
    'pasta deal',
    'chicken deal',
    'steak deal',
    'seafood deal',
    'dessert deal',
    'drink deal',
    'breakfast deal',
    'lunch deal',
    'dinner deal',
    'kids meal deal',
    'family meal deal',
    'party platter deal',
    'food deel',
    'food offfer',
    'food discont',
    'food promosion',
    'food spechial',
    'meel deal',
    'dine-in deall',
    'takeawy deal',
    'delivry deal',
    'buy one get onee',
    'half pricee',
    'discountt code',
    'vouchar',
    'couppon',
    'promosion code',
    'spechial offer',
    'limited time offfer',
    'seasonal offfer',
    'festive offfer',
    'deals',
    'deal',
    'del',
    'deal',
    'dael'
  ];

  // Restaurant Keywords
  List<String> meetNEatKeywords = [
    'meet n eat',
    'meet and eat',
    'meet n eat contact',
    'meet n eat location',
    'meet n eat menu',
    'meet n eat delivery'
  ];

  List<String> crustBrosKeywords = [
    'crust bros',
    'crust brothers',
    'crust bros contact',
    'crust bros location',
    'crust bros menu',
    'crust bros delivery'
  ];

  List<String> khanaKhazanaKeywords = [
    'khana khazana',
    'khana khazana contact',
    'khana khazana location',
    'khana khazana menu',
    'khana khazana delivery'
  ];

  List<String> mfcKeywords = [
    'miran jee',
    'miran jee food club',
    'mfc',
    'miran jee contact',
    'miran jee location',
    'miran jee delivery'
  ];

  List<String> pizzaSliceKeywords = [
    'pizza slice',
    'pizza slice contact',
    'pizza slice location',
    'pizza slice menu',
    'pizza slice delivery'
  ];

  List<String> tandoorKeywords = [
    'naan',
    'roti',
    'plain naan',
    'garlic naan',
    'cheese naan',
    'chicken cheese naan',
    'khamiri roti',
    'roghni naan',
    'kalwanji naan',
    'punjabi paratha'
  ];

  List<String> restaurantKeywords = [
    'restaurant',
    'restaurants',
    'hotel',
    'hotels',
    'food places',
    'eatery',
    'dining',
    'cafe',
    'cafes',
    'food shops'
  ];

  // Adding keywords related to food items

  @override
  void initState() {
    super.initState();
    _loadDataset();
    _testOpenAIConnection();
    // Show welcome message
    _messages.add(ChatMessage(text: welcomeMessage, isUser: false));
  }

  /// Test OpenAI connection on app start
  Future<void> _testOpenAIConnection() async {
    try {
      final isConnected = await OpenAIService.testConnection();
      if (isConnected) {
        debugPrint('✅ OpenAI ChatGPT service connected successfully');
      } else {
        debugPrint('❌ OpenAI ChatGPT service connection failed');
      }
    } catch (e) {
      debugPrint('❌ Error testing OpenAI connection: $e');
    }
  }

  Future<void> _loadDataset() async {
    try {
      // Here you can implement the logic to train the AI with the dataset
    } catch (e) {
      debugPrint('Error loading dataset: $e');
    }
  }

  /// Get restaurant data for AI context
  Future<String> _getRestaurantContext() async {
    try {
      // Fetch restaurant data from Supabase
      final restaurantResponse =
          await _supabase.from('restaurants').select('*').limit(10);
      final dealsResponse = await _supabase.from('deals').select('*').limit(10);
      final menuResponse =
          await _supabase.from('food_items').select('*').limit(20);

      return OpenAIService.buildRestaurantContext(
        restaurants: List<Map<String, dynamic>>.from(restaurantResponse ?? []),
        deals: List<Map<String, dynamic>>.from(dealsResponse ?? []),
        menuItems: List<Map<String, dynamic>>.from(menuResponse ?? []),
      );
    } catch (e) {
      debugPrint('❌ Error fetching restaurant context: $e');
      return _getStaticRestaurantContext();
    }
  }

  /// Static restaurant context as fallback
  String _getStaticRestaurantContext() {
    return '''
RESTAURANTS IN JAHANIAN:
1. Meet N Eat - Fast food, pizza, burgers (0328-5500112) - 4.7★
2. Crust Bros - Pizza, wings, burgers (0325-800-3399) - 4.6★
3. Khana Khazana - BBQ, traditional food (0345-7277634) - 4.8★
4. MFC - Pizza, burgers, deals (0309-7000178) - 4.5★
5. Pizza Slice - Pizza, burgers, wings (0308-4824792) - 4.4★

POPULAR ITEMS:
- Pizza: Rs. 500-1600 (Small to Large)
- Burgers: Rs. 280-600 (Patty to Mighty Zinger)
- Deals: Rs. 600-1400 (Combo deals available)
- Delivery: Free on orders Rs. 800+
    ''';
  }

  /// AI-powered response using OpenAI ChatGPT
  Future<String> respondToQueryAsync(String query) async {
    try {
      // Get restaurant context
      final restaurantContext = await _getRestaurantContext();

      // Get ChatGPT response with context
      final response = await OpenAIService.getChatGPTResponse(
        query,
        restaurantContext: restaurantContext,
      );

      return response;
    } catch (e) {
      debugPrint('❌ Error getting AI response: $e');
      return _getFallbackResponse(query);
    }
  }

  /// Fallback response when AI fails
  String _getFallbackResponse(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('pizza')) {
      return '🍕 We have amazing pizzas! Meet N Eat offers Peri Peri (Rs. 500-1200), Crust Bros has Chicken Tikka (Rs. 599-1399), and more. What size would you like?';
    } else if (lowerQuery.contains('burger')) {
      return '🍔 Great burger options! Try our Crispy Zinger (Rs. 350), Mighty Zinger (Rs. 600), or Patty Burger (Rs. 280) from Meet N Eat.';
    } else if (lowerQuery.contains('deal')) {
      return '🎉 Amazing deals available! Family combos starting from Rs. 600. Want details about specific restaurant deals?';
    } else if (lowerQuery.contains('restaurant')) {
      return '🏪 We have 6 premium restaurants: Meet N Eat, Crust Bros, Khana Khazana, MFC, Pizza Slice, and Khana Khazana Tandoor. Which one interests you?';
    } else {
      return '''🍽 I can help you find:
- Pizza 🍕 • Burgers 🍔 • Deals 🎉
- Wings 🍗 • Pasta 🍝 • Wraps 🌯
- Restaurant info • Prices • Delivery

What are you craving today?''';
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isLoading = true;
    });

    // Scroll to bottom to show user message
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    try {
      // Get AI response asynchronously
      final response = await respondToQueryAsync(text);

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
        ));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error handling message: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: _getFallbackResponse(text),
          isUser: false,
        ));
        _isLoading = false;
      });
    }

    // Scroll to bottom to show AI response
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppTheme.backgroundColor(context);
    final headerGradient = AppTheme.getHeaderGradient(context);
    final textColor = AppTheme.textColor(context);
    final cardColor = AppTheme.cardColor(context);
    final accentColor = AppTheme.getAccentColor(context);
    final searchBarColor = AppTheme.getSearchBarColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Modern Header with Orange Gradient
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: headerGradient,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Torbaaz AI Assistant',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Your food guide chatbot',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ask me about restaurants, menus, deals, and more!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20.0),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _messages[index];
                }

                // Loading indicator
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10.0),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: isDarkMode
                              ? accentColor.withOpacity(0.2)
                              : Colors.orange.shade100,
                          child: Icon(
                            Icons.smart_toy,
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppTheme.darkCardColor
                                : Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'AI is thinking...',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Modern Input Section
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkSurface : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        offset: const Offset(0, -4),
                        blurRadius: 20,
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: searchBarColor,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isDarkMode
                              ? AppTheme.darkDivider
                              : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Ask about food, restaurants, deals...',
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[500]
                                : const Color(0xFF8B8B8B),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor,
                        ),
                        onSubmitted: _handleSubmitted,
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: headerGradient,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () {
                          if (_messageController.text.trim().isNotEmpty) {
                            _handleSubmitted(_messageController.text);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppTheme.getAccentColor(context);
    final headerGradient = AppTheme.getHeaderGradient(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: headerGradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: isUser
                    ? accentColor
                    : (isDarkMode ? AppTheme.darkCardColor : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: isDarkMode
                    ? null
                    : [
                        BoxShadow(
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                border: !isUser
                    ? Border.all(
                        color: isDarkMode
                            ? AppTheme.darkDivider
                            : Colors.grey.withOpacity(0.1),
                        width: 1,
                      )
                    : null,
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isDarkMode ? Colors.white : const Color(0xFF2C3E50)),
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 12.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode
                    ? AppTheme.darkCardColor
                    : const Color(0xFF34495E),
                boxShadow: isDarkMode
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
