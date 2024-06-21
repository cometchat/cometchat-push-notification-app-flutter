import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pn/services/api_services.dart';
import 'package:flutter_pn/services/cometchat_service.dart';

import '../models/material_button_user_model.dart';

class SampleUsersLoginSection extends StatelessWidget {
  final BuildContext thatContext;

  const SampleUsersLoginSection({
    super.key,
    required this.thatContext,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MaterialButtonUserModel>>(
      future: ApiServices.fetchUsers(),
      builder: (BuildContext context,
          AsyncSnapshot<List<MaterialButtonUserModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loader while fetching data
          return Center(
            child: Image.asset(
              AssetConstants.spinner,
              package: UIConstants.packageName,
            ),
          );
        } else if (snapshot.hasError) {
          // Handle error
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          // Show user selection buttons
          return GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 3.0,
            children: (snapshot.data ?? []).take(4).map((user) {
              return userSelectionButton(user, context);
            }).toList(),
          );
        }
      },
    );
  }

  Widget userSelectionButton(
    MaterialButtonUserModel model,
    BuildContext context,
  ) {
    return MaterialButton(
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      onPressed: () {
        CometChatService().login(model.userId, context);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: model.imageURL.startsWith('http')
                  ? Image.network(
                      model.imageURL,
                      height: 30,
                      width: 30,
                    )
                  : Image.asset(
                      model.imageURL,
                      height: 30,
                      width: 30,
                    ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                model.username,
                style: const TextStyle(color: Colors.white, fontSize: 14.0),
              ),
            )
          ],
        ),
      ),
    );
  }
}
