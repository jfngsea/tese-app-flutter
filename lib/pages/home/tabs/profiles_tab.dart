import 'package:flutter/material.dart';
import 'package:jam_app/components/JammerCurrentStateConsumer.dart';
import 'package:jam_app/components/LoadingWidget.dart';
import 'package:jam_app/components/ProfileContentCard.dart';
import 'package:jam_app/pages/home/tabs/waveforms_tab.dart';
import 'package:jam_app/providers/ProfileProvider.dart';
import 'package:provider/provider.dart';

import '../../../components/NoListItemsCard.dart';

class ProfilesTab extends StatelessWidget {
  const ProfilesTab({super.key});

  @override
  Widget build(BuildContext context) {
    ProfileProvider provider =
        Provider.of<ProfileProvider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profiles"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: provider.pick_from_device_storage,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.force_local_update,
          ),
        ],
      ),
      body: Column(
        children: [
          const JammerCurrentStateConsumer(),
          if (provider.local_profiles.isEmpty) ...[
            const Expanded(child: NoListItemsCard()),
          ] else ...[
            Expanded(
              child: ListView.builder(
                itemCount: provider.local_profiles.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(provider.local_profiles[index]),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            ProfileDetailPage(provider.local_profiles[index])));
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => delete_on_click(context, provider.local_profiles[index]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.upload),
                        onPressed: () => upload_on_click(context, provider.local_profiles[index]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}

class ProfileDetailPage extends StatelessWidget {
  final String profile_name;

  const ProfileDetailPage(this.profile_name, {super.key});

  @override
  Widget build(BuildContext context) {
    ProfileProvider provider =
        Provider.of<ProfileProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Detail"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => delete_on_click(context, profile_name),
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => upload_on_click(context, profile_name),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Card(
                child: ListTile(
              title: Text("Name: $profile_name"),
            )),

            FutureBuilder(future: provider.get_model_from_file(profile_name), builder: (context, snapshot) {
              if(snapshot.hasData){
                return ProfileContentCard(snapshot.data!);
              }
              if(snapshot.hasError){
                return Text(snapshot.error.toString());
              }
              return LoadingWidget();
            },),
          ],
        ),
      ),
    );
  }
}

void delete_on_click(BuildContext context, String name) async {
  final res = await Provider.of<ProfileProvider>(context, listen: false).delete_local_profile(name);
  if (res) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deleted ${name}!")));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting ${name}!")));
  }
}
void upload_on_click(BuildContext context, String name) async {
  final res = await Provider.of<ProfileProvider>(context, listen: false).apply_profile_in_jammer(name);
  if (res) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Applied  ${name}!")));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error applying ${name}!")));
  }
}