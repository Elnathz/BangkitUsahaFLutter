// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import '../../services/address_service.dart';

class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final AddressService _addressService = AddressService();
  bool _isLoadingLocation = false;

  // Fungsi Tambah Alamat via GPS
  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final result = await _addressService.getCurrentLocationAddress();

      if (!mounted) return;

      // Tampilkan Dialog Konfirmasi Simpan
      _showSaveAddressDialog(
        result['address'],
        result['latitude'],
        result['longitude'],
      );
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text("Gagal"),
        description: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _showSaveAddressDialog(String address, double lat, double lng) {
    final labelController = TextEditingController(text: "Rumah");
    final addressController = TextEditingController(text: address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Simpan Alamat"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: "Label (Contoh: Rumah, Kantor)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Detail Alamat",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _addressService.saveAddress(
                labelController.text,
                addressController.text,
                lat,
                lng,
              );
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Fungsi Tambah Alamat Manual (Formulir)
  void _showManualAddressDialog() {
    final labelController = TextEditingController(text: "Rumah");
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final postalCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Alamat Manual"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: "Label (Contoh: Rumah, Kantor)",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Jalan, No. Rumah, RT/RW",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: "Kota / Kecamatan",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: postalCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Kode Pos",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            onPressed: () async {
              if (addressController.text.trim().isEmpty || 
                  cityController.text.trim().isEmpty) {
                toastification.show(
                  context: context,
                  type: ToastificationType.warning,
                  title: const Text("Data Belum Lengkap"),
                  description: const Text("Harap isi detail alamat dan kota."),
                  autoCloseDuration: const Duration(seconds: 3),
                );
                return;
              }

              Navigator.pop(context);
              
              // Gabungkan menjadi satu string alamat lengkap
              String fullAddress = "${addressController.text.trim()}, ${cityController.text.trim()}";
              if (postalCodeController.text.isNotEmpty) {
                fullAddress += ", ${postalCodeController.text.trim()}";
              }

              await _addressService.saveAddress(
                labelController.text.isEmpty ? "Alamat" : labelController.text,
                fullAddress,
                0.0, // Lat 0.0 karena manual
                0.0, // Lng 0.0 karena manual
              );
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Alamat Pengiriman"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Tombol Gunakan Lokasi Saat Ini
          InkWell(
            onTap: _isLoadingLocation ? null : _useCurrentLocation,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  _isLoadingLocation
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          LucideIcons.mapPin,
                          color: Color(0xFF1565C0),
                        ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Gunakan Lokasi Saat Ini",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Otomatis cari alamat via GPS",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, color: Colors.grey),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          
          // Tombol Tambah Alamat Manual
          InkWell(
            onTap: _showManualAddressDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.pencil,
                    color: Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Isi Alamat Manual",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Isi formulir alamat jika GPS bermasalah",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, color: Colors.grey),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Daftar Alamat Tersimpan
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _addressService.getUserAddresses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.map,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Belum ada alamat tersimpan",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(LucideIcons.home, color: Colors.grey),
                      title: Text(
                        data['label'] ?? "Alamat",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        data['fullAddress'] ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Radio(
                        value: true,
                        groupValue: false, // Hanya visual indikator
                        onChanged: (val) {
                          Navigator.pop(context, data['fullAddress']);
                        },
                      ),
                      onTap: () {
                        // Kembalikan alamat yang dipilih ke halaman Checkout
                        Navigator.pop(context, data['fullAddress']);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
