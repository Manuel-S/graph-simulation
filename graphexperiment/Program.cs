using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Xml;
using System.Xml.Serialization;
using System.Net.Http;
using CsvHelper;
using CsvHelper.Configuration;
using QuickGraph;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using QuickGraph.Algorithms;
using QuickGraph.Graphviz;
using QuickGraph.Serialization;

namespace graphexperiment
{
    class Point
    {
        [XmlAttribute("x")]
        public double X { get; set; }
        [XmlAttribute("y")]
        public double Y { get; set; }

        public double R { get; set; }

        public int intWeight { get; set; }
    }

    public static class extensions
    {
        public static double NextDoubleRange(this Random random, double minimum, double maximum)
        {
            return random.NextDouble() * (maximum - minimum) + minimum;
        }
    }

    class Program
    {
        static Random Generator = new System.Random();


        static void Main(string[] args)
        {
            var rangeMin = 0.005;
            var rangeAverageMin = 0.005;
            var rangeAverageMax = 0.2;
            var rangeMaxDevianceMin = 1.5;
            var rangeMaxDevianceMax = 8.0;

            var nodeCountMin = 50;
            var nodeCountMax = 200;

            //using (var file = new StreamWriter(@"C:\Users\Manuel\Desktop\data.csv"))
            //{
            //    using (var csv = new CsvWriter(file, new CsvConfiguration{Delimiter = ";"}))
            //    {
                    //csv.WriteHeader(typeof(Model));
                    Console.WriteLine("Running simulations, press ESC to quit...");
                    var run = true;
                    while (run)
                    {
                        var rangeAverage = Generator.NextDoubleRange(rangeAverageMin, rangeAverageMax);
                        var rangeMaxDeviance = Generator.NextDoubleRange(rangeMaxDevianceMin, rangeMaxDevianceMax);

                        var nodeCount = Generator.Next(nodeCountMin, nodeCountMax);


                        var graph = new BidirectionalGraph<Point, Edge<Point>>();

                        var unidirectionalGraph = new BidirectionalGraph<Point, Edge<Point>>();

                        foreach (var i in Enumerable.Range(1, nodeCount))
                        {
                            var range = (Generator.NextDoubleRange(rangeMaxDeviance, 1/rangeMaxDeviance) * rangeAverage);
                            if (range < rangeMin)
                                range = rangeMin;
                            var vertex = new Point
                            {
                                X = Generator.NextDouble(),
                                Y = Generator.NextDouble(),
                                R = range
                            };

                            graph.AddVertex(vertex);
                            unidirectionalGraph.AddVertex(vertex);

                            foreach (var u in graph.Vertices.Except(new[] { vertex }))
                            {
                                var dist = System.Math.Sqrt((u.X - vertex.X) * (u.X - vertex.X) + (u.Y - vertex.Y) * (u.Y - vertex.Y));
                                if (dist < u.R)
                                {
                                    var edge = new Edge<Point>(u, vertex);
                                    graph.AddEdge(edge);
                                    if (dist > vertex.R)
                                    {
                                        unidirectionalGraph.AddEdge(edge);
                                    }
                                }
                                if (dist < vertex.R)
                                {
                                    var edge = new Edge<Point>(vertex, u);
                                    graph.AddEdge(edge);
                                    if (dist > u.R)
                                    {
                                        unidirectionalGraph.AddEdge(edge);
                                    }
                                }
                            }
                        }

                        //var file = @"C:\Users\Manuel\Desktop\graphs\graph{0}.dgml";

                        //var fi = 1;
                        //var filestring = String.Format(file, string.Empty);
                        //while (File.Exists(filestring))
                        //{
                        //    filestring = String.Format(file, fi++);
                        //}
                        //var file2 = @"C:\Users\Manuel\Desktop\graphs\unidirectionalGraph{0}.dgml";
                        //var filestring2 = String.Format(file2, --fi);


                        //graph.ToDirectedGraphML()
                        //    .WriteXml(filestring);
                        //unidirectionalGraph.ToDirectedGraphML()
                        //    .WriteXml(filestring2);
                        //Process.Start(filestring2);

                        IDictionary<Point, int> components2;
                        var model = new Model();

                        model.NodeCount = nodeCount;

                        model.MaxInDegree = graph.Vertices.Max(x => graph.InDegree(x));
                        model.MaxOutDegree = graph.Vertices.Max(x => graph.OutDegree(x));

                        model.AverageInDegree = graph.Vertices.Average(x => graph.InDegree(x));
                        model.AverageOutDegree = graph.Vertices.Average(x => graph.OutDegree(x));

                        model.MaxRange = graph.Vertices.Max(x => x.R);
                        model.MinRange = graph.Vertices.Min(x => x.R);
                        model.AverageRange = graph.Vertices.Average(x => x.R);

                        model.WeaklyConnectedComponents = graph.WeaklyConnectedComponents(new Dictionary<Point, int>());
                        model.StronglyConnectedComponents = graph.StronglyConnectedComponents(out components2);


                        foreach (var vertex in unidirectionalGraph.TopologicalSort())
                        {
                            var edges = unidirectionalGraph.InEdges(vertex);
                            if (edges.Any())
                            {
                                vertex.intWeight = edges.Max(x => x.Source.intWeight) + 1;
                            }
                            else
                            {
                                vertex.intWeight = 0;
                            }
                        }

                        model.CriticalPathLength = unidirectionalGraph.Vertices.Max(x => x.intWeight);

                        //csv.WriteRecord(model);

                        string apiUrl = @"http://graphexperimentservice.azurewebsites.net/api/stats";
                        var client = new HttpClient();
                        var sending = client.PostAsJsonAsync<Model>(apiUrl, model);



                        if (Console.KeyAvailable)
                        {
                            ConsoleKeyInfo key = Console.ReadKey(true);
                            switch (key.Key)
                            {
                                case ConsoleKey.Escape:
                                    run = false;
                                    sending.Wait();
                                    break;
                                default:
                                    break;
                            }
                        }
                    }
            //    }
            //}

        }
    }
}
