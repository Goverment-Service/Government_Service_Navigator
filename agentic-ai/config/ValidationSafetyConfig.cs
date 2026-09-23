namespace Government_Service_Navigator.AgenticAi.Config
{
    public class ValidationSafetyConfig
    {
        /// <summary>
        /// Base URL for the ASP.NET Core backend API.
        /// </summary>
        public string BackendApiUrl { get; set; } = "http://localhost:5119";

        /// <summary>
        /// Enables deterministic defense against adversarial prompt-injection attacks.
        /// </summary>
        public bool EnableAdversarialDefense { get; set; } = true;

        /// <summary>
        /// Minimum legal age for submitting government service applications.
        /// </summary>
        public int MinimumLegalAge { get; set; } = 16;

        /// <summary>
        /// Maximum realistic age bound.
        /// </summary>
        public int MaximumLegalAge { get; set; } = 125;

        /// <summary>
        /// Sri Lankan National Identity Card regex (9 digits + V/X or 12 digits).
        /// </summary>
        public string NicRegexPattern { get; set; } = @"^([0-9]{9}[vVxX]|[0-9]{12})$";

        /// <summary>
        /// If true, blocks submissions if an active application already exists for the citizen.
        /// </summary>
        public bool BlockDuplicateSubmissions { get; set; } = true;
    }
}
