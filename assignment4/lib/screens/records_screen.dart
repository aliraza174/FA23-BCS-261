import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  Future<List<Map<String, dynamic>>> _fetch() async {
    final res = await Supabase.instance.client
        .from('submissions')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _delete(String id) async {
    await Supabase.instance.client
        .from('submissions')
        .delete()
        .eq('id', id);

    setState(() {});
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Record'),
        content:
            const Text('This action is permanent. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _delete(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Submitted Records'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No records found',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: isWide
                ? _buildTable(data)
                : _buildCards(data),
          );
        },
      ),
    );
  }

  /// Web / Desktop view
  Widget _buildTable(List<Map<String, dynamic>> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 56,
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Gender')),
            DataColumn(label: Text('Actions')),
          ],
          rows: data.map((r) {
            return DataRow(
              cells: [
                DataCell(Text(r['full_name'])),
                DataCell(Text(r['email'])),
                DataCell(Text(r['phone'])),
                DataCell(Text(r['gender'])),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(r['id']),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Mobile view
  Widget _buildCards(List<Map<String, dynamic>> data) {
    return ListView.separated(
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = data[i];

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            title: Text(
              r['full_name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${r['email']}'),
                  Text('Phone: ${r['phone']}'),
                  Text('Gender: ${r['gender']}'),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(r['id']),
            ),
          ),
        );
      },
    );
  }
}
