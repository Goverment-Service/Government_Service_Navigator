using System;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using AgenticAi.Agents.IntakePlanningAgent;
using Pgvector;

namespace Government_Service_Navigator.Backend.Services;

public class GeminiAiService : IGenerativeAiService
{
    private readonly HttpClient _http;
    private readonly string _apiKey;

    public GeminiAiService(HttpClient http)
    {
        _http = http;
        
        var rawKey = Environment.GetEnvironmentVariable("GEMINI_API_KEY");
        if (string.IsNullOrWhiteSpace(rawKey)) 
            throw new InvalidOperationException("Missing GEMINI_API_KEY in .env");
        
        // Trims quotes, spaces, and hidden line endings that cause 404 routing failures
        _apiKey = rawKey.Trim('"', '\'', ' ', '\n', '\r');
    }

    public async Task<Vector> GetEmbeddingAsync(string text)
    {
        // text-embedding-004 returns 768 dimensions directly to match Postgres schema
        var url = $"https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key={_apiKey}";
        
        var payload = new 
        { 
            model = "models/text-embedding-004", 
            content = new { parts = new[] { new { text } } }
        };
        
        var response = await _http.PostAsJsonAsync(url, payload);
        
        if (!response.IsSuccessStatusCode)
        {
            var errorDetails = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"Gemini Embedding API Error ({response.StatusCode}): {errorDetails}");
        }
        
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var values = json.GetProperty("embedding").GetProperty("values")
                         .EnumerateArray().Select(x => x.GetSingle()).ToArray();
                         
        return new Vector(values);
    }

    public async Task<string> GenerateTextAsync(string prompt)
    {
        var modelNames = new[] { "gemini-1.5-flash-latest", "gemini-2.0-flash-exp", "gemini-2.0-flash", "gemini-1.5-pro" };
        var payload = new { contents = new[] { new { parts = new[] { new { text = prompt } } } } };

        foreach (var modelName in modelNames)
        {
            var url = $"https://generativelanguage.googleapis.com/v1beta/models/{modelName}:generateContent?key={_apiKey}";
            var response = await _http.PostAsJsonAsync(url, payload);

            if (response.IsSuccessStatusCode)
            {
                var json = await response.Content.ReadFromJsonAsync<JsonElement>();
                return json.GetProperty("candidates")[0].GetProperty("content")
                           .GetProperty("parts")[0].GetProperty("text").GetString() ?? string.Empty;
            }
        }

        throw new HttpRequestException("Gemini API Error: No compatible Gemini generation model endpoint found for key.");
    }
}
