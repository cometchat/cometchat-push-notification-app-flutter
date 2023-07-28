import 'package:flutter/material.dart';

List<UserModel> userModelList = [
  UserModel("superhero1", "SUPERHERO1", "assets/ironman_avatar.png"),
  UserModel("superhero2", "SUPERHERO2", "assets/captainamerica_avatar.png"),
  UserModel("superhero3", "SUPERHERO3", "assets/spiderman_avatar.png"),
  UserModel("superhero5", "SUPERHERO5", "assets/cyclops_avatar.png"),
];

class UserModel {
  String uid;
  String username;
  String imageURL;

  UserModel(this.uid, this.username, this.imageURL);
}

class SampleUsersLoginSection extends StatelessWidget {
  final BuildContext thatContext;
  final Function onLoginPressed;

  const SampleUsersLoginSection({
    Key? key,
    required this.thatContext,
    required this.onLoginPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 10.0,
      mainAxisSpacing: 10.0,
      childAspectRatio: 3.0,
      children: userModelList
          .map((model) => UserLoginButton(
              model: model,
              thatContext: thatContext,
              onLoginPressed: onLoginPressed))
          .toList(),
    );
  }
}

class UserLoginButton extends StatelessWidget {
  final UserModel model;
  final BuildContext thatContext;
  final Function onLoginPressed;

  const UserLoginButton(
      {Key? key,
      required this.model,
      required this.thatContext,
      required this.onLoginPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      color: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      onPressed: () => onLoginPressed(model.uid),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Image.asset(
              model.imageURL,
              height: 30,
              width: 30,
            ),
          ),
          Text(
            model.username,
            style: const TextStyle(color: Colors.white, fontSize: 14.0),
          )
        ],
      ),
    );
  }
}
