namespace RendezVous.Api.DTOs;

public class ChatMessageDto
{
    public string Role { get; set; } = string.Empty; // "user" ou "assistant"
    public string Content { get; set; } = string.Empty;
}

public class SendChatDto
{
    public List<ChatMessageDto> Messages { get; set; } = new();
}

public class ChatReplyDto
{
    public string Reply { get; set; } = string.Empty;
}