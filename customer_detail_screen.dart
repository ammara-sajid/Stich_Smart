import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailors_app/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tailors_app/add_customer_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // this line must be here
  runApp(MyApp());
}
class CustomerDetailScreen extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? customerData;
  final String? customerId;
  final String? tailorId;
  const CustomerDetailScreen({ super.key,
    this.isEdit = false,
    this.customerId,
    this.tailorId,
    this.customerData,});
  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}
class _CustomerDetailScreenState extends State<CustomerDetailScreen> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  int selectedCategory = 0; // 1=Men, 2=Women, 3=Boy, 4=Girl

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? tailorId;
  void initState() {
    super.initState();
    _loadTailorId();
    if (widget.isEdit && widget.customerData != null) {
      _nameController.text = widget.customerData!['name'] ?? '';
      _phoneController.text = widget.customerData!['phone'] ?? '';
      _addressController.text = widget.customerData!['address'] ?? '';
      selectedCategory = widget.customerData!['category'] ?? 0;
    }
  }
  Future<void> _loadTailorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tailorId = prefs.getString('tailorId');
    });
    print("Tailor ID: $tailorId"); // Debugging line to verify the value
  }
  Future<void> _addCustomer() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String address =_addressController.text.trim();
    if (name.isEmpty || phone.isEmpty || address.isEmpty  || selectedCategory == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields",style: TextStyle(color: Colors.white),
        ), duration: const Duration(seconds: 2), // Timer: 3 seconds
          behavior: SnackBarBehavior.floating, // Makes it float above other widgets
          backgroundColor: Colors.grey[700], // Customize background
          shape: RoundedRectangleBorder( // Rounded corners
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }
    print("Fields are filled");
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? tailorId = prefs.getString('tailorId');
      print('TailorID from SharedPreferences: $tailorId');

      if (tailorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tailor not logged in",style: TextStyle(color: Colors.white)
          ), duration: const Duration(seconds: 2), // Timer: 3 seconds
            behavior: SnackBarBehavior.floating, // Makes it float above other widgets
            backgroundColor: Colors.grey[700], // Customize background
            shape: RoundedRectangleBorder( // Rounded corners
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
        return;
      }
      DocumentReference tailorDocRef =
          _firestore.collection('tailors').doc(tailorId);
      DocumentReference newCustomer =
          await tailorDocRef.collection('customers').add({
            'name': name,
            'phone': phone,
            'address': address,
            'category': selectedCategory,
            'createdAt': FieldValue.serverTimestamp(),
            "updatedAt":FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer added successfully!',style: TextStyle(color: Colors.white)),
            duration: const Duration(seconds: 2), // Timer: 3 seconds
            behavior: SnackBarBehavior.floating, // Makes it float above other widgets
            backgroundColor: Colors.grey[700], // Customize background
            shape: RoundedRectangleBorder( // Rounded corners
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddCustomerScreen()));
      }

      print("New customer ID: ${newCustomer.id}");
      await prefs.setString('customerId', newCustomer.id);

      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();
      selectedCategory = 0; // Reset the category
      setState(() {}); // Update UI if you have a category UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Widget categoryCard(
      {required IconData icon, required String label, required int value}) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(8),
        child: Material(
          color: Color(0xFFD3D3D3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                selectedCategory = value;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 50,
                    color: selectedCategory == value
                        ? Colors.black
                        : Color(0xFFA9A9A9),
                  ),
                  SizedBox(height: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedCategory == value
                          ? Colors.black
                          : Color(0xFFA9A9A9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Detail'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  height: 22,
                ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    labelStyle:
                        const TextStyle(color: Colors.black, fontSize: 18),
                    hintText: "Your Customer's Full Name!",
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                    errorStyle: TextStyle(color: Colors.grey[800]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey, width: 2)),
                  ),
                  keyboardType: TextInputType.text,
                ),
                SizedBox(
                  height: 22,
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'PhoneNumber',
                    labelStyle:
                        const TextStyle(color: Colors.black, fontSize: 18),
                    hintText: "Your Customer's phoneNumber!",
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                    errorStyle: TextStyle(color: Colors.grey[800]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey, width: 2)),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(
                  height: 22,
                ),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle:
                        const TextStyle(color: Colors.black, fontSize: 18),
                    hintText: "For home delivery",
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                    errorStyle: TextStyle(color: Colors.grey[800]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey, width: 2)),
                  ),
                  keyboardType: TextInputType.text,
                ),
                SizedBox(
                  height: 22,
                ),
                Text(
                  "Select Category:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    categoryCard(icon: Icons.man, label: "Men", value: 1),
                    categoryCard(icon: Icons.woman, label: "Women", value: 2),
                    categoryCard(icon: Icons.boy, label: "Boy", value: 3),
                    categoryCard(icon: Icons.girl, label: "Girl", value: 4),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: _addCustomer,
                  child: const Text("Save Customer Details"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      // Shape
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            if (tailorId == null)
                 DrawerHeader(
              child: Center(child: CircularProgressIndicator()),
            ),StreamBuilder<DocumentSnapshot>(
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

                var tailorData = snapshot.data!.data() as Map<String, dynamic>;

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
                          backgroundImage: AssetImage('assets/image/Logo.png'),
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
                    builder: (context) => AddCustomerScreen(), // Removed semicolon here
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
