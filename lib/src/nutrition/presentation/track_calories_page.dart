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
  int get _totalCalories => _items.fold(0, (sum, item) => sum + (item.calories * item.quantity));
  double get _totalProtein => _items.fold(0, (sum, item) => sum + (item.protein * item.quantity));
  double get _totalFat => _items.fold(0, (sum, item) => sum + (item.fat * item.quantity));
  double get _totalCarbs => _items.fold(0, (sum, item) => sum + (item.carbs * item.quantity));

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

  void _updateItem(int index, {String? name, int? qty, int? cals, double? prot, double? fat, double? carbs, String? foodId, int? origCals, double? origProt, double? origFat, double? origCarbs}) {
    setState(() {
      final item = _items[index];
      if (name != null) item.name = name;
      if (qty != null) item.quantity = qty;
      if (cals != null) item.calories = cals;
      if (prot != null) item.protein = prot;
      if (fat != null) item.fat = fat;
      if (carbs != null) item.carbs = carbs;
      if (foodId != null) item.foodId = foodId;
      if (origCals != null) item.originalCalories = origCals;
      if (origProt != null) item.originalProtein = origProt;
      if (origFat != null) item.originalFat = origFat;
      if (origCarbs != null) item.originalCarbs = origCarbs;
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
        title: const Text('Describe your food', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: descriptionController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. Idli with sambar',
            hintStyle: TextStyle(color: Colors.white60),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white60)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, descriptionController.text),
            child: const Text('Analyze', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeFood(DietLogItem item, String description) async {
    if (item.imagePath == null) return;

    try {
      final File imageFile = File(item.imagePath!);
      final result = await NutritionApiService().analyzeFood(imageFile, description);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  void _continueToPost() async {
    // Filter out items with no name
    final validItems = _items.where((item) => item.name.isNotEmpty && !item.isLoading).toList();
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
        title: const Text('Track Calories', style: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.black,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.pureWhite, size: 20),
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
                 MaterialPageRoute(builder: (context) => const CameraPage()) 
               );
               if (result == true && mounted) {
                 Navigator.pop(context, true);
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
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index.isOdd) return const SizedBox(height: 16);
                          return _buildFoodItemCard(index ~/ 2);
                        },
                        childCount: _items.length * 2 - 1,
                      ),
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
           style: const TextStyle(color: AppColors.pureWhite, fontSize: 16, fontWeight: FontWeight.w600),
           onChanged: (String? newValue) {
             if (newValue != null) {
               setState(() {
                 _selectedMeal = newValue;
               });
             }
           },
           items: _mealTypes.map<DropdownMenuItem<String>>((String value) {
             return DropdownMenuItem<String>(
               value: value,
               child: Text(value),
             );
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
          Expanded(child: _buildStatBox('${_totalProtein.toInt()}g', 'Protein')),
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
            style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold, fontSize: 16),
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
    final item = _items[index];
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
              // Display captured image if present
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

              // Loading Indicator
              if (item.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.greyDark,
                    color: AppColors.primary,
                  ),
                ),

              // Name and Qty
              Row(
                children: [
                  Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return RawAutocomplete<FoodItem>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          if (textEditingValue.text.length < 2) {
                            return const Iterable<FoodItem>.empty();
                          }
                          return await NutritionApiService().searchFoods(textEditingValue.text);
                        },
                        displayStringForOption: (FoodItem option) => option.name,
                        onSelected: (FoodItem selection) {
                          _updateItem(
                            index,
                            name: selection.name,
                            cals: selection.calories,
                            prot: selection.protein,
                            fat: selection.fat,
                            carbs: selection.carbs,
                            foodId: selection.id,
                            origCals: selection.calories,
                            origProt: selection.protein,
                            origFat: selection.fat,
                            origCarbs: selection.carbs,
                          );
                        },
                        fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                          // Sync controller with item name if needed, but carefully to avoid loops
                          if (item.name.isNotEmpty && textEditingController.text != item.name) {
                             textEditingController.text = item.name;
                          }
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.greyDark.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              onChanged: (val) => _updateItem(index, name: val),
                              style: const TextStyle(color: AppColors.pureWhite),
                              decoration: const InputDecoration(
                                hintText: 'What did you eat?',
                                hintStyle: TextStyle(color: AppColors.white40),
                                border: InputBorder.none,
                              ),
                            ),
                          );
                        },
                        optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<FoodItem> onSelected, Iterable<FoodItem> options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              color: AppColors.black100, // Match card color or slightly lighter
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                              child: Container(
                                width: constraints.maxWidth,
                                constraints: const BoxConstraints(maxHeight: 200),
                                decoration: BoxDecoration(
                                   color: AppColors.black100,
                                   borderRadius: BorderRadius.circular(12),
                                   border: Border.all(color: AppColors.greyDark),
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final FoodItem option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(option.name, style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold)),
                                            Text(
                                              '${option.calories} kcal • P: ${option.protein} • F: ${option.fat} • C: ${option.carbs}',
                                              style: const TextStyle(color: AppColors.white60, fontSize: 12),
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
                    }
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
                      controller: TextEditingController(text: item.quantity.toString())
                         ..selection = TextSelection.fromPosition(TextPosition(offset: item.quantity.toString().length)),
                      onChanged: (val) => _updateItem(index, qty: int.tryParse(val) ?? 1),
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
              
              // Macros Inputs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMacroInput('Calories', item.calories.toString(), 'Cal', AppColors.primary, (val) => _updateItem(index, cals: int.tryParse(val) ?? 0)),
                  _buildMacroInput('Protein', item.protein.toString(), 'g', AppColors.primary, (val) => _updateItem(index, prot: double.tryParse(val) ?? 0)),
                  _buildMacroInput('Fat', item.fat.toString(), 'g', AppColors.primary, (val) => _updateItem(index, fat: double.tryParse(val) ?? 0)),
                  _buildMacroInput('Carbs', item.carbs.toString(), 'g', AppColors.primary, (val) => _updateItem(index, carbs: double.tryParse(val) ?? 0)),
                ],
              ),
            ],
          ),
        ),
        if (_items.length > 1 && index == _items.length - 1)
          Positioned(
            top: -10,
            right: -10,
            child: GestureDetector(
              onTap: () => _removeItem(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMacroInput(String label, String value, String unit, Color color, Function(String) onChanged) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department, size: 12, color: color), // Placeholder icons
            const SizedBox(width: 4),
            Text(label, style: InputDecorationTheme().labelStyle?.copyWith(color: color) ?? TextStyle(color: color, fontSize: 12)),
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
                  controller: TextEditingController(text: value == '0' || value == '0.0' ? '' : value),
                  onChanged: onChanged,
                  style: const TextStyle(color: AppColors.white60, fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0$unit',
                    hintStyle: const TextStyle(color: AppColors.white40, fontSize: 13),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Food', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Discard Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
