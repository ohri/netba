using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Microsoft.ApplicationBlocks.Data;
using System.Data;

namespace netba.Controls
{
    public partial class TradeBlock : System.Web.UI.UserControl
    {
        protected void Page_Load( object sender, EventArgs e )
        {
            if( !IsPostBack )
            {
                DataSet dsTopPerformances = SqlHelper.ExecuteDataset( System.Configuration.ConfigurationManager.AppSettings["ConnectionString"],
                    @"spFetchTradeBlockRecent" );
                dgTradeBlock.DataSource = dsTopPerformances;
                dgTradeBlock.DataBind();
            }
        }
    }
}