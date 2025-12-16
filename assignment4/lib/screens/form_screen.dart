import 'package:flutter/material.dart';
import 'records_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  String _gender = 'Male';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await Supabase.instance.client.from('submissions').insert({
      'full_name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
      'gender': _gender,
    });

    _name.clear();
    _email.clear();
    _phone.clear();
    _address.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submitted successfully')),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Submission Form'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Information',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// Responsive grid
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 2 : 1,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 4,
                        ),
                        children: [
                          TextFormField(
                            controller: _name,
                            decoration:
                                _input('Full Name', Icons.person),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          TextFormField(
                            controller: _email,
                            decoration:
                                _input('Email', Icons.email),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                v != null && v.contains('@')
                                    ? null
                                    : 'Invalid email',
                          ),
                          TextFormField(
                            controller: _phone,
                            decoration:
                                _input('Phone Number', Icons.phone),
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v != null && v.length >= 7
                                    ? null
                                    : 'Invalid phone',
                          ),
                          DropdownButtonFormField<String>(
                            value: _gender,
                            decoration:
                                _input('Gender', Icons.people),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Male', child: Text('Male')),
                              DropdownMenuItem(
                                  value: 'Female', child: Text('Female')),
                              DropdownMenuItem(
                                  value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _gender = v);
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _address,
                        decoration:
                            _input('Address', Icons.location_on),
                        maxLines: 3,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Submit'),
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
