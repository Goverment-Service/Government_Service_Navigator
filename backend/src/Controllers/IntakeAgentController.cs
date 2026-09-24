using AgenticAi.Agents.IntakePlanningAgent;
using Microsoft.AspNetCore.Mvc;

namespace Government_Service_Navigator.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class IntakeAgentController : ControllerBase
{
    private readonly IIntakePlanningAgent _agent;

    public IntakeAgentController(IIntakePlanningAgent agent)
    {
        _agent = agent;
    }

    [HttpPost("ask")]
    public async Task<IActionResult> AskAgent([FromBody] UserQueryDto query)
    {
        if (string.IsNullOrWhiteSpace(query.Text))
            return BadRequest("Text is required.");

        // 1. Create the request for the agent
        var request = new IntakePlanRequest(query.Text);

        // 2. The agent will embed the text, search Neon, and call Gemini
        var response = await _agent.GeneratePlanAsync(request);

        // 3. Return the AI-generated plan and the context it used
        return Ok(response);
    }
}

// A simple DTO to catch the incoming JSON request
public class UserQueryDto
{
    public string Text { get; set; } = string.Empty;
}
