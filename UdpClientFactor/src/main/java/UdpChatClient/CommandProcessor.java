package UdpChatClient;

import java.util.HashMap;
import java.util.Map;

import UdpChatClient.command.AddUserHandler;
import UdpChatClient.command.CommandHandler;
import UdpChatClient.command.CreateRoomHandler;
import UdpChatClient.command.DeleteRoomHandler;
import UdpChatClient.command.ExitHandler;
import UdpChatClient.command.GetRoomUsersHandler;
import UdpChatClient.command.GetUsersHandler;
import UdpChatClient.command.HelpHandler;
import UdpChatClient.command.ListMessagesHandler;
import UdpChatClient.command.ListRoomsHandler;
import UdpChatClient.command.LoginHandler;
import UdpChatClient.command.RegisterHandler;
import UdpChatClient.command.RemoveUserHandler;
import UdpChatClient.command.RenameRoomHandler;
import UdpChatClient.command.SendHandler;

public class CommandProcessor {

    private final ClientState clientState;
    private final HandshakeManager handshakeManager;
    private final Map<String, CommandHandler> commandHandlers = new HashMap<>();

    public CommandProcessor(ClientState clientState, HandshakeManager handshakeManager) {
        this.clientState = clientState;
        this.handshakeManager = handshakeManager;
        
        // Register all command handlers
        registerCommandHandler(Constants.CMD_REGISTER, new RegisterHandler());
        registerCommandHandler(Constants.CMD_GET_USERS, new GetUsersHandler());
        registerCommandHandler(Constants.CMD_LOGIN, new LoginHandler());
        registerCommandHandler(Constants.CMD_CREATE_ROOM, new CreateRoomHandler());
        registerCommandHandler(Constants.CMD_SEND, new SendHandler());
        registerCommandHandler(Constants.CMD_LIST_ROOMS, new ListRoomsHandler());
        registerCommandHandler(Constants.CMD_LIST_MESSAGES, new ListMessagesHandler());
        registerCommandHandler(Constants.CMD_ADD_USER, new AddUserHandler());
        registerCommandHandler(Constants.CMD_REMOVE_USER, new RemoveUserHandler());
        registerCommandHandler(Constants.CMD_DELETE_ROOM, new DeleteRoomHandler());
        registerCommandHandler(Constants.CMD_RENAME_ROOM, new RenameRoomHandler());
        registerCommandHandler(Constants.CMD_GET_ROOM_USERS, new GetRoomUsersHandler());
        registerCommandHandler(Constants.CMD_HELP, new HelpHandler(this));
        registerCommandHandler(Constants.CMD_EXIT, new ExitHandler());
    }
    
    private void registerCommandHandler(String command, CommandHandler handler) {
        commandHandlers.put(command.toLowerCase(), handler);
    }

    public void processCommand(String line) {
        String trimmedLine = line.trim();
        if (trimmedLine.isEmpty()) {
            System.out.print("> ");
            return;
        }

        String[] parts = trimmedLine.split("\\s+", 2);
        String command = parts[0].toLowerCase();
        String args = parts.length > 1 ? parts[1] : "";

        CommandHandler handler = commandHandlers.get(command);
        if (handler != null) {
            handler.handle(args, clientState, handshakeManager);
        } else {
            System.out.println("Invalid command. Type /help for available commands.");
            System.out.print("> ");
        }
    }

    public void showHelp() {
        System.out.println("\nAvailable commands:");
        for (Map.Entry<String, CommandHandler> entry : commandHandlers.entrySet()) {
            System.out.println("  " + entry.getValue().getDescription());
        }
        System.out.println("    Time options: e.g., '12"+Constants.TIME_OPTION_HOURS+"', '7"+Constants.TIME_OPTION_DAYS+"', '3"+Constants.TIME_OPTION_WEEKS+"', '"+Constants.TIME_OPTION_ALL+"', ISO format, or 'yyyy-MM-dd HH:mm:ss'");
        System.out.print("> ");
    }
    
    // Get command handlers - used by HelpHandler
    public Map<String, CommandHandler> getCommandHandlers() {
        return commandHandlers;
    }
}
