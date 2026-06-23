import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ngo_listing_model.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart'; // REQUIRED: To navigate back safely

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({Key? key}) : super(key: key);

  @override
  State<CreateListingScreen> createState() => CreateListingScreenState();
}

class CreateListingScreenState extends State<CreateListingScreen> {
  final FirestoreService firestoreService = FirestoreService();
  
  String _listingType = 'food';
  bool _isStep1 = true; // Controls Progressive Disclosure (The "Next" logic)
  
  // Volunteer Availability State
  bool? _isVolunteerAvailable;

  final TextEditingController _foodTypeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  
  // Dedicated units for separate listing branches
  String _foodUnit = 'kg';
  String _productUnit = 'items';

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  
  bool _isLoading = false;
  final Color themeColor = const Color(0xFF7D444C); // App Theme Color

  // Suggestion Lists for Autocomplete
  static const List<String> _foodSuggestions = [
    'Biriyani', 'Chappathi', 'Curry', 'Dal', 'Dosa', 'Idli', 'Meals',
    'Parotta', 'Pongal', 'Puri', 'Rice', 'Roll', 'Sambar', 'Sandwich'
  ];

  static const List<String> _productSuggestions = [
    'Blankets', 'Books', 'Clothes', 'Footwear', 'Furniture',
    'Medicines', 'School Supplies', 'Stationery', 'Toys', 'Utensils', 'Winter Wear'
  ];

  @override
  void dispose() {
    _foodTypeController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _productNameController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  //--- Interactive Date and Time Picker
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Transform.scale(
          scale: 0.85,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: themeColor,
                onPrimary: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Transform.scale(
            scale: 0.85,
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: themeColor,
                  onPrimary: Colors.white,
                  onSurface: Colors.black87,
                ),
              ),
              child: child!,
            ),
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          String day = pickedDate.day.toString().padLeft(2, '0');
          String month = pickedDate.month.toString().padLeft(2, '0');
          String year = pickedDate.year.toString();
          String time = pickedTime.format(context);
          _availabilityController.text = "$day-$month-$year $time";
        });
      }
    }
  }

  void _goToNextStep() {
    if (_listingType == 'food' && _foodTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Food Type')),
      );
      return;
    }
    if (_listingType == 'product' &&
        (_categoryController.text.trim().isEmpty || _productNameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Category and Product Name')),
      );
      return;
    }
    setState(() {
      _isStep1 = false;
    });
  }

  void navigateSafelyHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _createListing() async {
    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Quantity')),
      );
      return;
    }
    if (_availabilityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date & Time')),
      );
      return;
    }
    if (_isVolunteerAvailable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select if a Volunteer is Available')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUserModel;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String listingId = FirebaseFirestore.instance.collection('ngo_listings').doc().id;
      final selectedText = _availabilityController.text.trim();

final parts = selectedText.split(' ');
final datePart = parts[0]; // dd-MM-yyyy
final timePart = "${parts[1]} ${parts[2]}"; // hh:mm AM/PM

final datePieces = datePart.split('-');

final day = int.parse(datePieces[0]);
final month = int.parse(datePieces[1]);
final year = int.parse(datePieces[2]);

final parsedTime = TimeOfDay(
  hour: TimeOfDay(
    hour: int.parse(timePart.split(':')[0]),
    minute: int.parse(
      timePart.split(':')[1].split(' ')[0],
    ),
  ).hour,
  minute: int.parse(
    timePart.split(':')[1].split(' ')[0],
  ),
);

DateTime selectedDateTime = DateTime(
  year,
  month,
  day,
  parsedTime.hour,
  parsedTime.minute,
);

      NgoListingModel newListing = NgoListingModel(
        listingId: listingId,
        ngoId: user.uid,
        ngoName: user.name,
        ngoLocation: user.location,
        type: _listingType,
        imageUrl: null, // Image feature removed completely
        foodType: _listingType == 'food' ? _foodTypeController.text.trim() : null,
        quantity: int.parse(_quantityController.text.trim()),
        unit: _listingType == 'food' ? _foodUnit : _productUnit,
        category: _listingType == 'product' ? _categoryController.text.trim() : null,
        productName: _listingType == 'product' ? _productNameController.text.trim() : null,
        availability: _availabilityController.text.trim(),
        liveUntil: selectedDateTime,
        createdAt: DateTime.now(),
        status: 'open',
        isVolunteerAvailable: _isVolunteerAvailable,
      );

      await firestoreService.createNgoListing(newListing);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request created successfully!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      navigateSafelyHome();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String hintText,
    required List<String> suggestions,
    required bool isEnabled,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        String query = textEditingValue.text.toLowerCase();
        var startsWithMatches = suggestions
            .where((option) => option.toLowerCase().startsWith(query))
            .toList();
        var containsMatches = suggestions
            .where((option) =>
                option.toLowerCase().contains(query) &&
                !option.toLowerCase().startsWith(query))
            .toList();
        return [...startsWithMatches, ...containsMatches];
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        
        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          enabled: isEnabled,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          onChanged: (value) {
            controller.text = value; 
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: isEnabled ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: themeColor.withOpacity(0.5), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            shadowColor: themeColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: MediaQuery.of(context).size.width - 64, 
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Text(
                        option,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFDF7F8),
            Color(0xFFEEDAE0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.1, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: Colors.black87),
            onPressed: navigateSafelyHome,
          ),
          title: const Text(
            "Create Request",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 22),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      themeColor.withOpacity(0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _isStep1
                                        ? () {
                                            setState(() {
                                              _listingType = 'food';
                                            });
                                          }
                                        : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _listingType == 'food' ? themeColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: _listingType == 'food'
                                            ? [
                                                BoxShadow(
                                                  color: themeColor.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                )
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Food",
                                          style: TextStyle(
                                            color: _listingType == 'food' ? Colors.white : Colors.grey.shade600,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _isStep1
                                        ? () {
                                            setState(() {
                                              _listingType = 'product';
                                            });
                                          }
                                        : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _listingType == 'product' ? themeColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: _listingType == 'product'
                                            ? [
                                                BoxShadow(
                                                  color: themeColor.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                )
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Product",
                                          style: TextStyle(
                                            color: _listingType == 'product' ? Colors.white : Colors.grey.shade600,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          if (_listingType == 'food') ...[
                            _buildAutocompleteField(
                              controller: _foodTypeController,
                              hintText: "Food Type (e.g., Rice, Meals)",
                              suggestions: _foodSuggestions,
                              isEnabled: _isStep1,
                            ),
                          ] else ...[
                            Opacity(
                              opacity: _isStep1 ? 1.0 : 0.5,
                              child: IgnorePointer(
                                ignoring: !_isStep1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: CustomTextField(
                                    controller: _categoryController,
                                    hintText: "Category (Clothes, Books)",
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildAutocompleteField(
                              controller: _productNameController,
                              hintText: "Product Name",
                              suggestions: _productSuggestions,
                              isEnabled: _isStep1,
                            ),
                          ],
                          
                          const SizedBox(height: 25),
                          
                          if (_isStep1)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _goToNextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  elevation: 4,
                                  shadowColor: themeColor.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text(
                                  "Continue",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                                ),
                              ),
                            ),
                          
                          AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.fastOutSlowIn,
                            child: _isStep1
                                ? const SizedBox.shrink()
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _isStep1 = true; 
                                            });
                                          },
                                          icon: Icon(Icons.edit_rounded, size: 16, color: themeColor),
                                          label: Text(
                                            "Edit Selection",
                                            style: TextStyle(color: themeColor, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      
                                      // Numeric text field and context-adaptive dropdown row
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: CustomTextField(
                                                controller: _quantityController,
                                                hintText: "Quantity",
                                                keyboardType: TextInputType.number,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: _listingType == 'food' ? _foodUnit : _productUnit,
                                                  isExpanded: true,
                                                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: themeColor),
                                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 15),
                                                  items: (_listingType == 'food'
                                                          ? ['kg', 'packs', 'members']
                                                          : ['items', 'sets/pairs', 'kg', 'boxes/cartons'])
                                                      .map((value) {
                                                    return DropdownMenuItem(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      if (_listingType == 'food') {
                                                        _foodUnit = value!;
                                                      } else {
                                                        _productUnit = value!;
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      TextFormField(
                                        controller: _availabilityController,
                                        readOnly: true,
                                        onTap: () => _selectDateTime(context),
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                        decoration: InputDecoration(
                                          hintText: "Select Date & Time",
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          suffixIcon: Icon(Icons.calendar_month_rounded, color: themeColor, size: 22),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: themeColor.withOpacity(0.5), width: 1.5),
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      const Text(
                                        "Do you have a volunteer for pickup?",
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() => _isVolunteerAvailable = true),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                decoration: BoxDecoration(
                                                  color: _isVolunteerAvailable == true ? themeColor : Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: _isVolunteerAvailable == true
                                                      ? [
                                                          BoxShadow(
                                                            color: themeColor.withOpacity(0.3),
                                                            blurRadius: 10,
                                                            offset: const Offset(0, 4),
                                                          )
                                                        ]
                                                      : [],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "Yes, I do",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: _isVolunteerAvailable == true ? Colors.white : Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => setState(() => _isVolunteerAvailable = false),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                decoration: BoxDecoration(
                                                  color: _isVolunteerAvailable == false ? themeColor : Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: _isVolunteerAvailable == false
                                                      ? [
                                                          BoxShadow(
                                                            color: themeColor.withOpacity(0.3),
                                                            blurRadius: 10,
                                                            offset: const Offset(0, 4),
                                                          )
                                                        ]
                                                      : [],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "No",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: _isVolunteerAvailable == false ? Colors.white : Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 45),
                                      
                                      SizedBox(
                                        width: double.infinity,
                                        child: CustomButton(
                                          text: "Publish Request",
                                          isLoading: _isLoading,
                                          onPressed: _createListing,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}