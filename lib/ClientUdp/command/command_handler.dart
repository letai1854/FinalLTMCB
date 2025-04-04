import '../client_state.dart';
import '../handshake_manager.dart';

/// Interface for handling client commands.
abstract class CommandHandler {
  /// Executes the command logic.
  ///
  /// @param args The arguments provided with the command (excluding the command itself).
  /// @param clientState The current state of the client.
  /// @param handshakeManager The manager for sending requests to the server.
  void handle(String args, ClientState clientState, HandshakeManager handshakeManager);

  /// Gets the description of the command for help display.
  /// @return The command description string.
  String getDescription();
}
