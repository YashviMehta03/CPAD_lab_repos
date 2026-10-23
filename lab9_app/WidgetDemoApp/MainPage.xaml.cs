namespace WidgetDemoApp;

public partial class MainPage : ContentPage
{
    // Step 3: Counter for the Like button
    int likeCount = 0;

    public MainPage()
    {
        InitializeComponent();

        // Step 5: Populate the horizontal skill list
        SkillsCollection.ItemsSource = new List<string>
        {
            "Python", "Machine Learning", "Deep Learning", "TensorFlow",
            "PyTorch", "REST APIs", "FastAPI", "SQL", "Docker", "LLMs"
        };
    }

    // Step 3: Increment like count and update button text
    private void OnLikeClicked(object? sender, EventArgs e)
    {
        likeCount++;
        LikeBtn.Text = $"Like ({likeCount})";
    }

    // Step 4: Show a simple confirmation alert when Message is tapped
    private async void OnMessageClicked(object? sender, EventArgs e)
    {
        await DisplayAlert("Message", "Your message has been sent!", "OK");
    }
}

