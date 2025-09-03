import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_customer_screen.dart';
import 'chose_category.dart';
import 'home_screen.dart';
import 'login_page.dart';
import 'package:tailors_app/order_list.dart';

class MeasurementDetailScreen extends StatefulWidget {
  final String customerId;
  final String tailorId;
  final String orderId;

  const MeasurementDetailScreen(
      {super.key,
      required this.customerId,
      required this.tailorId,
      required this.orderId});

  @override
  State<MeasurementDetailScreen> createState() =>
      _MeasurementDetailScreenState();
}

class _MeasurementDetailScreenState extends State<MeasurementDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? category;

  String? tailorId;
  String? customerId;
  bool isLoading = true;
  bool isMeasurementLoading = true;

  String? customerName;
  String? customerPhone;
  String? customerAddress;
  String? deliveryDate;
  String? orderStatus;


  Map<String, dynamic>? shirtMeasurements;
  Map<String, dynamic>? trouserMeasurements;


  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadTailorId();
    //await _loadCustomerId();
    await _fetchCustomerData();
  }

  Future<void> _loadTailorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    tailorId = prefs.getString('tailorId');
  }

  List<String> orderStatusOptions = ['Start', 'Pending', 'Delivered'];
  String? selectedStatus;
  Map<String, Map<String, dynamic>> categoryMeasurements = {};
  List<String> selectedCategories = [];

  Future<void> _fetchCustomerData() async {
    try {
      var doc = await _firestore
          .collection('tailors')
          .doc(tailorId)
          .collection('customers')
          .doc(widget.customerId)
          .get();

      if (doc.exists) {
        setState(() {
          customerName = doc['name'];
          customerPhone = doc.data()?['phone'];
          customerAddress = doc.data()?['address'];
          isLoading = false;

        });
        var orderDoc = await _firestore
            .collection('tailors')
            .doc(tailorId)
            .collection('customers')
            .doc(widget.customerId)
            .collection('orders')
            .doc(widget.orderId)
            .get();

        if (orderDoc.exists) {
          setState(() {
            deliveryDate = orderDoc.data()?['deliveryDate'];
            orderStatus = orderDoc.data()?['orderStatus'];
            selectedStatus = orderStatus;
          });
        }

        var categoriesSnapshot = await _firestore
            .collection('tailors')
            .doc(tailorId)
            .collection('customers')
            .doc(widget.customerId)
            .collection('orders')
            .doc(widget.orderId)
            .collection('categories')
            .get();

        for (var categoryDoc in categoriesSnapshot.docs) {
          String categoryName = categoryDoc.id;
          var measurementDoc = await _firestore
              .collection('tailors')
              .doc(tailorId)
              .collection('customers')
              .doc(widget.customerId)
              .collection('orders')
              .doc(widget.orderId)
              .collection('categories')
              .doc(categoryName)
              .get();

          if (measurementDoc.exists) {
            setState(() {
              selectedCategories.add(categoryName);
              categoryMeasurements[categoryName] = measurementDoc.data()!;
            });
          }
        }

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching customer: $e');
    }
    finally {
      setState(() {
        isLoading = false;
        isMeasurementLoading = false;
      });
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          SizedBox(width: 10),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child:
                  Text(value ?? '', style: TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Widget SectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMeasurementCard(Map<String, dynamic> measurements) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey[300],
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: measurements.entries.map((entry) {
            final categoryName = entry.key;
            final categoryMeasurements = entry.value as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Title and Edit Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // Fields in Two Columns
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = (constraints.maxWidth - 16) ; // 16 for spacing

                        return Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          children: categoryMeasurements.entries.map((field) {
                            return Container(
                              width: itemWidth,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      field.key,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    '${field.value}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  )

                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }



  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Measurements',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.white, // this sets the color of the drawer icon
        ),
        centerTitle: true,
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
              title: Text('Add Measurements',style: TextStyle(fontWeight: FontWeight.bold),),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChoseCategory(
                      tailorId: widget.tailorId,
                      customerId: widget.customerId,
                      orderId: widget.orderId,), // Removed semicolon here
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
      body: (isLoading || isMeasurementLoading)
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      color: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Divider(),
                            _buildInfoRow(Icons.person, 'Name', customerName),
                            _buildInfoRow(Icons.phone, 'Phone', customerPhone),
                            _buildInfoRow(
                                Icons.home, 'Address', customerAddress),
                            _buildInfoRow(Icons.delivery_dining,
                                'Delivery Date', deliveryDate),
                            _buildInfoRow(Icons.category, 'Category Selected', selectedCategories.join(', ')),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (categoryMeasurements.isNotEmpty)
                            ...categoryMeasurements.entries.map((entry) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      SectionTitle('Measurements'),
                                      SizedBox(
                                        width: 150,
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChoseCategory(
                                                tailorId: widget.tailorId,
                                                customerId: widget.customerId,
                                                orderId: widget.orderId,
                                                isEdit: true,
                                                initialSelectedCategory: entry.key,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.edit, color: Colors.black),
                                        label: Text(
                                          'Edit',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildMeasurementCard(entry.value),

                                ],
                              );
                            }).toList()
                          else
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChoseCategory(
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text('Add Measurements'),
                              ),
                            ),

                        ]
                    )
                  ]
              )
      ),
    );
  }
}
