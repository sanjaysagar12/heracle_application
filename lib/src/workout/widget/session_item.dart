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
        title: Row(
          children: [
            Expanded(child: Text(session.name)),
            if (session.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
            ),
            if (session.isPublic)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.public,
                  size: 16,
                  color: Colors.blue[600],
                ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((session.description ?? '').isNotEmpty) Text(session.description!),
            // show lastWorkoutLogId if present
            if (session.lastWorkoutLogId != null && session.lastWorkoutLogId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Last Log: ${session.lastWorkoutLogId!}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
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
