import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class EditPhotoScreen extends StatefulWidget {
  final XFile imageFile;

  const EditPhotoScreen({super.key, required this.imageFile});

  @override
  State<EditPhotoScreen> createState() => _EditPhotoScreenState();
}

enum ActiveTool { none, auto, filter, crop, sticker }

class StickerItem {
  String id;
  String emoji;
  Offset position;

  StickerItem({required this.id, required this.emoji, required this.position});
}

class _EditPhotoScreenState extends State<EditPhotoScreen> {
  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _deleteAreaKey = GlobalKey();
  XFile? _currentFile;
  
  ActiveTool _activeTool = ActiveTool.none;
  
  // Edit States
  bool _isAutoAdjusted = false;
  String _selectedFilter = 'No filter';
  double? _cropRatio; // null means 'Free' / Original if not zoomed
  final List<StickerItem> _stickers = [];
  
  // Interactive / Crop State
  final TransformationController _transformController = TransformationController();
  
  // Drag State
  bool _isDraggingSticker = false;
  bool _isHoveringDelete = false;

  final List<String> _filters = [
    'No filter', 'Halki', 'Loreto', 'Gazette', 'Kilda', 'Lapis', 'Dune'
  ];

  final List<String> _emojis = [
    '😀', '😂', '😍', '🔥', '👍', '🎉', '❤️', '😱', '😎', '💡', '🚀', '💯'
  ];

  @override
  void initState() {
    super.initState();
    _currentFile = widget.imageFile;
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  // --- Logic ---

  Future<void> _saveImage() async {
    if (!mounted) return;
    
    try {
      // Wait for any active animations or layout passes to settle
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      RenderRepaintBoundary? boundary =
          _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      
      if (boundary == null || boundary.debugNeedsPaint) {
         // If it needs paint, wait one frame
         await Future.delayed(const Duration(milliseconds: 20));
         if (!mounted) return;
         boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
         if (boundary == null) return;
      }

      // Ensure boundary is still attached to render tree
      if (!boundary.attached) {
        debugPrint("Boundary not attached, cannot save");
        return;
      }
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      
      if (!mounted) return; // Check again after async toImage

      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return;
      
      Uint8List pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        if (mounted) {
           Navigator.pop(context, XFile.fromData(
             pngBytes, 
             mimeType: 'image/png',
             name: 'edited_${DateTime.now().millisecondsSinceEpoch}.png'
           ));
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(pngBytes);

        if (mounted) {
          Navigator.pop(context, XFile(file.path));
        }
      }
    } catch (e) {
      debugPrint("Error saving image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving image: $e")),
        );
      }
    }
  }
  
  void _addSticker(String emoji) {
    setState(() {
      _stickers.add(StickerItem(
        id: DateTime.now().toString(),
        emoji: emoji,
        position: const Offset(150, 200), // Default center-ish
      ));
      _activeTool = ActiveTool.none; // Hide panel to show stickers clearly
    });
  }

  void _updateStickerPosition(String id, Offset newPos) {
    setState(() {
      final index = _stickers.indexWhere((s) => s.id == id);
      if (index != -1) {
        _stickers[index].position = newPos;
      }
    });
    
    // Check delete intersection
    _checkDeleteIntersection(newPos);
  }
  
  void _checkDeleteIntersection(Offset stickerPos) {
    // Determine bounds of delete button (approximate bottom center of screen)
    // Using a simpler approach: if Y > screenHeight - 150
    final screenHeight = MediaQuery.of(context).size.height;
    final isHovering = stickerPos.dy > screenHeight - 160; // Threshold
    
    if (_isHoveringDelete != isHovering) {
      setState(() => _isHoveringDelete = isHovering);
    }
  }

  void _onStickerDragEnd(String id) {
    if (_isHoveringDelete) {
      setState(() {
         _stickers.removeWhere((s) => s.id == id);
         _isHoveringDelete = false;
         _isDraggingSticker = false;
      });
    } else {
      setState(() {
         _isDraggingSticker = false;
         _isHoveringDelete = false;
      });
    }
  }

  ColorFilter _getFilterMatrix(String filterName) {
    switch (filterName) {
      case 'Halki':
        return const ColorFilter.matrix([
           0.9, 0, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0, 1.1, 0, 0, 0, 0, 0, 1, 0,
        ]);
      case 'Loreto':
        return const ColorFilter.mode(Colors.purpleAccent, BlendMode.overlay); 
      case 'Gazette':
        return const ColorFilter.matrix([
           0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0.33, 0.33, 0.33, 0, 0, 0, 0, 0, 1, 0,
        ]); 
      case 'Kilda':
        // Warm, slightly vintage
        return const ColorFilter.matrix([
          1.1, 0, 0, 0, 0, 
          0, 0.9, 0, 0, 0, 
          0, 0, 0.8, 0, 0, 
          0, 0, 0, 1, 0,
        ]);
      case 'Lapis':
        // Cool/Blueish
        return const ColorFilter.matrix([
          0.9, 0, 0, 0, 0, 
          0, 0.9, 0, 0, 0, 
          0, 0, 1.2, 0, 0, 
          0, 0, 0, 1, 0,
        ]);
      case 'Dune':
        // Sandy/Orange
        return const ColorFilter.matrix([
          1.1, 0, 0, 0, 0, 
          0, 1.0, 0, 0, 0, 
          0, 0, 0.7, 0, 0, 
          0, 0, 0, 1, 0,
        ]);
      default:
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0,
        ]); 
    }
  }


  @override
  Widget build(BuildContext context) {
    // 1. Prepare Base Image Widget
    Widget imageWidget = kIsWeb
        ? Image.network(_currentFile!.path, fit: BoxFit.contain)
        : Image.file(File(_currentFile!.path), fit: BoxFit.contain);

    // 2. Apply Filters
    if (_selectedFilter != 'No filter') {
       if (_selectedFilter == 'Loreto') {
          imageWidget = ColorFiltered(colorFilter: _getFilterMatrix('Loreto'), child: imageWidget);
       } else {
          imageWidget = ColorFiltered(colorFilter: _getFilterMatrix(_selectedFilter), child: imageWidget);
       }
    }
    // 3. Apply Auto Adjust
    if (_isAutoAdjusted) {
       imageWidget = ColorFiltered(
           colorFilter: const ColorFilter.matrix([
             1.1, 0, 0, 0, 10,
             0, 1.1, 0, 0, 10,
             0, 0, 1.1, 0, 10,
             0, 0, 0, 1, 0,
           ]),
           child: imageWidget,
       );
    }
    
    // 4. Interactive Content (Image + Stickers)
    // We wrap image in a Stack to place stickers on TOP of the image explicitly
    // This entire Stack is what gets Zoomed/Panned by InteractiveViewer
    Widget contentWithStickers = Stack(
      children: [
        imageWidget,
        ..._stickers.map((s) => Positioned(
          left: s.position.dx,
          top: s.position.dy,
          child: GestureDetector(
            onPanStart: (_) => setState(() => _isDraggingSticker = true),
            onPanUpdate: (details) {
               // Adjust delta by usage scale if needed, but simple delta works for direct manipulation usually
               // Problem: If zoomed in, delta is in screen pixels, but position is in local pixels.
               // We might need to divide delta by current scale.
               double scale = _transformController.value.getMaxScaleOnAxis();
               _updateStickerPosition(s.id, s.position + details.delta / scale);
            },
            onPanEnd: (_) => _onStickerDragEnd(s.id),
            child: Text(
              s.emoji, 
              style: const TextStyle(
                fontSize: 50, 
                decoration: TextDecoration.none,
                fontFamilyFallback: ['Noto Color Emoji', 'Apple Color Emoji', 'Segoe UI Emoji'],
              )
            ),
          ),
        )),
      ],
    );

    // 5. Crop/viewport logic
    Widget viewport;
    
    // Always use InteractiveViewer to allow Zoom/Pan
    // We maintain 'contentWithStickers' as the child
    Widget interactiveWrapper = InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5, 
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(double.infinity), // Allow free panning
      child: contentWithStickers,
    );

    if (_cropRatio != null) {
       // Fixed Aspect Ratio mode
       // We wrap the InteractiveViewer in an AspectRatio
       viewport = Center(
         child: AspectRatio(
           aspectRatio: _cropRatio!,
           child: Container(
             color: Colors.black,
             child: interactiveWrapper, // Now interactable!
           ),
         ),
       );
    } else {
       // Free/Original mode
       viewport = interactiveWrapper;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Edit photo', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
             onPressed: _saveImage,
             child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // THE SAVABLE AREA
                RepaintBoundary(
                  key: _globalKey,
                  child: ClipRect(
                    child: Container(
                      color: Colors.black,
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      child: viewport,
                    ),
                  ),
                ),
                
                // Delete Bin
                if (_isDraggingSticker)
                   Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isHoveringDelete ? Colors.red : Colors.grey[900],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.trash2, color: Colors.white, size: 24),
                    ),
                   ),
              ],
            ),
          ),
          
          // TOOLS UI (Bottom)
          _buildBottomTools(),
        ],
      ),
    );
  }
  
  Widget _buildBottomTools() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          if (_activeTool == ActiveTool.crop)
             Container(
               height: 60,
               color: Colors.black,
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                    _buildCropBtn("Free", null),
                    _buildCropBtn("Original", -1.0),
                    _buildCropBtn("1:1", 1.0),
                    _buildCropBtn("3:4", 3/4),
                    _buildCropBtn("16:9", 16/9),
                 ],
               ),
             ),
          
          if (_activeTool == ActiveTool.filter)
             Container(
                height: 90,
                color: Colors.black,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (ctx, i) {
                     final f = _filters[i];
                     return GestureDetector(
                       onTap: () => setState(() => _selectedFilter = f),
                       child: Container(
                         margin: const EdgeInsets.all(8),
                         child: Column(
                           children: [
                             Container(
                               width: 50, height: 50,
                               color: Colors.grey[800],
                               child: Center(child: Text(f[0], style: const TextStyle(color: Colors.white))),
                             ),
                             Text(f, style: TextStyle(color: _selectedFilter == f ? Colors.blue : Colors.grey, fontSize: 10)),
                           ],
                         ),
                       ),
                     );
                  },
                ),
             ),

          if (_activeTool == ActiveTool.sticker)
             Container(
                height: 50,
                color: Colors.black,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _emojis.map((e) => InkWell(
                    onTap: () => _addSticker(e),
                    child: Container(
                       padding: const EdgeInsets.all(10),
                       child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
             ),

          // Main Bar
          SafeArea(
            child: Container(
              height: 60,
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   IconButton(
                     icon: Icon(LucideIcons.wand2, color: _isAutoAdjusted ? Colors.blue : Colors.white),
                     onPressed: () => setState(() { _activeTool = ActiveTool.auto; _isAutoAdjusted = !_isAutoAdjusted; }),
                   ),
                   IconButton(
                     icon: Icon(LucideIcons.sliders, color: _activeTool == ActiveTool.filter ? Colors.blue : Colors.white),
                     onPressed: () => setState(() => _activeTool = _activeTool == ActiveTool.filter ? ActiveTool.none : ActiveTool.filter),
                   ),
                   IconButton(
                     icon: Icon(LucideIcons.crop, color: _activeTool == ActiveTool.crop ? Colors.blue : Colors.white),
                     onPressed: () => setState(() => _activeTool = _activeTool == ActiveTool.crop ? ActiveTool.none : ActiveTool.crop),
                   ),
                   IconButton(
                     icon: Icon(LucideIcons.smile, color: _activeTool == ActiveTool.sticker ? Colors.blue : Colors.white),
                     onPressed: () => setState(() => _activeTool = _activeTool == ActiveTool.sticker ? ActiveTool.none : ActiveTool.sticker),
                   ),
                ],
              ),
            ),
          )
      ],
    );
  }

  Widget _buildCropBtn(String label, double? ratio) {
     final isSelected = _cropRatio == (ratio == -1.0 ? null : ratio);
     return TextButton(
       onPressed: () {
          setState(() {
             if (ratio == -1.0) {
               _cropRatio = null;
               _transformController.value = Matrix4.identity(); 
             } else {
               _cropRatio = ratio;
             }
          });
       },
       child: Text(label, style: TextStyle(color: isSelected ? Colors.blue : Colors.white)),
     );
  }
}
