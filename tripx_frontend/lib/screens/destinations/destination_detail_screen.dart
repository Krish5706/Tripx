import 'package:flutter/material.dart';
import 'package:tripx_frontend/models/destination.dart';
import 'package:tripx_frontend/repositories/destination_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DestinationDetailScreen extends StatefulWidget {
  const DestinationDetailScreen({super.key});

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  final DestinationRepository _repository = DestinationRepository();
  Future<String>? _detailsFuture;
  late Destination _destination;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _destination = ModalRoute.of(context)!.settings.arguments as Destination;
    _detailsFuture =
        _repository.getDestinationDetails(_destination.name, _destination.country);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _destination.name,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _destination.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: colorScheme.onSurfaceVariant,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.9),
                          colorScheme.surface.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<String>(
            future: _detailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Could not load details.',
                      style: textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildMarkdownContent(snapshot.data!, context),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Simple Markdown Parser Widget ---
  Widget _buildMarkdownContent(String text, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final List<Widget> content = [];
    final lines = text.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('**') && line.endsWith('**')) {
        content.add(Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
          child: Text(
            line.replaceAll('**', ''),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ));
      } else if (line.startsWith('* ') || line.startsWith('- ')) {
        content.add(Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: textTheme.bodyLarge?.copyWith(height: 1.5)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ));
      } else if (line.isNotEmpty) {
        content.add(Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            line,
            style: textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }
}