import 'package:flutter/material.dart';

/// Shared "official document" visual building blocks - used by both the
/// fillable Apply form and the read-only submitted-application view, so a
/// citizen sees the same document layout whether they're filling it in or
/// looking back at what they submitted.

Widget documentSheet({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFCCCCCC)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: child,
  );
}

Widget documentHeader({required String formName, required String? subTitle}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFCCCCCC))),
        alignment: Alignment.center,
        child: const Text('Logo', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Text(
                formName.isNotEmpty ? formName : 'FORM NO',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                (subTitle?.isNotEmpty ?? false) ? subTitle!.toUpperCase() : 'DOCUMENT TITLE',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
      Container(
        width: 64,
        height: 56,
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCCCCCC))),
        alignment: Alignment.center,
        child: const Text('Emblem\n/ QR', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey)),
      ),
    ],
  );
}

Widget documentFieldRow({required String label, bool required = false, required Widget input}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
                children: [
                  TextSpan(text: label),
                  if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                  const TextSpan(text: ' :'),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: input),
      ],
    ),
  );
}

Widget documentBoxedInput(Widget child) {
  return Container(
    decoration: BoxDecoration(border: Border.all(color: Colors.black)),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: child,
  );
}

Widget documentHeading(String label) {
  return Container(
    margin: const EdgeInsets.only(top: 16, bottom: 8),
    padding: const EdgeInsets.only(bottom: 4),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 2))),
    child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
  );
}

Widget documentParagraph(String label) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(label, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
  );
}

Widget documentFooter({required String presentedBy, required String email, required Widget telephone}) {
  return Container(
    padding: const EdgeInsets.only(top: 16),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 2))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Presented by:', style: TextStyle(fontWeight: FontWeight.bold)),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(border: Border.all(color: Colors.black)),
          child: Text(presentedBy.isNotEmpty ? presentedBy : '-'),
        ),
        const SizedBox(height: 10),
        documentFooterBoxedRow('Email:', Text(email.isNotEmpty ? email : '-')),
        const SizedBox(height: 8),
        documentFooterBoxedRow('Telephone:', telephone),
      ],
    ),
  );
}

Widget documentFooterBoxedRow(String label, Widget value) {
  return Container(
    decoration: BoxDecoration(border: Border.all(color: Colors.black)),
    child: Row(
      children: [
        Container(
          width: 90,
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: value)),
      ],
    ),
  );
}
