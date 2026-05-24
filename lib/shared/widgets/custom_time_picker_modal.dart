import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wheel_picker/wheel_picker.dart';

Future<TimeOfDay?> showTimePickerModalBottomSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return const _TimeWheelContent();
    },
  );
}

class _TimeWheelContent extends StatefulWidget {
  const _TimeWheelContent();

  @override
  State<_TimeWheelContent> createState() => _TimeWheelContentState();
}

class _TimeWheelContentState extends State<_TimeWheelContent> {
  final now = TimeOfDay.now();
  late final _hoursWheel = WheelPickerController(
    itemCount: 24,
    initialIndex: now.hour % 24,
  );
  late final _minutesWheel = WheelPickerController(
    itemCount: 60,
    initialIndex: now.minute,
    mounts: [_hoursWheel],
  );

  @override
  void dispose() {
    _hoursWheel.dispose();
    _minutesWheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: greyscale200,
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          AppText(text: 'time'.tr(), size: 24, fw: FontWeight.w700),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: greyscale200),
          WheelPickerWidget(hoursWheel: _hoursWheel, minuteWheel: _minutesWheel),
          const Divider(height: 1, thickness: 1, color: greyscale200),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledSecondaryAppButton(
                  text: 'cancel'.tr(),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledAppButton(
                  text: 'ok'.tr(),
                  isActive: true,
                  onTap: () {
                    final time = TimeOfDay(
                      hour: _hoursWheel.selected,
                      minute: _minutesWheel.selected,
                    );

                    Navigator.of(context).pop(time);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class WheelPickerWidget extends StatefulWidget {
  final WheelPickerController hoursWheel;
  final WheelPickerController minuteWheel;
  const WheelPickerWidget({
    super.key,
    required this.hoursWheel,
    required this.minuteWheel,
  });

  @override
  State<WheelPickerWidget> createState() => _WheelPickerWidgetState();
}

class _WheelPickerWidgetState extends State<WheelPickerWidget> {
  final now = TimeOfDay.now();
  // late final _hoursWheel = WheelPickerController(
  //   itemCount: 24,
  //   initialIndex: now.hour % 24,
  // );
  // late final _minutesWheel = WheelPickerController(
  //   itemCount: 60,
  //   initialIndex: now.minute,
  //   mounts: [_hoursWheel],
  // );

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 30.0, height: 1.6);
    final wheelStyle = WheelPickerStyle(
      itemExtent: textStyle.fontSize! * textStyle.height!,
      squeeze: 0.8,
      diameterRatio: 1.3,
      surroundingOpacity: .8,
      magnification: 1.2,
    );

    Widget itemBuilder(BuildContext context, int index) {
      return AppText(
        text: "$index".padLeft(2, '0'),
        size: 40,
      );
    }

    final timeWheels = <Widget>[
      for (final wheelController in [widget.hoursWheel, widget.minuteWheel])
        Expanded(
          child: WheelPicker(
            builder: itemBuilder,
            controller: wheelController,
            looping: wheelController == widget.minuteWheel,
            style: wheelStyle,
            selectedIndexColor: primary900,
          ),
        ),
    ];
    timeWheels.insert(1, const AppText(text: ":", size: 50, color: primary900));

    return Center(
      child: SizedBox(
        width: double.infinity,
        height: 360.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _centerBar(context),
            Row(children: [...timeWheels]),
          ],
        ),
      ),
    );
  }

  Widget _centerBar(BuildContext context) {
    return Center(
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 80.0,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primary900, width: 1),
                  top: BorderSide(color: primary900, width: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Container(
              height: 80.0,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: primary900, width: 1),
                  top: BorderSide(color: primary900, width: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
