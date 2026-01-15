  Widget _buildImagePreview() {
    if (_imageFile == null) return const SizedBox.shrink();
    
    if (kIsWeb) {
      // safe check for path
      if (_imageFile!.path.isEmpty) {
         // It's likely from bytes (XFile.fromData)
         return FutureBuilder<Uint8List>(
           future: _imageFile!.readAsBytes(),
           builder: (ctx, snapshot) {
             if (snapshot.hasData) {
               return Image.memory(
                 snapshot.data!,
                 fit: BoxFit.cover,
                 width: double.infinity,
               );
             }
             return const Center(child: CircularProgressIndicator());
           },
         );
      }
      return Image.network(
        _imageFile!.path,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    
    return Image.file(
      File(_imageFile!.path),
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }
