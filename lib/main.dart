import 'package:flutter/material.dart';

import 'screens/login_page.dart';

void main() => runApp(const MyApp());

const ink = Color(0xFF183C32);
const green = Color(0xFF26745B);
const muted = Color(0xFF7D8983);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Agile',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F9F5),
      colorScheme: ColorScheme.fromSeed(seedColor: green),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: ink),
      ),
    ),
    home: const LoginPage(),
  );
}

class Task {
  Task(this.title, this.project, this.priority, {this.done = false});
  final String title;
  final String project;
  final String priority;
  bool done;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  final tasks = [
    Task('Eksplorasi desain homepage', 'Agile Mobile', 'Tinggi'),
    Task('Review alur onboarding', 'Website Redesign', 'Sedang'),
    Task('Susun sprint backlog', 'Agile Mobile', 'Rendah', done: true),
  ];

  Future<void> addTask() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tugas baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(
            labelText: 'Nama tugas',
            hintText: 'Apa yang ingin dikerjakan?',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    if (value != null && mounted) {
      setState(() => tasks.insert(0, Task(value, 'Agile Mobile', 'Sedang')));
    }
  }

  void projectDetail(String name) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              const Text(
                'Sprint 04 • Dalam pengerjaan',
                style: TextStyle(color: green),
              ),
              const SizedBox(height: 20),
              ...tasks
                  .where((task) => task.project == name)
                  .map(
                    (task) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        task.done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: green,
                      ),
                      title: Text(task.title),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completed = tasks.where((task) => task.done).length;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFD8EFAC),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'agile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: ink,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Notifikasi',
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        builder: (context) => const SafeArea(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notifikasi',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.notifications_none_rounded,
                                  ),
                                  title: Text('Semua sudah beres'),
                                  subtitle: Text('Belum ada notifikasi baru.'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE7ECDD),
                      child: Text(
                        'AR',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (tab == 0) ...[
                  const Text(
                    'RUANG KERJA PERSONAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Ide besar, langkah kecil.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Yuk, buat progres yang berarti hari ini.',
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFFD8EFAC),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'SPRINT SAAT INI',
                                style: TextStyle(
                                  color: Color(0xFFD8EFAC),
                                  fontSize: 10,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '5 hari lagi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 19),
                        const Text(
                          'Sedikit lagi, sampai! ✨',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 23,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sprint 04 · Pengembangan MVP',
                          style: TextStyle(
                            color: Color(0xFFB5CBC0),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '18 dari 24 tugas selesai',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '75%',
                              style: TextStyle(
                                color: Color(0xFFD8EFAC),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const LinearProgressIndicator(
                            value: .75,
                            minHeight: 7,
                            color: Color(0xFFD8EFAC),
                            backgroundColor: Color(0xFF416055),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      stat('02', 'Proyek aktif', Icons.layers_outlined),
                      const SizedBox(width: 12),
                      stat(
                        '${tasks.length - completed}'.padLeft(2, '0'),
                        'Tugas tersisa',
                        Icons.task_alt_rounded,
                      ),
                      const SizedBox(width: 12),
                      stat(
                        '$completed'.padLeft(2, '0'),
                        'Selesai hari ini',
                        Icons.check_circle_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
                if (tab != 2) ...[
                  section(
                    'Proyek aktif',
                    tab == 0 ? 'Lihat semua' : '2 proyek',
                    () => setState(() => tab = 1),
                  ),
                  const SizedBox(height: 12),
                  project(
                    'Agile Mobile',
                    'Aplikasi produktivitas tim',
                    .65,
                    'AM',
                    const Color(0xFFEDF1E6),
                    '12 / 18 tugas',
                    3,
                  ),
                  const SizedBox(height: 12),
                  project(
                    'Website Redesign',
                    'Pengalaman baru, lebih baik',
                    .4,
                    'WR',
                    const Color(0xFFF4EDE2),
                    '4 / 10 tugas',
                    2,
                  ),
                  const SizedBox(height: 26),
                ],
                if (tab != 1) ...[
                  section(
                    'Tugas hari ini',
                    '$completed/${tasks.length} selesai',
                    null,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Satu per satu, kamu pasti bisa.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  ...tasks.map(taskTile),
                ],
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Ruang untuk fokus. Waktu untuk bertumbuh.',
                    style: TextStyle(fontSize: 10, color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTask,
        tooltip: 'Tambah tugas',
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE5EFDF),
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Proyek',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tugas saya',
          ),
        ],
      ),
    );
  }

  Widget section(String title, String action, VoidCallback? onTap) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ),
      if (onTap != null)
        TextButton(
          onPressed: onTap,
          child: Text(action, style: const TextStyle(fontSize: 12)),
        )
      else
        Text(action, style: const TextStyle(fontSize: 11, color: muted)),
    ],
  );

  Widget stat(String value, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE9EDE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: green),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: muted, fontSize: 10)),
        ],
      ),
    ),
  );

  Widget project(
    String title,
    String subtitle,
    double progress,
    String initials,
    Color color,
    String count,
    int members,
  ) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(19),
      side: const BorderSide(color: Color(0xFFE9EDE5)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => projectDetail(title),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_outward_rounded, size: 18, color: muted),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(count, style: const TextStyle(color: muted, fontSize: 11)),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                color: green,
                backgroundColor: const Color(0xFFEEF1E9),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < members; i++)
                  Align(
                    widthFactor: .8,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: [
                        const Color(0xFFE3EBD9),
                        const Color(0xFFF1DDC9),
                        const Color(0xFFDEE7F1),
                      ][i],
                      child: Text(
                        ['AR', 'DN', 'MF'][i],
                        style: const TextStyle(
                          fontSize: 8,
                          color: ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  '$members anggota',
                  style: const TextStyle(color: muted, fontSize: 10),
                ),
                const Spacer(),
                const Icon(Icons.schedule_rounded, size: 13, color: muted),
                const SizedBox(width: 4),
                const Text(
                  'Sprint 04',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget taskTile(Task task) {
    final priorityColor = task.priority == 'Tinggi'
        ? const Color(0xFFB77254)
        : task.priority == 'Sedang'
        ? const Color(0xFF9D8A48)
        : green;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE9EDE5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: CheckboxListTile(
          value: task.done,
          onChanged: (value) => setState(() => task.done = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: green,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: task.done ? muted : ink,
              decoration: task.done ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              task.project,
              style: const TextStyle(color: muted, fontSize: 10),
            ),
          ),
          secondary: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task.priority,
              style: TextStyle(color: priorityColor, fontSize: 9),
            ),
          ),
        ),
      ),
    );
  }
}
