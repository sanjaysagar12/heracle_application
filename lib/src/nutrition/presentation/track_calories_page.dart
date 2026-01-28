import 'dart:io'; // Added
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../nutrition/api/nutrition_service.dart';
import '../../nutrition/data/food_item_model.dart';
import '../../nutrition/data/diet_log_item.dart';
import 'package:heracle/src/camera/presentation/camera_page.dart';
import 'post_nutrition_page.dart';
import 'diet_history_page.dart'; // Added

class TrackCaloriesPage extends StatefulWidget {
  const TrackCaloriesPage({super.key});

  @override
  State<TrackCaloriesPage> createState() => _TrackCaloriesPageState();
}

class _TrackCaloriesPageState extends State<TrackCaloriesPage> {
  final List<DietLogItem> _items = [];
  String _selectedMeal = 'Breakfast';
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
  bool _hasProcessedArgs = false; // Added to prevent duplicate processing

  @override
  void initState() {
    super.initState();
    // Start with one empty item
    _addItem();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasProcessedArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DietLogItem) {
      _hasProcessedArgs = true;
      setState(() {
        if (_items.length == 1 && _items.first.name.isEmpty) {
          _items[0] = args;
        } else {
          _items.add(args);
        }
      });

      // Check if it's a Cal AI item needing analysis
      if (args.isLoading && args.imagePath != null) {
        // Use a post frame callback to show dialog after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initiateAnalysis(args);
        });
      }
    }
  }

  // Calculate totals
  int get _totalCalories =>
      _items.fold(0, (sum, item) => sum + (item.calories * item.quantity));
  double get _totalProtein =>
      _items.fold(0, (sum, item) => sum + (item.protein * item.quantity));
  double get _totalFat =>
      _items.fold(0, (sum, item) => sum + (item.fat * item.quantity));
  double get _totalCarbs =>
      _items.fold(0, (sum, item) => sum + (item.carbs * item.quantity));

  void _addItem() {
    setState(() {
      _items.add(DietLogItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _initiateAnalysis(DietLogItem item) async {
    final description = await _showDescriptionDialog();
    if (description != null && description.isNotEmpty) {
      await _analyzeFood(item, description);
    } else {
      // If cancelled or empty, maybe remove the item or keep it as placeholder?
      // For now, let's stop loading so user can edit manually
      setState(() {
        item.isLoading = false;
      });
    }
  }

  Future<String?> _showDescriptionDialog() async {
    final descriptionController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // Force user to choose
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.greyDark,
        title: const Text(
          'Describe your food',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: descriptionController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. Idli with sambar',
            hintStyle: TextStyle(color: Colors.white60),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white60),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, descriptionController.text),
            child: const Text(
              'Analyze',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeFood(DietLogItem item, String description) async {
    if (item.imagePath == null) return;

    try {
      final File imageFile = File(item.imagePath!);
      final result = await NutritionApiService().analyzeFood(
        imageFile,
        description,
      );
      print("Debugging: Analyze Result: $result"); // Debug print

      if (mounted) {
        setState(() {
          item.isLoading = false;
          item.name = result['foodName'] ?? 'Unknown Food';
          print("Debugging: Setting name to ${item.name}");
          item.calories = (result['calories'] as num?)?.toInt() ?? 0;
          item.protein = (result['protein'] as num?)?.toDouble() ?? 0.0;
          item.fat = (result['fat'] as num?)?.toDouble() ?? 0.0;
          item.carbs = (result['carbs'] as num?)?.toDouble() ?? 0.0;
          item.fiber = (result['fiber'] as num?)?.toDouble() ?? 0.0;
          print("Debugging: Updated Item: ${item.calories} ${item.protein}");
          // Keep the image path on the item so we can display it
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          item.isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
      }
    }
  }

  void _continueToPost() async {
    // Filter out items with no name
    final validItems = _items
        .where((item) => item.name.isNotEmpty && !item.isLoading)
        .toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one food item')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostNutritionPage(
          items: validItems,
          totalCalories: _totalCalories,
          totalProtein: _totalProtein,
          totalFat: _totalFat,
          totalCarbs: _totalCarbs,
          mealType: _selectedMeal.toUpperCase(), // Need to pass this
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text(
          'Track Calories',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.black,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.pureWhite,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DietHistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: AppColors.primary),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CameraPage(returnItem: true),
                ),
              );

              if (result is DietLogItem && mounted) {
                setState(() {
                  // If we have a single empty placeholder, replace it. Otherwise add.
                  if (_items.length == 1 && _items.first.name.isEmpty) {
                    _items[0] = result;
                  } else {
                    _items.add(result);
                  }
                });
                // Launch analysis flow
                _initiateAnalysis(result);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildTopStats()),
                  SliverToBoxAdapter(child: _buildMealTypeSelector()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index.isOdd) return const SizedBox(height: 16);
                        return _buildFoodItemCard(index ~/ 2);
                      }, childCount: _items.length * 2 - 1),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 16),
                        _buildBottomActions(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMeal,
          isExpanded: true,
          dropdownColor: AppColors.black100,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedMeal = newValue;
              });
            }
          },
          items: _mealTypes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopStats() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: _buildStatBox('${_totalCalories}', 'Calories')),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatBox('${_totalProtein.toInt()}g', 'Protein'),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildStatBox('${_totalFat.toInt()}g', 'Fat')),
          const SizedBox(width: 8),
          Expanded(child: _buildStatBox('${_totalCarbs.toInt()}g', 'Carbs')),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.white60, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemCard(int index) {
    return FoodItemCard(
      key: ValueKey(_items[index]),
      item: _items[index],
      onUpdate: () => setState(() {}),
      onRemove: () => _removeItem(index),
      canRemove: _items.length > 1, // Hide delete button if only 1 item
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Add Food
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton.icon(
              onPressed: _addItem,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.black100,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Food',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Discard Log
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.black100,
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Discard Log',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Continue
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _continueToPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FoodItemCard extends StatefulWidget {
  final DietLogItem item;
  final VoidCallback onUpdate;
  final VoidCallback onRemove;
  final bool canRemove;

  const FoodItemCard({
    super.key,
    required this.item,
    required this.onUpdate,
    required this.onRemove,
    this.canRemove = true,
  });

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  final FocusNode _qtyFocusNode = FocusNode();  // Add FocusNode
  late TextEditingController _calsController;
  late TextEditingController _protController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _qtyController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    // Add listener to handle blur
    _qtyFocusNode.addListener(() {
      if (!_qtyFocusNode.hasFocus) {
        if (_qtyController.text.isEmpty) {
          _qtyController.text = '1';
          widget.item.quantity = 1;
          widget.onUpdate();
        }
      }
    });
    _calsController = TextEditingController(
      text: _formatInt(widget.item.calories),
    );
    _protController = TextEditingController(
      text: _formatDouble(widget.item.protein),
    );
    _fatController = TextEditingController(
      text: _formatDouble(widget.item.fat),
    );
    _carbsController = TextEditingController(
      text: _formatDouble(widget.item.carbs),
    );
  }

  String _formatInt(int val) => val == 0 ? '' : val.toString();
  String _formatDouble(double val) => val == 0.0 ? '' : val.toString();

  @override
  void didUpdateWidget(FoodItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always sync controllers since item is mutated in-place (same object reference)
    // Compare actual values to avoid overwriting user typing
    _updateControllerIfChanged(_nameController, widget.item.name);
    _updateControllerIfChanged(_qtyController, widget.item.quantity.toString());
    _updateControllerIfChanged(
      _calsController,
      _formatInt(widget.item.calories),
    );
    _updateControllerIfChanged(
      _protController,
      _formatDouble(widget.item.protein),
    );
    _updateControllerIfChanged(_fatController, _formatDouble(widget.item.fat));
    _updateControllerIfChanged(
      _carbsController,
      _formatDouble(widget.item.carbs),
    );
  }

  void _updateControllerIfChanged(
    TextEditingController controller,
    String newVal,
  ) {
    if (controller.text != newVal) {
      // Only update if it's not what user is currently typing?
      // It's hard to know. But generally if local state matches model, no op.
      // If model changed (e.g. Reset to 0), we update.
      // If user typed "5", model has 5. newVal is "5". No change.
      // If user typed "", model has 0. newVal is "". No change.
      controller.text = newVal;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _qtyFocusNode.dispose(); // Dispose FocusNode
    _calsController.dispose();
    _protController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  void _onNameChanged(String val) {
    widget.item.name = val;
    // Don't call onUpdate needed for name change? Maybe not affecting totals.
  }

  void _onQtyChanged(String val) {
    if (val.isEmpty) return; // Don't update state or force text if empty
    widget.item.quantity = int.tryParse(val) ?? 1;
    widget.onUpdate();
  }

  void _onMacroChanged(String val, String type) {
    final dVal = double.tryParse(val) ?? 0.0;
    final iVal = int.tryParse(val) ?? 0;

    setState(() {
      switch (type) {
        case 'cals':
          widget.item.calories = iVal;
          break;
        case 'prot':
          widget.item.protein = dVal;
          break;
        case 'fat':
          widget.item.fat = dVal;
          break;
        case 'carbs':
          widget.item.carbs = dVal;
          break;
      }
    });
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.black100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              if (item.imagePath != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(File(item.imagePath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              if (item.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.greyDark,
                    color: AppColors.primary,
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return RawAutocomplete<FoodItem>(
                          optionsBuilder:
                              (TextEditingValue textEditingValue) async {
                                if (textEditingValue.text.length < 2) {
                                  return const Iterable<FoodItem>.empty();
                                }
                                return await NutritionApiService().searchFoods(
                                  textEditingValue.text,
                                );
                              },
                          displayStringForOption: (FoodItem option) =>
                              option.name,
                          onSelected: (FoodItem selection) {
                            // Update item
                            setState(() {
                              item.name = selection.name;
                              item.calories = selection.calories;
                              item.protein = selection.protein;
                              item.fat = selection.fat;
                              item.carbs = selection.carbs;
                              item.foodId = selection.id;
                              item.originalCalories = selection.calories;
                              item.originalProtein = selection.protein;
                              item.originalFat = selection.fat;
                              item.originalCarbs = selection.carbs;
                            });

                            // Update controllers
                            _nameController.text = selection.name;
                            _calsController.text = _formatInt(
                              selection.calories,
                            );
                            _protController.text = _formatDouble(
                              selection.protein,
                            );
                            _fatController.text = _formatDouble(selection.fat);
                            _carbsController.text = _formatDouble(
                              selection.carbs,
                            );

                            widget.onUpdate();
                          },
                          fieldViewBuilder:
                              (
                                context,
                                textController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                // We need to use our persistent controller, but Autocomplete wants to provide one.
                                // Solution: Use Autocomplete's controller but sync with ours?
                                // Or better, pass our controller to Autocomplete if RawAutocomplete supported it (it doesn't directly in constructor easily without hook).

                                // Actually RawAutocomplete `textEditingController` param can take our controller.
                                if (textController.text !=
                                    _nameController.text) {
                                  textController.text = _nameController.text;
                                  textController.selection =
                                      _nameController.selection;
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.greyDark.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    onChanged: (val) {
                                      _nameController.text = val;
                                      _onNameChanged(val);
                                    },
                                    style: const TextStyle(
                                      color: AppColors.pureWhite,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'What did you eat?',
                                      hintStyle: TextStyle(
                                        color: AppColors.white40,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                );
                              },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                color: AppColors.black100,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(12),
                                  ),
                                ),
                                child: Container(
                                  width: constraints.maxWidth,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.black100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.greyDark,
                                    ),
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final FoodItem option = options.elementAt(
                                        index,
                                      );
                                      return InkWell(
                                        onTap: () => onSelected(option),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                option.name,
                                                style: const TextStyle(
                                                  color: AppColors.pureWhite,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${option.calories} kcal • P: ${option.protein} • F: ${option.fat} • C: ${option.carbs}',
                                                style: const TextStyle(
                                                  color: AppColors.white60,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(
                      color: AppColors.greyDark.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      controller: _qtyController,
                      focusNode: _qtyFocusNode, // Attach FocusNode
                      onChanged: _onQtyChanged,
                      style: const TextStyle(color: AppColors.pureWhite),
                      decoration: const InputDecoration(
                        hintText: 'Qty',
                        hintStyle: TextStyle(color: AppColors.white40),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMacroInput(
                    'Calories',
                    _calsController,
                    'Cal',
                    AppColors.primary,
                    (v) => _onMacroChanged(v, 'cals'),
                  ),
                  _buildMacroInput(
                    'Protein',
                    _protController,
                    'g',
                    AppColors.primary,
                    (v) => _onMacroChanged(v, 'prot'),
                  ),
                  _buildMacroInput(
                    'Fat',
                    _fatController,
                    'g',
                    AppColors.primary,
                    (v) => _onMacroChanged(v, 'fat'),
                  ),
                  _buildMacroInput(
                    'Carbs',
                    _carbsController,
                    'g',
                    AppColors.primary,
                    (v) => _onMacroChanged(v, 'carbs'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.canRemove)
          Positioned(
            top: -10,
            right: -10,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMacroInput(
    String label,
    TextEditingController controller,
    String unit,
    Color color,
    Function(String) onChanged,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.greyDark.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  controller: controller, // Use persistent controller
                  onChanged: onChanged,
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0$unit',
                    hintStyle: const TextStyle(
                      color: AppColors.white40,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
