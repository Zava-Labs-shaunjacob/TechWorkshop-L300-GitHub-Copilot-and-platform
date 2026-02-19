using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly HttpClient _httpClient;
        private readonly string _endpoint;
        private readonly string _apiKey;
        private readonly string _deploymentName;
        private readonly ILogger<ChatService> _logger;

        public ChatService(IConfiguration configuration, HttpClient httpClient, ILogger<ChatService> logger)
        {
            _httpClient = httpClient;
            _logger = logger;

            _endpoint = configuration["AzureAIFoundry:Endpoint"]
                ?? throw new InvalidOperationException("AzureAIFoundry:Endpoint is not configured.");
            _apiKey = configuration["AzureAIFoundry:ApiKey"]
                ?? throw new InvalidOperationException("AzureAIFoundry:ApiKey is not configured.");
            _deploymentName = configuration["AzureAIFoundry:DeploymentName"] ?? "Phi-4";
        }

        public async Task<string> GetChatResponseAsync(List<ChatMessage> conversationHistory)
        {
            var url = $"{_endpoint.TrimEnd('/')}/openai/deployments/{_deploymentName}/chat/completions?api-version=2024-10-21";

            var requestBody = new
            {
                messages = conversationHistory.Select(m => new { role = m.Role, content = m.Content }).ToArray(),
                max_tokens = 800,
                temperature = 0.7
            };

            var json = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Add("api-key", _apiKey);

            _logger.LogInformation("Sending chat request to {Endpoint} deployment {Deployment}", _endpoint, _deploymentName);

            var response = await _httpClient.PostAsync(url, content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("Foundry API error {StatusCode}: {Response}", response.StatusCode, responseContent);
                throw new HttpRequestException($"Foundry API returned {response.StatusCode}: {responseContent}");
            }

            var result = JsonSerializer.Deserialize<ChatCompletionResponse>(responseContent);
            return result?.Choices?.FirstOrDefault()?.Message?.Content ?? "No response received.";
        }

        private class ChatCompletionResponse
        {
            [JsonPropertyName("choices")]
            public List<Choice>? Choices { get; set; }
        }

        private class Choice
        {
            [JsonPropertyName("message")]
            public ResponseMessage? Message { get; set; }
        }

        private class ResponseMessage
        {
            [JsonPropertyName("content")]
            public string? Content { get; set; }
        }
    }
}
