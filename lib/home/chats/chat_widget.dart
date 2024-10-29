import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/home/auctions/auction_card.dart';
import 'package:harvest_guard/home/chats/chat_page.dart';
import 'package:harvest_guard/services/tools.dart';
import 'package:provider/provider.dart';

class ChatWidget extends StatefulWidget {
  final String chatUid;
  final String message;
  final Map? file;
  final bool isReceiver;
  final String timestamp;
  final ImageProvider imageSender;
  final ImageProvider imageReceiver;
  final bool isHiddenTime;
  final bool isHiddenDate;
  final bool isCentered;
  final EdgeInsets margin;
  final bool isSeen;

  const ChatWidget({
    super.key,
    required this.chatUid,
    required this.message,
    required this.isReceiver,
    required this.timestamp,
    required this.imageSender,
    required this.imageReceiver,
    required this.isHiddenTime,
    required this.isHiddenDate,
    required this.isCentered,
    this.file,
    this.margin = const EdgeInsets.symmetric(vertical: 2.0, horizontal: 20),
    this.isSeen = false,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  bool _timeHidden = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var borderRadius = widget.isReceiver
        ? BorderRadius.only(
            topLeft: const Radius.circular(20.0),
            topRight: widget.isCentered
                ? const Radius.circular(5.0)
                : const Radius.circular(20.0),
            bottomLeft: const Radius.circular(20.0),
            bottomRight: const Radius.circular(5.0),
          )
        : BorderRadius.only(
            topLeft: widget.isCentered
                ? const Radius.circular(5.0)
                : const Radius.circular(20.0),
            topRight: const Radius.circular(20.0),
            bottomRight: const Radius.circular(20.0),
            bottomLeft: const Radius.circular(5.0),
          );

    return Container(
      alignment:
          widget.isReceiver ? Alignment.centerRight : Alignment.centerLeft,
      margin: widget.margin,
      width: MediaQuery.of(context).size.width *
          0.75, // Set width to 75% of the screen

      child: Column(
        crossAxisAlignment: widget.isReceiver
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
              decoration: BoxDecoration(
                  color: widget.isReceiver
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primary,
                  borderRadius: borderRadius),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: widget.isReceiver
                      ? Theme.of(context)
                          .colorScheme
                          .surfaceTint
                          .withOpacity(0.25)
                      : Theme.of(context)
                          .colorScheme
                          .inversePrimary
                          .withOpacity(0.5),
                  onTap: () {
                    setState(() {
                      if (widget.isHiddenTime) {
                        _timeHidden = !_timeHidden;
                      }
                    });
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Message Options'),
                          contentPadding:
                              const EdgeInsets.only(top: 10.0, bottom: 20.0),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 25.0),
                                leading: const Icon(Icons.copy),
                                title: const Text('Copy'),
                                onTap: () async {
                                  // copy to clipboard
                                  await Clipboard.setData(
                                      ClipboardData(text: widget.message));
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 25.0),
                                leading: const Icon(Icons.delete),
                                title: const Text('Delete'),
                                onTap: () async {
                                  await FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(widget.chatUid)
                                      .collection('messages')
                                      .doc(widget.timestamp)
                                      .delete();

                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Message deleted'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                               ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 25.0),
                                  leading: const Icon(Icons.edit),
                                  title: const Text('Edit'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    
                                  },
                                ), 
                            ],
                          ),
                        );
                      },
                    );
                  },
                  borderRadius: borderRadius,
                  child: Stack(
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.file != null &&
                                widget.file!['type'] == 'auction')
                              Container(
                                  margin: const EdgeInsets.only(
                                      left: 10.0, right: 10.0, top: 10.0),
                                  height: 370,
                                  child: AuctionCard(
                                      product: widget.file!['auctionInfo']
                                          ['itemInfo'],
                                      bid: widget.file!['currentBid'],
                                      bidCount: widget
                                          .file!['auctionInfo']['bidUid']
                                          .length,
                                      epochStart: int.parse(widget
                                          .file!['auctionInfo']['epochStart']),
                                      epochEnd: int.parse(widget
                                          .file!['auctionInfo']['epochEnd']),
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                          '/auction',
                                          arguments: {
                                            'auctionUid':
                                                widget.file!['data']['auctionId'],
                                            'from': context.findAncestorWidgetOfExactType<ChatPage>(),
                                          },
                                        );
                                      })),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 10.0),
                                child: Text(
                                  widget.message,
                                  style: TextStyle(
                                      color: widget.isReceiver
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                      fontSize: 16.0),
                                ))
                          ])
                    ],
                  ),
                ),
              )),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves
                .fastEaseInToSlowEaseOut, // Use the bounce curve for animation
            height: (widget.isHiddenTime && !_timeHidden
                ? 0.0
                : 20.0), // Height of the box animated with a bounce effect
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                parseDate(widget.timestamp),
                style: TextStyle(
                    fontSize: 12.0,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.75)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
