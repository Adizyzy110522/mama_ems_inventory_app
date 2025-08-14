import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/status_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/custom_bottom_nav.dart';
import 'providers/order_provider.dart';
import 'providers/product_manager.dart';
import 'providers/theme_provider.dart';
import 'config/app_theme.dart';

void main() {
  // Run everything in the same zone
  runApp(const InventoryApp());
}

// Initialize the app and database
Future<void> _initializeApp() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database factory based on platform
  if (kIsWeb) {
    // Use FFI web implementation for web platform
    databaseFactory = databaseFactoryFfiWeb;
    debugPrint('Initialized database factory for web');
  } else if (!kIsWeb) {
    try {
      if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
        // Use FFI for desktop platforms
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        debugPrint('Initialized database factory for desktop');
      }
    } catch (e) {
      // This catch block handles the case where io.Platform is accessed in web
      debugPrint('Error initializing database factory: $e');
    }
  }
  // Mobile platforms use the default sqflite implementation
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
}

class InventoryApp extends StatefulWidget {
  const InventoryApp({super.key});

  @override
  State<InventoryApp> createState() => _InventoryAppState();
}

class _InventoryAppState extends State<InventoryApp> {
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp().then((_) {
      setState(() {
        _isInitialized = true;
      });
    }).catchError((e) {
      setState(() {
        _error = e.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // If still initializing, show a loading indicator
    if (!_isInitialized) {
      return MaterialApp(
        title: 'Loading...',
        home: Scaffold(
          body: Center(
            child: _error != null
                ? Text('Error initializing app: $_error')
                : const CircularProgressIndicator(),
          ),
        ),
      );
    }

    // App is initialized
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ProductManager(),
        ),
        ChangeNotifierProxyProvider<ProductManager, OrderProvider>(
          create: (context) => OrderProvider(),
          update: (context, productManager, previous) {
            // Create or update the OrderProvider based on the currently selected product
            final provider = previous ?? OrderProvider(productCategory: productManager.currentProduct);
            provider.setProductCategory(productManager.currentProduct);
            return provider..loadOrders();
          },
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider()..initialize(), // Initialize theme provider
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'OMATA - Order Monitoring and Tracking App',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.isLoaded 
            ? themeProvider.getTheme() 
            : AppTheme.getTheme(), // Use theme provider when loaded
          home: const LandingScreen(), // Start with the landing page
          builder: (context, child) {
            // Add error boundary
            return _ErrorBoundary(child: child ?? const SizedBox());
          },
          // Define routes for navigation
          routes: {
            '/landing': (context) => const LandingScreen(),
            '/main': (context) => const MainPage(),
            '/home': (context) => const HomeScreen(),
            '/orders': (context) => const OrdersScreen(),
            '/schedule': (context) => const ScheduleScreen(),
            '/status': (context) => const StatusScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        ),
      ),
    );
  }
}

/// Widget to catch errors in the widget tree
class _ErrorBoundary extends StatefulWidget {
  final Widget child;
  
  const _ErrorBoundary({required this.child});
  
  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline, 
                size: 64, 
                color: AppTheme.cancelledColor
              ),
              const SizedBox(height: AppTheme.mediumSpacing),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: AppTheme.smallSpacing),
              const Text(
                'The application encountered an unexpected error',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.mediumSpacing),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Use ErrorWidget.builder to customize error display
    return widget.child;
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Catch errors thrown during build
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _hasError = true;
      return const SizedBox(); // Return empty widget to prevent further errors
    };
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    OrdersScreen(),
    ScheduleScreen(),
    StatusScreen(),
    SettingsScreen(),
  ];

  // This method is called when a tab is selected from the bottom navigation
  void _onTabSelected(int index) {
    // If switching to Orders tab (index 1), always reload all orders
    if (index == 1) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      // Reset any filtered orders and load all orders
      provider.loadOrders(refresh: true);
    }
    
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}