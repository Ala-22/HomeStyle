import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RoomOption {
  final String name;
  final IconData icon;
  final String promptHint;
  final String imageUrl;

  const RoomOption({
    required this.name,
    required this.icon,
    required this.promptHint,
    required this.imageUrl,
  });
}

const String _roomImageBase =
    'http://localhost/homestyle_api/images/';

const roomOptions = [
  RoomOption(
    name: 'Kitchen',
    icon: Icons.kitchen_outlined,
    promptHint: 'e.g. modern kitchen, wooden cabinets, warm lighting',
    imageUrl: '${_roomImageBase}Kitchen/1.png',
  ),
  RoomOption(
    name: 'Bedroom',
    icon: Icons.bed_outlined,
    promptHint: 'e.g. cozy bedroom, soft colors, minimalist',
    imageUrl: '${_roomImageBase}Bedrooms/1.jpg',
  ),
  RoomOption(
    name: 'Living Room',
    icon: Icons.chair_outlined,
    promptHint: 'e.g. elegant living room, beige sofa, plants',
    imageUrl: '${_roomImageBase}Living%20Room/1.jpg',
  ),
  RoomOption(
    name: 'Bathroom',
    icon: Icons.bathtub_outlined,
    promptHint: 'e.g. luxury bathroom, marble, gold fixtures',
    imageUrl: '${_roomImageBase}Bathroom/1.jpg',
  ),
  RoomOption(
    name: 'Office',
    icon: Icons.desk_outlined,
    promptHint: 'e.g. home office, comfortable desk, good lighting',
    imageUrl: '${_roomImageBase}Guest%20Room/1.jpg',
  ),
  RoomOption(
    name: 'Kids Room',
    icon: Icons.toys_outlined,
    promptHint: 'e.g. playful kids room, colorful, safe and fun',
    imageUrl: '${_roomImageBase}Bedrooms/2.jpg',
  ),
  RoomOption(
    name: 'Dining Room',
    icon: Icons.table_restaurant_outlined,
    promptHint: 'e.g. elegant dining room, large wooden table, pendant lights',
    imageUrl: '${_roomImageBase}Guest%20Room/2.jpg',
  ),
  RoomOption(
    name: 'Balcony',
    icon: Icons.deck_outlined,
    promptHint: 'e.g. cozy balcony, plants, outdoor seating, evening lights',
    imageUrl: '${_roomImageBase}Living%20Room/2.jpg',
  ),
];

class DesignStyle {
  final String name;
  final String prompt;
  final String imageUrl;

  const DesignStyle({
    required this.name,
    required this.prompt,
    required this.imageUrl,
  });
}

const designStyles = [
  DesignStyle(
    name: 'Modern',
    prompt: 'modern interior design',
    imageUrl: '${_roomImageBase}Living%20Room/2.jpg',
  ),
  DesignStyle(
    name: 'Minimalist',
    prompt: 'minimalist interior design with clean lines',
    imageUrl: '${_roomImageBase}Kitchen/2.jpg',
  ),
  DesignStyle(
    name: 'Classic',
    prompt: 'classic elegant interior design',
    imageUrl: '${_roomImageBase}Living%20Room/5.jpg',
  ),
  DesignStyle(
    name: 'Scandinavian',
    prompt: 'scandinavian interior design, light wood, cozy',
    imageUrl: '${_roomImageBase}Bedrooms/3.png',
  ),
  DesignStyle(
    name: 'Luxurious',
    prompt: 'luxurious high-end interior design, premium materials',
    imageUrl: '${_roomImageBase}Bathroom/2.jpg',
  ),
  DesignStyle(
    name: 'Industrial',
    prompt: 'industrial loft interior design, exposed brick and metal',
    imageUrl: '${_roomImageBase}Guest%20Room/3.jpg',
  ),
];

class AIDesignerScreen extends StatelessWidget {
  const AIDesignerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Room Designer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const AIDesignerBody(),
    );
  }
}

class AIDesignerBody extends StatefulWidget {
  const AIDesignerBody({super.key});

  @override
  State<AIDesignerBody> createState() => _AIDesignerBodyState();
}

class _AIDesignerBodyState extends State<AIDesignerBody> {
  final ApiService _apiService = ApiService();
  final TextEditingController _descriptionController =
      TextEditingController();

  String selectedRoom = 'Living Room';
  String selectedStyle = 'Modern';

  bool _loading = false;
  bool _usingDirect = false;
  String? _error;

  String? _imageUrl;
  String? _generatedPrompt;
  String _lastDescription = '';

  final List<Map<String, String>> _history = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _stylePrompt() {
    switch (selectedStyle) {
      case 'Modern':
        return 'modern interior design';
      case 'Minimalist':
        return 'minimalist interior design with clean lines, neutral palette';
      case 'Classic':
        return 'classic elegant interior design, timeless details';
      case 'Scandinavian':
        return 'scandinavian interior design, light wood, cozy textiles';
      case 'Luxurious':
        return 'luxurious high-end interior design, premium materials';
      case 'Industrial':
        return 'industrial loft interior design, exposed brick and metal';
      default:
        return 'beautiful interior design';
    }
  }

  String _directPollinationsUrl(String prompt) {
    final encoded = Uri.encodeQueryComponent(prompt);

    final seed = DateTime.now().millisecondsSinceEpoch % 100000;

    return 'https://image.pollinations.ai/prompt/'
        '$encoded?width=1024&height=1024&seed=$seed&nologo=true';
  }

  Future<void> _generate() async {
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your dream room first'),
        ),
      );
      return;
    }

    final prompt = '$selectedRoom in $selectedStyle style - '
        '${_stylePrompt()}. User request: $description. '
        'High quality, detailed, photorealistic rendering.';

    setState(() {
      _loading = true;
      _usingDirect = false;
      _error = null;
      _imageUrl = null;
      _generatedPrompt = null;
      _lastDescription = description;
    });

    try {
      final result = await _apiService.generateDesign(
        roomType: selectedRoom,
        description: description,
        style: selectedStyle,
      );

      if (!mounted) return;

      final url = result['image_url'] as String?;
      final resultPrompt = result['prompt'] as String?;

      setState(() {
        _loading = false;
        _imageUrl = url;
        _generatedPrompt = resultPrompt;

        if (url != null) {
          _history.insert(
            0,
            {
              'room': selectedRoom,
              'description': description,
              'image': url,
            },
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _usingDirect = true;
        _imageUrl = _directPollinationsUrl(prompt);
        _generatedPrompt = prompt;

        _history.insert(
          0,
          {
            'room': selectedRoom,
            'description': description,
            'image': _imageUrl!,
          },
        );
      });
    }
  }

  String _defaultDesignName() {
    var name = _lastDescription.trim();

    if (name.isEmpty) return 'AI Design';

    if (name.length > 40) {
      name = name.substring(0, 40).trim();
    }

    return name;
  }

  Future<void> _saveDesign() async {
    final imageUrl = _imageUrl;

    if (imageUrl == null || _usingDirect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please use the local AI server (not the direct service) '
            'to save images to the AI Images section.',
          ),
        ),
      );
      return;
    }

    final filename = imageUrl.split('/').last;

    final nameController = TextEditingController(text: _defaultDesignName());
    final priceController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.add_photo_alternate_outlined,
          color: Colors.green,
          size: 36,
        ),
        title: const Text('Add to AI Images ✨'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Give this design a name and it will be added '
              'to the AI Images section in the home page.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Design name',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (leave empty for auto)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add to AI Images'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      nameController.dispose();
      priceController.dispose();
      return;
    }

    final name = nameController.text.trim().isEmpty
        ? 'AI Design'
        : nameController.text.trim();

    double? price;

    final priceText = priceController.text.trim();

    if (priceText.isNotEmpty) {
      price = double.tryParse(priceText);
    }

    nameController.dispose();
    priceController.dispose();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adding your design...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await _apiService.saveDesignToGallery(
        filename: filename,
        name: name,
        price: price,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added! Open the Home page to see it in '
            'AI Images ✨ ($name)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save the design.\n'
            'Make sure the AI server is running.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ============================
        // HEADER
        // ============================
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Design your dream room',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Describe your space and our AI agent will '
                'generate a design image for you.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // ============================
        // ROOM TYPE
        // ============================
        const Text(
          'Choose Room Type',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: roomOptions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final option = roomOptions[index];
            final selected = option.name == selectedRoom;

            return InkWell(
              onTap: () {
                setState(() {
                  selectedRoom = option.name;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? Colors.brown : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      option.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  color: Colors.brown.shade100,
                                  child: Center(
                                    child: Icon(
                                      option.icon,
                                      size: 26,
                                      color: Colors.brown.shade300,
                                    ),
                                  ),
                                ),
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.brown.shade200
                                  : Colors.brown.shade100,
                            ),
                            child: Icon(
                              option.icon,
                              size: 30,
                              color: Colors.brown.shade700,
                            ),
                          ),
                    ),

                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.45, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.68),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 7,
                      child: Text(
                        option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),

                    if (selected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.brown,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // ============================
        // DESIGN STYLE
        // ============================
        const Text(
          'Choose Design Style',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: designStyles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final style = designStyles[index];
            final selected = style.name == selectedStyle;

            return InkWell(
              onTap: () {
                setState(() {
                  selectedStyle = style.name;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? Colors.brown : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      style.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  color: Colors.brown.shade100,
                                  child: const Center(
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 22,
                                      color: Colors.brown,
                                    ),
                                  ),
                                ),
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            color: Colors.brown.shade200,
                            child: Center(
                              child: Text(
                                style.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    ),

                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.5, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 6,
                      child: Text(
                        style.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),

                    if (selected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.brown,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // ============================
        // DESCRIPTION
        // ============================
        const Text(
          'Describe Your Idea',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: roomOptions
                .firstWhere((o) => o.name == selectedRoom)
                .promptHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ============================
        // GENERATE BUTTON
        // ============================
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _generate,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _loading
                  ? 'Generating your dream room...'
                  : 'Generate Design',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        if (_loading) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Generating... the first image can take 10-60 seconds',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 14,
            ),
          ),
        ],

        // ============================
        // RESULT
        // ============================
        if (_imageUrl != null) ...[
          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Dream Room',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _usingDirect
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _usingDirect
                          ? Icons.cloud_outlined
                          : Icons.dns_outlined,
                      size: 14,
                      color: _usingDirect
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _usingDirect ? 'Direct service' : 'Local AI server',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _usingDirect
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;

                            return Container(
                              color: Colors.brown.shade50,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.brown.shade50,
                              height: 300,
                              child: const Center(
                                child:
                                    Text('Could not load the generated image'),
                              ),
                            );
                          },
                        ),
                      ),

                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            selectedRoom,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ADD BUTTON NEXT TO THE IMAGE
              if (!_usingDirect) ...[
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 132,
                      height: 66,
                      child: ElevatedButton(
                        onPressed: _saveDesign,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 24,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add to AI Images ✨',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Save to AI\nImages section',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          if (_usingDirect) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Generated through the free Pollinations service '
                    'because the local AI backend is not running.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (_generatedPrompt != null) ...[
            const SizedBox(height: 12),
            Text(
              _generatedPrompt!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],

        // ============================
        // HISTORY
        // ============================
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 30),

          const Text(
            'Design History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _history.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = _history[index];

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _imageUrl = item['image'];
                        _generatedPrompt = item['description'];
                      });
                    },
                    child: Image.network(
                      item['image']!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}