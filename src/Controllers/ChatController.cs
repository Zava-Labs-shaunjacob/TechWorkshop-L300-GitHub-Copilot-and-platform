using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Models;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers;

public class ChatController : Controller
{
    private readonly ChatService _chatService;
    private readonly ILogger<ChatController> _logger;
    private const string SessionKeyMessages = "ChatMessages";

    public ChatController(ChatService chatService, ILogger<ChatController> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    public IActionResult Index()
    {
        var messages = GetMessagesFromSession();
        var viewModel = new ChatViewModel { Messages = messages };
        return View(viewModel);
    }

    [HttpPost]
    public async Task<IActionResult> Send(ChatViewModel model)
    {
        var messages = GetMessagesFromSession();

        if (string.IsNullOrWhiteSpace(model.UserMessage))
        {
            return View("Index", new ChatViewModel { Messages = messages });
        }

        // Add user message
        messages.Add(new ChatMessage { Role = "user", Content = model.UserMessage });

        try
        {
            _logger.LogInformation("Sending user message to Foundry endpoint");
            var response = await _chatService.GetChatResponseAsync(messages);

            // Add assistant response
            messages.Add(new ChatMessage { Role = "assistant", Content = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calling Foundry endpoint");
            messages.Add(new ChatMessage { Role = "assistant", Content = $"Error: {ex.Message}" });
        }

        SaveMessagesToSession(messages);
        return View("Index", new ChatViewModel { Messages = messages });
    }

    [HttpPost]
    public IActionResult Clear()
    {
        HttpContext.Session.Remove(SessionKeyMessages);
        return RedirectToAction("Index");
    }

    private List<ChatMessage> GetMessagesFromSession()
    {
        var json = HttpContext.Session.GetString(SessionKeyMessages);
        if (string.IsNullOrEmpty(json))
            return new List<ChatMessage>();
        return JsonSerializer.Deserialize<List<ChatMessage>>(json) ?? new List<ChatMessage>();
    }

    private void SaveMessagesToSession(List<ChatMessage> messages)
    {
        var json = JsonSerializer.Serialize(messages);
        HttpContext.Session.SetString(SessionKeyMessages, json);
    }
}
