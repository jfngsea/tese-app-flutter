import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/JammerStateProvider.dart';


class JammerCurrentStateConsumer extends StatelessWidget {
  const JammerCurrentStateConsumer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JammerStateProvider>(
      builder: (context, value, child) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Last Updated: ${value.lastUpdate != null ? DateFormat("HH:mm dd-MM-yyyy").format(value.lastUpdate!) : "---"}",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (value.connection_state ==
              JammerConnectionState.fail) ...[
            Text("Offline 🔴",
                style: Theme.of(context).textTheme.bodySmall),
          ] else if (value.connection_state ==
              JammerConnectionState.ok) ...[
            Text("Online 🟢",
                style: Theme.of(context).textTheme.bodySmall),
          ] else ...[
            Text("Online 🟠",
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
