import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioQualitySettingsScreen extends StatefulWidget {
  const AudioQualitySettingsScreen({super.key});

  @override
  State<AudioQualitySettingsScreen> createState() => _AudioQualitySettingsScreenState();
}

class _AudioQuality {
  final String key;
  final String label;
  final String description;

  const _AudioQuality(this.key, this.label, this.description);
}

const List<_AudioQuality> _qualities = [
  _AudioQuality('original', 'Highest possible', 'Quality as good as the orginal file'),
  _AudioQuality('flac24', 'Hi-Res', 'FLAC 24-bit / 48khz'),
  _AudioQuality('flac16', 'Lossless', 'FLAC 16-bit / 44.1kHz'),
  _AudioQuality('320', 'Very High', '320 kbps'),
  _AudioQuality('160', 'High', '160 kbps'),
  _AudioQuality('96', 'Medium', '96 kbps '),
  _AudioQuality('24', 'Data Saver', '24 kbps'),
];

const String _defaultQuality = '320';

class _AudioQualitySettingsScreenState extends State<AudioQualitySettingsScreen> {
  String _selectedQuality = _defaultQuality;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('qualityMode');

    if (!mounted) return;
    setState(() {
      _selectedQuality = saved ?? _defaultQuality;
      _isLoading = false;
    });
  }

  Future<void> _selectQuality(String qualityKey) async {
    setState(() => _selectedQuality = qualityKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qualityMode', qualityKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageHeader(),
              const SizedBox(height: 32),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: Colors.blue)),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _qualities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final quality = _qualities[index];
                      final isSelected = quality.key == _selectedQuality;

                      return _QualityTile(
                        label: quality.label,
                        description: quality.description,
                        isSelected: isSelected,
                        onTap: () => _selectQuality(quality.key),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityTile extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _QualityTile({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[800]!,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

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
          'Audio Quality',
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