import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../data/model/song.dart';
import '../rn_playing/playing.dart';

class DiscoveryTab extends StatefulWidget {
  const DiscoveryTab({super.key});

  @override
  State<DiscoveryTab> createState() => _DiscoveryTabState();
}

class _DiscoveryTabState extends State<DiscoveryTab> {
  final TextEditingController _controller = TextEditingController();

  List<Song> _all = [];           // toàn bộ bài hát từ JSON
  List<Song> _suggestions = [];   // kết quả lọc theo query
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/songs.json');
      final raw = json.decode(jsonStr);

      // Hỗ trợ cả 2 dạng JSON: [ {...}, ... ] hoặc { "songs": [ {...}, ... ] }
      final List items;
      if (raw is List) {
        items = raw;
      } else if (raw is Map && raw['songs'] is List) {
        items = raw['songs'] as List;
      } else {
        throw 'Định dạng songs.json không đúng (List hoặc Map{songs: List}).';
      }

      _all = items
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _loading = false;
        _suggestions = []; // ⬅️ KHÔNG hiển thị gì khi chưa gõ
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được songs.json: $e')),
      );
    }
  }

  void _onChanged() {
    final q = _controller.text;
    final qLower = q.toLowerCase();
    setState(() {
      _query = q; // để highlight
      if (qLower.isEmpty) {
        _suggestions = []; // ⬅️ rỗng khi chưa gõ gì
      } else {
        _suggestions = _all.where((s) {
          return s.title.toLowerCase().contains(qLower) ||
              s.artist.toLowerCase().contains(qLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discovery')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài hát…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    FocusScope.of(context).unfocus();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: _suggestions.isEmpty
                ? const Center(child: Text('Nhập để tìm bài hát…'))
                : ListView.separated(
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
              const Divider(indent: 16, endIndent: 16, height: 8),
              itemBuilder: (context, i) {
                final s = _suggestions[i];
                return ListTile(
                  leading: const Icon(Icons.search),
                  title: _highlight(s.title, _query, context),
                  subtitle: _highlight(s.artist, _query, context, subtle: true),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NowPlaying(
                          playingSong: s,
                          songs: _all,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Tô đậm/đổi màu phần khớp trong chuỗi
  Widget _highlight(String text, String query, BuildContext ctx,
      {bool subtle = false}) {
    if (query.isEmpty) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);

    if (start == -1) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final end = start + query.length;
    final normal = Theme.of(ctx).textTheme.bodyMedium!;
    final faded = normal.copyWith(color: Theme.of(ctx).hintColor);
    final match = normal.copyWith(
      color: Theme.of(ctx).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: subtle ? faded : normal,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(text: text.substring(start, end), style: match),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}
