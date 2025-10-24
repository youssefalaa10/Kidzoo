import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/logic/drawlab_cubit.dart';
import '../../data/models/drawlab_models.dart';

class ColorPickerWidget extends StatefulWidget {
  const ColorPickerWidget({super.key});

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Color _selectedColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<DrawLabCubit, DrawingState>(
      builder: (context, state) {
        _selectedColor = state.currentColor;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.colorPicker,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Current color preview
              _buildCurrentColorPreview(state.currentColor),
              const SizedBox(height: 16),

              // Color picker tabs
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.defaultColors),
                  Tab(text: l10n.pastelColors),
                  Tab(text: l10n.vibrantColors),
                ],
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
              ),
              const SizedBox(height: 16),

              // Color palette
              SizedBox(
                height: 200,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildColorPalette(ColorPalette.defaultColors),
                    _buildColorPalette(ColorPalette.pastelColors),
                    _buildColorPalette(ColorPalette.vibrantColors),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Custom color picker
              _buildCustomColorPicker(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentColorPreview(Color color) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentColor,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(List<Color> colors) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = _selectedColor == color;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = color;
            });
            context.read<DrawLabCubit>().setColor(color);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildCustomColorPicker() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customColor,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showColorPickerDialog,
                icon: const Icon(Icons.color_lens, size: 16),
                label: Text(l10n.pickColor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showColorPickerDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pickAColor),
        content: SizedBox(
          width: 300,
          height: 400,
          child: _buildAdvancedColorPicker(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DrawLabCubit>().setColor(_selectedColor);
              Navigator.pop(context);
            },
            child: Text(l10n.select),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedColorPicker() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            // HSV Color Picker
            Expanded(
              child: _buildHSVColorPicker(setState),
            ),
            const SizedBox(height: 16),

            // RGB Inputs
            _buildRGBInputs(setState),
            const SizedBox(height: 16),

            // Hex Input
            _buildHexInput(setState),
          ],
        );
      },
    );
  }

  Widget _buildHSVColorPicker(StateSetter setState) {
    final l10n = AppLocalizations.of(context);
    final hsv = HSVColor.fromColor(_selectedColor);

    return Column(
      children: [
        // Hue slider
        Text('${l10n.hue}: ${hsv.hue.toInt()}°'),
        Slider(
          value: hsv.hue,
          max: 360,
          divisions: 360,
          onChanged: (value) {
            setState(() {
              _selectedColor = HSVColor.fromAHSV(
                hsv.alpha,
                value,
                hsv.saturation,
                hsv.value,
              ).toColor();
            });
          },
        ),

        // Saturation slider
        Text('${l10n.saturation}: ${(hsv.saturation * 100).toInt()}%'),
        Slider(
          value: hsv.saturation,
          divisions: 100,
          onChanged: (value) {
            setState(() {
              _selectedColor = HSVColor.fromAHSV(
                hsv.alpha,
                hsv.hue,
                value,
                hsv.value,
              ).toColor();
            });
          },
        ),

        // Value slider
        Text('${l10n.value}: ${(hsv.value * 100).toInt()}%'),
        Slider(
          value: hsv.value,
          divisions: 100,
          onChanged: (value) {
            setState(() {
              _selectedColor = HSVColor.fromAHSV(
                hsv.alpha,
                hsv.hue,
                hsv.saturation,
                value,
              ).toColor();
            });
          },
        ),

        // Alpha slider
        Text('${l10n.alpha}: ${(hsv.alpha * 100).toInt()}%'),
        Slider(
          value: hsv.alpha,
          divisions: 100,
          onChanged: (value) {
            setState(() {
              _selectedColor = HSVColor.fromAHSV(
                value,
                hsv.hue,
                hsv.saturation,
                hsv.value,
              ).toColor();
            });
          },
        ),
      ],
    );
  }

  Widget _buildRGBInputs(StateSetter setState) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'R',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(
              text: _selectedColor.red.toString(),
            ),
            onChanged: (value) {
              final red = int.tryParse(value) ?? 0;
              setState(() {
                _selectedColor = Color.fromARGB(
                  _selectedColor.alpha,
                  red.clamp(0, 255),
                  _selectedColor.green,
                  _selectedColor.blue,
                );
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'G',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(
              text: _selectedColor.green.toString(),
            ),
            onChanged: (value) {
              final green = int.tryParse(value) ?? 0;
              setState(() {
                _selectedColor = Color.fromARGB(
                  _selectedColor.alpha,
                  _selectedColor.red,
                  green.clamp(0, 255),
                  _selectedColor.blue,
                );
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'B',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            keyboardType: TextInputType.number,
            controller: TextEditingController(
              text: _selectedColor.blue.toString(),
            ),
            onChanged: (value) {
              final blue = int.tryParse(value) ?? 0;
              setState(() {
                _selectedColor = Color.fromARGB(
                  _selectedColor.alpha,
                  _selectedColor.red,
                  _selectedColor.green,
                  blue.clamp(0, 255),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHexInput(StateSetter setState) {
    final l10n = AppLocalizations.of(context);

    return TextField(
      decoration: InputDecoration(
        labelText: l10n.hex,
        border: const OutlineInputBorder(),
        prefixText: '#',
      ),
      controller: TextEditingController(
        text: _selectedColor.value.toRadixString(16).substring(2).toUpperCase(),
      ),
      onChanged: (value) {
        if (value.length == 6) {
          final colorValue = int.tryParse('FF$value', radix: 16);
          if (colorValue != null) {
            setState(() {
              _selectedColor = Color(colorValue);
            });
          }
        }
      },
    );
  }
}
