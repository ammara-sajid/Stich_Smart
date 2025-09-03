import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_customer_screen.dart';
import 'login_page.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? tailorId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  Future<int> getTotalCustomers() async {
    final snapshot = await _firestore
        .collection('tailors')
        .doc(tailorId)
        .collection('customers')
        .get();
    return snapshot.docs.length;
  }
  Future<List<Map<String, dynamic>>> getOrdersPerCustomer() async {
    List<Map<String, dynamic>> result = [];
    final customerSnapshot = await _firestore
        .collection('tailors')
        .doc(tailorId)
        .collection('customers')
        .get();

    for (var doc in customerSnapshot.docs) {
      final orderSnapshot = await _firestore
          .collection('tailors')
          .doc(tailorId)
          .collection('customers')
          .doc(doc.id)
          .collection('orders')
          .get();

      result.add({
        'customerName': doc['name'],
        'orderCount': orderSnapshot.docs.length,
      });
    }

    return result;
  }
  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    List<Map<String, dynamic>> result = [];

    final customerSnapshot = await _firestore
        .collection('tailors')
        .doc(tailorId)
        .collection('customers')
        .get();

    for (var doc in customerSnapshot.docs) {
      final orders = await _firestore
          .collection('tailors')
          .doc(tailorId)
          .collection('customers')
          .doc(doc.id)
          .collection('orders')
          .where('status', isEqualTo: status)
          .get();

      for (var order in orders.docs) {
        result.add({
          'customerName': doc['name'],
          'orderId': order.id,
        });
      }
    }

    return result;
  }
  Future<List<Map<String, dynamic>>> getRecentCustomers() async {
    final snapshot = await _firestore
        .collection('tailors')
        .doc(tailorId)
        .collection('customers')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    return snapshot.docs
        .map((doc) => {'name': doc['name'], 'phone': doc['phone']})
        .toList();
  }
  Future<List<Map<String, dynamic>>> getRecentOrders() async {
    List<Map<String, dynamic>> result = [];

    final customerSnapshot = await _firestore
        .collection('tailors')
        .doc(tailorId)
        .collection('customers')
        .get();

    for (var customer in customerSnapshot.docs) {
      final orders = await _firestore
          .collection('tailors')
          .doc(tailorId)
          .collection('customers')
          .doc(customer.id)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      for (var order in orders.docs) {
        result.add({
          'customerName': customer['name'],
          'orderId': order.id,
        });
      }
    }

    return result;
  }

  Widget buildDashboard() {
    if (tailorId == null) return Center(child: CircularProgressIndicator());

    return FutureBuilder(
      future: Future.wait([
        getTotalCustomers(),
        getOrdersPerCustomer(),
        getOrdersByStatus('pending'),
        getOrdersByStatus('delivered'),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) return Center(child: Text('No data available'));

        final totalCustomers = snapshot.data![0] as int;
        final ordersPerCustomer = snapshot.data![1] as List;
        final pendingOrders = snapshot.data![2] as List;
        final deliveredOrders = snapshot.data![3] as List;

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Dashboard Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              // Summary Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard("Customers", totalCustomers.toString(), Icons.people, Colors.black),
                  _buildStatCard("Pending", pendingOrders.length.toString(), Icons.schedule, Colors.black),
                  _buildStatCard("Delivered", deliveredOrders.length.toString(), Icons.check_circle, Colors.black),
                ],
              ),
              SizedBox(height: 24),
              // Orders per Customer
              _buildSectionCard(
                title: "Orders Per Customer",
                children: ordersPerCustomer.map<Widget>((e) {
                  return ListTile(
                    leading: Icon(Icons.person),
                    title: Text(e['customerName']),
                    trailing: Text("${e['orderCount']} orders"),
                  );
                }).toList(),
              ),

              SizedBox(height: 16),

              // Pending Orders
              _buildSectionCard(
                title: "Pending Orders",
                children: pendingOrders.isEmpty
                    ? [ListTile(title: Text("No pending orders"))]
                    : pendingOrders.map<Widget>((e) {
                  return ListTile(
                    leading: Icon(Icons.hourglass_top),
                    title: Text(e['customerName']),
                    subtitle: Text("Order ID: ${e['orderId']}"),
                  );
                }).toList(),
              ),


              SizedBox(height: 16),

              // Delivered Orders
              _buildSectionCard(
                title: "Delivered Orders",
                children: deliveredOrders.isEmpty
                    ? [ListTile(title: Text("No delivered orders"))]
                    : deliveredOrders.map<Widget>((e) {
                  return ListTile(
                    leading: Icon(Icons.done),
                    title: Text(e['customerName']),
                    subtitle: Text("Order ID: ${e['orderId']}"),
                  );
                }).toList(),
              ),
              SizedBox(height: 10,),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddCustomerScreen()),
                  );
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
                child: Text('Customer List'),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              SizedBox(height: 8),
              Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: tailorId == null
            ? Text(
          'Welcome',
          style: TextStyle(color: Colors.white),
        )
            : StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('tailors').doc(tailorId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(
                'Welcome...',
                style: TextStyle(color: Colors.white),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
              return Text(
                'Welcome',
                style: TextStyle(color: Colors.white),
              );
            }

            var tailorData = snapshot.data!.data() as Map<String, dynamic>;
            return Text(
              'Welcome ${tailorData['fullName'] ?? ''}',
              style: TextStyle(color: Colors.white),
            );
          },
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: tailorId == null
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
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

            Spacer(),
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
            SizedBox(height: 15,)
          ],
        ),
      ),
      body: buildDashboard(),

    );

  }
}
