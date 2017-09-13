using System;
using System.Collections;
using System.Net;
using System.IO;
using System.Text.RegularExpressions;
using Microsoft.Practices.EnterpriseLibrary.Data.Sql;
using System.Data.Common;
using Newtonsoft.Json.Linq;
using System.Collections.Generic;
using System.Text;

namespace StatGrabber
{
    public class StatGrabber
    {
        public StatGrabber()
        { 
        }

        public ArrayList GetGames( DateTime DateToGet )
        {
            string endpoint = "scoreboard";
            Dictionary<string, string> p = new Dictionary<string, string>();
            p.Add("LeagueId", "00");
            p.Add( "GameDate", String.Format("{0:00}%2F{1:00}%2F{2}",
                DateToGet.Month.ToString(), DateToGet.Day.ToString(), DateToGet.Year.ToString() ) );
            p.Add( "DayOffset", "0" );
            string page = ScrapeNBAApi(endpoint, p );

            ArrayList retval = new ArrayList();
            JObject sb = JObject.Parse( page );
            JArray games = (JArray)sb["resultSets"][0]["rowSet"];
            foreach (var game in games)
            {
                retval.Add((string)game[2]);
            }
            return retval;
        }

        public ArrayList GetGamePerformances( string GameId )
        {
            string endpoint = "boxscoretraditionalv2";
            Dictionary<string, string> parameters = new Dictionary<string, string>();
            parameters.Add("GameId", GameId );
            parameters.Add("Season", "2016-17");
            parameters.Add("SeasonType", "Regular%20Season");
            parameters.Add("RangeType", "0");
            parameters.Add("StartPeriod", "0");
            parameters.Add("EndPeriod", "0");
            parameters.Add("StartRange", "0");
            parameters.Add("EndRange", "0");
            string page = ScrapeNBAApi(endpoint, parameters);

            ArrayList perfs = new ArrayList();
            JObject sb = JObject.Parse(page);
            JArray performances = (JArray)sb["resultSets"][0]["rowSet"];
            Regex ExtractPlayerName = new Regex(@"^([\w\.\'-]+)\s+?([\w\.\'-]+(?:\s[\w.]+)?)(?:.*?)");
            try
            {
                foreach (var perf in performances)
                {
                    if (((string)perf[7]).Length > 0)
                    {
                        // DNP
                        continue;
                    }
                    PlayerPerformance p = new PlayerPerformance();
                    p.NBAId = Int32.Parse((string)perf[4]);
                    p.Assists = Int32.Parse((string)perf[21]);
                    p.Blocks = Int32.Parse((string)perf[23]);
                    p.DefensiveRebounds = Int32.Parse((string)perf[19]);

                    // these come in a single string
                    try
                    {
                        if (((string)perf[5]).Equals("Nene"))
                        {
                            p.FirstName = "Nene";
                            p.LastName = "Hilario";
                        }
                        else
                        {
                            MatchCollection PlayerName = ExtractPlayerName.Matches((string)perf[5]);
                            p.FirstName = PlayerName[0].Groups[1].Value;
                            p.LastName = PlayerName[0].Groups[2].Value;
                            if (p.FirstName.Length == 2)
                            {
                                p.FirstName = p.FirstName.Substring(0, 1);
                            }
                        }
                    }
                    catch (Exception e)
                    {
                        StatGrabberException ex = new StatGrabberException(
                            "Having trouble with: " + (string)perf[5]);
                        throw ex;
                    }

                    // this comes as MM:SS 
                    string[] minuteSplit = ((string)perf[8]).Split(':');
                    if (int.Parse(minuteSplit[1]) > 29)
                    {
                        p.Minutes = int.Parse(minuteSplit[0]) + 1;
                    }
                    else
                    {
                        p.Minutes = int.Parse(minuteSplit[0]);
                    }

                    p.Fouls = Int32.Parse((string)perf[25]);
                    p.FTAttempts = Int32.Parse((string)perf[16]);
                    p.FTsMade = Int32.Parse((string)perf[15]);
                    p.OffensiveRebounds = Int32.Parse((string)perf[18]);
                    p.PlusMinus = Int32.Parse((string)perf[27]);
                    p.ShotAttempts = Int32.Parse((string)perf[10]);
                    p.ShotsMade = Int32.Parse((string)perf[9]);
                    p.Steals = Int32.Parse((string)perf[22]);
                    p.TeamName = (string)perf[2];
                    p.ThreeAttempts = Int32.Parse((string)perf[13]);
                    p.ThreesMade = Int32.Parse((string)perf[12]);
                    p.Turnovers = Int32.Parse((string)perf[24]);
                    perfs.Add(p);
                }
            }
            catch (Exception ex)
            {
                throw new StatGrabberException("Having trouble parsing info from game " + GameId);
            }
            return perfs;
        }

        public ArrayList SavePerformances( SqlDatabase db, ArrayList perfs, DateTime when )
        {
            ArrayList problems = new ArrayList();
            DbConnection conn = db.CreateConnection();
            conn.Open();
            DbTransaction trans = conn.BeginTransaction();
            try
            {
                foreach( PlayerPerformance p in perfs )
                {
                    DbCommand cmd = db.GetStoredProcCommand( "spAddPlayerPerformance",
                        when, p.FirstName, p.LastName, p.TeamName, p.Minutes, p.Assists, p.Blocks,
                        p.DefensiveRebounds, p.Fouls, p.FTAttempts, p.FTsMade, p.OffensiveRebounds,
                        p.PlusMinus, p.ShotAttempts, p.ShotsMade, p.Steals, p.ThreeAttempts,
                        p.ThreesMade, p.Turnovers, p.NBAId );
                    int x = (int)db.ExecuteScalar( cmd, trans );
                    if( x != 0 )
                    {
                        problems.Add( p );
                    }
                }
                trans.Commit();
            }
            catch( Exception e )
            {
                trans.Rollback();
                PlayerPerformance p = new PlayerPerformance();
                p.FirstName = "Exception thrown while saving results to db: " + e.Message;
                problems.Add( p );
            }
            conn.Close();
            return problems;
        }
        
        public string UpdateAveragesAndScores( SqlDatabase db, DateTime when )
        {
            string result = "Successfully updated scores and averages";
            DbConnection conn = db.CreateConnection();
            conn.Open();
            DbTransaction trans = conn.BeginTransaction();
            try
            {
                db.ExecuteNonQuery( "spSetCurrentScore", when );
                db.ExecuteNonQuery( "spRecalcPlayerAverages" );
                trans.Commit();
            }
            catch( Exception e )
            {
                result = "Failed to update scores and averages: " + e.Message;
                trans.Rollback();
            }
            conn.Close();
            return result;
        }

        public string ScrapeNBAApi(string endpoint, Dictionary<string, string> parameters)
        {
            System.Threading.Thread.Sleep(1000);

            string url = "http://stats.nba.com/stats/" + endpoint + "?";
            bool first = true;
            foreach (KeyValuePair<string,string> param in parameters)
            {
                if (!first)
                {
                    url += "&";
                }
                else
                {
                    first = false;
                }
                url += param.Key + "=" + param.Value;
            }

            HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
            request.AutomaticDecompression = DecompressionMethods.Deflate | DecompressionMethods.GZip;
            request.Referer = "http://stats.nba.com/scores/";
            request.Method = "GET";
            request.UserAgent = "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36";
			request.Headers["Dnt"] = "1";
			request.Headers["Accept-Encoding"] = "gzip, deflate, sdch";
			request.Headers["Accept-Language"] = "en-US,en;q=0.8,af;q=0.6";
			request.Headers["origin"] = "http://stats.nba.com";
            WebResponse wres = request.GetResponse();
            Stream receiveStream = wres.GetResponseStream();
            Encoding encode = Encoding.GetEncoding("utf-8");
            // Pipes the stream to a higher level stream reader with the required encoding format. 
            StreamReader sr = new StreamReader(receiveStream, encode);
            string page = sr.ReadToEnd();
            sr.Close();
            return page;
        }
    }
}
