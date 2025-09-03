import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailors_app/add_customer_screen.dart';
import 'package:tailors_app/measurement_detail_screen.dart';
import 'home_screen.dart';
import 'login_page.dart';
import 'order_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailors_app/chose_category.dart';

class OrderList extends StatefulWidget {
  final String customerId;
  final String tailorId;
  const OrderList({super.key, required this.customerId, required this.tailorId});

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  String? tailorId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = true;


  late DateTime now;
  late String formattedDate;
  String? customerName;
  String? customerPhone;
  String? customerAddress;
  Future<void> _fetchCustomerData() async {
    try {

      var doc = await _firestore
          .collection('tailors')
          .doc(widget.tailorId)
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
      setState(() {
        isLoading = false;
      });
    }
  }

  void initState() {
    super.initState();
    _loadTailorId();
    _fetchCustomerData(); // <-- add this line!
  }
  Future<void> _loadTailorId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tailorId = prefs.getString('tailorId');
    });
  }


  Future<void> _addOrder() async {
    try {
      DocumentReference orderRef = await _firestore
          .collection('tailors')
          .doc(widget.tailorId)
          .collection('customers')
          .doc(widget.customerId)
          .collection('orders')
          .add({
        'createdAt': FieldValue.serverTimestamp(),
        'orderStatus': 'Pending',
        'deliveryDate': formattedDate,
        'orderNo': 01,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order created successfully!')),
      );
    } catch (e) {
      print('Error adding order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order.')),
      );
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
          Expanded(child: Text(value ?? '', style: TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    CollectionReference ordersRef = _firestore
        .collection('tailors')
        .doc(widget.tailorId)
        .collection('customers')
        .doc(widget.customerId)
        .collection('orders');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Order List',
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
            SizedBox(height: 20),
            ListTile(

              title: Text('Your Customers',style: TextStyle(fontWeight: FontWeight.bold),),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCustomerScreen(),
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
      body: isLoading
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
                    Text('Customer Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Divider(),
                    _buildInfoRow(Icons.person, 'Name', customerName),
                    _buildInfoRow(Icons.phone, 'Phone', customerPhone),
                    _buildInfoRow(Icons.home, 'Address', customerAddress),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: ordersRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('No orders to show.'),
                    ),
                  );
                }

                final orders = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index];
                    var orderId = order.id;
                    var status = order['orderStatus'] ?? 'Pending';
                    var deliveryDate = order['deliveryDate'] ?? 'No Date';
                    var data = order.data() as Map<String, dynamic>?;
                    var orderNo = data != null && data.containsKey('orderNo') ? data['orderNo'].toString() : 'N/A';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.shopping_bag),
                        title: Text('Order No: $orderNo'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: $status'),
                            Text('Delivery Date: $deliveryDate'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailScreen(
                                    customerId: widget.customerId,
                                    tailorId: widget.tailorId,
                                    orderId: orderId, // pass this for editing
                                    isEdit: true,
                                    orderData: order.data() as Map<String, dynamic>,
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              bool confirm = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Delete Order'),
                                  content: Text('Are you sure you want to delete this order?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text('Delete', style: TextStyle(color: Colors.black)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm) {
                                await ordersRef.doc(orderId).delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Order deleted')),
                                );
                              }
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MeasurementDetailScreen(
                              customerId: widget.customerId,
                              tailorId: widget.tailorId,
                              orderId: orderId, // you might need orderId to fetch measurements
                            ),
                          ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),

      ),


      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      OrderDetailScreen(
                        customerId: widget.customerId, // FIX: use widget.customerId
                        tailorId: widget.tailorId,
                      )));
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
            child: Text('Add New Order')),
      ),
    );
  }
}
