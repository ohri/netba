using System;
using System.Collections;
using System.Net;
using System.IO;
using System.Text.RegularExpressions;
using Microsoft.Practices.EnterpriseLibrary.Data.Sql;
using System.Data.Common;

namespace StatGrabber
{
    public class StatGrabber
    {
        public StatGrabber()
        { 
        }

        public ArrayList GetGames( DateTime DateToGet )
        {
            string page = WebPageToString( "http://espn.go.com/nba/scoreboard?date=" + DateToString( DateToGet ) );

            ArrayList retval = new ArrayList();

            Regex boxstart = new Regex(@"en"",""href"":""(http://espn.go.com/nba/boxscore\?gameId=\d*)");
            //Extract the address
            Match m = boxstart.Match( page );
            while( m.Success )
            {
                string url = m.Groups[1].Value;
                if (!retval.Contains(url))
                {
                    retval.Add(url);
                }
                m = m.NextMatch();
            }

            return retval;
        }

        public ArrayList GetGamePerformances( string url )
        {
            // <div class="team-name"><img src="http://a.espncdn.com/combiner/i?img=/i/teamlogos/nba/500/phi.png&h=100&w=100" /></div>76ers<div class
            Regex GetTeams = new Regex(@"<div class=""team-name""><img src.*?div>(.*?)<div class");

            /*
            <tr>< td class="name" "><a  name=" &lpos=nba:game:boxscore:playercard" href="http://espn.go.com/nba/player/_/id/3064290">A. Gordon</a>
            <span class="position">PF</span></td><td class="min">30</td><td class="fg">4-10</td><td class="threeptm-a">0-1</td>
            <td class="ftma">3-6</td><td class="oreb">2</td><td class="dreb">9</td><td class="reb">11</td><td class="ast">3</td>
            <td class="stl">3</td><td class="blk">1</td><td class="to">2</td><td class="pf">3</td><td class="plusminus">+2</td>
            <td class="pts">11</td></tr>
            */
            Regex GetPlayerStatRows = new Regex(@"<tr><td class=""name"" "">(.*?)</td></tr>");
            Regex SplitStatRows = new Regex( @"</td><td.*?>" );
            Regex ExtractPlayerName = new Regex( @"^(?:.+?>)?([\w\.\'-]+)\s+?([\w\.\'-]+(?:\s[\w.]+)?)(?:.*?)?$" );
            Regex ExtractThrees = new Regex( @"([0-9]*)\-([0-9]*)" );
            Regex ESPNIdReg = new Regex(@"([0-9]+)");
            Regex NeneException = new Regex(@".*Nen.*", RegexOptions.IgnoreCase);
            string Page = WebPageToString( url );

            MatchCollection TeamMatches = GetTeams.Matches( Page );
            if( TeamMatches.Count != 2 )
            {
                StatGrabberException ex = new StatGrabberException(
                    "Couldn't find the teams in game "
                    + url
                    + " ... maybe ESPN hasn't finalized them?" );
                throw ex;
            }

            int HomeAfterThis = TeamMatches[1].Groups[1].Index;

            ArrayList perfs = new ArrayList();
            MatchCollection StatLines = GetPlayerStatRows.Matches( Page );
            foreach( Match i in StatLines )
            {
                if( i.Groups.Count < 2 )
                {
                    StatGrabberException ex = new StatGrabberException(
                        "Seems to be a problem in the statline structure in game "
                        + url
                        + " ... maybe ESPN has changed format?" );
                    throw ex;
                }

                string[] Cells = SplitStatRows.Split( i.Groups[1].Value );

                PlayerPerformance p = new PlayerPerformance();
                MatchCollection PlayerName = ExtractPlayerName.Matches( Cells[0] );
                MatchCollection ESPNIdMatches = ESPNIdReg.Matches( Cells[0] );
                try
                {
                    p.ESPNId = Int32.Parse(ESPNIdMatches[0].Groups[0].Value);
                }
                catch
                {
                    // we really don't care if it doesn't work, just keep trucking
                    int x = 1;
                }

                if( PlayerName.Count < 1 )
                {
                    // the nene exception
                    MatchCollection Nene = NeneException.Matches( Cells[0] );
                    if( Nene.Count > 0 )
                    {
                        // yup, it's him
                        p.FirstName = "Nene";
                        p.LastName = "Hilario";
                    }
                    else
                    {
                        StatGrabberException ex = new StatGrabberException(
                            "Player's name doesn't match the pattern: " + Cells[0] );
                        throw ex;
                    }
                }
                else
                {
                    p.FirstName = PlayerName[0].Groups[1].Value;
                    p.LastName = PlayerName[0].Groups[2].Value;
                    if (p.FirstName.Length == 2)
                    {
                        p.FirstName = p.FirstName.Substring(0, 1);
                    }
                }

                if ( i.Index >= HomeAfterThis )
                {
                    p.TeamName = TeamMatches[1].Groups[1].Value;
                }
                else
                {
                    p.TeamName = TeamMatches[0].Groups[1].Value;
                }
                try
                {
                    // cell 1 has minutes
                    p.Minutes = Convert.ToInt32( Cells[1] );

                    // cell 2 has made-attempted FG
                    Match fgs = ExtractThrees.Match( Cells[2] );
                    p.ShotsMade = Convert.ToInt32( fgs.Groups[1].Value );
                    p.ShotAttempts = Convert.ToInt32( fgs.Groups[2].Value );

                    // cell 3 has made-attempted on 3 pointers
                    Match threes = ExtractThrees.Match( Cells[3] );
                    p.ThreesMade = Convert.ToInt32( threes.Groups[1].Value );
                    p.ThreeAttempts = Convert.ToInt32( threes.Groups[2].Value );

                    // cell 4 has made-attempted FT
                    Match fts = ExtractThrees.Match( Cells[4] );
                    p.FTsMade = Convert.ToInt32( fts.Groups[1].Value );
                    p.FTAttempts = Convert.ToInt32( fts.Groups[2].Value );

                    // cell 5 has off rebs
                    p.OffensiveRebounds = Convert.ToInt32( Cells[5] );

                    // cell 6 has def rebs
                    p.DefensiveRebounds = Convert.ToInt32( Cells[6] );

                    // cell 8 has ast
                    p.Assists = Convert.ToInt32( Cells[8] );

                    // cell 9 has stl
                    p.Steals = Convert.ToInt32( Cells[9] );

                    // cell 10 has blocks
                    p.Blocks += Convert.ToInt32( Cells[10] );

                    // cell 11 has to
                    p.Turnovers = Convert.ToInt32( Cells[11] );

                    // cell 12 has pf
                    p.Fouls = Convert.ToInt32( Cells[12] );

                    // cell 13 has +/-
                    p.PlusMinus = Convert.ToInt32( Cells[13] );

                    // cell 14 has points

                    perfs.Add( p );
                }
                catch( System.FormatException e )
                {
                    // yes, this is a horrible thing to do, but it works and i'm 
                    // too lazy to switch it
                    // this exception happens when the player gets a DNP of some
                    // sort
                }
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
                        p.ThreesMade, p.Turnovers, p.ESPNId );
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

        public string DateToString( DateTime x )
        {
            return x.Year.ToString() + x.Month.ToString( "0#" ) + x.Day.ToString( "0#" );
        }

        public string WebPageToString( string url )
        {
            WebRequest wreq = HttpWebRequest.Create( url );
            WebResponse wres = wreq.GetResponse();
            StreamReader sr = new StreamReader( wres.GetResponseStream() );
            string page = sr.ReadToEnd();
            sr.Close();
            return page;
        }
    }
}
