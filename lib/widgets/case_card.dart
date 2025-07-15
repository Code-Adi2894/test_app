import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_app/entities.dart';

import '../Screens/case_detail_screen.dart';

class CaseCard extends StatefulWidget{
  final Cases cases;

  const CaseCard({
    Key? key,
    required this.cases
  }) : super(key: key);


  @override
    _CaseCardState createState() => _CaseCardState();
  }

  class _CaseCardState extends State<CaseCard> {

  bool isCaseSyncOn = false;

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CaseDetailScreen(case_: widget.cases )
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.cases.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14,
                              color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.cases.site.target?.name ?? 'No Site',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (widget.cases.description != null &&
                          widget.cases.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(widget.cases.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Created: ${widget.cases.createdAt.toString().substring(0, 19)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E)),
                      ),
                      Switch(
                          value: isCaseSyncOn,
                          onChanged: (bool value){
                            setState(() {
                              isCaseSyncOn = value;
                            });
                          }
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    // if (buildSyncButton(c) != null)
                    //   buildSyncButton(c)!,
                    IconButton(
                      icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF2196F3)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CaseDetailScreen(case_: widget.cases)
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }