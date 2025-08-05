import 'package:flutter/material.dart';

class ConnectivityIndicator extends StatefulWidget{
  final bool connectivityStatus;
  const ConnectivityIndicator({super.key, required this.connectivityStatus});

  @override
  State<ConnectivityIndicator> createState() => _ConnectivityIndicator();
}

class _ConnectivityIndicator extends State<ConnectivityIndicator>{
  @override
  Widget build(BuildContext context){
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: (widget.connectivityStatus)
        ? const Color(0xFF28A745)
        : const Color(0xFFDC3545),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if(widget.connectivityStatus)
            const Icon(
              Icons.wifi,
              color: Colors.white,
              size: 16,
            )else
            const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 16,
            ),
          const SizedBox(width: 8),
          if(widget.connectivityStatus)
              const Text(
                'You are online',
                  style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              )else
              const Text(
                'Offline - No Internet Connection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
        ],
      ),
    );
  }
}