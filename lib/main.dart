import 'dart:io';
import 'package:flutter/material.dart';
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
  PhoneState status = PhoneState.nothing();
  bool granted = false;

  Future<bool> requestPermission() async {
    var status = await Permission.phone.request();


    print(PermissionStatus);
    return switch (status) {
      PermissionStatus.denied || PermissionStatus.restricted || PermissionStatus.limited || PermissionStatus.permanentlyDenied => false,
      PermissionStatus.provisional || PermissionStatus.granted => true,
    };
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
    openNotificationPolicySettings();
  }

  @override
  void dispose() {
    FlutterVolumeController.removeListener();
    super.dispose();
  }
  void setStream() {
    PhoneState.stream.listen((event) {
      setState(() {

        FlutterVolumeController.setMute(
          false,
          stream: AudioStream.ring,
        );
        status = event;
        print(status.number);
        print("this is status num");
        if (status.number == "01227236361") {
          print(_audioStream.toString());
          handleMuteButtonPress();
        }
      });
    });
  }




  void openNotificationPolicySettings() async {
    String url = 'package:com.android.settings/notification.NotificationAccessSettings';
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle if the settings page cannot be opened
    }
  }



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
              MaterialButton(
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
