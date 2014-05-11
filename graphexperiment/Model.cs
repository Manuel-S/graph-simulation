using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace graphexperiment
{
    public class Model
    {
        public int Id { get; set; }
        public int NodeCount { get; set; }
        public int CriticalPathLength { get; set; }
        public double AverageInDegree { get; set; }
        public double AverageOutDegree { get; set; }
        public int MaxInDegree { get; set; }
        public int MaxOutDegree { get; set; }
        public int WeaklyConnectedComponents { get; set; }
        public int StronglyConnectedComponents { get; set; }
        public double AverageRange { get; set; }
        public double MaxRange { get; set; }
        public double MinRange { get; set; }
    }
}
