import 'package:flutter/material.dart';
import '../domain/models/session_model.dart';
import '../presentation/session_detail_page.dart';

class SessionItem extends StatelessWidget {
  final WorkoutSession session;

  const SessionItem({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        title: Text(session.name),
        subtitle: Text(session.description ?? ''),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionDetailPage(session: session),
            ),
          );
        },
      ),
    );
  }
}
