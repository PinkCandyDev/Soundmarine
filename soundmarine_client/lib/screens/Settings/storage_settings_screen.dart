import 'package:flutter/material.dart';
import '../../services/audio_proxy_server.dart';
import '../../widgets/common/app_text_field.dart';

class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  double _usedCacheGb = 0;
  double _maxCacheGb = 20.0;
  bool _replaceOldest = true;
  late TextEditingController _cacheController;

  @override
  void initState() {
    super.initState();
    _cacheController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final limitGb =
        (await AudioProxyServer.instance.getCacheLimit()) / (1024 * 1024 * 1024);
    final usedGb = AudioProxyServer.instance.getTotalCacheSizeGb();
    if (!mounted) return;
    setState(() {
      _maxCacheGb = limitGb;
      _usedCacheGb = usedGb;
      _cacheController.text = limitGb.toStringAsFixed(1);
    });
  }

  Future<void> _saveCacheLimit() async {
    final parsed = double.tryParse(_cacheController.text);
    if (parsed == null || parsed <= 0) return;
    await AudioProxyServer.instance.setCacheLimitGb(parsed);
    setState(() => _maxCacheGb = parsed);
  }

  Future<void> _clearCache() async {
    await AudioProxyServer.instance.clearAll();
    setState(() => _usedCacheGb = 0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  void dispose() {
    _cacheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_usedCacheGb / _maxCacheGb).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(),
              const SizedBox(height: 32),
              _CacheUsageIndicator(
                progress: progress,
                usedCacheGb: _usedCacheGb,
                maxCacheGb: _maxCacheGb,
              ),
              const SizedBox(height: 32),
              _CacheLimitInput(
                controller: _cacheController,
                onSave: _saveCacheLimit,
              ),
              const SizedBox(height: 20),
              _ReplaceOldestToggle(
                value: _replaceOldest,
                onChanged: (value) {
                  setState(() => _replaceOldest = value);
                  AudioProxyServer.instance.setReplaceOldest(value);
                },
              ),
              const SizedBox(height: 16),
              _ActionButton(
                label: 'Save',
                color: Colors.blue,
                onTap: _saveCacheLimit,
              ),
              const SizedBox(height: 12),
              _ActionButton(
                label: 'Clear Cache',
                color: Colors.grey[900]!,
                onTap: _clearCache,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
        const Text(
          'Storage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CacheUsageIndicator extends StatelessWidget {
  final double progress;
  final double usedCacheGb;
  final double maxCacheGb;

  const _CacheUsageIndicator({
    required this.progress,
    required this.usedCacheGb,
    required this.maxCacheGb,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cache Usage',
          style: TextStyle(color: Colors.grey[400], fontSize: 15),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 14,
            backgroundColor: Colors.grey[850],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${usedCacheGb.toStringAsFixed(2)} GB / ${maxCacheGb.toStringAsFixed(1)} GB',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    );
  }
}

class _CacheLimitInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const _CacheLimitInput({
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Max Cache Space',
          style: TextStyle(color: Colors.grey[400], fontSize: 15),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: controller,
          label: '',
          hintText: 'Enter GB limit',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixText: 'GB',
          onSubmitted: (_) => onSave(),
        ),
      ],
    );
  }
}

class _ReplaceOldestToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReplaceOldestToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Replace oldest',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'When cache is full, remove least recently played tracks',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}