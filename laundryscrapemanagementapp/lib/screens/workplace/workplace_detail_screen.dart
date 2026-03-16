import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/workplace_model.dart';

class WorkplaceDetailScreen extends StatelessWidget {
  final WorkplaceModel workplace;
  const WorkplaceDetailScreen({super.key, required this.workplace});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: workplace.bannerImageUrl != null ? 220 : 100,
            pinned: true,
            title: Text(workplace.name),
            flexibleSpace: FlexibleSpaceBar(
              background: workplace.bannerImageUrl != null
                  ? Image.network(workplace.bannerImageUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)]),
                      ),
                    ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // About
                if (workplace.description != null &&
                    workplace.description!.isNotEmpty) ...[
                  _Section(
                      title: 'About',
                      child: Text(workplace.description!,
                          style: const TextStyle(fontSize: 14, height: 1.6))),
                  const SizedBox(height: 16),
                ],

                // Location
                if (workplace.location != null) ...[
                  _Section(
                    title: 'Location',
                    child: GestureDetector(
                      onTap: () => launchUrl(Uri.parse(
                          'https://maps.google.com/?q=${Uri.encodeComponent(workplace.location!)}')),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Color(0xFF1A56DB), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(workplace.location!,
                                  style: const TextStyle(
                                      color: Color(0xFF1A56DB),
                                      decoration: TextDecoration.underline))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Instructions
                if (workplace.instructions != null &&
                    workplace.instructions!.isNotEmpty) ...[
                  _Section(
                    title: 'Employee Instructions',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(workplace.instructions!,
                          style: const TextStyle(fontSize: 14, height: 1.6)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Contact
                if (workplace.contactName != null) ...[
                  _Section(
                    title: 'Contact Person',
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(workplace.contactName!),
                          subtitle: workplace.contactEmail != null
                              ? Text(workplace.contactEmail!)
                              : null,
                        ),
                        if (workplace.contactPhone != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.phone, size: 18),
                              label: Text(workplace.contactPhone!),
                              onPressed: () => launchUrl(
                                  Uri.parse('tel:${workplace.contactPhone}')),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
