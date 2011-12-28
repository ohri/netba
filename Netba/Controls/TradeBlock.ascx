<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="TradeBlock.ascx.cs" Inherits="netba.Controls.TradeBlock" %>
<link href="/Styles/netba.css" type="text/css" rel="stylesheet" />
<asp:Panel ID="Panel1" runat="server" BorderStyle="Solid" BorderColor="Silver" BackColor="White">
    <center><strong>Trade Block</strong>
    <asp:DataGrid ID="dgTradeBlock" runat="server" CssClass="subtlegrid" AutoGenerateColumns="False"
        ShowHeader="False" GridLines="None">
        <Columns>
            <asp:BoundColumn DataField="TeamAbbrev" HeaderText="Team"></asp:BoundColumn>
            <asp:BoundColumn DataField="Player" HeaderText="Player"></asp:BoundColumn>
            <asp:BoundColumn DataField="NetPPG" HeaderText="Points"></asp:BoundColumn>
            <asp:HyperLinkColumn DataNavigateUrlField="PlayerId" 
                DataNavigateUrlFormatString="/Pages/TradePropose.aspx?PlayerId={0}" 
                Text="Trade"></asp:HyperLinkColumn>
        </Columns>
    </asp:DataGrid>
    </center>
</asp:Panel>
