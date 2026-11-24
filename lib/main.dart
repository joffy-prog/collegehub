import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CollegeHub());
}

class CollegeHub extends StatelessWidget {
  const CollegeHub({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CollegeHub',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        //debugPrint('LOGGED IN UID: ${user?.uid}');

        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text('Unable to load your account role.')),
              );
            }

            if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'Your account has no assigned role. Contact an administrator.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final role = roleSnapshot.data!.data()?['role'];

            if (role != 'admin' && role != 'lecturer') {
              return const Scaffold(
                body: Center(child: Text('Access denied. Invalid user role.')),
              );
            }

            return HomeScreen(userRole: role);
          },
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  Future<void> authenticate() async {
    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CollegeHub'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blue),
            const SizedBox(height: 20),

            Text(
              isLogin ? 'Welcome Back' : 'Create Account',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : authenticate,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(isLogin ? 'Login' : 'Register'),
              ),
            ),

            TextButton(
              onPressed: () {
                setState(() => isLogin = !isLogin);
              },
              child: Text(
                isLogin
                    ? "Don't have an account? Register"
                    : 'Already have an account? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String userRole;

  const HomeScreen({super.key, required this.userRole});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CollegeHub Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.school, size: 45, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'CollegeHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'College Management System',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Students'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StudentManagementScreen(userRole: userRole),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Courses'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CourseManagementScreen(userRole: userRole),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Enrollments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EnrollmentManagementScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Reports & Analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to CollegeHub!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              'Logged in as: ${FirebaseAuth.instance.currentUser?.email ?? 'Unknown user'}',
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage your students, courses and enrollments.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .snapshots(),
              builder: (context, snapshot) {
                return StatCard(
                  title: 'Total Students',
                  count: snapshot.data?.docs.length ?? 0,
                  icon: Icons.people,
                  color: Colors.blue,
                );
              },
            ),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .snapshots(),
              builder: (context, snapshot) {
                return StatCard(
                  title: 'Total Courses',
                  count: snapshot.data?.docs.length ?? 0,
                  icon: Icons.menu_book,
                  color: Colors.green,
                );
              },
            ),

            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('enrollments')
                  .snapshots(),
              builder: (context, snapshot) {
                return StatCard(
                  title: 'Total Enrollments',
                  count: snapshot.data?.docs.length ?? 0,
                  icon: Icons.assignment,
                  color: Colors.orange,
                );
              },
            ),

            const SizedBox(height: 25),

            const Text(
              'Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            ManagementCard(
              title: 'Students',
              subtitle: 'Register and manage students',
              icon: Icons.people,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentManagementScreen(userRole: userRole),
                  ),
                );
              },
            ),

            ManagementCard(
              title: 'Courses',
              subtitle: 'Add and manage courses',
              icon: Icons.menu_book,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseManagementScreen(userRole: userRole),
                  ),
                );
              },
            ),

            ManagementCard(
              title: 'Enrollments',
              subtitle: 'Manage student enrollments and grades',
              icon: Icons.assignment,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EnrollmentManagementScreen(),
                  ),
                );
              },
            ),
            ManagementCard(
              title: 'Reports & Analytics',
              subtitle: 'View college statistics and performance',
              icon: Icons.analytics,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          count.toString(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ManagementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const ManagementCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title will be built next.',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class StudentManagementScreen extends StatefulWidget {
  final String userRole;

  const StudentManagementScreen({super.key, required this.userRole});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final CollectionReference students = FirebaseFirestore.instance.collection(
    'students',
  );
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

  Future<void> showStudentForm({DocumentSnapshot? student}) async {
    final isEditing = student != null;
    final data = student?.data() as Map<String, dynamic>?;

    final idController = TextEditingController(text: data?['studentID'] ?? '');

    final nameController = TextEditingController(
      text: data?['studentName'] ?? '',
    );

    final phoneController = TextEditingController(
      text: data?['phoneNumber'] ?? '',
    );

    String gender = data?['gender'] ?? 'Male';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Student' : 'Register Student'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      enabled: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Student ID',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Student Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Male', 'Female', 'Other'].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            gender = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final id = idController.text.trim();
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();

                    if (id.isEmpty || name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                        ),
                      );
                      return;
                    }
                    if (idController.text.trim().isEmpty ||
                        nameController.text.trim().isEmpty ||
                        phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all student details.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final ref = students.doc(isEditing ? student.id : id);

                    try {
                      if (isEditing) {
                        await ref.update({
                          'studentName': name,
                          'gender': gender,
                          'phoneNumber': phone,
                        });
                      } else {
                        final existing = await ref.get();

                        if (existing.exists) {
                          throw Exception('Student ID already exists');
                        }
                        await ref.set({
                          'studentID': id,
                          'studentName': name,
                          'gender': gender,
                          'phoneNumber': phone,
                        });
                      }

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Student updated successfully'
                                : 'Student registered successfully',
                          ),
                        ),
                      );
                    } on FirebaseException catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Firebase error: ${e.message}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    idController.dispose();
    nameController.dispose();
    phoneController.dispose();
  }

  Future<void> deleteStudent(String id) async {
    try {
      await students.doc(id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting student: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name or ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: students.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allStudents = snapshot.data!.docs;

                final studentList = allStudents.where((student) {
                  final data = student.data() as Map<String, dynamic>;

                  final name = (data['studentName'] ?? '')
                      .toString()
                      .toLowerCase();

                  final id = (data['studentID'] ?? '').toString().toLowerCase();

                  return name.contains(searchQuery) || id.contains(searchQuery);
                }).toList();

                if (studentList.isEmpty) {
                  return Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? 'No students registered yet.'
                          : 'No matching students found.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: studentList.length,
                  itemBuilder: (context, index) {
                    final student = studentList[index];
                    final data = student.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(data['studentName'] ?? 'Unknown'),
                        subtitle: Text(
                          'ID: ${data['studentID']}\n'
                          'Gender: ${data['gender']}\n'
                          'Phone: ${data['phoneNumber']}',
                        ),
                        isThreeLine: true,
                        trailing: widget.userRole == 'admin'
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    showStudentForm(student: student);
                                  } else if (value == 'delete') {
                                    deleteStudent(student.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: widget.userRole == 'admin'
          ? FloatingActionButton(
              onPressed: () => showStudentForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class CourseManagementScreen extends StatefulWidget {
  final String userRole;

  const CourseManagementScreen({super.key, required this.userRole});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final CollectionReference courses = FirebaseFirestore.instance.collection(
    'courses',
  );
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

  Future<void> showCourseForm({DocumentSnapshot? course}) async {
    if (widget.userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only administrators can manage courses')),
      );
      return;
    }
    final isEditing = course != null;
    final data = course?.data() as Map<String, dynamic>?;

    final idController = TextEditingController(text: data?['courseID'] ?? '');
    final nameController = TextEditingController(
      text: data?['courseName'] ?? '',
    );
    final lecturerController = TextEditingController(
      text: data?['lecturerName'] ?? '',
    );
    final semesterController = TextEditingController(
      text: data?['semester'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Course' : 'Add Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  enabled: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Course ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: lecturerController,
                  decoration: const InputDecoration(
                    labelText: 'Lecturer Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: semesterController,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    hintText: 'e.g. Semester 1',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final id = idController.text.trim();
                final name = nameController.text.trim();
                final lecturer = lecturerController.text.trim();
                final semester = semesterController.text.trim();

                if (id.isEmpty ||
                    name.isEmpty ||
                    lecturer.isEmpty ||
                    semester.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all course details'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final ref = courses.doc(isEditing ? course.id : id);

                  if (isEditing) {
                    await ref.update({
                      'courseName': name,
                      'lecturerName': lecturer,
                      'semester': semester,
                    });
                  } else {
                    final existing = await ref.get();

                    if (existing.exists) {
                      throw Exception('Course ID already exists');
                    }

                    await ref.set({
                      'courseID': id,
                      'courseName': name,
                      'lecturerName': lecturer,
                      'semester': semester,
                    });
                  }

                  if (!mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Course updated successfully'
                            : 'Course added successfully',
                      ),
                    ),
                  );
                } on FirebaseException catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Firebase Error: ${e.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        );
      },
    );

    idController.dispose();
    nameController.dispose();
    lecturerController.dispose();
    semesterController.dispose();
  }

  Future<void> deleteCourse(String id) async {
    if (widget.userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only administrators can delete courses')),
      );
      return;
    }
    try {
      await courses.doc(id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by course name, ID or lecturer...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: courses.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final courseDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final courseName = (data['courseName'] ?? '')
                      .toString()
                      .toLowerCase();

                  final courseID = (data['courseID'] ?? '')
                      .toString()
                      .toLowerCase();

                  final lecturerName = (data['lecturerName'] ?? '')
                      .toString()
                      .toLowerCase();

                  return courseName.contains(searchQuery) ||
                      courseID.contains(searchQuery) ||
                      lecturerName.contains(searchQuery);
                }).toList();

                if (courseDocs.isEmpty) {
                  return const Center(child: Text('No courses found'));
                }

                return ListView.builder(
                  itemCount: courseDocs.length,
                  itemBuilder: (context, index) {
                    final doc = courseDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.book)),
                        title: Text(data['courseName'] ?? ''),
                        subtitle: Text(
                          'ID: ${data['courseID'] ?? ''}\n'
                          'Lecturer: ${data['lecturerName'] ?? ''}\n'
                          'Semester: ${data['semester'] ?? ''}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: widget.userRole == 'admin'
          ? FloatingActionButton(
              onPressed: () => showCourseForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class EnrollmentManagementScreen extends StatefulWidget {
  const EnrollmentManagementScreen({super.key});

  @override
  State<EnrollmentManagementScreen> createState() =>
      _EnrollmentManagementScreenState();
}

class _EnrollmentManagementScreenState
    extends State<EnrollmentManagementScreen> {
  final enrollments = FirebaseFirestore.instance.collection('enrollments');

  final students = FirebaseFirestore.instance.collection('students');

  final courses = FirebaseFirestore.instance.collection('courses');

  Future<void> showEnrollmentForm() async {
    final studentSnapshot = await students.get();
    final courseSnapshot = await courses.get();

    if (!mounted) return;

    if (studentSnapshot.docs.isEmpty || courseSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Register at least one student and one course first.'),
        ),
      );
      return;
    }

    String? selectedStudent;
    String? selectedCourse;

    final gradeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enroll Student'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Student',
                        border: OutlineInputBorder(),
                      ),
                      items: studentSnapshot.docs.map((doc) {
                        final data = doc.data();

                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(
                            '${data['studentName']} (${data['studentID']})',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStudent = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Course',
                        border: OutlineInputBorder(),
                      ),
                      items: courseSnapshot.docs.map((doc) {
                        final data = doc.data();

                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(
                            '${data['courseName']} (${data['courseID']})',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCourse = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: gradeController,
                      decoration: const InputDecoration(
                        labelText: 'Grade (optional)',
                        hintText: 'e.g. A, B, C',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (selectedStudent == null || selectedCourse == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select a student and a course.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final existing = await enrollments
                          .where('studentID', isEqualTo: selectedStudent)
                          .where('courseID', isEqualTo: selectedCourse)
                          .get();

                      if (existing.docs.isNotEmpty) {
                        throw Exception(
                          'This student is already enrolled in this course.',
                        );
                      }

                      await enrollments.add({
                        'studentID': selectedStudent,
                        'courseID': selectedCourse,
                        'grade': gradeController.text.trim().isEmpty
                            ? null
                            : gradeController.text.trim(),
                        'enrolledAt': FieldValue.serverTimestamp(),
                      });

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enrollment created successfully.'),
                        ),
                      );
                    } on FirebaseException catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Firebase error: ${e.message}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Enroll'),
                ),
              ],
            );
          },
        );
      },
    );

    gradeController.dispose();
  }

  Future<void> updateGrade(String enrollmentId, String currentGrade) async {
    final controller = TextEditingController(text: currentGrade);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Grade'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Grade',
              hintText: 'e.g. A, B, C',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await enrollments.doc(enrollmentId).update({
                    'grade': controller.text.trim().isEmpty
                        ? null
                        : controller.text.trim(),
                  });

                  if (!mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Grade updated successfully.'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> deleteEnrollment(String id) async {
    try {
      await enrollments.doc(id).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrollment Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: enrollments.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final enrollmentList = snapshot.data!.docs;

          if (enrollmentList.isEmpty) {
            return const Center(
              child: Text(
                'No enrollments found. Press + to enroll a student.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: enrollmentList.length,
            itemBuilder: (context, index) {
              final enrollment = enrollmentList[index];
              final data = enrollment.data() as Map<String, dynamic>;

              final studentId = data['studentID'];
              final courseId = data['courseID'];

              return FutureBuilder(
                future: Future.wait([
                  students.doc(studentId).get(),
                  courses.doc(courseId).get(),
                ]),
                builder: (context, detailsSnapshot) {
                  if (!detailsSnapshot.hasData) {
                    return const Card(
                      child: ListTile(title: Text('Loading enrollment...')),
                    );
                  }

                  final studentData =
                      detailsSnapshot.data![0].data() as Map<String, dynamic>?;

                  final courseData =
                      detailsSnapshot.data![1].data() as Map<String, dynamic>?;

                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.assignment),
                      ),

                      title: Text(
                        studentData?['studentName'] ?? 'Unknown Student',
                      ),

                      subtitle: Text(
                        'Course: ${courseData?['courseName'] ?? 'Unknown Course'}\n'
                        'Grade: ${data['grade'] ?? 'Not yet graded'}',
                      ),

                      isThreeLine: true,

                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'grade') {
                            updateGrade(
                              enrollment.id,
                              data['grade']?.toString() ?? '',
                            );
                          } else if (value == 'delete') {
                            deleteEnrollment(enrollment.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'grade',
                            child: Text('Update Grade'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Enrollment'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: showEnrollmentForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('students').snapshots(),
        builder: (context, studentSnapshot) {
          if (!studentSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: db.collection('courses').snapshots(),
            builder: (context, courseSnapshot) {
              if (!courseSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<QuerySnapshot>(
                stream: db.collection('enrollments').snapshots(),
                builder: (context, enrollmentSnapshot) {
                  if (!enrollmentSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final studentDocs = studentSnapshot.data!.docs;

                  final courseDocs = courseSnapshot.data!.docs;

                  final enrollmentDocs = enrollmentSnapshot.data!.docs;

                  // Calculate grade distribution.
                  final Map<String, int> grades = {};

                  for (final enrollment in enrollmentDocs) {
                    final data = enrollment.data() as Map<String, dynamic>;

                    final grade = data['grade']?.toString();

                    if (grade != null && grade.isNotEmpty) {
                      grades[grade] = (grades[grade] ?? 0) + 1;
                    }
                  }

                  // Calculate enrollments per course.
                  final Map<String, int> courseCounts = {};

                  for (final enrollment in enrollmentDocs) {
                    final data = enrollment.data() as Map<String, dynamic>;

                    final courseId = data['courseID']?.toString();

                    if (courseId != null) {
                      courseCounts[courseId] =
                          (courseCounts[courseId] ?? 0) + 1;
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'College Performance Overview',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Live statistics from your college database.',
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      // Summary cards.
                      _reportCard(
                        'Total Students',
                        studentDocs.length,
                        Icons.people,
                        Colors.blue,
                      ),

                      _reportCard(
                        'Total Courses',
                        courseDocs.length,
                        Icons.menu_book,
                        Colors.green,
                      ),

                      _reportCard(
                        'Total Enrollments',
                        enrollmentDocs.length,
                        Icons.assignment,
                        Colors.orange,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Enrollments by Course',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (courseDocs.isEmpty)
                        const Text('No courses available yet.'),

                      ...courseDocs.map((course) {
                        final data = course.data() as Map<String, dynamic>;

                        final count = courseCounts[course.id] ?? 0;

                        return Card(
                          child: ListTile(
                            title: Text(data['courseName'] ?? 'Unknown Course'),
                            subtitle: Text('Course ID: ${data['courseID']}'),
                            trailing: Text(
                              '$count students',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      const Text(
                        'Grade Distribution',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (grades.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No grades recorded yet.'),
                          ),
                        ),

                      ...grades.entries.map((entry) {
                        final totalGraded = grades.values.fold<int>(
                          0,
                          (sum, count) => sum + count,
                        );

                        final percentage = totalGraded == 0
                            ? 0.0
                            : entry.value / totalGraded;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Grade ${entry.key}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('${entry.value} students'),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 10,
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  '${(percentage * 100).toStringAsFixed(1)}%',
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _reportCard(String title, int count, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          count.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
