<%@ WebHandler Language="C#" Class="SparkHandler" %>

/*
Copyright (c) 2005 Eric W. Bachtal

Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
and associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or substantial 
  portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO 
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE 
USE OR OTHER DEALINGS IN THE SOFTWARE.    

-------------

http://ewbi.blogs.com/develops/2005/07/sparklines.html

Based on spark.py, Copyright 2005, Joe Gregorio.  See http://bitworking.org/projects/sparklines/ 
for more on Mr. Gregorio's original Python-based sparklines work, including an explanation of the 
parameters expected for the smooth and disrete types.

See http://www.edwardtufte.com/bboard/q-and-a-fetch-msg?msg_id=0001OR&topic_id=1&topic= for more 
on sparklines from Edward Tufte, the man who invented them.

The bars sparkline type represents custom logic not found in the original spark.py.  Like the other
sparklines, it takes a "d" parameter containing a list of comma-delimited values between 0 and 100.
In addition, it accepts optional "bar-colors", "bar-height", "width", "shadow-color", and "align-right"
parameters.

This code doesn't really represent a best-practice C# ASP.NET IHttpHandler.  However, it was intended to 
replicate Mr. Gregorio's original Python code and its run-time behavior, not produce an outstanding example 
of C# ASP.NET programming.  It's behavior differs from Mr. Gregorio's code in the following ways:

- It includes support for a "bars" type.
- It includes error traps in the plot routines that will result in the error mark (an "X") being returned
  if there are problems with the parameters.  Mr. Gregorio's code will simply return an untrapped Python
  error, which, because it follows the content-type already being set, results in the browser reporting the 
  graphic as invalid.
- It ignores non-numeric values in the "d" parameter, whereas Mr. Gregorio's code returns an untrapped Python
  error.
- It is more forgiving of incomplete RGB colors (i.e., "#CE").

v2.0 7/16/2005 ewb
  - Added support for barlines.

v2.1 8/3/2005 ewb
  - Added new options for marking a normal range beneath smooth sparklines.  See updates to Edward Tufte's
    Beautiful Evidence http://www.edwardtufte.com/bboard/q-and-a-fetch-msg?msg_id=0001OR&topic_id=1&topic=.
  - Changed smooth sparkline line color to avoid dithering.

v2.2 8/25/2005 ewb
  - Added support for transparent backgrounds via the new transparent=true/false parameter.  Would liked to 
    have made transparent backgrounds the default behavior, but needed to preserve backward compatibility 
    (maybe someone was counting on the White background?), and it does require additional processing and so 
    isn't as fast.  However, I did change the error graphic so it is always transparent.  The background is 
    made transparent by setting the White palette entry transparent.  This means it affects any use of White.  
    So, if White is used for anything other than the background (like bar, bar-shadow, min/max/final ticks, 
    etc.), it will be transparent there, too.  See these resources for additional information on GIF 
    transparency with .NET:
      http://support.microsoft.com/default.aspx?scid=kb;EN-US;Q319061
      http://www.bobpowell.net/giftransparency.htm    
      http://msdn.microsoft.com/library/en-us/dnaspp/html/colorquant.asp
      
v2.3 8/31/2005 ewb
  - Added support for auto-scaling results (i.e., the series of values passed via the "d" parameter) to the
    expected range of 0-100 using a new scale=true parameter.  Note that the smooth sparkline's range-lower 
    and range-upper parameters are still expected to reflect a 0-100 range, as is the discrete sparkline's
    upper parameter.  For bars, when scaling, a decision had to be made about what to do with unavoidable
    0-bar.  Rather than eliminate it or always show it as a blank bar, the descision was made to give it a
    value of 1.
  
*/

using System;
using System.IO;
using System.Net;
using System.Web;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections;
using System.Runtime.InteropServices;

public class SparkHandler : IHttpHandler {

  const string VERSION = "2.3";
  
  MemoryStream PlotSparklineDiscrete(int[] results) {

    /*
      original Python:
      
      height = int(args.get('height', '14'))
      upper = int(args.get('upper', '50'))
      below_color = args.get('below-color', 'gray')
      above_color = args.get('above-color', 'red')
      im = Image.new("RGB", (len(results)*2-1, height), 'white')
      draw = ImageDraw.Draw(im)
      for (r, i) in zip(results, range(0, len(results)*2, 2)):
        color = (r >= upper) and above_color or below_color
        draw.line((i, im.size[1]-r/(101.0/(height-4))-4, i, (im.size[1]-r/(101.0/(height-4)))), fill=color)      
    */

    try {      
      int height = int.Parse(GetArg("height", "14"));
      int upper = int.Parse(GetArg("upper", "50"));
      Color belowColor = GetColor(GetArg("below-color", "gray"));
      Color aboveColor = GetColor(GetArg("above-color", "red"));
      bool transparent = bool.Parse(GetArg("transparent", "false"));
      bool scale = bool.Parse(GetArg("scale", "false"));

      ResultsInfo resultsInfo = EvaluateResults(results, scale);

      using (Bitmap bitmap = new Bitmap(results.Length*2-1, height, PixelFormat.Format32bppArgb)) {
        using (Graphics g = Graphics.FromImage(bitmap)) {

          using (SolidBrush br = new SolidBrush(Color.White)) {
            g.FillRectangle(br, 0, 0, bitmap.Width, height);
          }

          for (int x = 0; x < results.Length; x++) {
            int r = results[x];
            int y = height - (int) Math.Ceiling(r/(101F/(height-4))) - 4;
            using (Pen p = new Pen((r >= upper) ? aboveColor : belowColor)) {
              g.DrawLine(p, x*2, y, x*2, y+3);
            }
          }      

          MemoryStream m = new MemoryStream();
          bitmap.Save(m, ImageFormat.Gif);
          return (transparent) ? MakeTransparent(m) : m;
        }
      }        
    } catch {
      return PlotError();
    }
  }

  MemoryStream PlotSparklineSmooth(int[] results) {
    
    /*
      original Python:
      
      step = int(args.get('step', '2'))
      height = int(args.get('height', '20'))

      im = Image.new("RGB", ((len(results)-1)*step+4, height), 'white')
      draw = ImageDraw.Draw(im)
      coords = zip(range(1,len(results)*step+1, step), [height - 3  - y/(101.0/(height-4)) for y in results])
      draw.line(coords, fill="#888888")
      min_color = args.get('min-color', '#0000FF')
      max_color = args.get('max-color', '#00FF00')
      last_color = args.get('last-color', '#FF0000')
      has_min = args.get('min-m', 'false')
      has_max = args.get('max-m', 'false')
      has_last = args.get('last-m', 'false')
      if has_min == 'true':
          min_pt = coords[results.index(min(results))]
          draw.rectangle([min_pt[0]-1, min_pt[1]-1, min_pt[0]+1, min_pt[1]+1], fill=min_color)
      if has_max == 'true':
          max_pt = coords[results.index(max(results))]
          draw.rectangle([max_pt[0]-1, max_pt[1]-1, max_pt[0]+1, max_pt[1]+1], fill=max_color)
      if has_last == 'true':
          end = coords[-1]
          draw.rectangle([end[0]-1, end[1]-1, end[0]+1, end[1]+1], fill=last_color)
    */

    try {
      int step = int.Parse(GetArg("step", "2"));
      int height = int.Parse(GetArg("height", "20"));
      Color minColor = GetColor(GetArg("min-color", "#0000FF"));
      Color maxColor = GetColor(GetArg("max-color", "#00FF00"));
      Color lastColor = GetColor(GetArg("last-color", "#FF0000"));
      Color rangeColor = GetColor(GetArg("range-color", "#CCCCCC"));
      bool hasMin = bool.Parse(GetArg("min-m", "false"));
      bool hasMax = bool.Parse(GetArg("max-m", "false"));
      bool hasLast = bool.Parse(GetArg("last-m", "false"));
      int rangeLower = int.Parse(GetArg("range-lower", "0"));
      int rangeUpper = int.Parse(GetArg("range-upper", "0"));
      bool transparent = bool.Parse(GetArg("transparent", "false"));
      bool scale = bool.Parse(GetArg("scale", "false"));

      ResultsInfo resultsInfo = EvaluateResults(results, scale);
      
      if ((rangeLower < 0) || (rangeLower > 100)) return PlotError();
      if ((rangeUpper < 0) || (rangeUpper > 100)) return PlotError();

      using (Bitmap bitmap = new Bitmap((results.Length-1)*step+4, height, PixelFormat.Format32bppArgb)) {
        using (Graphics g = Graphics.FromImage(bitmap)) {

          using (SolidBrush br = new SolidBrush(Color.White)) {
            g.FillRectangle(br, 0, 0, bitmap.Width, height);
          }
          
          if ((!((0 == rangeLower) && (0 == rangeUpper))) && (rangeLower <= rangeUpper)) {
            using (SolidBrush br = new SolidBrush(rangeColor)) {
              int y = height - 3 - (int) Math.Ceiling(rangeUpper/(101F/(height-4)));
              int h = (height - 3 - (int) Math.Ceiling(rangeLower/(101F/(height-4)))) - y + 1;
              g.FillRectangle(br, 1, y, bitmap.Width-2, h);
            }
          }

          Point[] coords = new Point[results.Length];
          for (int x = 0; x < results.Length; x++) {
            int r = results[x];
            int y = height - 3 - (int) Math.Ceiling(r/(101F/(height-4)));
            coords[x] = new Point(x*step+1, y);
          }
          using (Pen p = new Pen(GetColor("#999999"))) {
            g.DrawLines(p, coords);
          }

          if (hasMin) { DrawTick(g, minColor, coords[resultsInfo.MinIndex]); }
          if (hasMax) { DrawTick(g, maxColor, coords[resultsInfo.MaxIndex]); }
          if (hasLast) { DrawTick(g, lastColor, coords[results.Length-1]); }

          MemoryStream m = new MemoryStream();
          bitmap.Save(m, ImageFormat.Gif);
          return (transparent) ? MakeTransparent(m) : m;
        }
      }        
    } catch {
      return PlotError();
    }
  }
  
  MemoryStream PlotSparklineBars(int[] results) {

    try {
      int barHeight = int.Parse(GetArg("bar-height", "3"));
      int height = (barHeight+1)*results.Length+(results.Length-1);
      int width = int.Parse(GetArg("width", "20")) + 1;
      ArrayList barColors = new ArrayList(GetArg("bar-colors", "blue").Split(new char[] {','}));
      Color shadowColor = GetColor(GetArg("shadow-color", "#222222"));
      bool alignRight = bool.Parse(GetArg("align-right", "false"));
      bool transparent = bool.Parse(GetArg("transparent", "false"));
      bool scale = bool.Parse(GetArg("scale", "false"));

      ResultsInfo resultsInfo = EvaluateResults(results, scale);
      
      using (Bitmap bitmap = new Bitmap(width, height, PixelFormat.Format32bppArgb)) {
        using (Graphics g = Graphics.FromImage(bitmap)) {

          using (SolidBrush br = new SolidBrush(Color.White)) {
            g.FillRectangle(br, 0, 0, width, height);
          }
          
          using (Pen p = new Pen(shadowColor)) {
            for (int y = 0; y < results.Length; y++) {
              int r = results[y];
              if (0 == r) continue;
              int barWidth = (int) Math.Ceiling(r/(100F/(width-1)));      
              int barTop = y*(barHeight+1);        
              if (0 < y) barTop += y;
              int barLeft = (alignRight) ? (width-barWidth)-1 : 0;
              Color barColor = GetColor((string) barColors[Math.Min(barColors.Count-1, y)]);
              using (SolidBrush br = new SolidBrush(barColor)) {
                g.FillRectangle(br, barLeft, barTop, barWidth, barHeight);
              }
              if (barWidth > 1)
                g.DrawLine(p, barLeft+1, barTop+barHeight, barLeft+barWidth, barTop+barHeight);
              g.DrawLine(p, barLeft+barWidth, barTop+1, barLeft+barWidth, barTop+barHeight);
            }      
          }
          
          MemoryStream m = new MemoryStream(); 
          bitmap.Save(m, ImageFormat.Gif);
          return (transparent) ? MakeTransparent(m) : m;
        }
      }        
    } catch {
      return PlotError();
    }
  }
  
  MemoryStream PlotError() {

    MemoryStream m = new MemoryStream();
  
    using (Bitmap bitmap = new Bitmap(40, 15, PixelFormat.Format32bppArgb)) {
      using (Graphics g = Graphics.FromImage(bitmap)) {
        using (SolidBrush br = new SolidBrush(Color.White)) {
          g.FillRectangle(br, 0, 0, bitmap.Width, bitmap.Height);
        }
        using (Pen p = new Pen(Color.Red)) {
          g.DrawLine(p, 0, 0, bitmap.Width, bitmap.Height);
          g.DrawLine(p, 0, bitmap.Height, bitmap.Width, 0);
        }
        bitmap.Save(m, ImageFormat.Gif);
      }
    }
    return MakeTransparent(m);
  }
  
  void ok() {
    SetResponse(HttpStatusCode.OK, "Ok");
  }
  
  void error() {
    error(HttpStatusCode.BadRequest, "Bad Request");
  }
  void error(HttpStatusCode statusCode, string statusDescription) {
    SetResponse(statusCode, statusDescription);
    _response.BinaryWrite(PlotError().ToArray());
    _response.End();
  }

  HttpRequest _request;
  HttpResponse _response;
  
  public void ProcessRequest(HttpContext context) {
  
    _request = context.Request;
    _response = context.Response;
    
    if (!(("GET" == _request.RequestType) || ("HEAD" == _request.RequestType)))
      error(HttpStatusCode.MethodNotAllowed, "Method Not Allowed");
    
    ArrayList dataRaw = new ArrayList(GetArg("d", "").Split(new char[] {','}));
    int[] data = new int[dataRaw.Count];
    int dataIndex = -1;
    for (int rawIndex = 0; rawIndex < dataRaw.Count; rawIndex++) {
      if (0 == ((string) dataRaw[rawIndex]).Trim().Length) continue; 
      try { 
        data[dataIndex + 1] = int.Parse((string) dataRaw[rawIndex]); 
      }
      catch { continue; } 
      dataIndex++;
      if ((data[dataIndex] < 0) || (data[dataIndex] > 100)) 
        error();        
    }
    if (-1 == dataIndex) 
      error();
    data = (int[]) Redim(data, dataIndex + 1);

    string type = GetArg("type", "");
    if (!(("discrete" == type) || ("smooth" == type) || ("bars" == type)))
      error();
      
    ok();        
    
    if ("discrete" == type) _response.BinaryWrite(PlotSparklineDiscrete(data).ToArray());        
    if ("smooth" == type) _response.BinaryWrite(PlotSparklineSmooth(data).ToArray());
    if ("bars" == type) _response.BinaryWrite(PlotSparklineBars(data).ToArray());
        
  }
  
  public bool IsReusable {
    get { return false; }
  }
  
  // --------------------------------------------------------------------
  
  string GetArg(string argName, string argDefault) {
    string arg = _request.QueryString[argName];
    if (null == arg) return argDefault;
    return arg;
  }
  
  void SetResponse(HttpStatusCode statusCode, string statusDescription) {
    _response.ContentType = "image/gif";
    _response.StatusCode = (int) statusCode;
    _response.StatusDescription = statusDescription;
    _response.AddHeader("ETag", ((string) (_request.QueryString.ToString() + VERSION)).GetHashCode().ToString());
    _response.Flush();  
  }
      
  Array Redim(Array origArray, int newSize) {
    Type t = origArray.GetType().GetElementType();
    Array newArray = Array.CreateInstance(t, newSize);
    Array.Copy(origArray, 0, newArray, 0, Math.Min(origArray.Length, newSize));
    return newArray;      
  }
  
  void DrawTick(Graphics g, Color color, Point coord) {
    SolidBrush br = new SolidBrush(color);
    g.FillRectangle(br, coord.X-1, coord.Y-1, 3, 3);
    br.Dispose();
  }
  
  Color GetColor(string color) {
    if (color.StartsWith("#")) {        
      return Color.FromArgb(IntFromHexRgbPart(color, RgbPart.RgbPartRed), 
                            IntFromHexRgbPart(color, RgbPart.RgbPathGreen),
                            IntFromHexRgbPart(color, RgbPart.RgbPartBlue)
                            );
    }
    return Color.FromName(color);
  }
  
  enum RgbPart { RgbPartRed, RgbPathGreen, RgbPartBlue };
  
  int IntFromHexRgbPart(string hexRgb, RgbPart part) {
    if ((null == hexRgb) || (hexRgb.Length == 0) || (!(hexRgb.StartsWith("#"))))
      return 0;
    try {
      switch (part) {
        case RgbPart.RgbPartRed:
          if (hexRgb.Length < 3) return 0;
          return IntFromHex(hexRgb.Substring(1, 2));
        case RgbPart.RgbPathGreen:
          if (hexRgb.Length < 5) return 0;
          return IntFromHex(hexRgb.Substring(3, 2));
        case RgbPart.RgbPartBlue:
          if (hexRgb.Length < 7) return 0;
          return IntFromHex(hexRgb.Substring(5, 2));
        default:
          return 0;
      }
    }
    catch { return 0; }
  }
  
  int IntFromHex(string hex) {
    return (int) byte.Parse(hex, System.Globalization.NumberStyles.HexNumber);
  }
  
  MemoryStream MakeTransparent(MemoryStream origBitmapMemoryStream) {

    Color transparentColor = GetColor("White");
    int transparentArgb = transparentColor.ToArgb();

    using (Bitmap origBitmap = new Bitmap(origBitmapMemoryStream)) {
      using (Bitmap newBitmap = new Bitmap(origBitmap.Width, origBitmap.Height, origBitmap.PixelFormat)) {

        ColorPalette origPalette = origBitmap.Palette;
        ColorPalette newPalette = newBitmap.Palette;

        int index = 0;
        int transparentIndex = -1;

        foreach (Color origColor in origPalette.Entries) {
          newPalette.Entries[index] = Color.FromArgb(255, origColor);
          if (origColor.ToArgb() == transparentArgb) transparentIndex = index;
          index += 1;
        }

        if (-1 == transparentIndex) {
          return origBitmapMemoryStream;
        }

        newPalette.Entries[transparentIndex] = Color.FromArgb(0, transparentColor);
        newBitmap.Palette = newPalette;
        
        Rectangle rect = new Rectangle(0, 0, origBitmap.Width, origBitmap.Height);
        
        BitmapData origBitmapData = origBitmap.LockBits(rect, ImageLockMode.ReadOnly, origBitmap.PixelFormat);
        BitmapData newBitmapData = newBitmap.LockBits(rect, ImageLockMode.WriteOnly, newBitmap.PixelFormat);    

        for (int y = 0; y < origBitmap.Height; y++) {
          for (int x = 0; x < origBitmap.Width; x++) {
            byte origBitmapByte = Marshal.ReadByte(origBitmapData.Scan0, origBitmapData.Stride * y + x);
            Marshal.WriteByte(newBitmapData.Scan0, newBitmapData.Stride * y + x, origBitmapByte);
          }    
        }

        newBitmap.UnlockBits(newBitmapData);
        origBitmap.UnlockBits(origBitmapData);

        MemoryStream m = new MemoryStream();
        newBitmap.Save(m, ImageFormat.Gif);
        return m;
        
      }
    }
    
  }

  ResultsInfo EvaluateResults(int[] results, bool scale) {
    ResultsInfo ri = EvaluateResults(results);
    if (!scale) return ri;
    float range = ri.Max - ri.Min;
    for (int x = 0; x < results.Length; x++) {
      results[x] = Math.Max((int)((results[x]-ri.Min)/range*100F), 1);
    }
    return EvaluateResults(results);
  }
  
  ResultsInfo EvaluateResults(int[] results) {
    int min = 100, minIndex = -1;
    int max = 0, maxIndex = -1;    
    for (int x = 0; x < results.Length; x++) {
      int r = results[x];
      if (r < min) { min = r; minIndex = x; }
      if (r > max) { max = r; maxIndex = x; }
    }    
    return new ResultsInfo(min, minIndex, max, maxIndex);
  }
  
  private class ResultsInfo {
  
    public readonly int Min = 100;
    public readonly int MinIndex = 0;
    public readonly int Max = 0;
    public readonly int MaxIndex = 0;
    
    private ResultsInfo() {}
    
    public ResultsInfo(int min, int minIndex, int max, int maxIndex) {
      Min = min;
      MinIndex = minIndex;
      Max = max;
      MaxIndex = maxIndex;
    }
    
  }

}