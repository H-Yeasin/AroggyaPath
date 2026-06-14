import 'dart:io';
import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final List<File> selectedFiles;
  final bool isSending;
  final VoidCallback onPickImage;
  final Function(int) onRemoveFile;
  final VoidCallback onSendMessage;
  final Function(String) onChanged;

  const ChatInput({
    super.key,
    required this.controller,
    required this.selectedFiles,
    required this.isSending,
    required this.onPickImage,
    required this.onRemoveFile,
    required this.onSendMessage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (selectedFiles.isNotEmpty)
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: selectedFiles.length,
            itemBuilder: (context, index) => Stack(children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                        image: FileImage(selectedFiles[index]),
                        fit: BoxFit.cover)),
              ),
              Positioned(
                top: 0,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemoveFile(index),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
            ]),
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Color(0xFF6C5CE7), size: 26),
              onPressed: onPickImage,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                ),
                onChanged: onChanged,
                onSubmitted: (_) => onSendMessage(),
              ),
            ),
            GestureDetector(
              onTap: onSendMessage,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 22),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}
