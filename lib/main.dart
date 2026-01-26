import 'package:english_words/english_words.dart'; // Provides the random word pairs
import 'package:flutter/material.dart'; // The core Flutter UI framework
import 'package:provider/provider.dart'; // Helps share data (state) across the app

void main() {
  runApp(MyApp()); // Starting point: tells Flutter to run the MyApp class
}

// This is the root of your application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider wraps the whole app so all screens can see 'MyAppState'
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        debugShowCheckedModeBanner: false, // Removes the red 'debug' banner
        theme: ThemeData(
          // Sets the overall color scheme based on a 'seed' color (Deep Orange)
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(), // The first screen shown to the user
      ),
    );
  }
}

// --- STATE MANAGEMENT ---
// This class stores the app's "brain": the data and the functions to change it
class MyAppState extends ChangeNotifier {
  var current = WordPair.random(); // Stores the current word pair displayed

  // Generates a new word and tells the UI to refresh
  void getNext() {
    current = WordPair.random();
    notifyListeners(); // This triggers the UI to rebuild with the new word
  }

  var favorites = <WordPair>[]; // A list (array) to store liked words

  // Adds or removes the current word from the favorites list
  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners(); // Updates the UI (e.g., changes the heart icon)
  }

  // Removes a specific word pair from favorites (used in the Favorites tab)
  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

// --- MAIN SCREEN WITH NAVIGATION ---
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex =
      0; // Tracks which tab is active (0 for Home, 1 for Favorites)

  @override
  Widget build(BuildContext context) {
    Widget page;
    // Decides which widget (page) to show based on the selected index
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // LayoutBuilder helps make the app responsive to screen size
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              // SafeArea ensures the menu doesn't overlap with notches or status bars
              SafeArea(
                child: NavigationRail(
                  // If the screen is wide (>= 600px), show text labels next to icons
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    // Update the index and rebuild the UI when a user clicks a tab
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              // Expanded takes up all remaining space for the actual page content
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- TAB 1: GENERATOR PAGE ---
class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // watch<MyAppState> tells this widget: "If the state changes, rebuild me!"
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    // Logic to decide which heart icon to show
    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair), // The stylized card showing the word
          SizedBox(height: 10), // Empty space between elements
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- STYLIZED WORD CARD ---
class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    // Defines the text style using the app's theme settings
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          pair.asLowerCase,
          style: style,
          // Accessibility label for screen readers
          semanticsLabel: pair.asPascalCase,
        ),
      ),
    );
  }
}

// --- TAB 2: FAVORITES PAGE ---
class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    // If the list is empty, show a centered message
    if (appState.favorites.isEmpty) {
      return Center(child: Text('No favorites yet.'));
    }

    // A scrollable list of liked words
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'You have ${appState.favorites.length} favorites:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        // A 'for-in' loop that creates a ListTile for every word in the list
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
            // Trash icon to delete the item from favorites
            trailing: IconButton(
              icon: Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              onPressed: () {
                appState.removeFavorite(pair);
              },
            ),
          ),
      ],
    );
  }
}
