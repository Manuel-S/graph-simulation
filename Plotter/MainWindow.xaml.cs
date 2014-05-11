using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using graphexperiment;
using Newtonsoft.Json;
using OxyPlot;
using OxyPlot.Reporting;
using OxyPlot.Series;
using OxyPlot.Wpf;

namespace Plotter
{
    /// <summary>
    /// Interaktionslogik für MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();



        }

        private async void Button_Click(object sender, RoutedEventArgs e)
        {
            var httpClient = new HttpClient();
            var response = await httpClient.GetAsync("http://graphexperimentservice.azurewebsites.net/api/stats");


            response.EnsureSuccessStatusCode();

            File.WriteAllText(@"C:\Users\Manuel\Desktop\data.txt", await response.Content.ReadAsStringAsync());

        }

        private void Button_Click_1(object sender, RoutedEventArgs e)
        {
            var plot = ((PlotViewModel) (this.DataContext)).Plot;

            using (var stream = File.OpenWrite(@"C:\Users\Manuel\Desktop\plot.png"))
            {
                PngExporter.Export(plot, stream, (int)PlotControl.ActualWidth, (int)PlotControl.ActualHeight, OxyColor.FromRgb((byte)255, (byte)255, (byte)255));
            }
            using (var stream = File.OpenWrite(@"C:\Users\Manuel\Desktop\plot.pdf"))
            {
                PdfExporter.Export(plot, stream, (int)PlotControl.ActualWidth, (int)PlotControl.ActualHeight);
            }
        }

        private async void Button_Click_2(object sender, RoutedEventArgs e)
        {
            var httpClient = new HttpClient();
            var response = await httpClient.GetAsync("http://graphexperimentservice.azurewebsites.net/api/stats");

            response.EnsureSuccessStatusCode();

            var objects = await JsonConvert.DeserializeObjectAsync<IEnumerable<Model>>(await response.Content.ReadAsStringAsync());

            MessageBox.Show(objects.Count().ToString());
        }
    }
}
