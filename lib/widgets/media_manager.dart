import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class MediaManager extends StatefulWidget {
  final String? initialImagePath;
  final String? initialAudioPath;
  final Function(String?) onImageChanged;
  final Function(String?) onAudioChanged;

  const MediaManager({
    super.key,
    this.initialImagePath,
    this.initialAudioPath,
    required this.onImageChanged,
    required this.onAudioChanged,
  });

  @override
  State<MediaManager> createState() => _MediaManagerState();
}

class _MediaManagerState extends State<MediaManager> {
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  String? _currentImagePath;
  String? _currentAudioPath;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.initialImagePath;
    _currentAudioPath = widget.initialAudioPath;
    
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seção de Imagem
        _buildImageSection(),
        
        const SizedBox(height: 16),
        
        // Seção de Áudio
        _buildAudioSection(),
      ],
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image),
                const SizedBox(width: 8),
                Text(
                  'Imagem',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate),
                  onPressed: _pickImage,
                  tooltip: 'Adicionar imagem',
                ),
                if (_currentImagePath != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _removeImage,
                    tooltip: 'Remover imagem',
                  ),
              ],
            ),
            
            if (_currentImagePath != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_currentImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: Text('Erro ao carregar imagem'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, color: Colors.grey[400], size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhuma imagem adicionada',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.audiotrack),
                const SizedBox(width: 8),
                Text(
                  'Áudio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.audio_file),
                  onPressed: _pickAudio,
                  tooltip: 'Adicionar áudio',
                ),
                if (_currentAudioPath != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _removeAudio,
                    tooltip: 'Remover áudio',
                  ),
              ],
            ),
            
            if (_currentAudioPath != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: _togglePlayPause,
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop),
                          onPressed: _stopAudio,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getAudioFileName(),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (_duration.inMilliseconds > 0) ...[
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _position.inMilliseconds.toDouble(),
                          max: _duration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.audiotrack, color: Colors.grey[400], size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhum áudio adicionado',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final savedPath = await _saveImageToAppDirectory(image.path);
        if (savedPath != null) {
          setState(() {
            _currentImagePath = savedPath;
          });
          widget.onImageChanged(savedPath);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao selecionar imagem: $e');
    }
  }

  Future<String?> _saveImageToAppDirectory(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetFile = File('${imagesDir.path}/$fileName');
      
      await File(sourcePath).copy(targetFile.path);
      return targetFile.path;
    } catch (e) {
      debugPrint('Erro ao salvar imagem: $e');
      return null;
    }
  }

  void _removeImage() {
    setState(() {
      _currentImagePath = null;
    });
    widget.onImageChanged(null);
  }

  Future<void> _pickAudio() async {
    // Simulação de seleção de arquivo de áudio
    // Em um app real, você usaria file_picker ou similar
    _showInfoDialog('Seleção de Áudio', 
        'Em um aplicativo real, aqui seria aberto um seletor de arquivos de áudio. '
        'Por enquanto, esta funcionalidade está simulada.');
  }

  void _removeAudio() {
    _audioPlayer.stop();
    setState(() {
      _currentAudioPath = null;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    widget.onAudioChanged(null);
  }

  Future<void> _togglePlayPause() async {
    if (_currentAudioPath == null) return;
    
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(DeviceFileSource(_currentAudioPath!));
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao reproduzir áudio: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _position = Duration.zero;
      });
    } catch (e) {
      _showErrorSnackBar('Erro ao parar áudio: $e');
    }
  }

  String _getAudioFileName() {
    if (_currentAudioPath == null) return '';
    return _currentAudioPath!.split('/').last;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

