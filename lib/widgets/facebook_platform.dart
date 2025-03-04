import 'package:flutter/material.dart';

class FacebookPlatform extends StatefulWidget {
  final BuildContext context;
  final Function(String?) onPlatformSelected;
  final TextEditingController streamKeyController;

  const FacebookPlatform({
    required this.context,
    required this.onPlatformSelected,
    required this.streamKeyController,
    Key? key,
  }) : super(key: key);

  @override
  _FacebookPlatformState createState() => _FacebookPlatformState();
}

class _FacebookPlatformState extends State<FacebookPlatform> {
  bool _obscureText = true; // Trạng thái ẩn/hiện trong dialog

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => widget.onPlatformSelected(null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 0.0),
          child: Column(
            children: [
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(widget.context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đăng nhập Facebook đang phát triển')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: widget.context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Nhập Stream Key cho Facebook'),
                        content: StatefulBuilder(
                          builder: (BuildContext context, StateSetter setDialogState) {
                            return TextField(
                              controller: widget.streamKeyController,
                              obscureText: _obscureText,
                              decoration: InputDecoration(
                                labelText: 'Stream Key',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFF4e7fff),
                                  ),
                                  onPressed: () {
                                    setDialogState(() {
                                      _obscureText = !_obscureText;
                                      print('Obscure text changed to: $_obscureText'); // Debug
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(widget.context).showSnackBar(
                                const SnackBar(content: Text('Stream Key đã được lưu')),
                              );
                            },
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Nhập Stream Key',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
