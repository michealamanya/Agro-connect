import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/produce_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/produce_service.dart';
import '../../utils/app_theme.dart';
import '../chat/chat_screen.dart';

class ProduceDetailScreen extends StatelessWidget {
  final ProduceModel produce;

  const ProduceDetailScreen({super.key, required this.produce});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.userModel;
    final isOwner = user?.uid == produce.farmerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: produce.imageUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: produce.imageUrls.length,
                      itemBuilder: (_, index) => Image.network(
                        produce.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 50),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.eco, size: 80, color: Colors.grey),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: produce.isReady
                              ? AppTheme.readyColor
                              : AppTheme.unreadyColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          produce.isReady ? 'Ready for Sale' : 'Not Yet Ready',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(label: Text(produce.category)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    produce.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    'KSh ${produce.price.toStringAsFixed(2)} / ${produce.unit}',
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Quantity
                  Text(
                    'Available: ${produce.quantity} ${produce.unit}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    produce.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Expected ready date
                  if (!produce.isReady && produce.expectedReadyDate != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.unreadyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule,
                              color: AppTheme.unreadyColor),
                          const SizedBox(width: 8),
                          Text(
                            'Expected ready: ${DateFormat('MMM dd, yyyy').format(produce.expectedReadyDate!)}',
                            style: const TextStyle(
                              color: AppTheme.unreadyColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 16),

                  // Farmer info
                  const Text(
                    'Farmer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen,
                      child: Text(
                        produce.farmerName.isNotEmpty
                            ? produce.farmerName[0].toUpperCase()
                            : 'F',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(produce.farmerName),
                    subtitle: produce.location != null
                        ? Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(produce.location!),
                            ],
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Posted date
                  Text(
                    'Posted: ${DateFormat('MMM dd, yyyy').format(produce.createdAt)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 80), // Space for button
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom action buttons
      bottomNavigationBar: !isOwner && user != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final chatService = context.read<ChatService>();
                          final chatRoomId =
                              await chatService.getOrCreateChatRoom(
                            currentUserId: user.uid,
                            currentUserName: user.name,
                            otherUserId: produce.farmerId,
                            otherUserName: produce.farmerName,
                            produceId: produce.id,
                            produceName: produce.name,
                          );

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chatRoomId: chatRoomId,
                                  otherUserName: produce.farmerName,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Contact Farmer'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : isOwner
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _deleteProduce(context),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!produce.isReady)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _markAsReady(context),
                              icon: const Icon(Icons.check),
                              label: const Text('Mark Ready'),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : null,
    );
  }

  Future<void> _deleteProduce(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Produce'),
        content: const Text('Are you sure you want to delete this produce?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final error = await context
          .read<ProduceService>()
          .deleteProduce(produce.id);
      if (context.mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _markAsReady(BuildContext context) async {
    final error = await context
        .read<ProduceService>()
        .updateProduce(produce.id, {'status': 'ready'});
    if (context.mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produce marked as ready!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      Navigator.pop(context);
    }
  }
}
