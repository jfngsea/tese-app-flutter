import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/JammerStateProvider.dart';


class JammerCurrentStateConsumer extends StatelessWidget {
  final bool showLastUpdated;
  final bool showJammerConectionSate;
  const JammerCurrentStateConsumer({
    super.key,
    this.showLastUpdated=true,
    this.showJammerConectionSate=true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<JammerStateProvider>(
      builder: (context, value, child) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if(showLastUpdated) ...[
            Text(
              "Last Updated: ${value.lastUpdate != null ? DateFormat("HH:mm dd-MM-yyyy").format(value.lastUpdate!) : "---"}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            Text(""),
          ],

          if(showJammerConectionSate) ...[
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
          ] else ...[
            Text("data"),
          ],


        ],
      ),
    );
  }
}
