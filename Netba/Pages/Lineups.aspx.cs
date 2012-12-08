using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using Microsoft.ApplicationBlocks.Data;
using System.Text;
using Logger;

namespace netba.Pages
{
	public partial class Lineups : System.Web.UI.Page
	{

        private ArrayList PlayerLabels;
        private ArrayList PlayerHiddens;

		protected void Page_Load(object sender, System.EventArgs e)
		{
            if( PlayerLabels == null )
            {
                PlayerLabels = PopulatePlayerLabels();
            }
            if( PlayerHiddens == null )
            {
                PlayerHiddens = PopulatePlayerHiddens();
            }

            if( DBUtilities.GetCurrentWeek().Equals( "1" ) )
            {
                CopyButton.Enabled = false;
            }
            else
            {
                CopyButton.Enabled = true;
            }

			if( !IsPostBack )
			{
                DataSet teams = SqlHelper.ExecuteDataset(System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
					"spGetAllTeams" );		
				lbTeams.DataSource = teams;
				lbTeams.DataTextField = "TeamAbbrev";
				lbTeams.DataValueField = "TeamId";
				lbTeams.DataBind();

                DataSet weeks = SqlHelper.ExecuteDataset(System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
					"spGetAllWeeks" );		
				lbWeeks.DataSource = weeks;
				lbWeeks.DataTextField = "Week";
				lbWeeks.DataValueField = "WeekId";
				lbWeeks.DataBind();

				int currentweekid = DBUtilities.GetLineupWeekId();
                if (currentweekid == -1)
                {
                    Response.Redirect( "/Static/no_lineups.html" );
                }
				Session["LineupWeekId"] = currentweekid;

				int i = 0;
				while( i < lbWeeks.Items.Count )
				{
					if( Convert.ToInt32( lbWeeks.Items[i].Value ) == currentweekid )
					{
						break;
					}
					i++;
				}
				lbWeeks.SelectedIndex = i;

				int teamid = DBUtilities.GetUsersTeamId( Page.User.Identity.Name );
				Session["TeamId"] = teamid;
				i = 0;
				while( i < lbTeams.Items.Count )
				{
					if( Convert.ToInt32( lbTeams.Items[i].Value ) == teamid )
					{
						break;
					}
					i++;
				}
				lbTeams.SelectedIndex = i;
			}
		}

        private ArrayList PopulatePlayerHiddens()
        {
            ArrayList hiddens = new ArrayList();
            hiddens.Add( hiddenSPG );
            hiddens.Add( hiddenSSG );
            hiddens.Add( hiddenSSF );
            hiddens.Add( hiddenSPF );
            hiddens.Add( hiddenSC );
            hiddens.Add( hiddenBPG );
            hiddens.Add( hiddenBSG );
            hiddens.Add( hiddenBSF );
            hiddens.Add( hiddenBPF );
            hiddens.Add( hiddenBC );
            hiddens.Add( hiddenG1 );
            hiddens.Add( hiddenG2 );
            return hiddens;
        }

        private ArrayList PopulatePlayerLabels()
        {
            ArrayList labels = new ArrayList();
            labels.Add( lblPG );
            labels.Add( lblSG );
            labels.Add( lblSF );
            labels.Add( lblPF );
            labels.Add( lblC );
            labels.Add( lblBackupPG );
            labels.Add( lblBackupSG );
            labels.Add( lblBackupSF );
            labels.Add( lblBackupPF );
            labels.Add( lblBackupC );
            labels.Add( lblGarbage1 );
            labels.Add( lblGarbage2 );
            return labels;
        }

		#region Web Form Designer generated code
		override protected void OnInit(EventArgs e)
		{
			//
			// CODEGEN: This call is required by the ASP.NET Web Form Designer.
			//
			InitializeComponent();
			base.OnInit(e);
		}
		
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{    

		}
		#endregion

		protected void ButtonSubmitTeamWeek_Click(object sender, System.EventArgs e)
		{
			PlayerSelection.Visible = true;
			TeamWeekSelection.Visible = false;

            int GameId = GameId = (int)SqlHelper.ExecuteScalar(System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
				"spGetGame", lbTeams.SelectedValue, lbWeeks.SelectedValue );
            DataSet GameInfo = SqlHelper.ExecuteDataset(System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
				"spGetGameDetails", GameId );
			DataRow r = GameInfo.Tables[0].Rows[0];

			lblGameHeader.Text = "";

			Session["TeamId"] = lbTeams.SelectedValue;

			lblGameHeader.Text = "Week " + r["Week"] + ": ";
			lblGameHeader.Text += r["visitor"].ToString() + " @ " + r["home"].ToString();
			lblGameHeader.Text += ", " + r["NumGames"] + " games";

            Session["WeekId"] = lbWeeks.SelectedValue;
			Session["LineupGameId"] = GameId;

            DataSet lineup = SqlHelper.ExecuteDataset(System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
				"spGetTeamLineup", GameId, lbTeams.SelectedValue );	
			lbRoster.DataSource = lineup;
			lbRoster.DataTextField = "player";
			lbRoster.DataValueField = "PlayerId";
			lbRoster.DataBind();

			// if there was an existing lineup, prepopulate!
			if( lineup.Tables[0].Rows[0]["LineupId"] != DBNull.Value )
			{
                for( int i = 0; i < 12; i++ )
                {
                    ( (HiddenField)PlayerHiddens[i] ).Value = lineup.Tables[0].Rows[i]["PlayerId"].ToString();
                }

                for( int i = 0; i < 12; i++ )
                {
                   ((Label)PlayerLabels[i]).Text = lineup.Tables[0].Rows[i]["player"].ToString();
                }
			}
		}

		protected void ButtonSubmitLineup_Click(object sender, System.EventArgs e)
		{
			Log.AddLogEntry( LogEntryTypes.LineupSubmission, 
				Page.User.Identity.Name, 
				"Lineup submitted for team id " + Session["TeamId"] + ", gameid " + Session["LineupGameId"] );

			// delete the existing lineup records for this 
			try
			{
                SqlHelper.ExecuteNonQuery(System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
					"spClearTeamLineup", Session["TeamId"], Session["LineupGameId"] );
            }
            catch( Exception ex )
            {
                Log.AddLogEntry( Logger.LogEntryTypes.SystemError,
                    Page.User.Identity.Name,
                    "Failed to clear existing lineup for teamid " + Session["TeamId"] + ", gameid " + Session["LineupGameId"] + " with exception: " + ex.Message );
                Response.Redirect( "/Static/default_error.html" );
                return;
            }

            // write each of the new lineup items
			try
			{
                SqlHelper.ExecuteNonQuery( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    "spSetPlayerLineupStatus", hiddenSPG.Value, "S", Session["TeamId"], Session["LineupGameId"], 1 );
                SqlHelper.ExecuteNonQuery( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    "spSetPlayerLineupStatus", hiddenSSG.Value, "S", Session["TeamId"], Session["LineupGameId"], 2 );
                SqlHelper.ExecuteNonQuery( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    "spSetPlayerLineupStatus", hiddenSSF.Value, "S", Session["TeamId"], Session["LineupGameId"], 3 );
                SqlHelper.ExecuteNonQuery( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    "spSetPlayerLineupStatus", hiddenSPF.Value, "S", Session["TeamId"], Session["LineupGameId"], 4 );
                SqlHelper.ExecuteNonQuery( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    "spSetPlayerLineupStatus", hiddenSC.Value, "S", Session["TeamId"], Session["LineupGameId"], 5 );
                SqlHelper.ExecuteNonQuery( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    "spSetPlayerLineupStatus", hiddenBPG.Value, "B", Session["TeamId"], Session["LineupGameId"], 6 );
                SqlHelper.ExecuteNonQuery( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    "spSetPlayerLineupStatus", hiddenBSG.Value, "B", Session["TeamId"], Session["LineupGameId"], 7 );
                SqlHelper.ExecuteNonQuery( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    "spSetPlayerLineupStatus", hiddenBSF.Value, "B", Session["TeamId"], Session["LineupGameId"], 8 );
                SqlHelper.ExecuteNonQuery( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    "spSetPlayerLineupStatus", hiddenBPF.Value, "B", Session["TeamId"], Session["LineupGameId"], 9 );
                SqlHelper.ExecuteNonQuery( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    "spSetPlayerLineupStatus", hiddenBC.Value, "B", Session["TeamId"], Session["LineupGameId"], 10 );
                
                // it's possible someone could be short a garbage player
				if( hiddenG1.Value.Length != 0 )
				{
                    SqlHelper.ExecuteNonQuery(System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                        "spSetPlayerLineupStatus", hiddenG1.Value, "G", Session["TeamId"], Session["LineupGameId"], 11 );
				}
                if( hiddenG2.Value.Length != 0 )
				{
                    SqlHelper.ExecuteNonQuery(System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                        "spSetPlayerLineupStatus", hiddenG2.Value, "G", Session["TeamId"], Session["LineupGameId"], 12 );
				}
                
            }
			catch( Exception ex )
			{
				Log.AddLogEntry( Logger.LogEntryTypes.SystemError, 
					Page.User.Identity.Name, 
					"Failed to save new lineup records for teamid " + Session["TeamId"] + ", gameid " + Session["LineupGameId"] + " with exception: " + ex.Message );
                Response.Redirect( "/Static/default_error.html" );
                return;
            }

            SendLineupEmail( int.Parse( Session["TeamId"].ToString() ), int.Parse( Session["LineupGameId"].ToString() ) );

            Response.Redirect( "/Pages/home.aspx" );
        }

        protected void SendLineupEmail( int teamid, int gameid )
        {
            DataSet GameInfo = SqlHelper.ExecuteDataset( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                "spGetGameDetails", gameid );
            DataRow r = GameInfo.Tables[0].Rows[0];
            String MsgBody = "<h2><font face=arial>";
            String thisteam;
            if( r["hometeamid"].ToString() == teamid.ToString() )
            {
                MsgBody += r["home"].ToString() + " Lineup vs. " + r["visitor"].ToString() + "</font></h2>";
                thisteam = r["home"].ToString();
            }
            else
            {
                MsgBody += r["visitor"].ToString() + " Lineup @ " + r["home"].ToString() + "</font></h2>";
                thisteam = r["visitor"].ToString();
            }
            MsgBody += "<font face=arial><p><strong>Week " + r["Week"].ToString() + ": " + r["NumGames"].ToString() + " games</strong></p><br />";

            MsgBody += "<strong>Comment: </strong>" + tbComment.Text + "<br />";
            MsgBody += "<i>&nbsp;&nbsp;-- " + Page.User.Identity.Name.ToString() + "</i></font><br /><br />";

            DataSet lineup = SqlHelper.ExecuteDataset( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                "spGetTeamLineupSimple", gameid, teamid );

            MsgBody += "<font face=arial><strong><u>Starters</u></strong><br />";
            MsgBody += lineup.Tables[0].Rows[0]["player"] + "<br />";
            MsgBody += lineup.Tables[0].Rows[1]["player"] + "<br />";
            MsgBody += lineup.Tables[0].Rows[2]["player"] + "<br />";
            MsgBody += lineup.Tables[0].Rows[3]["player"] + "<br />";
            MsgBody += lineup.Tables[0].Rows[4]["player"] + "<br />";
            MsgBody += "<br /><strong><u>Backups</u></strong><br />";
            MsgBody += lineup.Tables[0].Rows[5]["player"] + "<br />";
            MsgBody += lineup.Tables[0].Rows[6]["player"] + "<br />";
            MsgBody += lineup.Tables[0].Rows[7]["player"] + "<br />";
            MsgBody += lineup.Tables[0].Rows[8]["player"] + "<br />";
            MsgBody += lineup.Tables[0].Rows[9]["player"] + "<br />";
            MsgBody += "<br /><strong><u>Garbage</u></strong><br />";
            if( lineup.Tables[0].Rows.Count > 10 )
            {
                MsgBody += lineup.Tables[0].Rows[10]["player"] + "<br />";
            }
            if( lineup.Tables[0].Rows.Count > 11 )
            {
                MsgBody += lineup.Tables[0].Rows[11]["player"] + "<br />";
            }
            MsgBody += "</font>";

            String subject = thisteam + "Lineup for Week " + r["Week"].ToString();
            if( tbComment.Text.Length > 0 )
            {
                subject += " (C)";
            }

            mailer.sendSynchronousLeagueMail(
                subject,
                MsgBody,
                true,
                Page.User.Identity.Name );
        }

        protected void ResetButton_Click(object sender, EventArgs e)
        {
            ResetFields();
        }

        private void ResetFields()
        {
            for( int i = 0; i < 12; i++ )
            {
                ( (HiddenField)PlayerHiddens[i] ).Value = "";
            } 
            
            for( int i = 0; i < 12; i++ )
            {
                ( (Label)PlayerLabels[i] ).Text = "Pick 'n Click";
            }
        }

        protected void CopyButton_Click(object sender, EventArgs e)
        {
            // get last weeks starters who are still on the team and active
            DataSet lineup = SqlHelper.ExecuteDataset( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                "spGetTeamLastWeekLineup", lbTeams.SelectedValue, Session["WeekId"] );

            ResetFields();

            // loop through all returned info
            foreach( DataRow r in lineup.Tables[0].Rows )
            {
                ((Label)PlayerLabels[ Int32.Parse( r["LineupPosition"].ToString() ) - 1 ]).Text  = r["player"].ToString();
                ((HiddenField)PlayerHiddens[ Int32.Parse( r["LineupPosition"].ToString() ) - 1 ]).Value = r["PlayerId"].ToString();
            }
        }
	}
}
