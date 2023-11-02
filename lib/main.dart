import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dnd/flutter_dnd.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:silent/ex.dart';
import 'package:system_info2/system_info2.dart';
import 'package:url_launcher/url_launcher.dart';


main() {
  runApp(
    const MaterialApp(
      home: Example(),
    ),
  );
}


class Example extends StatefulWidget {
  const Example({Key? key}) : super(key: key);

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  List<String> numbersTrue = [/*"01202089993" ,"01223378428" , "01227236361"*/];
  List<String> numbersFalse = ["01202089993" ,"01223378428" , "01227236361"];
  PhoneState status = PhoneState.nothing();
  bool granted = false;


  Future<bool> checkPermission() async {
    var status = await Permission.phone.status;
    return status.isGranted;
  }

/*
  Future<bool> requestPermission() async {
    var status = await Permission.phone.request();

    if ( await FlutterDnd.isNotificationPolicyAccessGranted!= null) {
      FlutterDnd.gotoPolicySettings();
    }

    print(PermissionStatus);
    return switch (status) {
      PermissionStatus.denied || PermissionStatus.restricted || PermissionStatus.limited || PermissionStatus.permanentlyDenied => false,
      PermissionStatus.provisional || PermissionStatus.granted => true,
    };

  }*/

  Future<void> requestPermission() async {
    var status = await Permission.phone.request();


    if (status.isGranted) {
      // Permission is granted, perform necessary actions
      setStream();
    }
  }


  AudioStream _audioStream = AudioStream.ring;
  AudioSessionCategory _audioSessionCategory = AudioSessionCategory.ambient;
  double _currentVolume = 0.0;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) setStream();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Platform.isIOS) {
        await _loadIOSAudioSessionCategory();
      }
      if (Platform.isAndroid) {
        await _loadAndroidAudioStream();
      }
    });
    FlutterVolumeController.addListener((volume) {
      setState(() {
        _currentVolume = volume;
      });
    });
/*
    openNotificationPolicySettings();
*/

    checkPermission().then((isGranted) {
      setState(() {
        granted = isGranted;
        if (!granted) {
          // If permission is not granted, prompt the user
          checkDND();
          requestPermission();
        } else {
          // Permission is already granted, perform necessary actions
          setStream();
        }
      });
    });
  }

  void checkDND()async{
    if ( await FlutterDnd.isNotificationPolicyAccessGranted!= null) {
      FlutterDnd.gotoPolicySettings();
    }
  }

  void returnAsIt(bool t){
    FlutterVolumeController.setMute(
      t,
      stream: AudioStream.ring,
    );
  }

  @override
  void dispose() {
    FlutterVolumeController.removeListener();
    super.dispose();
  }

  void setStream() {
    PhoneState.stream.listen((event) {
      print(event.status.name);
      setState(() {
        status = event;
        if (numbersTrue.contains(status.number)){
          FlutterVolumeController.setMute(
          false,
          stream: AudioStream.ring,
        );
          if(event.status.name =="CALL_ENDED"){
            returnAsIt(true);
          }
        }
        else if (numbersFalse.contains(status.number)){
          FlutterVolumeController.setMute(
          true,
          stream: AudioStream.ring,
        );
          if(event.status.name =="CALL_ENDED"){
            returnAsIt(false);
          }
        }
      });

    });
  }





/*

  void openNotificationPolicySettings() async {
    String url = 'package:com.android.settings/notification.NotificationAccessSettings';
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle if the settings page cannot be opened
    }
  }
*/



  Future<void> handleMuteButtonPress() async {
    try {
      await FlutterVolumeController.setMute(false, stream: _audioStream);
    } catch (e) {
      print('Failed to set mute: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone State"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (Platform.isAndroid)
              /*MaterialButton(
                onPressed: !granted
                    ? () async {
                  bool temp = await requestPermission();
                  setState(() {
                    granted = temp;
                    if (granted) {
                      setStream();
                    }
                  });
                }
                    : null,
                child: const Text("Request permission of Phone"),
              ),*/
              MaterialButton(
                onPressed: !granted
                    ? () async {
                  requestPermission();
                }
                    : null,
                child: const Text("Request Phone Permission"),
              ),
            const Text(
              "Status of call",
              style: TextStyle(fontSize: 24),
            ),
            if (status.status == PhoneStateStatus.CALL_INCOMING || status.status == PhoneStateStatus.CALL_STARTED)
                Text(
                  "Number: ${status.number}",
                  style: const TextStyle(fontSize: 24),
                ),
            Icon(
              getIcons(),
              color: getColor(),
              size: 80,
            ),
            ElevatedButton(onPressed: (){
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Home() ));
            }, child: Text('not'),),
          ],
        ),
      ),
    );
  }

  IconData getIcons() {

    print(status.number);
    return switch (status.status) {
      PhoneStateStatus.NOTHING => Icons.clear,
      PhoneStateStatus.CALL_INCOMING => Icons.add_call,
      PhoneStateStatus.CALL_STARTED => Icons.call,
      PhoneStateStatus.CALL_ENDED => Icons.call_end,
    };
  }

  Color getColor() {
    return switch (status.status) {
      PhoneStateStatus.NOTHING || PhoneStateStatus.CALL_ENDED => Colors.red,
      PhoneStateStatus.CALL_INCOMING => Colors.green,
      PhoneStateStatus.CALL_STARTED => Colors.orange,
    };
  }


  Future<void> _loadIOSAudioSessionCategory() async {
    final category = await FlutterVolumeController.getIOSAudioSessionCategory();
    if (category != null) {
      setState(() {
        _audioSessionCategory = category;
      });
    }
  }

  Future<void> _loadAndroidAudioStream() async {
    final audioStream = await FlutterVolumeController.getAndroidAudioStream();
    if (audioStream != null) {
      setState(() {
        _audioStream = _audioStream;
      });
    }
  }


}
