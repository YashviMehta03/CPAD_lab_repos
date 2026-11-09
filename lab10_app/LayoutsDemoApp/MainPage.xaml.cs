namespace LayoutsDemoApp;

public partial class MainPage : ContentPage
{
	public MainPage()
	{
		InitializeComponent();
	}

	private async void OnViewProfileClicked(object? sender, EventArgs e)
	{
		await DisplayAlertAsync("Profile", "Full profile coming soon!", "OK");
	}
}
