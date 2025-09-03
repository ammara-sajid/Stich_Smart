import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailors_app/order_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_customer_screen.dart';
import 'home_screen.dart';
import 'login_page.dart';
import 'measurement_detail_screen.dart';


class ChoseCategory extends StatefulWidget {
  final String customerId;
  final String tailorId;
  final String orderId;
  final bool isEdit;
  final String? initialSelectedCategory;

  const ChoseCategory(
      {super.key,
        required this.customerId,
        required this.tailorId,
        required this.orderId, this.isEdit = false, this.initialSelectedCategory,});

  @override
  State<ChoseCategory> createState() => _ChoseCategoryState();
}

class _ChoseCategoryState extends State<ChoseCategory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? tailorId;
  int? gender; // 1: men, 2: women, 3: boy, 4: girl
  String? selectedCategory;
  String? selectedSubCategory;
  Map<String, dynamic> measurementData = {};
  Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    tailorId = widget.tailorId;
    if (widget.isEdit && widget.initialSelectedCategory != null) {
      selectedCategory = widget.initialSelectedCategory;
      _loadCustomerGender().then((_) {
        _loadMeasurementData(); // load measurements after gender is loaded
      });
    } else {
      _loadCustomerGender();
    }
  }
  Future<void> _loadTailorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tailorId = prefs.getString('tailorId');
    });
  }

  List<String> menBoyCategories = [
    'Shalwar Kameez',
    'Kurta Pajama',
    'Waistcoat Suit',
    'Sherwani'
  ];
  List<String> womenGirlCategories = [
    'Shirt & Trouser',
    'Maxi',
    'Frock',
    'Plazo Shirt',
    'Open Shirt',
    'Gown'
  ];

  Future<void> _loadCustomerGender() async {
    if (tailorId == null) return;

    try {
      DocumentSnapshot customerSnapshot = await _firestore
          .collection('tailors')
          .doc(tailorId)
          .collection('customers')
          .doc(widget.customerId)
          .get();

      if (customerSnapshot.exists) {
        final data = customerSnapshot.data() as Map<String, dynamic>;
        print("Fetched data: $data");

        if (data.containsKey('category')) {
          setState(() {
            gender = data['category']; // Make sure it's an int like 1, 2, etc.
          });
          print("Gender (category) loaded: $gender");
        } else {
          print("⚠ 'category' field not found in customer data.");
        }
      } else {
        print("⚠ Customer document does not exist.");
      }
    } catch (e) {
      print(" Error loading customer gender: $e");
    }
  }
  Future<void> _saveSelectedCategory() async {
    if (tailorId == null || selectedCategory == null) return;

    await _firestore
        .collection('tailors')
        .doc(tailorId)
        .collection('customers')
        .doc(widget.customerId)
        .collection('orders')
        .doc(widget.orderId)
        .set({
      'categories': selectedCategory,
      "createdAt": Timestamp,
      "updatedAt": Timestamp
    }, SetOptions(merge: true));
  }
  List<String> _getMeasurementParts(String category) {
    switch (category) {
      case 'Shalwar Kameez':
        return ['Shalwar', 'Kameez'];
      case 'Kurta Pajama':
        return ['Kurta', 'Pajama'];
      case 'Waistcoat Suit':
        return ['Waistcoat', 'Suit'];
      case 'Sherwani':
        return ['Sherwani'];
      case 'Maxi':
        return ['Maxi'];
      case 'Frock':
        return ['Frock'];
      case 'Shirt & Trouser':
        return ['Shirt', 'Trouser'];
      case 'Plazo Shirt':
        return ['Plazo', 'Shirt'];
      case 'Gown':
        return ['Gown'];
      case 'Open Shirt':
        return ['Shirt'];
      default:
        return [];
    }
  }

  List<String> _getMeasurementFieldsForPart(String part) {
    switch (part) {
      case 'Shalwar':
        return ['Length', 'Bottom'];
      case 'Kameez':
        return ['Length', 'Chest', 'Sleeves', 'Shoulder'];
      case 'Kurta':
        return ['Length', 'Chest', 'Sleeves', 'Shoulder'];
      case 'Pajama':
        return ['Length', 'Bottom'];
      case 'Maxi':
      case 'Frock':
      case 'Gown':
        return ['Length', 'Chest','Shoulder','Bottom Width'];
      case 'Shirt':
        return ['Length', 'Chest', 'Sleeves', 'Shoulder'];
      case 'Trouser':
      case 'Plazo':
        return ['Length', 'Waist', 'Bottom Width'];
      case 'Waistcoat':
        return ['Length', 'Chest', 'Waist'];
      case 'Suit':
        return ['Length', 'Chest', 'Sleeves', 'Shoulder'];
      case 'Sherwani':
        return ['Length', 'Chest', 'Waist', 'Shoulder','Sleeves'];
      default:
        return ['Length'];
    }
  }
  Future<void> _loadMeasurementData() async {
    if (tailorId == null || selectedCategory == null) return;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('tailors')
          .doc(tailorId)
          .collection('customers')
          .doc(widget.customerId)
          .collection('orders')
          .doc(widget.orderId)
          .collection('categories')
          .doc(selectedCategory)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.isNotEmpty) {
          String firstPart = data.keys.first;
          Map<String, dynamic> partData = Map<String, dynamic>.from(data[firstPart]);

          setState(() {
            selectedSubCategory = firstPart;
            measurementData = partData;
            _controllers = {
              for (var field in partData.keys)
                field: TextEditingController(text: partData[field]?.toString() ?? ''),
            };
          });
        }
      }
    } catch (e) {
      print("Error loading measurements for editing: $e");
    }
  }

  Widget _buildMeasurementFields(String part) {
    List<String> fields = _getMeasurementFieldsForPart(part);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...fields.map((field) {
          if (!_controllers.containsKey(field)) {
            _controllers[field] = TextEditingController(
              text: measurementData[field]?.toString() ?? '',
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    field,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    controller: _controllers[field],
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    // restrict to 2-3 digits
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      measurementData[field] = value;
                    },
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'in',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          );
        }).toList(),

        _buildSaveMeasurementButtons([part]),
      ],
    );
  }

  Widget _buildSaveMeasurementButtons(List<String> parts) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: parts.map((part) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () => _saveMeasurements(part),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Save $part Measurements'),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveMeasurements(String part) async {
    if (tailorId == null || selectedCategory == null || selectedSubCategory == null) return;

    // Prepare the data to be saved (measurementData holds the entered measurement fields)
    Map<String, dynamic> measurements = {};
    measurementData.forEach((key, value) {
      measurements[key] = value;  // Save each field of the part
    });
    if (measurementData.isEmpty) {
      // If no data is entered, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all the fields before saving.', style: TextStyle(color: Colors.white),
        ), duration: const Duration(seconds: 2), // Timer: 3 seconds
          behavior: SnackBarBehavior.floating, // Makes it float above other widgets
          backgroundColor: Colors.grey[700], // Customize background
          shape: RoundedRectangleBorder( // Rounded corners
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return; // Do not proceed with saving if fields are empty
    }

    // Proceed with saving if the fields are filled
    if (tailorId == null || selectedCategory == null) return;

    try {
      await _firestore
          .collection('tailors')
          .doc(tailorId)
          .collection('customers')
          .doc(widget.customerId)
          .collection('orders')
          .doc(widget.orderId)
          .collection('categories')
          .doc(selectedCategory)
          .set({
        part: measurementData,
      }, SetOptions(merge: true));

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$part measurements saved',style: TextStyle(color: Colors.white),),
          duration: const Duration(seconds: 2), // Timer: 3 seconds
          behavior: SnackBarBehavior.floating, // Makes it float above other widgets
          backgroundColor: Colors.grey[700], // Customize background
          shape: RoundedRectangleBorder( // Rounded corners
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } catch (e) {
      print("Error saving measurements: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save measurements',style: TextStyle(color: Colors.white),
        ),duration: const Duration(seconds: 2), // Timer: 3 seconds
          behavior: SnackBarBehavior.floating, // Makes it float above other widgets
          backgroundColor: Colors.grey[700], // Customize background
          shape: RoundedRectangleBorder( // Rounded corners
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    };
  }
  Future<void> _loadPartMeasurements(String part) async {
    if (tailorId == null || selectedCategory == null) return;

    try {
      DocumentSnapshot doc = await _firestore
          .collection('tailors')
          .doc(tailorId)
          .collection('customers')
          .doc(widget.customerId)
          .collection('orders')
          .doc(widget.orderId)
          .collection('categories')
          .doc(selectedCategory)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey(part)) {
          setState(() {
            measurementData = Map<String, dynamic>.from(data[part]);
            _controllers = {
              for (var field in measurementData.keys)
                field: TextEditingController(text: measurementData[field]?.toString() ?? '')
            };
          });
        }
      }
    } catch (e) {
      print("Error loading part measurements: $e");
    }
  }
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    List<String> categories = [];

    if (gender == 1 || gender == 3) {
      categories = menBoyCategories;
    } else if (gender == 2 || gender == 4) {
      categories = womenGirlCategories;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Chose Category',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white, // this sets the color of the drawer icon
        ),
      ),
      body: tailorId == null || gender == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select a Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ...categories.map((category) => ListTile(
                leading: Icon(
                  selectedCategory == category
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: Colors.black,
                ),
                title: Text(category),
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                    selectedSubCategory = null;
                    measurementData.clear(); // Reset measurements
                  });
                  _saveSelectedCategory(); // Save when selected
                },
              )),
              if (selectedCategory != null) ...[
                Divider(),
                SizedBox(height: 15,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Select Part to Measure",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Wrap(
                          spacing: 10,
                          children: _getMeasurementParts(selectedCategory!).map((part) {
                            return ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedSubCategory = part;
                                  measurementData.clear();
                                  _controllers.clear(); // clear previous controllers
                                });
                                _loadPartMeasurements(part);
                              },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black, // black background
                                foregroundColor: Colors.white,
                                minimumSize: Size(160, 35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20), // rounded edges
                                ),
                              ),
                              child: Text(part),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),



                SizedBox(height: 20),
                if (selectedSubCategory != null)
                  _buildMeasurementFields(selectedSubCategory!),
                ElevatedButton(
                  onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MeasurementDetailScreen(
                          customerId: widget.customerId,
                          tailorId: widget.tailorId,
                          orderId: widget.orderId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder( // Shape
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('Show Measurements'),
                )
              ]
            ],
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            tailorId == null
                ? DrawerHeader(
              child: Center(child: CircularProgressIndicator()),
            )
                : StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('tailors')
                  .doc(tailorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return DrawerHeader(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return DrawerHeader(
                    child: Center(child: Text('Error fetching data')),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return DrawerHeader(
                    child: Center(child: Text('No tailor data found')),
                  );
                }

                var tailorData =
                snapshot.data!.data() as Map<String, dynamic>;

                return DrawerHeader(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                          AssetImage('assets/image/Logo.png'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tailorData['fullName'] ?? 'Tailor Name',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              tailorData['email'] ?? 'tailor@example.com',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              tailorData['phone'] ?? '+1234567890',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(
              height: 20,
            ),
            ListTile(
              title: Text('Your Customers',style: TextStyle(fontWeight: FontWeight.bold),),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddCustomerScreen(), // Removed semicolon here
                  ),
                );
              },
            ),
            ListTile(
              title: Text('Order List',style: TextStyle(fontWeight: FontWeight.bold),),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderList(
                        customerId: widget.customerId,
                        tailorId: widget.tailorId), // Removed semicolon here
                  ),
                );
              },
            ), ListTile(
              title: Text('View Measurements',style: TextStyle(fontWeight: FontWeight.bold),),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MeasurementDetailScreen(
                      customerId: widget.customerId,
                      tailorId: widget.tailorId,
                      orderId: widget.orderId,
                    ), // Removed semicolon here
                  ),
                );
              },
            ),
            ListTile(
              title: Text('Home ',style: TextStyle(fontWeight: FontWeight.bold),),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(), // Removed semicolon here
                  ),
                );
              },
            ),
            Spacer(),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings,color: Colors.grey),
              title: Text('Settings'),
              onTap: () {
                // Navigate to settings screen
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline,color: Colors.grey),
              title: Text('Help'),
              onTap: () {
                // Navigate to help screen
              },
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip,color: Colors.grey),
              title: Text('Privacy Policy'),
              onTap: () {
                // Navigate to privacy policy screen
              },
            ),

            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout',style: TextStyle(fontWeight: FontWeight.bold),),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
