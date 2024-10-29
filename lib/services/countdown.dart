import 'package:flutter/material.dart';
import 'dart:async';

class Countdown extends StatefulWidget {
  final int epochStart;
  final int epochEnd;

  const Countdown({
    super.key,
    required this.epochStart,
    required this.epochEnd,
  });

  /// Static method to generate countdown string without creating widget
  static List<String> getCountdownString(int epochStart, int epochEnd) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final start = epochStart * 1000;
    final end = epochEnd * 1000;
    
    String status;
    if (now < start) {
      status = 'Starts in';
    } else if (now < end) {
      status = 'Ends in';
    } else {
      return ['Auction ended', ''];
    }

    final targetTime = now < start ? start : end;
    final remaining = _calculateRemainingTime(targetTime, now);

    return [status , '${remaining['days']}d ${remaining['hours']}h ${remaining['minutes']}m ${remaining['seconds']}s'];
  }

  /// Static helper method for time calculations
  static Map<String, int> _calculateRemainingTime(int targetTime, int currentTime) {
    final difference = targetTime - currentTime;
    final totalSeconds = (difference / 1000).floor();
    
    if (totalSeconds < 0) {
      return {
        'days': 0,
        'hours': 0,
        'minutes': 0,
        'seconds': 0,
      };
    }

    return {
      'days': (totalSeconds / 86400).floor(),
      'hours': ((totalSeconds % 86400) / 3600).floor(),
      'minutes': ((totalSeconds % 3600) / 60).floor(),
      'seconds': totalSeconds % 60,
    };
  }

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  late DateTime currentTime;
  late String status;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    currentTime = DateTime.now();
    _updateStatus();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now();
        _updateStatus();
      });
    });
  }

  void _updateStatus() {
    final now = currentTime.millisecondsSinceEpoch;
    final start = widget.epochStart * 1000;
    final end = widget.epochEnd * 1000;

    if (now < start) {
      status = 'Starts in';
    } else if (now < end) {
      status = 'Ends in';
    } else {
      status = 'Auction ended';
    }
  }

  Map<String, int> _getRemainingTime(int targetTime) {
    return Countdown._calculateRemainingTime(
      targetTime,
      currentTime.millisecondsSinceEpoch,
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetTime = currentTime.millisecondsSinceEpoch < (widget.epochStart * 1000)
        ? widget.epochStart * 1000
        : widget.epochEnd * 1000;

    final remaining = _getRemainingTime(targetTime);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(status),
        if (status != 'Auction ended') ...[
          const SizedBox(width: 4),
          Text(
            '${remaining['days']}d ${remaining['hours']}h ${remaining['minutes']}m ${remaining['seconds']}s',
          ),
        ],
      ],
    );
  }
}