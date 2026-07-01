import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibehub/ui/theme/vibehub_theme.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_bloc.dart';
import 'package:vibehub/ui/bloc/repositories/repositories_event.dart';

class RepositorySearchHeader extends StatefulWidget {
  const RepositorySearchHeader({super.key});

  @override
  State<RepositorySearchHeader> createState() => _RepositorySearchHeaderState();
}

class _RepositorySearchHeaderState extends State<RepositorySearchHeader> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRegisterDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth / 3 < 400 ? 400 : screenWidth / 3,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Register New Repository',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: VibeHubTheme.slate850,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 13, color: VibeHubTheme.slate850),
                      decoration: InputDecoration(
                        labelText: 'Repository Name',
                        hintText: 'e.g. agent-sandbox',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: VibeHubTheme.slate150),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: VibeHubTheme.slate300),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: pathController,
                      style: const TextStyle(fontSize: 13, color: VibeHubTheme.slate850),
                      decoration: InputDecoration(
                        labelText: 'Local Path',
                        hintText: 'Select folder or enter path',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 4),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: VibeHubTheme.slate150),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: VibeHubTheme.slate300),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.folder_open_outlined, color: VibeHubTheme.slate400, size: 20),
                          tooltip: 'Select Folder',
                          onPressed: () async {
                            try {
                              final String? selectedPath = await getDirectoryPath();
                              if (selectedPath != null) {
                                pathController.text = selectedPath;
                                if (nameController.text.trim().isEmpty) {
                                  final lastSegment = p.basename(selectedPath);
                                  nameController.text = lastSegment;
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Folder picker unavailable: $e. You can type the path manually.'),
                                    backgroundColor: Colors.red.shade600,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a path.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: VibeHubTheme.slate400, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VibeHubTheme.slate600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () {
                            if (formKey.currentState?.validate() ?? false) {
                              context.read<RepositoriesBloc>().add(
                                    RepositoryRegisterRequested(
                                      name: nameController.text.trim(),
                                      path: pathController.text.trim(),
                                    ),
                                  );
                              Navigator.of(dialogContext).pop();
                            }
                          },
                          child: const Text(
                            'Register',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: VibeHubTheme.slate100),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  context.read<RepositoriesBloc>().add(RepositoriesSearchQueryChanged(value));
                },
                style: const TextStyle(fontSize: 13, color: VibeHubTheme.slate850),
                decoration: InputDecoration(
                  hintText: 'Filter local repositories...',
                  hintStyle: const TextStyle(color: VibeHubTheme.slate300, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18, color: VibeHubTheme.slate300),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: const Color(0xFFFCFDFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: VibeHubTheme.slate100),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: VibeHubTheme.slate100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: VibeHubTheme.slate300),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: VibeHubTheme.slate600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: () => _showRegisterDialog(context),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text(
              'Register Directory',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
