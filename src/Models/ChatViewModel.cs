using System.Collections.Generic;

namespace ZavaStorefront.Models
{
    public class ChatViewModel
    {
        public List<ChatMessage> Messages { get; set; } = new();
        public string UserMessage { get; set; } = string.Empty;
    }
}
