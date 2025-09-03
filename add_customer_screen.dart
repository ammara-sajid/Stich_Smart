import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tailors_app/home_screen.dart';
import 'package:tailors_app/login_page.dart';
import 'package:tailors_app/customer_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailors_app/order_list.dart';
import 'measurement_detail_screen.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({
    super.key,
  });

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  String? tailorId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadTailorId();
  }

  Future<void> _loadTailorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tailorId = prefs.getString('tailorId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Your Customers',
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
      body: tailorId == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Customers List',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    // This will refresh the StreamBuilder and screen
                                  });
                                },
                                icon: const Icon(Icons.refresh,
                                    color: Colors.black),
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                          stream: tailorId == null
                              ? null
                              : _firestore
                                  .collection('tailors')
                                  .doc(tailorId)
                                  .collection('customers')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            // Check if the collection exists and has documents
                            if (snapshot.hasError) {
                              return const Center(
                                  child: Text('Something went wrong.'));
                            }

                            if (!snapshot.hasData ||
                                snapshot.data == null ||
                                snapshot.data!.docs.isEmpty) {
                              // Collection might not exist yet, or is empty
                              return const Center(
                                  child: Text('No customers added yet.'));
                            }

                            // If we reach here, subcollection exists and has customers
                            return ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                var customer = snapshot.data!.docs[index];
                                return InkWell(
                                  onTap: () {
                                    // Navigate to the OrderListScreen (replace with your actual screen)
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderList(
                                          customerId: customer.id,
                                          tailorId: tailorId!,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 3,
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person),
                                          const SizedBox(width: 12),
                                          // Expanded to push menu to right
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  customer.data().toString().contains('name')
                                                      ? customer['name']
                                                      : 'No Name',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                SizedBox(height: 6.5,),
                                                Text(
                                                  customer.data().toString().contains('phone')
                                                      ? "Phone: ${customer['phone']}"
                                                      : "Phone: Not available",
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            onSelected: (value) async {
                                              if (value == 'edit') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => CustomerDetailScreen(
                                                      isEdit: true,
                                                      customerId: customer.id,
                                                      customerData: customer.data() as Map<String, dynamic>,
                                                      tailorId: tailorId!,
                                                    ),
                                                  ),
                                                );
                                              } else if (value == 'delete') {
                                                bool confirm = await showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Delete Customer'),
                                                    content: const Text(
                                                        'Are you sure you want to delete this customer?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        child: const Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm) {
                                                  await _firestore
                                                      .collection('tailors')
                                                      .doc(tailorId)
                                                      .collection('customers')
                                                      .doc(customer.id)
                                                      .delete();
                                                }
                                              }
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );

                              },
                            );
                          },
                        )),
                        const SizedBox(height: 10),
                        ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      CustomerDetailScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 40),
                              shape: RoundedRectangleBorder(
                                // Shape
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text('Add Customer')),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
