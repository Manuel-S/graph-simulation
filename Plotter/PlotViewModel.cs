using System.IO;
using graphexperiment;
using Newtonsoft.Json;
using OxyPlot;
using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using OxyPlot.Series;
using OxyPlot.Axes;

namespace Plotter
{
    public class PlotViewModel
    {
        public static IEnumerable<Model> GetData()
        {
            var text = File.ReadAllText(@"C:\Users\Manuel\Desktop\data.txt");

            var objects = JsonConvert.DeserializeObject<IEnumerable<Model>>(text).OrderBy(x => x.NodeCount);

            return objects;
        }

        public static PlotModel CreateScatterPlotOfNAndL()
        {
            var objects = GetData();

            var plot = new PlotModel();


            var series = new ScatterSeries();
            series.BinSize = 10;

            series.Points.AddRange(objects.Select(x => new ScatterPoint((double)x.NodeCount, (double)x.CriticalPathLength)));

            plot.Series.Add(series);

            return plot;
        }

        public static PlotModel CreateBoxPlotOf(Func<Model, double> xFunc, Func<Model, double> yFunc, int boxCount = 10,
            string xLabel = "X", string yLabel ="Y")
        {
            Func<Model, double> func = xFunc;

            var objects = GetData().OrderBy(func);

            var plot = new PlotModel();


            var series = new BoxPlotSeries();

            var steps = objects.Max(func) / boxCount;

            series.BoxWidth = 0.8 * steps;

            foreach (var i in Enumerable.Range(0, boxCount))
            {
                var values = objects
                    .SkipWhile(x => func(x) < i * steps)
                    .TakeWhile(x => func(x) < (i + 1) * steps)
                    .Select(yFunc);

                var quartiles = values.Quartiles();
                var median = quartiles.Item2;
                var thirdQuartil = quartiles.Item3;
                var firstQuartil = quartiles.Item1;

                var iqr = thirdQuartil - firstQuartil;
                var step = iqr * 1.5;
                var upperWhisker = thirdQuartil + step;
                upperWhisker = values.Where(v => v <= upperWhisker).Max();
                var lowerWhisker = firstQuartil - step;
                lowerWhisker = values.Where(v => v >= lowerWhisker).Min();

                var outliers = values.Where(v => v > upperWhisker || v < lowerWhisker).ToList();

                series.Items.Add(new BoxPlotItem((double)(i + 1) * steps, lowerWhisker, firstQuartil, median, thirdQuartil, upperWhisker, outliers));




            }
            var linearAxis1 = new LinearAxis();
            linearAxis1.Position = AxisPosition.Bottom;
            linearAxis1.Title = xLabel;
            plot.Axes.Add(linearAxis1);


            var linearAxis2 = new LinearAxis();

            linearAxis2.Title = yLabel;
            plot.Axes.Add(linearAxis2);


            plot.Series.Add(series);

            return plot;
        }

        public PlotViewModel()
        {
            Plot = CreateBoxPlotOf(x => x.AverageRange, x => x.AverageInDegree, 15, "Average Range", "Average InDegree");
        }
        public PlotModel Plot { get; set; }
    }

}
