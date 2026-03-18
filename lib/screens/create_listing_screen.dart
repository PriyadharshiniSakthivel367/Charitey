
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ngo_listing_model.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';


class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({Key? key}) : super(key: key);

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _listingType = 'food';

  final TextEditingController _foodTypeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _unit = 'kg';

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();

  final TextEditingController _availabilityController = TextEditingController();

  bool _isLoading = false;

File? _selectedImage;
Uint8List? _webImage;  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _foodTypeController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _productNameController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
  final picked = await _picker.pickImage(source: ImageSource.gallery);

  if (picked != null) {
    if (kIsWeb) {
      _webImage = await picked.readAsBytes();
    } else {
      _selectedImage = File(picked.path);
    }

    setState(() {});
  }
}

  Future<void> _createListing() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUserModel;

    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        final storageService = StorageService();
imageUrl = await storageService.uploadImage(_selectedImage, _webImage);      }

      String listingId =
          FirebaseFirestore.instance.collection('ngo_listings').doc().id;

      NgoListingModel newListing = NgoListingModel(
        listingId: listingId,
        ngoId: user.uid,
        ngoName: user.name,
        ngoLocation: user.location,
        type: _listingType,
        imageUrl: imageUrl,
        foodType:
            _listingType == 'food' ? _foodTypeController.text.trim() : null,
       quantity: _listingType == 'food' &&
        _quantityController.text.trim().isNotEmpty
    ? int.parse(_quantityController.text.trim())
    : null,
        unit: _listingType == 'food' ? _unit : null,
        category:
            _listingType == 'product' ? _categoryController.text.trim() : null,
        productName: _listingType == 'product'
            ? _productNameController.text.trim()
            : null,
        availability: _availabilityController.text.trim(),
        liveUntil: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        status: 'open',
      );

      await _firestoreService.createNgoListing(newListing);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing Created Successfully')),
      );

      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Listing"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text("Food Registration"),
                  selected: _listingType == 'food',
                  onSelected: (_) {
                    setState(() {
                      _listingType = 'food';
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text("Product Request"),
                  selected: _listingType == 'product',
                  onSelected: (_) {
                    setState(() {
                      _listingType = 'product';
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_listingType == 'food') ...[
              CustomTextField(
                controller: _foodTypeController,
                hintText: "Food Type (Rice, Meals)",
              ),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      hintText: "Quantity",
                      keyboardType: TextInputType.number,
                    ),
                  ),

                  const SizedBox(width: 10),

                  DropdownButton<String>(
                    value: _unit,
                    items: ['kg', 'packs', 'members'].map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _unit = value!;
                      });
                    },
                  )
                ],
              ),
            ] else ...[
              CustomTextField(
                controller: _categoryController,
                hintText: "Category (Clothes, Books)",
              ),

              CustomTextField(
                controller: _productNameController,
                hintText: "Product Name",
              ),
            ],

            CustomTextField(
              controller: _availabilityController,
              hintText: "Availability (9AM - 12PM)",
            ),

            const SizedBox(height: 20),

           if (_selectedImage != null || _webImage != null)
  ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: kIsWeb
        ? Image.memory(
            _webImage!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : Image.file(
            _selectedImage!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
  ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Select Image"),
            ),

            const SizedBox(height: 30),

            CustomButton(
              text: "Publish Listing",
              isLoading: _isLoading,
              onPressed: _createListing,
            ),
          ],
        ),
      ),
    );
  }
}
