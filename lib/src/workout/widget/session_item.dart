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
