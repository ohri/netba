<%@ Page Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" Inherits="netba.Pages.admin"
    Title="Site Admin" CodeBehind="admin.aspx.cs" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Title" runat="Server">
    System Administration
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Main" runat="Server">
    <p>Password Reset</p>
    <asp:DropDownList ID="ddlOwners" runat="server">
    </asp:DropDownList>
    <asp:Button ID="ButtonResetPassword" runat="server" Text="Reset" OnClick="ButtonResetPassword_Click">
    </asp:Button><br />
    <asp:Label ID="lblMessage" runat="server"></asp:Label>
    <div class="navdivider">
    </div>
    <p>
        <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl="playereditor.aspx">Player Editor</asp:HyperLink></p>
    <div class="navdivider">
    </div>
    <p>
        <asp:HyperLink ID="HyperLink2" runat="server" NavigateUrl="LogViewer.aspx">Log Viewer</asp:HyperLink></p>
    <div class="navdivider">
    </div>
    <p>
        <asp:HyperLink ID="HyperLink3" runat="server" NavigateUrl="Scoring.aspx">Scoring Management</asp:HyperLink></p>
    <div class="navdivider">
    </div>
    <p>
        <asp:CheckBox ID="cbDraftOpen" runat="server" Text="Draft Open" AutoPostBack="True"
            TextAlign="Left" OnCheckedChanged="cbDraftOpen_CheckedChanged"></asp:CheckBox></p>
    <p>
        <asp:CheckBox ID="cbFAOpen" runat="server" Text="Free Agency Open" AutoPostBack="True"
            TextAlign="Left" oncheckedchanged="cbFAOpen_CheckedChanged"></asp:CheckBox></p>
    <p>
        <asp:CheckBox ID="cbTradingOpen" runat="server" Text="Trading Open" AutoPostBack="True"
            TextAlign="Left" oncheckedchanged="cbTradingOpen_CheckedChanged"></asp:CheckBox></p>
    <p>
        <asp:CheckBox ID="cbNagOwnersOpen" runat="server" Text="Nag Owners About Lineups" AutoPostBack="True"
            TextAlign="Left" oncheckedchanged="cbNagOwners_CheckedChanged"></asp:CheckBox></p>
   <div class="navdivider"></div>
    <table border="0" cellpadding="5" cellspacing="5">
        <tr>
            <th colspan="2">
                Undo Pick
            </th>
        </tr>
        <tr>
            <td>
                Round:
            </td>
            <td>
                <asp:TextBox ID="tbRound" runat="server" Width="32px"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td>
                Pick:
            </td>
            <td>
                <asp:TextBox ID="tbPick" runat="server" Width="32px"></asp:TextBox>
            </td>
        </tr>
        <tr>
            <td colspan="2">
                <asp:Button ID="btnGo" runat="server" Text="Go" OnClick="btnGo_Click"></asp:Button>
            </td>
        </tr>
    </table>
    <p>
        <asp:Label ID="lblPickMessage" runat="server"></asp:Label></p>
</asp:Content>
