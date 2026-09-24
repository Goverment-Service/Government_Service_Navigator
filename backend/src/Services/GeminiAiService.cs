using System.Net.Http.Json;
using System.Text.Json;
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
        // Upgraded to Google's current stable embedding model
        var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-2:embedContent?key={_apiKey}";
        
        // gemini-embedding-2 defaults to 3,072 dimensions. 
        // outputDimensionality instructs Google to truncate the vector to 768 to match our Postgres schema.
        var payload = new 
        { 
            model = "models/gemini-embedding-2", 
            content = new { parts = new[] { new { text } } },
            outputDimensionality = 768
        };
        
        var response = await _http.PostAsJsonAsync(url, payload);
        
        if (!response.IsSuccessStatusCode)
        {
            var errorDetails = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"Gemini API Error ({response.StatusCode}): {errorDetails}");
        }
        
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var values = json.GetProperty("embedding").GetProperty("values")
                         .EnumerateArray().Select(x => x.GetSingle()).ToArray();
                         
        return new Vector(values);
    }

          public async Task<string> GenerateTextAsync(string prompt)
    {
        // Upgraded to the current Gemini 3.5 Flash model
        var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key={_apiKey}";
        var payload = new { contents = new[] { new { parts = new[] { new { text = prompt } } } } };

        int maxRetries = 3;
        
        for (int i = 0; i < maxRetries; i++)
        {
            var response = await _http.PostAsJsonAsync(url, payload);

            if (response.IsSuccessStatusCode)
            {
                var json = await response.Content.ReadFromJsonAsync<JsonElement>();
                return json.GetProperty("candidates")[0].GetProperty("content")
                           .GetProperty("parts")[0].GetProperty("text").GetString() ?? string.Empty;
            }

            // If Google is overloaded (503) or rate-limiting (429), wait and try again
            if (response.StatusCode == System.Net.HttpStatusCode.ServiceUnavailable || 
                response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
            {
                if (i == maxRetries - 1) break; 
                
                // Exponential backoff: Wait 2s, then 4s, then try again
                await Task.Delay(2000 * (i + 1));
                continue;
            }

            // For all other errors (like 400 Bad Request or 401 Unauthorized), fail immediately
            var errorDetails = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"Gemini API Error ({response.StatusCode}): {errorDetails}");
        }

        throw new HttpRequestException("Gemini API Error: Service Unavailable after multiple retries. The model is currently overloaded.");
    }


}
