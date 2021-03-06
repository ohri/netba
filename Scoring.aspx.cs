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
using System.Data.SqlClient;
using Logger;
using StatGrabber;
using Microsoft.Practices.EnterpriseLibrary.Data.Sql;

namespace netba.Pages
{
	/// <summary>
	/// Summary description for Scoring.
	/// </summary>
	public partial class Scoring : System.Web.UI.Page
	{
	
		protected void Page_Load(object sender, System.EventArgs e)
		{
			if( !DBUtilities.IsUserAdmin( Page.User.Identity.Name ) )
			{
				Response.Redirect( "/Static/notauthorized.html" );
			}

            Server.ScriptTimeout = 300;

			// Put user code to initialize the page here
			if( !IsPostBack )
			{
                DataSet ds = SqlHelper.ExecuteDataset(System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
				"spGetAllWeeks" );
				ddlWeeks.DataSource = ds;
				ddlWeeks.DataTextField = "Week";
				ddlWeeks.DataValueField = "WeekId";
				ddlWeeks.DataBind();

				calStatDate.SelectedDate = DateTime.Today.AddDays( -1 );
			}
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

		protected void ButtonFinalize_Click(object sender, System.EventArgs e)
		{
            SqlDatabase db = new SqlDatabase( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"] );
            tbOutput.Text += Autosub( ddlWeeks.SelectedValue, db, calStatDate.SelectedDate );
            SqlHelper.ExecuteNonQuery(System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
				"spFinalizeGames", Convert.ToInt32( ddlWeeks.SelectedValue ) );
            tbOutput.Text += "\r\nGames finalized for week " + ddlWeeks.SelectedItem.Text;
			Log.AddLogEntry( LogEntryTypes.WeekFinalized, Page.User.Identity.Name, "Finalized stats for weekid " + ddlWeeks.SelectedValue + ", week " + ddlWeeks.SelectedItem.Text );
		}

		protected void ButtonProcessDaily_Click(object sender, System.EventArgs e)
		{
            tbOutput.Text += "\r\nScraping " + calStatDate.SelectedDate.ToString() + "\r\n";

            StatGrabber.StatGrabber sg = new StatGrabber.StatGrabber();

            ArrayList urls = sg.GetGames( this.calStatDate.SelectedDate );

            tbOutput.Text += "Found " + urls.Count + " games\r\n";

            SqlDatabase db = new SqlDatabase( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"] );
            ArrayList problems = new ArrayList();
            foreach( string url in urls )
            {
                try
                {
                    ArrayList perfs = sg.GetGamePerformances( url );
                    tbOutput.Text += "Got " + perfs.Count + " perfs from " + url + "\r\n";
                    problems.AddRange( sg.SavePerformances( db, perfs, calStatDate.SelectedDate ) );
                }
                catch( StatGrabber.StatGrabberException ex )
                {
                    tbOutput.Text += ex.Message + "\r\n";
                }
            }

            if( problems.Count > 0 )
            {
                tbOutput.Text += "\r\nFound the following problems:\r\n";
                foreach( StatGrabber.PlayerPerformance p in problems )
                {
                    tbOutput.Text += p.FirstName + " " + p.LastName + " " + p.TeamName + "\r\n";
                }
            }
            else
            {
                tbOutput.Text += "\r\nNo problems identifying players\r\n";
            }

            tbOutput.Text += "\r\n";
            tbOutput.Text += sg.UpdateAveragesAndScores( db, calStatDate.SelectedDate );

            Log.AddLogEntry( 
				LogEntryTypes.StatsProcessed, 
				Page.User.Identity.Name, 
				tbOutput.Text );
		}
        protected void btnAutosub_Click( object sender, EventArgs e )
        {
            //string result = AutoSub.ProcessAutosubs( ddlWeeks.SelectedValue );
            //tbOutput.Text += result;
            //StatGrabber.StatGrabber sg = new StatGrabber.StatGrabber();
            SqlDatabase db = new SqlDatabase( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"] );
            //tbOutput.Text += sg.UpdateAveragesAndScores( db, calStatDate.SelectedDate );
            tbOutput.Text += Autosub( ddlWeeks.SelectedValue, db, calStatDate.SelectedDate );
        }

        protected void ButtonClear_Click( object sender, EventArgs e )
        {
            tbOutput.Text = "";
        }

        protected string Autosub( string weekId, SqlDatabase db, DateTime selectedDate )
        {
            string result = AutoSub.ProcessAutosubs( weekId );
            StatGrabber.StatGrabber sg = new StatGrabber.StatGrabber();
            result += sg.UpdateAveragesAndScores( db, selectedDate );
            return result;
        }
    }
}
