import 'dart:developer' as logger;
import 'package:flutter/material.dart';
import 'package:finalltmcb/ClientUdp/udpmain.dart';
import 'package:finalltmcb/Controllers/UserController.dart';

class CommandConsole extends StatefulWidget {
  const CommandConsole({Key? key}) : super(key: key);

  @override
  _CommandConsoleState createState() => _CommandConsoleState();
}

class _CommandConsoleState extends State<CommandConsole> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _outputLines = [];
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UDP Debug Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _outputLines.length,
                itemBuilder: (context, index) {
                  return Text(
                    _outputLines[index],
                    style: TextStyle(
                      color: _outputLines[index].startsWith('Error:') 
                          ? Colors.red 
                          : (_outputLines[index].startsWith('>') 
                              ? Colors.yellow 
                              : Colors.green),
                      fontFamily: 'monospace',
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    decoration: const InputDecoration(
                      hintText: 'Enter command (e.g., /login user pass)',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontFamily: 'monospace'),
                    onSubmitted: (_) => _sendCommand(),
                    enabled: !_isProcessing,
                  ),
                ),
                IconButton(
                  icon: _isProcessing 
                      ? const CircularProgressIndicator() 
                      : const Icon(Icons.send),
                  onPressed: _isProcessing ? null : _sendCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;
    
    setState(() {
      _outputLines.add('> $command');
      _isProcessing = true;
      _scrollToBottom();
    });
    
    try {
      final userController = UserController();
      if (userController.udpClient != null) {  // Use the public getter instead of _udpClient
        logger.log('Sending command to server: $command');
        _addOutput('Sending command to server...');
        
        await processCommand(userController.udpClient!, command);
        
        _addOutput('Command sent successfully');
        logger.log('Command sent successfully: $command');
        
        // For login commands, add special handling
        if (command.startsWith('/login')) {
          _addOutput('Waiting for login response (up to 5 seconds)...');
          // Give extra time for login response
          await Future.delayed(const Duration(seconds: 5));
          
          // Check if login succeeded
          if (userController.udpClient!.clientState.sessionKey != null) {  // Use the public getter here too
            _addOutput('LOGIN SUCCESSFUL!');
            _addOutput('Session key: ${userController.udpClient!.clientState.sessionKey}');
            _addOutput('User: ${userController.udpClient!.clientState.currentChatId}');
          } else {
            _addOutput('Login appears to have failed (no session key received)');
          }
        }
      } else {
        _addOutput('Error: UDP client not initialized');
        logger.log('Error: UDP client not initialized when trying to send: $command');
      }
    } catch (e) {
      _addOutput('Error: $e');
      logger.log('Error sending command: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _commandController.clear();
      });
    }
  }
  
  void _addOutput(String line) {
    setState(() {
      _outputLines.add(line);
      _scrollToBottom();
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Available Commands'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('/login <username> <password>', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('  Log in to the server', style: TextStyle(fontStyle: FontStyle.italic)),
              SizedBox(height: 8),
              Text('/ping', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('  Test server connection', style: TextStyle(fontStyle: FontStyle.italic)),
              SizedBox(height: 8),
              Text('/help', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('  Show available commands', style: TextStyle(fontStyle: FontStyle.italic)),
              SizedBox(height: 8),
              Text('/quit', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('  Disconnect from server', style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
