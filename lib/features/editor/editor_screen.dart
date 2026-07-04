import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../core/theme/ide_theme.dart';
import '../console/console_panel.dart';
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
    final controller = TextEditingController(text: 'novo.py');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo arquivo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome do arquivo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Criar'),
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
    final controller = TextEditingController(text: base);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renomear arquivo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Novo nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Renomear'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar arquivo?'),
        content: Text('"$name" será apagado permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
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
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state.currentFileName,
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              IconButton(
                tooltip: state.brightness == Brightness.dark
                    ? 'Tema claro'
                    : 'Tema escuro',
                icon: Icon(
                  state.brightness == Brightness.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                onPressed: state.toggleBrightness,
              ),
              IconButton(
                tooltip: 'Salvar arquivo',
                icon: const Icon(Icons.save_outlined),
                onPressed: state.saveCurrentFile,
              ),
              IconButton(
                tooltip: 'Executar código',
                icon: state.isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.play_arrow,
                        color: IdeColors.of(context).successColor,
                      ),
                onPressed: state.isRunning ? null : _run,
              ),
              IconButton(
                tooltip: 'Sair da conta',
                icon: const Icon(Icons.logout),
                onPressed: () => state.signOut(),
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
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Novo arquivo'),
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
                    return const Center(child: Text('Nenhum arquivo salvo'));
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
                            tooltip: 'Mais opções',
                            onSelected: (action) {
                              if (action == 'rename') onRename(f.name);
                              if (action == 'delete') onDelete(f.name);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Renomear'),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('Apagar'),
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
