import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../console/console_panel.dart';
import '../settings/settings_screen.dart';
import 'code_editor_widget.dart';

/// Tela principal estilo IDE: toolbar, editor, console inferior e gaveta
/// lateral com os arquivos salvos.
class EditorScreen extends StatefulWidget {
  final AppState state;

  const EditorScreen({super.key, required this.state});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _editorKey = GlobalKey<CodeEditorWidgetState>();

  AppState get state => widget.state;

  Future<void> _run() async {
    await state.runCurrentCode();
  }

  Future<void> _newFile() async {
    final strings = state.strings;
    final controller = TextEditingController(text: strings.newFileDefaultName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.newFile),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: strings.fileNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(strings.create),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await state.createFile(name.endsWith('.py') ? name : '$name.py');
    }
  }

  Future<void> _renameFile(String oldName) async {
    final base = oldName.endsWith('.py')
        ? oldName.substring(0, oldName.length - 3)
        : oldName;
    final strings = state.strings;
    final controller = TextEditingController(text: base);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.renameFile),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: strings.newNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(strings.rename),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    final normalized = newName.endsWith('.py') ? newName : '$newName.py';
    if (normalized == oldName) return;
    try {
      await state.renameFile(oldName, normalized);
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteFile(String name) async {
    final strings = state.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteFileTitle),
        content: Text(strings.deleteFileBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.deleteFile(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final strings = state.strings;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state.currentFileName,
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              IconButton(
                tooltip: strings.saveFile,
                icon: const Icon(Icons.save_outlined),
                onPressed: state.saveCurrentFile,
              ),
              // Executar é A ação do editor: botão cheio, não iconezinho.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8A3E),
                    foregroundColor: Colors.white,
                  ),
                  icon: state.isRunning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(strings.runLabel),
                  onPressed: state.isRunning ? null : _run,
                ),
              ),
              IconButton(
                tooltip: strings.settingsTitle,
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(state: state),
                  ),
                ),
              ),
            ],
          ),
          drawer: _FileDrawer(
            state: state,
            onNewFile: _newFile,
            onRename: _renameFile,
            onDelete: _deleteFile,
          ),
          body: Column(
            children: [
              Expanded(
                flex: 3,
                child: CodeEditorWidget(
                  key: _editorKey,
                  code: state.currentCode,
                  onChanged: state.updateCode,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                flex: 2,
                child: ConsolePanel(
                  result: state.lastResult,
                  isRunning: state.isRunning,
                  onStop: state.stopExecution,
                  onErrorTap: (line) =>
                      _editorKey.currentState?.moveCursorToLine(line),
                  onSubmitInput: state.submitInput,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Gaveta lateral: seletor de arquivos salvos, com renomear e apagar.
class _FileDrawer extends StatelessWidget {
  final AppState state;
  final VoidCallback onNewFile;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onDelete;

  const _FileDrawer({
    required this.state,
    required this.onNewFile,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final strings = state.strings;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: Text(strings.newFile),
              onTap: () {
                Navigator.pop(context);
                onNewFile();
              },
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder(
                future: state.codeRepository.list(),
                builder: (context, snapshot) {
                  final files = snapshot.data ?? [];
                  if (files.isEmpty) {
                    return Center(child: Text(strings.noSavedFiles));
                  }
                  return ListView(
                    children: [
                      for (final f in files)
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(f.name),
                          selected: f.name == state.currentFileName,
                          onTap: () {
                            Navigator.pop(context);
                            state.openFile(f.name);
                          },
                          trailing: PopupMenuButton<String>(
                            tooltip: strings.moreOptions,
                            onSelected: (action) {
                              if (action == 'rename') onRename(f.name);
                              if (action == 'delete') onDelete(f.name);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'rename',
                                child: ListTile(
                                  leading: const Icon(Icons.edit_outlined),
                                  title: Text(strings.rename),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: const Icon(Icons.delete_outline),
                                  title: Text(strings.delete),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
