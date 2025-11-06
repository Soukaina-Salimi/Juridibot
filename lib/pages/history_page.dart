import 'package:flutter/material.dart';
import 'package:juridibot/theme/app_theme.dart';
import 'package:juridibot/pages/chat_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<Map<String, dynamic>> _chats = [
    {
      'id': '1',
      'title': 'Droits en cas de licenciement',
      'preview':
          'Quels sont mes droits si mon employeur me licencie sans préavis ?',
      'time': 'Aujourd\'hui, 14:30',
      'messageCount': 12,
      'category': 'Droit du travail',
      'isPinned': true,
    },
    {
      'id': '2',
      'title': 'Renouvellement CIN',
      'preview':
          'Documents nécessaires pour le renouvellement de la carte d\'identité...',
      'time': 'Hier, 09:15',
      'messageCount': 8,
      'category': 'Administratif',
      'isPinned': false,
    },
    {
      'id': '3',
      'title': 'Contrat CDD durée maximale',
      'preview':
          'Quelle est la durée maximale autorisée pour un contrat à durée déterminée ?',
      'time': '12 Nov 2024',
      'messageCount': 15,
      'category': 'Contrats',
      'isPinned': true,
    },
    {
      'id': '4',
      'title': 'Déclaration revenus',
      'preview': 'Procédure et délais pour la déclaration des revenus...',
      'time': '10 Nov 2024',
      'messageCount': 6,
      'category': 'Fiscal',
      'isPinned': false,
    },
    {
      'id': '5',
      'title': 'Heures supplémentaires',
      'preview':
          'Calcul et paiement des heures supplémentaires selon le code du travail...',
      'time': '8 Nov 2024',
      'messageCount': 10,
      'category': 'Droit du travail',
      'isPinned': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
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
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historique des Conversations',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_chats.length} conversations',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildQuickStats()),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final chat = _chats[index];
              return _buildChatItem(chat, context);
            }, childCount: _chats.length),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clearAllHistory,
        backgroundColor: AppTheme.cardWhite,
        foregroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.delete_outline_rounded),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Conversations',
              '${_chats.length}',
              Icons.chat_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Épinglées', '2', Icons.push_pin_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard('Catégories', '4', Icons.category_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: _getCategoryGradient(
                        chat['category'] as String,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _getCategoryIcon(chat['category'] as String),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat['title'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chat['isPinned'] as bool)
                              const Icon(
                                Icons.push_pin_rounded,
                                size: 16,
                                color: AppTheme.warningColor,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chat['preview'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textLight,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                  chat['category'] as String,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                chat['category'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getCategoryColor(
                                    chat['category'] as String,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              chat['time'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${chat['messageCount']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getCategoryGradient(String category) {
    switch (category) {
      case 'Droit du travail':
        return const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
        );
      case 'Administratif':
        return const LinearGradient(
          colors: [AppTheme.successColor, Color(0xFF22D3EE)],
        );
      case 'Contrats':
        return const LinearGradient(
          colors: [AppTheme.warningColor, Color(0xFFF97316)],
        );
      case 'Fiscal':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
        );
      default:
        return const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
        );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Droit du travail':
        return AppTheme.primaryBlue;
      case 'Administratif':
        return AppTheme.successColor;
      case 'Contrats':
        return AppTheme.warningColor;
      case 'Fiscal':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.primaryBlue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Droit du travail':
        return Icons.work_history_rounded;
      case 'Administratif':
        return Icons.assignment_rounded;
      case 'Contrats':
        return Icons.description_rounded;
      case 'Fiscal':
        return Icons.attach_money_rounded;
      default:
        return Icons.chat_rounded;
    }
  }

  void _clearAllHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Effacer l\'historique',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer tout l\'historique des conversations ? Cette action est irréversible.',
          style: TextStyle(color: AppTheme.textLight, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: AppTheme.textLight)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implémenter la suppression de l'historique
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
