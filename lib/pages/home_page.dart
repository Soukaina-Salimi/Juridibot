import 'package:flutter/material.dart';
import 'package:juridibot/theme/app_theme.dart';
import 'package:juridibot/pages/chat_page.dart';
import 'package:juridibot/pages/history_page.dart';
import 'package:juridibot/pages/settings_page.dart';
import 'package:juridibot/services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Map<String, dynamic>> _quickQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadQuickQuestions();
  }

  void _loadQuickQuestions() async {
    final questions = await ApiService.getQuickQuestions();
    setState(() {
      _quickQuestions.addAll(questions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: _getCurrentPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return const _DashboardPage();
      case 1:
        return const HistoryPage();
      case 2:
        return const SettingsPage();
      default:
        return const _DashboardPage();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: NavigationBar(
          backgroundColor: AppTheme.cardWhite,
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Historique',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Paramètres',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  void _startNewChat(BuildContext context, String initialMessage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(initialMessage: initialMessage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.gavel_rounded,
                            size: 32,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'JuridiBot AI',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Votre assistant juridique intelligent\npour le Maroc',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 24),
            _buildQuickActions(context),
            _buildCategories(context),
            _buildRecentQuestions(context),
          ]),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions Rapides',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildActionCard(
                'Droit du Travail',
                Icons.work_history_rounded,
                AppTheme.primaryBlue,
                () => _startNewChat(
                  context,
                  'Quels sont mes droits en cas de licenciement ?',
                ),
              ),
              _buildActionCard(
                'Documents Admin',
                Icons.description_rounded,
                AppTheme.accentBlue,
                () => _startNewChat(
                  context,
                  'Comment obtenir un extrait d\'acte de naissance ?',
                ),
              ),
              _buildActionCard(
                'Contrats',
                Icons.article_rounded, // Correction: remplacé contract_rounded
                AppTheme.successColor,
                () => _startNewChat(
                  context,
                  'Quelles sont les clauses obligatoires dans un contrat ?',
                ),
              ),
              _buildActionCard(
                'Impôts & Taxes',
                Icons.attach_money_rounded,
                AppTheme.warningColor,
                () => _startNewChat(context, 'Quand déclarer mes revenus ?'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final categories = [
      {
        'title': 'Licenciement',
        'icon': Icons.exit_to_app_rounded,
        'color': AppTheme.primaryBlue,
      },
      {
        'title': 'CIN & Passeport',
        'icon': Icons.credit_card_rounded,
        'color': AppTheme.accentBlue,
      },
      {
        'title': 'Contrat travail',
        'icon': Icons.description_rounded,
        'color': AppTheme.successColor,
      },
      {
        'title': 'Déclaration fiscale',
        'icon': Icons.receipt_long_rounded,
        'color': AppTheme.warningColor,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catégories Populaires',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () => _startNewChat(
                    context,
                    'Questions sur ${category['title']}',
                  ),
                  child: Container(
                    width: 140,
                    margin: EdgeInsets.only(
                      right: index == categories.length - 1 ? 0 : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          category['color'] as Color,
                          (category['color'] as Color).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                          const Spacer(),
                          Text(
                            category['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentQuestions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions Fréquentes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (index) => _buildQuestionItem(context, index)),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(BuildContext context, int index) {
    final questions = [
      'Quels sont les documents pour un passeport ?',
      'Durée du préavis de licenciement ?',
      'SMIG 2024 au Maroc ?',
      'Procédure divorce par consentement mutuel ?',
    ];

    return GestureDetector(
      onTap: () => _startNewChat(context, questions[index]),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.question_mark_rounded,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
          ),
          title: Text(
            questions[index],
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
              fontSize: 14,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppTheme.textLight,
            size: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
