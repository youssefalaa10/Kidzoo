import 'package:flutter/material.dart';

import '../../data/model/animal_name_model.dart';

class AnimalNameDropTarget extends StatefulWidget {
  const AnimalNameDropTarget({
    required this.target,
    required this.onCorrectDrop,
    super.key,
  });

  final AnimalNameModel target;
  final VoidCallback onCorrectDrop;

  @override
  State<AnimalNameDropTarget> createState() => _AnimalNameDropTargetState();
}

class _AnimalNameDropTargetState extends State<AnimalNameDropTarget> {
  bool _isHovering = false;
  bool _isWrong = false;

  static const double _tileWidth = 130.0;
  static const double _tileHeight = 52.0;

  void _triggerWrongFeedback() {
    setState(() => _isWrong = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isWrong = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<AnimalNameModel>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _isHovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        if (details.data.name == widget.target.name) {
          widget.onCorrectDrop();
        } else {
          _triggerWrongFeedback();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: _tileWidth,
          height: _tileHeight,
          decoration: BoxDecoration(
            color: _buildBackgroundColor(),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _buildBorderColor(),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _buildShadowColor(),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.target.name.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: _buildTextColor(),
            ),
          ),
        );
      },
    );
  }

  Color _buildBackgroundColor() {
    if (_isWrong) return Colors.red.shade50;
    if (_isHovering) return Colors.teal.shade50;
    return Colors.white;
  }

  Color _buildBorderColor() {
    if (_isWrong) return Colors.red.shade300;
    if (_isHovering) return Colors.teal.shade400;
    return Colors.grey.shade300;
  }

  Color _buildShadowColor() {
    if (_isWrong) return Colors.red.withValues(alpha: 0.2);
    if (_isHovering) return Colors.teal.withValues(alpha: 0.2);
    return Colors.black.withValues(alpha: 0.08);
  }

  Color _buildTextColor() {
    if (_isWrong) return Colors.red.shade700;
    if (_isHovering) return Colors.teal.shade700;
    return Colors.blueGrey.shade700;
  }
}
