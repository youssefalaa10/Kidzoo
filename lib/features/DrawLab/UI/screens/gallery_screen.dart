import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/logic/drawlab_cubit.dart';
import '../../data/models/drawlab_models.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<SavedDrawing> _drawings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrawings();
  }

  Future<void> _loadDrawings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cubit = context.read<DrawLabCubit>();
      final drawings = await cubit.loadSavedDrawings();
      setState(() {
        _drawings = drawings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load drawings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDrawings),
        backgroundColor: Colors.blue.shade50,
        actions: [
          IconButton(
            onPressed: _loadDrawings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drawings.isEmpty
              ? _buildEmptyState()
              : _buildGalleryGrid(),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noDrawingsYet,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.startCreating,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.startDrawing),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _drawings.length,
      itemBuilder: (context, index) {
        final drawing = _drawings[index];
        return _buildDrawingCard(drawing);
      },
    );
  }

  Widget _buildDrawingCard(SavedDrawing drawing) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openDrawing(drawing),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _buildThumbnail(drawing),
                ),
              ),
            ),

            // Drawing info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drawing.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(drawing.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rename button
                      IconButton(
                        onPressed: () => _showRenameDialog(drawing),
                        icon: const Icon(Icons.edit, size: 16),
                        tooltip: l10n.renameTooltip,
                      ),

                      // Share button
                      IconButton(
                        onPressed: () => _shareDrawing(drawing),
                        icon: const Icon(Icons.share, size: 16),
                        tooltip: l10n.shareTooltip,
                      ),

                      // Delete button
                      IconButton(
                        onPressed: () => _showDeleteConfirmation(drawing),
                        icon: const Icon(Icons.delete, size: 16),
                        tooltip: l10n.deleteTooltip,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(SavedDrawing drawing) {
    if (File(drawing.thumbnailPath).existsSync()) {
      return Image.file(
        File(drawing.thumbnailPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderThumbnail(),
      );
    } else {
      return _buildPlaceholderThumbnail();
    }
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image,
          size: 40,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _openDrawing(SavedDrawing drawing) {
    // Navigate back to drawing screen with the selected drawing
    Navigator.pop(context, drawing);
  }

  void _showRenameDialog(SavedDrawing drawing) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: drawing.name);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameDrawing),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.enterNewName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != drawing.name) {
                final cubit = context.read<DrawLabCubit>();
                final success = await cubit.renameDrawing(drawing, newName);

                if (success) {
                  _loadDrawings();
                  Navigator.pop(context);
                  _showSuccessSnackBar(l10n.drawingRenamed);
                } else {
                  _showErrorSnackBar(l10n.failedToRename);
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.rename),
          ),
        ],
      ),
    );
  }

  void _shareDrawing(SavedDrawing drawing) async {
    try {
      final cubit = context.read<DrawLabCubit>();
      await cubit.shareDrawing(drawing.filePath);
    } catch (e) {
      _showErrorSnackBar('Failed to share drawing: $e');
    }
  }

  void _showDeleteConfirmation(SavedDrawing drawing) {
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDrawing),
        content: Text('${l10n.deleteConfirm} "${drawing.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final cubit = context.read<DrawLabCubit>();
              final success = await cubit.deleteDrawing(drawing);

              if (success) {
                _loadDrawings();
                Navigator.pop(context);
                _showSuccessSnackBar(l10n.drawingDeleted);
              } else {
                _showErrorSnackBar(l10n.failedToDelete);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
