<%@ Page Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" Inherits="netba.Pages.TeamPage"
    ValidateRequest="false" Title="Team Page" CodeBehind="TeamPage.aspx.cs" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Title" runat="Server">
    <asp:Label ID="lblPageTitle" runat="server" CssClass="pagetitle"></asp:Label>
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Main" runat="Server">
    <table border="0" cellpadding="10" cellspacing="10">
        <tr>
            <td>
                <p>
                    <font size="3">
                        <asp:HyperLink ID="hlEmail" runat="server">HyperLink</asp:HyperLink>
                        <asp:Literal ID="litOwnerInfo" runat="server"></asp:Literal>
                        <asp:Literal ID="litEditLink" runat="server"></asp:Literal>
                    </font>
                </p>
                </td><td>
                <p>
                    <font size="3">Record:
                        <asp:Label ID="lblRecord" runat="server"></asp:Label>
                    </font>
                    <br/>
                    <font size="3">
                        <asp:HyperLink ID="hlTeamHistory" runat="server" Font-Size="Smaller" NavigateUrl="TeamHistory.aspx?TeamId=">View History</asp:HyperLink>
                    </font>
                </p>
                <p>
                    <font size="2">Last Login:
                        <asp:Label ID="lblLastLogin" runat="server"></asp:Label>
                    </font>
                </p>
            </td></tr><tr>
            <td width="600" colspan="2">

                <asp:GridView ID="gvRoster" runat="server" CssClass="grid" 
                    AutoGenerateColumns="False" CellPadding="6" CellSpacing="6" 
                    onrowdatabound="gvRoster_RowDataBound" DataKeyNames="PlayerId" >
                    <Columns>
                        <asp:HyperLinkField DataNavigateUrlFields="PlayerId" DataNavigateUrlFormatString="DetailedStats.aspx?PlayerId={0}"
                            DataTextField="Player" HeaderText="Name" >
                            <ItemStyle Font-Bold="False" Font-Italic="False" Font-Overline="False" Font-Strikeout="False"
                                Font-Underline="False" HorizontalAlign="Left" />
                        </asp:HyperLinkField>
                        <asp:BoundField HeaderText="Pos" DataField="Position" >
                            <ItemStyle HorizontalAlign="Center"></ItemStyle>
                        </asp:BoundField>
                        <asp:HyperLinkField DataNavigateUrlFields="RealTeamId" DataNavigateUrlFormatString="RealTeamView.aspx?RealTeamId={0}"
                            DataTextField="RealTeam" HeaderText="Team">
                        <ItemStyle HorizontalAlign="Center" />
                        </asp:HyperLinkField>
                        <asp:BoundField DataField="NetPPG" HeaderText="NetPPG" DataFormatString="{0:0.0}">
                            <ItemStyle Font-Bold="False" Font-Italic="False" Font-Overline="False" Font-Strikeout="False"
                                Font-Underline="False" HorizontalAlign="Center" />
                        </asp:BoundField>
                        <asp:BoundField DataField="NetPPM" HeaderText="NetPPM" DataFormatString="{0:0.00}">
                            <ItemStyle HorizontalAlign="Center"></ItemStyle>
                        </asp:BoundField>
                        <asp:BoundField DataField="LastGame" HeaderText="Last Game">
                            <ItemStyle HorizontalAlign="Center"></ItemStyle>
                        </asp:BoundField>
                        <asp:BoundField HeaderText="Status" DataField="OnIR">
                        <ItemStyle Font-Bold="True" ForeColor="Red" HorizontalAlign="Center" />
                        </asp:BoundField>
                        <asp:TemplateField HeaderText="On Trade Block?">
                            <ItemTemplate>
                                <asp:CheckBox ID="cbTradeBlock" runat="server" OnCheckedChanged="cbTradeBlock_OnCheckedChanged"
                                    AutoPostBack="true" 
                                    Checked='<%# Convert.ToBoolean(Eval("IsOnTradeBlock")) %>' />
                                <asp:LinkButton ID="lbMakeOffer" visible="false" runat="server" PostBackUrl="TradePropose.aspx">Make Offer</asp:LinkButton>
                            </ItemTemplate>                    
                            <ItemStyle HorizontalAlign="Center" />
                        </asp:TemplateField>
                    </Columns>
                </asp:GridView>
            </td>
        </tr>
    </table>
</asp:Content>
