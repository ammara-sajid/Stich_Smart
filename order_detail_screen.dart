import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_customer_screen.dart';
import 'home_screen.dart';
import 'login_page.dart';
import 'order_list.dart';

class OrderDetailScreen extends StatefulWidget {
  final String tailorId;
  final String customerId;
  final bool isEdit;
  final String? orderId;
  final Map<String, dynamic>? orderData;

  const OrderDetailScreen({super.key, required this.tailorId,
    required this.customerId,this.isEdit = false,this.orderId,this.orderData});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}
class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _deliveryDateController = TextEditingController();
  TextEditingController _orderno = TextEditingController();
  String _selectedStatus = 'Start';
  void initState() {
    super.initState();
    if (widget.isEdit && widget.orderData != null) {
      _orderno.text = widget.orderData!['orderNo']?.toString() ?? '';
      _deliveryDateController.text = widget.orderData!['deliveryDate'] ?? '';
      _selectedStatus = widget.orderData!['orderStatus'] ?? 'Pending';
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _deliveryDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }
  Future<void> _saveOrder() async {
    if (_orderno.text.isEmpty || _deliveryDateController.text.isEmpty || _selectedStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields', style: TextStyle(color: Colors.white),),
          duration: const Duration(seconds: 2), // Timer: 3 seconds
          behavior: SnackBarBehavior.floating, // Makes it float above other widgets
          backgroundColor: Colors.grey[700], // Customize background
          shape: RoundedRectangleBorder( // Rounded corners
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    try {
      await _firestore
          .collection('tailors')
          .doc(widget.tailorId)
          .collection('customers')
          .doc(widget.customerId)
          .collection('orders')
          .add({
        'createdAt': FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        'deliveryDate': _deliveryDateController.text,
        'orderStatus': _selectedStatus,
        'orderNo': _orderno.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order saved successfully!', style: TextStyle(color: Colors.white),),
          duration: const Duration(seconds: 2), // Timer: 3 seconds
          behavior: SnackBarBehavior.floating, // Makes it float above other widgets
          backgroundColor: Colors.grey[700], // Customize background
          shape: RoundedRectangleBorder( // Rounded corners
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      Future.delayed(Duration(seconds: 3), () {
        Navigator.pop(context);
      });
    } catch (e) {
      print('Error saving order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save order', style: TextStyle(color: Colors.white),),
          duration: const Duration(seconds: 2), // Timer: 3 seconds
          behavior: SnackBarBehavior.floating, // Makes it float above other widgets
          backgroundColor: Colors.grey[700], // Customize background
          shape: RoundedRectangleBorder( // Rounded corners
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Order Details',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white, // this sets the color of the drawer icon
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            widget.tailorId == null
                ? DrawerHeader(
              child: Center(child: CircularProgressIndicator()),
            )
                : StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('tailors')
                  .doc(widget.tailorId)
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15,),
            TextField(
              controller: _orderno,
              decoration: InputDecoration(
                labelText: 'Order No',
                hintText: "Enter the order number",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                errorStyle: TextStyle(color: Colors.grey[800]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.grey, width: 2),
                ),

                ),
              keyboardType: TextInputType.number,
              ),


            SizedBox(height: 20,),
            TextField(
              controller: _deliveryDateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Delivery Date',
                hintText: "Select the delivery date",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                errorStyle: TextStyle(color: Colors.grey[800]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.grey, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Order Status Dropdown
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              items: ['Start', 'Pending', 'Delivered']
                  .map((status) => DropdownMenuItem(
                child: Text(status),
                value: status,
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Order Status',
                hintText: "Order Status",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                errorStyle: TextStyle(color: Colors.grey[800]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.grey, width: 2),
                ),
              ),
            ),
            SizedBox(height: 30),

            // Save Button
            Center(
              child: ElevatedButton(
                onPressed: _saveOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    // Shape
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text('Save Order Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
