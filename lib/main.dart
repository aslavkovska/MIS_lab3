import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'firebase_options.dart';
import 'exam.dart';
import 'map.dart';
import 'calendar.dart';
import 'notifications.dart';
import 'notifications_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelGroupKey: "basic_channel_group",
      channelKey: "basic_channel",
      channelName: "basic_notif",
      channelDescription: "basic notification channel",
    )
  ], channelGroups: [
    NotificationChannelGroup(
        channelGroupKey: "basic_channel_group", channelGroupName: "basic_group")
  ]);

  bool isAllowedToSendNotification =
  await AwesomeNotifications().isNotificationAllowed();

  if (!isAllowedToSendNotification) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const MainListScreen(),
        '/login': (context) => const AuthScreen(isLogin: true),
        '/register': (context) => const AuthScreen(isLogin: false),
      },
    );
  }
}

class MainListScreen extends StatefulWidget {
  const MainListScreen({super.key});

  @override
  MainListScreenState createState() => MainListScreenState();
}

class MainListScreenState extends State<MainListScreen> {
  final List<Exam> exams = [
    Exam(course: 'Mobilni IS', timestamp: DateTime(2024, 02, 10, 13, 00)),
    Exam(course: 'VNP', timestamp: DateTime(2023, 12, 23, 14, 0))
  ];

  bool isLocationBasedNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceiveMethod,
        onDismissActionReceivedMethod:
        NotificationController.onDismissActionReceiveMethod,
        onNotificationCreatedMethod:
        NotificationController.onNotificationCreateMethod,
        onNotificationDisplayedMethod:
        NotificationController.onNotificationDisplayed);
    NotificationService().scheduleNotificationsForExistingExams(exams);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_add),
            color: isLocationBasedNotificationsEnabled
                ? Colors.amberAccent
                : Colors.grey,
            onPressed: toggleLocationNotifications,
          ),
          IconButton(
              onPressed: map,
              icon: const Icon(Icons.map)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => FirebaseAuth.instance.currentUser != null
                ? addExam(context)
                : signInPage(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final course = exams[index].course;
          final timestamp = exams[index].timestamp;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Date: ${timestamp.toString().split(' ')[0]}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Time: ${timestamp.toString().split(' ')[1].substring(0, 5)}',
                    style: const TextStyle(color: Colors.grey),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void toggleLocationNotifications() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Based Notifications"),
          content: isLocationBasedNotificationsEnabled
              ? const Text("You have turned off location-based notifications")
              : const Text("You have turned on location-based notifications"),
          actions: [
            TextButton(
              onPressed: () {
                NotificationService().toggleLocationNotification();
                setState(() {
                  isLocationBasedNotificationsEnabled =
                  !isLocationBasedNotificationsEnabled;
                });
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  void calendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarWidget(exams: exams),
      ),
    );
  }

  void map() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const MapWidget()));
  }

  Future<void> addExam(BuildContext context) async {
    return showModalBottomSheet(
        context: context,
        builder: (_) {
          return GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: ExamWidget(
              addExam: addExamFunction,
            ),
          );
        });
  }

  void addExamFunction(Exam exam) {
    setState(() {
      exams.add(exam);
        NotificationService().scheduleNotification(exam);
    });
  }


  void signInPage(BuildContext context) {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

class AuthScreen extends StatefulWidget {
  final bool isLogin;

  const AuthScreen({super.key, required this.isLogin});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
  GlobalKey<ScaffoldMessengerState>();

  Future<void> _authAction() async {
    try {
      if (widget.isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        successDialog(
            "Login Successful", "You have successfully logged in!");
        homePage();
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        successDialog(
            "Registration Successful", "You have successfully registered!");
        loginPage();
      }
    } catch (e) {
      errorDialog(
          "Authentication Error", "Error during authentication: $e");
    }
  }

  void successDialog(String title, String message) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  void errorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void homePage() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  void loginPage() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  void registerPage() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacementNamed(context, '/register');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.isLogin ? const Text("Login") : const Text("Register"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authAction,
              child: Text(widget.isLogin ? "Login" : "Register"),
            ),
            if (!widget.isLogin)
              ElevatedButton(
                onPressed: loginPage,
                child: const Text('Already have an account?'),
              ),
            if (widget.isLogin)
              ElevatedButton(
                onPressed: registerPage,
                child: const Text('Register'),
              ),
            ElevatedButton(
              onPressed: homePage,
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}