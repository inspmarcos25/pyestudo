import 'app_language.dart';

/// Todos os textos fixos da interface, em cada idioma. O conteúdo didático
/// (capítulos, lições, exercícios) NÃO fica aqui — vem dos JSON por idioma.
abstract class AppStrings {
  const AppStrings();

  static const AppStrings pt = _PtStrings();
  static const AppStrings en = _EnStrings();

  static AppStrings of(AppLanguage language) =>
      language == AppLanguage.en ? en : pt;

  // Navegação
  String get editorTab;
  String get editorTooltip;
  String get exercisesTab;
  String get exercisesTooltip;
  String get progressTab;
  String get progressTooltip;

  // Tela de exercícios (trilha)
  String get chapterWordUpper; // "CAPÍTULO" / "CHAPTER"
  String get startBubble; // "COMEÇAR" / "START"
  String streakChip(int days); // número visível no chip
  String streakSemantics(int days); // rótulo acessível do chip/streak
  String chapterSemantics(int order, String title, String difficulty, int pct);
  String lessonSemantics(String title);
  String exerciseSemantics(String title);
  String exerciseDoneSemantics(String title);

  // Tela de progresso
  String get progressTitle;
  String get achievementsSection;
  String get chaptersSection;
  String streakHeroTitle(int days); // inclui caso 0
  String get streakBodyActive;
  String get streakBodyInactive;
  String get statExercises;
  String get statChapters;
  String get statAchievements;
  String get statCourse;
  String overallProgressSemantics(int done, int total);
  String chaptersDoneSemantics(int done, int total);
  String achievementsCountSemantics(int done, int total);
  String courseSemantics(int pct);
  String achievementSemantics(String title, String desc, bool unlocked);
  String chapterProgressSemantics(String title, int pct);

  // Conquistas (por id)
  String achievementTitle(String id);
  String achievementDescription(String id);

  // Tela de exercício
  String get exerciseComplete;
  String get hint;
  String get check;
  String get executionLabel; // nome do "teste" quando a execução falha
  String runFailed(Object error);
  String checkFailed(Object error);

  // Tela de lição
  String get openInEditor;

  // Editor
  String get lightTheme;
  String get darkTheme;
  String get saveFile;
  String get runCode;
  String get signOut;
  String get newFile;
  String get newFileDefaultName;
  String get fileNameLabel;
  String get cancel;
  String get create;
  String get renameFile;
  String get newNameLabel;
  String get rename;
  String get deleteFileTitle;
  String deleteFileBody(String name);
  String get delete;
  String get moreOptions;
  String get noSavedFiles;

  // Console
  String get stopExecution;
  String get running;
  String get consoleEmptyHint;
  String get noOutput;
  String get inputSemantics;
  String get inputHint;
  String get sendAnswer;

  // Editor de código
  String get codeEditorSemantics;

  // Login
  String get loginSubtitleRegister;
  String get loginSubtitleSignIn;
  String get emailLabel;
  String get passwordLabel;
  String get forgotPassword;
  String get createAccount;
  String get signIn;
  String get haveAccount;
  String get createNewAccount;
  String get or;
  String get continueWithGoogle;
  String get enterEmailForReset;
  String get resetEmailSent;

  // Erros de autenticação
  String authError(String code, String? fallbackMessage);

  // Seletor de idioma
  String get languageLabel;
  String get chooseLanguage;

  // Código inicial do editor para um usuário novo
  String get defaultCode;
}

class _PtStrings extends AppStrings {
  const _PtStrings();

  @override
  String get editorTab => 'Editor';
  @override
  String get editorTooltip => 'Editor e console';
  @override
  String get exercisesTab => 'Exercícios';
  @override
  String get exercisesTooltip => 'Lições e exercícios';
  @override
  String get progressTab => 'Progresso';
  @override
  String get progressTooltip => 'Seu progresso';

  @override
  String get chapterWordUpper => 'CAPÍTULO';
  @override
  String get startBubble => 'COMEÇAR';
  @override
  String streakChip(int days) => '$days';
  @override
  String streakSemantics(int days) => days > 0
      ? 'Sequência de $days dias estudando'
      : 'Sem sequência ativa hoje';
  @override
  String chapterSemantics(
    int order,
    String title,
    String difficulty,
    int pct,
  ) => 'Capítulo $order: $title, $difficulty, $pct% concluído';
  @override
  String lessonSemantics(String title) => 'Lição: $title';
  @override
  String exerciseSemantics(String title) => 'Exercício: $title';
  @override
  String exerciseDoneSemantics(String title) =>
      'Exercício concluído: $title';

  @override
  String get progressTitle => 'Seu progresso';
  @override
  String get achievementsSection => 'Conquistas';
  @override
  String get chaptersSection => 'Capítulos';
  @override
  String streakHeroTitle(int days) {
    if (days <= 0) return 'Sem sequência';
    if (days == 1) return '1 dia de sequência';
    return '$days dias seguidos';
  }

  @override
  String get streakBodyActive =>
      'Continue assim! Resolva um exercício por dia para manter a chama '
      'acesa.';
  @override
  String get streakBodyInactive =>
      'Resolva um exercício hoje para acender a chama!';
  @override
  String get statExercises => 'exercícios';
  @override
  String get statChapters => 'capítulos';
  @override
  String get statAchievements => 'conquistas';
  @override
  String get statCourse => 'do curso';
  @override
  String overallProgressSemantics(int done, int total) =>
      'Progresso geral: $done de $total exercícios';
  @override
  String chaptersDoneSemantics(int done, int total) =>
      'Capítulos completos: $done de $total';
  @override
  String achievementsCountSemantics(int done, int total) =>
      'Conquistas desbloqueadas: $done de $total';
  @override
  String courseSemantics(int pct) => 'Curso $pct% concluído';
  @override
  String achievementSemantics(String title, String desc, bool unlocked) =>
      '$title: $desc${unlocked ? ' (desbloqueada)' : ' (bloqueada)'}';
  @override
  String chapterProgressSemantics(String title, int pct) =>
      '$title: $pct% concluído';

  @override
  String achievementTitle(String id) => switch (id) {
    'first_exercise' => 'Primeiro passo',
    'five_exercises' => 'Pegando o jeito',
    'ten_exercises' => 'Dedicado',
    'twenty_exercises' => 'Persistente',
    'one_chapter' => 'Capítulo concluído',
    'all_chapters' => 'Mestre em Python',
    'streak_3' => 'Sequência de 3 dias',
    'streak_7' => 'Sequência de 7 dias',
    _ => id,
  };
  @override
  String achievementDescription(String id) => switch (id) {
    'first_exercise' => 'Complete seu primeiro exercício',
    'five_exercises' => 'Complete 5 exercícios',
    'ten_exercises' => 'Complete 10 exercícios',
    'twenty_exercises' => 'Complete 20 exercícios',
    'one_chapter' => 'Termine um capítulo inteiro',
    'all_chapters' => 'Termine todos os capítulos',
    'streak_3' => 'Estude 3 dias seguidos',
    'streak_7' => 'Estude 7 dias seguidos',
    _ => '',
  };

  @override
  String get exerciseComplete => 'Exercício concluído!';
  @override
  String get hint => 'Dica';
  @override
  String get check => 'Verificar';
  @override
  String get executionLabel => 'Execução';
  @override
  String runFailed(Object error) => 'não foi possível executar: $error';
  @override
  String checkFailed(Object error) => 'não foi possível verificar: $error';

  @override
  String get openInEditor => 'Abrir no editor';

  @override
  String get lightTheme => 'Tema claro';
  @override
  String get darkTheme => 'Tema escuro';
  @override
  String get saveFile => 'Salvar arquivo';
  @override
  String get runCode => 'Executar código';
  @override
  String get signOut => 'Sair da conta';
  @override
  String get newFile => 'Novo arquivo';
  @override
  String get newFileDefaultName => 'novo.py';
  @override
  String get fileNameLabel => 'Nome do arquivo';
  @override
  String get cancel => 'Cancelar';
  @override
  String get create => 'Criar';
  @override
  String get renameFile => 'Renomear arquivo';
  @override
  String get newNameLabel => 'Novo nome';
  @override
  String get rename => 'Renomear';
  @override
  String get deleteFileTitle => 'Apagar arquivo?';
  @override
  String deleteFileBody(String name) => '"$name" será apagado permanentemente.';
  @override
  String get delete => 'Apagar';
  @override
  String get moreOptions => 'Mais opções';
  @override
  String get noSavedFiles => 'Nenhum arquivo salvo';

  @override
  String get stopExecution => 'Parar execução';
  @override
  String get running => 'Executando...';
  @override
  String get consoleEmptyHint => 'Toque em ▶ para executar o código.';
  @override
  String get noOutput => '(sem saída)';
  @override
  String get inputSemantics => 'Resposta do input, digite e confirme';
  @override
  String get inputHint => 'digite a resposta e Enter…';
  @override
  String get sendAnswer => 'Enviar resposta';

  @override
  String get codeEditorSemantics => 'Editor de código Python';

  @override
  String get loginSubtitleRegister =>
      'Crie sua conta para salvar seu progresso';
  @override
  String get loginSubtitleSignIn => 'Entre para acessar seus estudos';
  @override
  String get emailLabel => 'E-mail';
  @override
  String get passwordLabel => 'Senha';
  @override
  String get forgotPassword => 'Esqueci minha senha';
  @override
  String get createAccount => 'Criar conta';
  @override
  String get signIn => 'Entrar';
  @override
  String get haveAccount => 'Já tenho conta';
  @override
  String get createNewAccount => 'Criar uma conta nova';
  @override
  String get or => 'ou';
  @override
  String get continueWithGoogle => 'Continuar com Google';
  @override
  String get enterEmailForReset => 'digite seu e-mail para recuperar a senha';
  @override
  String get resetEmailSent => 'e-mail de recuperação enviado';

  @override
  String authError(String code, String? fallbackMessage) => switch (code) {
    'invalid-email' => 'e-mail inválido',
    'user-disabled' => 'esta conta foi desativada',
    'user-not-found' => 'nenhuma conta encontrada com esse e-mail',
    'wrong-password' || 'invalid-credential' => 'senha incorreta',
    'email-already-in-use' => 'já existe uma conta com esse e-mail',
    'weak-password' => 'a senha precisa ter pelo menos 6 caracteres',
    'sign-in-canceled' => 'login cancelado',
    'unauthorized-domain' =>
      'este domínio não está autorizado para login com Google',
    _ => 'não foi possível entrar: ${fallbackMessage ?? code}',
  };

  @override
  String get languageLabel => 'Idioma';
  @override
  String get chooseLanguage => 'Escolher idioma';

  @override
  String get defaultCode =>
      "# Escreva seu código Python aqui\n"
      "print('Olá, mundo!')\n";
}

class _EnStrings extends AppStrings {
  const _EnStrings();

  @override
  String get editorTab => 'Editor';
  @override
  String get editorTooltip => 'Editor and console';
  @override
  String get exercisesTab => 'Exercises';
  @override
  String get exercisesTooltip => 'Lessons and exercises';
  @override
  String get progressTab => 'Progress';
  @override
  String get progressTooltip => 'Your progress';

  @override
  String get chapterWordUpper => 'CHAPTER';
  @override
  String get startBubble => 'START';
  @override
  String streakChip(int days) => '$days';
  @override
  String streakSemantics(int days) =>
      days > 0 ? '$days-day study streak' : 'No active streak today';
  @override
  String chapterSemantics(
    int order,
    String title,
    String difficulty,
    int pct,
  ) => 'Chapter $order: $title, $difficulty, $pct% complete';
  @override
  String lessonSemantics(String title) => 'Lesson: $title';
  @override
  String exerciseSemantics(String title) => 'Exercise: $title';
  @override
  String exerciseDoneSemantics(String title) => 'Exercise complete: $title';

  @override
  String get progressTitle => 'Your progress';
  @override
  String get achievementsSection => 'Achievements';
  @override
  String get chaptersSection => 'Chapters';
  @override
  String streakHeroTitle(int days) {
    if (days <= 0) return 'No streak';
    if (days == 1) return '1-day streak';
    return '$days days in a row';
  }

  @override
  String get streakBodyActive =>
      'Keep it up! Solve one exercise a day to keep the flame alive.';
  @override
  String get streakBodyInactive =>
      'Solve an exercise today to light the flame!';
  @override
  String get statExercises => 'exercises';
  @override
  String get statChapters => 'chapters';
  @override
  String get statAchievements => 'achievements';
  @override
  String get statCourse => 'of course';
  @override
  String overallProgressSemantics(int done, int total) =>
      'Overall progress: $done of $total exercises';
  @override
  String chaptersDoneSemantics(int done, int total) =>
      'Chapters completed: $done of $total';
  @override
  String achievementsCountSemantics(int done, int total) =>
      'Achievements unlocked: $done of $total';
  @override
  String courseSemantics(int pct) => 'Course $pct% complete';
  @override
  String achievementSemantics(String title, String desc, bool unlocked) =>
      '$title: $desc${unlocked ? ' (unlocked)' : ' (locked)'}';
  @override
  String chapterProgressSemantics(String title, int pct) =>
      '$title: $pct% complete';

  @override
  String achievementTitle(String id) => switch (id) {
    'first_exercise' => 'First step',
    'five_exercises' => 'Getting the hang of it',
    'ten_exercises' => 'Dedicated',
    'twenty_exercises' => 'Persistent',
    'one_chapter' => 'Chapter complete',
    'all_chapters' => 'Python master',
    'streak_3' => '3-day streak',
    'streak_7' => '7-day streak',
    _ => id,
  };
  @override
  String achievementDescription(String id) => switch (id) {
    'first_exercise' => 'Complete your first exercise',
    'five_exercises' => 'Complete 5 exercises',
    'ten_exercises' => 'Complete 10 exercises',
    'twenty_exercises' => 'Complete 20 exercises',
    'one_chapter' => 'Finish a whole chapter',
    'all_chapters' => 'Finish every chapter',
    'streak_3' => 'Study 3 days in a row',
    'streak_7' => 'Study 7 days in a row',
    _ => '',
  };

  @override
  String get exerciseComplete => 'Exercise complete!';
  @override
  String get hint => 'Hint';
  @override
  String get check => 'Check';
  @override
  String get executionLabel => 'Execution';
  @override
  String runFailed(Object error) => 'could not run: $error';
  @override
  String checkFailed(Object error) => 'could not check: $error';

  @override
  String get openInEditor => 'Open in editor';

  @override
  String get lightTheme => 'Light theme';
  @override
  String get darkTheme => 'Dark theme';
  @override
  String get saveFile => 'Save file';
  @override
  String get runCode => 'Run code';
  @override
  String get signOut => 'Sign out';
  @override
  String get newFile => 'New file';
  @override
  String get newFileDefaultName => 'new.py';
  @override
  String get fileNameLabel => 'File name';
  @override
  String get cancel => 'Cancel';
  @override
  String get create => 'Create';
  @override
  String get renameFile => 'Rename file';
  @override
  String get newNameLabel => 'New name';
  @override
  String get rename => 'Rename';
  @override
  String get deleteFileTitle => 'Delete file?';
  @override
  String deleteFileBody(String name) => '"$name" will be permanently deleted.';
  @override
  String get delete => 'Delete';
  @override
  String get moreOptions => 'More options';
  @override
  String get noSavedFiles => 'No saved files';

  @override
  String get stopExecution => 'Stop execution';
  @override
  String get running => 'Running...';
  @override
  String get consoleEmptyHint => 'Tap ▶ to run your code.';
  @override
  String get noOutput => '(no output)';
  @override
  String get inputSemantics => 'Input answer, type and confirm';
  @override
  String get inputHint => 'type your answer and press Enter…';
  @override
  String get sendAnswer => 'Send answer';

  @override
  String get codeEditorSemantics => 'Python code editor';

  @override
  String get loginSubtitleRegister =>
      'Create your account to save your progress';
  @override
  String get loginSubtitleSignIn => 'Sign in to access your studies';
  @override
  String get emailLabel => 'Email';
  @override
  String get passwordLabel => 'Password';
  @override
  String get forgotPassword => 'Forgot my password';
  @override
  String get createAccount => 'Create account';
  @override
  String get signIn => 'Sign in';
  @override
  String get haveAccount => 'I already have an account';
  @override
  String get createNewAccount => 'Create a new account';
  @override
  String get or => 'or';
  @override
  String get continueWithGoogle => 'Continue with Google';
  @override
  String get enterEmailForReset => 'enter your email to reset your password';
  @override
  String get resetEmailSent => 'password reset email sent';

  @override
  String authError(String code, String? fallbackMessage) => switch (code) {
    'invalid-email' => 'invalid email',
    'user-disabled' => 'this account has been disabled',
    'user-not-found' => 'no account found with this email',
    'wrong-password' || 'invalid-credential' => 'incorrect password',
    'email-already-in-use' => 'an account already exists with this email',
    'weak-password' => 'password must be at least 6 characters',
    'sign-in-canceled' => 'sign-in canceled',
    'unauthorized-domain' =>
      'this domain is not authorized for Google sign-in',
    _ => 'could not sign in: ${fallbackMessage ?? code}',
  };

  @override
  String get languageLabel => 'Language';
  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get defaultCode =>
      "# Write your Python code here\n"
      "print('Hello, world!')\n";
}
