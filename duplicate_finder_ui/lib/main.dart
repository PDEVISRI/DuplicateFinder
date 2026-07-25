import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DuplicateFinderApp());
}

// MODEL
class DuplicateGroup {
  String original;
  List<String> duplicates;
  List<bool> selected;

  DuplicateGroup({
    required this.original,
    required this.duplicates,
  }) : selected = List.filled(duplicates.length, true);

  factory DuplicateGroup.fromJson(Map<String, dynamic> json) {
    List<String> dups = List<String>.from(json['duplicatePaths'] ?? []);
    return DuplicateGroup(
      original: json['originalPath'] ?? '',
      duplicates: dups,
    );
  }
}

class DuplicateFinderApp extends StatelessWidget {
  const DuplicateFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Duplicate Finder",
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedFolder;
  String scanResult = "";
  bool isScanning = false;

  List<DuplicateGroup> groups = [];

  Future<void> selectFolder() async {
    String? path = await FilePicker.platform.getDirectoryPath();

    if (path != null) {
      setState(() {
        selectedFolder = path;
      });
    }
  }

  Future<void> scanFiles() async {
    if (selectedFolder == null) {
      setState(() {
        scanResult = "Please select a folder first";
      });
      return;
    }

    setState(() {
      isScanning = true;
      scanResult = "Scanning files via Spring Boot backend...";
      groups.clear();
    });

    try {
      final uri = Uri.parse(
          'http://localhost:8080/api/scan?path=${Uri.encodeComponent(selectedFolder!)}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = jsonDecode(response.body);

        List<DuplicateGroup> fetchedGroups = jsonList
            .map((item) => DuplicateGroup.fromJson(item))
            .where((group) => group.original.isNotEmpty && group.duplicates.isNotEmpty)
            .toList();

        setState(() {
          groups = fetchedGroups;
          scanResult = groups.isEmpty
              ? "No duplicate files found"
              : "${groups.length} duplicate group(s) found";
          isScanning = false;
        });
      } else {
        setState(() {
          scanResult = "Backend error: Server returned status code ${response.statusCode}";
          isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        scanResult = "Error connecting to Spring Boot server: $e";
        isScanning = false;
      });
    }
  }

  void deleteSelectedFiles() {
    int deletedCount = 0;

    for (var group in groups) {
      for (int i = 0; i < group.duplicates.length; i++) {
        if (i < group.selected.length && group.selected[i]) {
          File file = File(group.duplicates[i]);

          if (file.existsSync()) {
            try {
              file.deleteSync();
              deletedCount++;
            } catch (e) {
              debugPrint("Delete error: $e");
            }
          }
        }
      }
    }

    setState(() {
      scanResult = "$deletedCount file(s) deleted";
      groups.clear();
    });
  }

  void confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text(
              "Are you sure you want to delete the selected duplicate files?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                deleteSelectedFiles();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Delete"),
            )
          ],
        );
      },
    );
  }

  Widget showFileImage(String path) {
    File file = File(path);

    if (!file.existsSync()) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.orange, size: 40),
      );
    }

    String extension = path.toLowerCase();

    if (extension.endsWith(".jpg") ||
        extension.endsWith(".jpeg") ||
        extension.endsWith(".png") ||
        extension.endsWith(".webp") ||
        extension.endsWith(".gif")) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
      );
    }

    return const Center(
      child: Icon(Icons.insert_drive_file, size: 40, color: Colors.blueGrey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Duplicate File Finder"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              children: [
                const Icon(
                  Icons.folder_open,
                  size: 60,
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: selectFolder,
                  icon: const Icon(Icons.folder),
                  label: const Text("Select Folder"),
                ),
                if (selectedFolder != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      selectedFolder!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 10),
                isScanning
                    ? const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text("Scanning in progress..."),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: scanFiles,
                        icon: const Icon(Icons.search),
                        label: const Text("Scan for Duplicates"),
                      ),
                const SizedBox(height: 10),
                Text(
                  scanResult,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: groups.isEmpty
                ? const Center(child: Text("No scan results to display."))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final allFiles = [group.original, ...group.duplicates];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Group ${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: allFiles.length,
                                itemBuilder: (context, i) {
                                  bool isOriginal = (i == 0);
                                  int dupIndex = i - 1;

                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isOriginal
                                            ? Colors.green
                                            : Colors.red.shade200,
                                        width: isOriginal ? 2.5 : 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        // Header Badge
                                        Container(
                                          width: double.infinity,
                                          color: isOriginal
                                              ? Colors.green
                                              : Colors.red.shade100,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Text(
                                            isOriginal
                                                ? "Original"
                                                : "Duplicate",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isOriginal
                                                  ? Colors.white
                                                  : Colors.red.shade900,
                                            ),
                                          ),
                                        ),
                                        // Image thumbnail / File icon
                                        Expanded(
                                          child: ClipRRect(
                                            child: showFileImage(allFiles[i]),
                                          ),
                                        ),
                                        // Deletion Selection Controls
                                        if (!isOriginal &&
                                            dupIndex < group.selected.length)
                                          Checkbox(
                                            value: group.selected[dupIndex],
                                            onChanged: (value) {
                                              setState(() {
                                                group.selected[dupIndex] =
                                                    value ?? false;
                                              });
                                            },
                                          )
                                        else
                                          const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Icon(
                                              Icons.lock,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: confirmDelete,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text(
                    "Delete Selected Files",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}