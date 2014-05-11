﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Plotter
{
    public static class Extensions
    {
        /// <summary>
        /// Return the quartile values of an ordered set of doubles
        ///   assume the sorting has already been done.
        ///   
        /// This actually turns out to be a bit of a PITA, because there is no universal agreement 
        ///   on choosing the quartile values. In the case of odd values, some count the median value
        ///   in finding the 1st and 3rd quartile and some discard the median value. 
        ///   the two different methods result in two different answers.
        ///   The below method produces the arithmatic mean of the two methods, and insures the median
        ///   is given it's correct weight so that the median changes as smoothly as possible as 
        ///   more data ppints are added.
        ///    
        /// This method uses the following logic:
        /// 
        /// ===If there are an even number of data points:
        ///    Use the median to divide the ordered data set into two halves. 
        ///    The lower quartile value is the median of the lower half of the data. 
        ///    The upper quartile value is the median of the upper half of the data.
        ///    
        /// ===If there are (4n+1) data points:
        ///    The lower quartile is 25% of the nth data value plus 75% of the (n+1)th data value.
        ///    The upper quartile is 75% of the (3n+1)th data point plus 25% of the (3n+2)th data point.
        ///    
        ///===If there are (4n+3) data points:
        ///   The lower quartile is 75% of the (n+1)th data value plus 25% of the (n+2)th data value.
        ///   The upper quartile is 25% of the (3n+2)th data point plus 75% of the (3n+3)th data point.
        /// 
        /// </summary>
        public static Tuple<double, double, double> Quartiles(this IEnumerable<double> values)
        {
            var afVal = values.OrderBy(x => x).ToArray();
            int iSize = afVal.Length;
            int iMid = iSize / 2; //this is the mid from a zero based index, eg mid of 7 = 3;

            double fQ1 = 0;
            double fQ2 = 0;
            double fQ3 = 0;

            if (iSize % 2 == 0)
            {
                //================ EVEN NUMBER OF POINTS: =====================
                //even between low and high point
                fQ2 = (afVal[iMid - 1] + afVal[iMid]) / 2;

                int iMidMid = iMid / 2;

                //easy split 
                if (iMid % 2 == 0)
                {
                    fQ1 = (afVal[iMidMid - 1] + afVal[iMidMid]) / 2;
                    fQ3 = (afVal[iMid + iMidMid - 1] + afVal[iMid + iMidMid]) / 2;
                }
                else
                {
                    fQ1 = afVal[iMidMid];
                    fQ3 = afVal[iMidMid + iMid];
                }
            }
            else if (iSize == 1)
            {
                //================= special case, sorry ================
                fQ1 = afVal[0];
                fQ2 = afVal[0];
                fQ3 = afVal[0];
            }
            else
            {
                //odd number so the median is just the midpoint in the array.
                fQ2 = afVal[iMid];

                if ((iSize - 1) % 4 == 0)
                {
                    //======================(4n-1) POINTS =========================
                    int n = (iSize - 1) / 4;
                    fQ1 = (afVal[n - 1] * .25) + (afVal[n] * .75);
                    fQ3 = (afVal[3 * n] * .75) + (afVal[3 * n + 1] * .25);
                }
                else if ((iSize - 3) % 4 == 0)
                {
                    //======================(4n-3) POINTS =========================
                    int n = (iSize - 3) / 4;

                    fQ1 = (afVal[n] * .75) + (afVal[n + 1] * .25);
                    fQ3 = (afVal[3 * n + 1] * .25) + (afVal[3 * n + 2] * .75);
                }
            }

            return new Tuple<double, double, double>(fQ1, fQ2, fQ3);
        }
    }
}
