import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userName;
  final String? userAvatar;
  final String placeholderAsset;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onCancelSelection;
  final VoidCallback onDeleteSelected;
  final VoidCallback onBack;
  final List<Widget>? actions;

  const ChatAppBar({
    super.key,
    this.userName,
    this.userAvatar,
    this.placeholderAsset = 'assets/images/doctor_booking.png',
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onCancelSelection,
    required this.onDeleteSelected,
    required this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFF),
      elevation: 0,
      leading: IconButton(
        icon: Icon(isSelectionMode ? Icons.close : Icons.arrow_back,
            color: Colors.black, size: 26),
        onPressed: isSelectionMode ? onCancelSelection : onBack,
      ),
      title: isSelectionMode
          ? Text('$selectedCount selected',
              style: const TextStyle(color: Colors.black, fontSize: 18))
          : Row(children: [
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: userAvatar != null && userAvatar!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: userAvatar!, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Image.asset(placeholderAsset, fit: BoxFit.cover))
                      : Image.asset(placeholderAsset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(userName ?? 'User',
                    style: const TextStyle(color: Colors.black, fontSize: 18,
                        fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ]),
      actions: isSelectionMode
          ? [
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDeleteSelected),
              const SizedBox(width: 10),
            ]
          : actions ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
