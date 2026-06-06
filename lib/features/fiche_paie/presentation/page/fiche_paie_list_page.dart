import 'package:flutter/material.dart';

class FichePaieListPage extends StatelessWidget {
  const FichePaieListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fiches de paie")),
      body: ListView.builder(
        itemCount: 10, // remplacé par bloc plus tard
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text("Fiche #$index"),
              subtitle: const Text("CDI - Janvier"),
              trailing: const Icon(Icons.picture_as_pdf),
              onTap: () {
                // ouvrir détail ou PDF
              },
            ),
          );
        },
      ),
    );
  }
}