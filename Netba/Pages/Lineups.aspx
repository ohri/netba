<%@ Page Language="c#" Inherits="netba.Pages.Lineups" CodeBehind="Lineups.aspx.cs" %>

<%@ Register TagPrefix="uc1" TagName="footer" Src="/Controls/footer.ascx" %>
<%@ Register TagPrefix="uc1" TagName="navbar" Src="/Controls/navbar.ascx" %>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" >
<html>
<head>
    <title>Lineup Submission</title>
    <link href="/Styles/netba.css" type="text/css" rel="stylesheet" />
</head>
<body>
    <script language="javascript" type="text/javascript" src="/Scripts/jquery-1.4.1.js"></script>
    <script language="javascript" type="text/javascript" src="/Scripts/lineup_validation.js"></script>
    <script language="javascript" type="text/javascript">

        var pos_labels = [
            "#lblPG",
            "#lblSG",
            "#lblSF",
            "#lblPF",
            "#lblC",
            "#lblBackupPG",
            "#lblBackupSG",
            "#lblBackupSF",
            "#lblBackupPF",
            "#lblBackupC",
            "#lblGarbage1",
            "#lblGarbage2" 
            ];

        function enable_submit()
        {
            if ( $( "#SPG" ).html() == "" && $( '#hiddenSPG' ).val() > 0
                && $( "#SSG" ).html() == "" && $( '#hiddenSSG' ).val() > 0
                && $( "#SSF" ).html() == "" && $( '#hiddenSSF' ).val() > 0
                && $( "#SPF" ).html() == "" && $( '#hiddenSPF' ).val() > 0
                && $( "#SC" ).html() == "" && $( '#hiddenSC' ).val() > 0
                && $( "#BPG" ).html() == "" && $( '#hiddenBPG' ).val() > 0
                && $( "#BSG" ).html() == "" && $( '#hiddenBSG' ).val() > 0
                && $( "#BSF" ).html() == "" && $( '#hiddenBSF' ).val() > 0
                && $( "#BPF" ).html() == "" && $( '#hiddenBPF' ).val() > 0
                && $( "#BC" ).html() == "" && $( '#hiddenBC' ).val() > 0
                && $( "#G1" ).html() == "" && $( '#hiddenG1' ).val() > 0
                && $( "#G2" ).html() == "" && $( '#hiddenG2' ).val() > 0
            )
            {
                $( "#ButtonSubmitLineup" ).removeAttr( "disabled" );
            }
            else
            {
                $( "#ButtonSubmitLineup" ).attr( "disabled", true );
            }
        }

        function LineupOnClick( label, value, hidden, slot )
        {
            var x = $('#lbRoster :selected').text();
            if (x == $( label ).html()) {
                $( hidden ).val('');
                $( label ).html('');
                $( value ).html('');
            }
            else
            {
                $( value ).html(lineup_validate(x, slot));
                if ($( value ).html().length == 0)
                {
                    $( hidden ).val($('#lbRoster').val());
                    $( label ).html( x );
                }
            }
            enable_submit();
        }

      $( document ).ready( function ()
      {
          enable_submit();
      } );

    </script>
    <form id="Form1" method="post" runat="server">
    <table id="Table1" cellpadding="8">
        <tr>
            <td>
                <uc1:navbar ID="Navbar1" runat="server"></uc1:navbar>
            </td>
            <td>
                <br />
                <p>&nbsp;</p>
                <p>&nbsp;</p>
                <asp:Label ID="lblPageTitle" runat="server" CssClass="pagetitle">Lineup Submission</asp:Label>
                <hr align="left" width="100%" size="1" />
                <p></p>
                <div>
                    <asp:Panel ID="PlayerSelection" runat="server" Visible="False" BorderStyle="None"
                        Height="396px">
                        <p>
                            <asp:Label ID="Label1" runat="server" Height="40px" Width="672px">Instructions: Select a player from the Roster listbox 
                            on the left and click on the desired place on the depth chart on the right. Clicking on a filled in slot with the same
                                player will clear that slot.
                            </asp:Label></p>
                        <p>
                            <asp:Label ID="lblGameHeader" runat="server" Font-Bold="True" Font-Italic="True"></asp:Label></p>
                        <div>
                            <table id="Table2" cellpadding="10" border="0">
                                <tr>
                                    <td>
                                        <p><strong><u>Roster</u></strong></p>
                                        <p><asp:ListBox ID="lbRoster" runat="server" SelectionMode="Single" Rows="12"></asp:ListBox></p>
                                        <p style="text-align: center">
                                            <asp:Button ID="ResetButton" runat="server" onclick="ResetButton_Click" 
                                                Text="Reset" UseSubmitBehavior="False" Width="90px" />
                                        </p>
                                        <p style="text-align: center">
                                            <asp:Button ID="CopyButton" runat="server" onclick="CopyButton_Click" 
                                                Text="Copy Last" UseSubmitBehavior="False" Width="90px" />
                                        </p>
                                    </td>
                                    <td>
                                        <p><strong><u>Starters</u></strong></p>
                                        <strong>PG:</strong>
                                        <asp:Label ID="lblPG" runat="server" CssClass="handcursor" BorderStyle="Solid" Width="160px"
                                            Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px" Height="13px"
                                            onClick="javascript:LineupOnClick( '#lblPG', '#SPG', '#hiddenSPG', 1 );">
                                            Pick 'n Click</asp:Label><br />
                                        <asp:HiddenField ID="hiddenSPG" runat="server" />
                                        <p id="SPG" class="lineup_validation_error"></p>
                                        <br />
                                        <strong>SG</strong>:
                                        <asp:Label ID="lblSG" runat="server" CssClass="handcursor" BorderStyle="Solid" Width="160px"
                                            Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px" Height="13px"
                                            onClick="javascript:LineupOnClick( '#lblSG', '#SSG', '#hiddenSSG', 2 );">
                                            Pick 'n Click</asp:Label><br />
                                        <asp:HiddenField ID="hiddenSSG" runat="server" />
                                        <p id="SSG" class="lineup_validation_error"></p>
                                        <br />
                                        <strong>SF</strong>:
                                        <asp:Label ID="lblSF" runat="server" CssClass="handcursor" BorderStyle="Solid" Width="160px"
                                            Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px" Height="13px"
                                            onClick="javascript:LineupOnClick( '#lblSF', '#SSF', '#hiddenSSF', 3 );">
                                            Pick 'n Click</asp:Label><br />
                                        <asp:HiddenField ID="hiddenSSF" runat="server" />
                                        <p id="SSF" class="lineup_validation_error"></p>
                                        <br />
                                        <strong>PF</strong>:
                                        <asp:Label ID="lblPF" runat="server" CssClass="handcursor" BorderStyle="Solid" Width="160px"
                                            Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px" Height="13px"
                                            onClick="javascript:LineupOnClick( '#lblPF', '#SPF', '#hiddenSPF', 4 );">
                                            Pick 'n Click</asp:Label><br />
                                        <asp:HiddenField ID="hiddenSPF" runat="server" />
                                        <p id="SPF" class="lineup_validation_error"></p>
                                        <br />
                                        <strong>C&nbsp; </strong>:
                                        <asp:Label ID="lblC" runat="server" CssClass="handcursor" BorderStyle="Solid" Width="160px"
                                            Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px" Height="13px"
                                            onClick="javascript:LineupOnClick( '#lblC', '#SC', '#hiddenSC', 5 );">
                                            Pick 'n Click</asp:Label>
                                        <p id="SC" class="lineup_validation_error"></p>
                                        <asp:HiddenField ID="hiddenSC" runat="server" />
                                    </td>
                                    <td>
                                        <p><strong><u>Backups</u></strong></p>
                                        <strong>PG</strong>:
                                        <asp:Label ID="lblBackupPG" runat="server" CssClass="handcursor" BorderStyle="Solid" Height="13px"
                                            Width="160px" Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px"
                                            onClick="javascript:LineupOnClick( '#lblBackupPG', '#BPG', '#hiddenBPG', 6 );">
                                            Pick 'n Click</asp:Label><br />
                                        <p id="BPG" class="lineup_validation_error"></p>
                                        <asp:HiddenField ID="hiddenBPG" runat="server" />
                                        <br />
                                        <strong>SG</strong>:
                                        <asp:Label ID="lblBackupSG" runat="server" CssClass="handcursor" BorderStyle="Solid" Height="13px"
                                            Width="160px" Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px"
                                            onClick="javascript:LineupOnClick( '#lblBackupSG', '#BSG', '#hiddenBSG', 7 );">
                                            Pick 'n Click</asp:Label><br />
                                        <p id="BSG" class="lineup_validation_error"></p>
                                        <asp:HiddenField ID="hiddenBSG" runat="server" />
                                        <br />
                                        <strong>SF</strong>:
                                        <asp:Label ID="lblBackupSF" runat="server" CssClass="handcursor" BorderStyle="Solid" Height="13px"
                                            Width="160px" Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px"
                                            onClick="javascript:LineupOnClick( '#lblBackupSF', '#BSF', '#hiddenBSF', 8 );">
                                            Pick 'n Click</asp:Label><br />
                                        <p id="BSF" class="lineup_validation_error"></p>
                                        <asp:HiddenField ID="hiddenBSF" runat="server" />
                                        <br />
                                        <strong>PF</strong>:
                                        <asp:Label ID="lblBackupPF" runat="server" CssClass="handcursor" BorderStyle="Solid" Height="13px"
                                            Width="160px" Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px"
                                            onClick="javascript:LineupOnClick( '#lblBackupPF', '#BPF', '#hiddenBPF', 9 );">
                                            Pick 'n Click</asp:Label><br />
                                        <p id="BPF" class="lineup_validation_error"></p>
                                        <asp:HiddenField ID="hiddenBPF" runat="server" />
                                        <br />
                                        <strong>C&nbsp;</strong>&nbsp;:
                                        <asp:Label ID="lblBackupC" runat="server" CssClass="handcursor" BorderStyle="Solid" Height="13px"
                                            Width="160px" Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px"
                                            onClick="javascript:LineupOnClick( '#lblBackupC', '#BC', '#hiddenBC', 10 );">
                                            Pick 'n Click</asp:Label>
                                        <p id="BC" class="lineup_validation_error"></p>
                                        <asp:HiddenField ID="hiddenBC" runat="server" />
                                    </td>
                                    <td>
                                        <p>
                                            <strong><u>Garbage</u></strong></p>
                                            <strong>1</strong>:
                                            <asp:Label ID="lblGarbage1" runat="server" CssClass="handcursor" BorderStyle="Solid" Height="13px"
                                                Width="160px" Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px"
                                                onClick="javascript:LineupOnClick( '#lblGarbage1', '#G1', '#hiddenG1', 11 );">
                                                Pick 'n Click</asp:Label><br />
                                            <p id="G1" class="lineup_validation_error"></p>
                                            <asp:HiddenField ID="hiddenG1" runat="server" />
                                            <br />
                                            <strong>2</strong>:
                                            <asp:Label ID="lblGarbage2" runat="server" CssClass="handcursor" BorderStyle="Solid" Height="13px"
                                                Width="160px" Font-Size="X-Small" BorderColor="Silver" BackColor="#E0E0E0" BorderWidth="1px"
                                                onClick="javascript:LineupOnClick( '#lblGarbage2', '#G2', '#hiddenG2', 12 );">
                                                Pick 'n Click</asp:Label>
                                            <p id="G2" class="lineup_validation_error"></p>
                                            <asp:HiddenField ID="hiddenG2" runat="server" />
                                    </td>
                                </tr>
                            </table>
                        </div>
                        <center><font size="3"><strong><u>Comments</u></strong></font></center>
                        <center><font size="2">&nbsp;(will show up in email):</font></center>
                        <br />
                        <center><asp:TextBox ID="tbComment" Rows="4" runat="server" TextMode="MultiLine"  Width="360px" /></center>
                        <br />
                        <center>
                            <asp:Button ID="ButtonSubmitLineup" runat="server" Text="Submit" OnClick="ButtonSubmitLineup_Click"></asp:Button>
                        </center>
                    </asp:Panel>
                    <br />
                    <asp:Panel ID="TeamWeekSelection" runat="server" BorderStyle="None">
                        <table cellspacing="20" border="0">
                            <tr>
                                <th>
                                    Select team:
                                </th>
                                <th>
                                    Select week:
                                </th>
                            </tr>
                            <tr>
                                <td>
                                    <asp:ListBox ID="lbTeams" runat="server" Rows="16"></asp:ListBox>
                                </td>
                                <td>
                                    <asp:ListBox ID="lbWeeks" runat="server" Rows="19"></asp:ListBox>
                                </td>
                            </tr>
                        </table>
                        <center>
                            <asp:Button ID="ButtonSubmitTeamWeek" runat="server" Text="Submit" OnClick="ButtonSubmitTeamWeek_Click">
                            </asp:Button></center>
                    </asp:Panel>
                </div>
                <p></p>
                <p></p>
                <p></p>
            </td>
        </tr>
    </table>
    <uc1:footer ID="Footer1" runat="server"></uc1:footer>
    </form>
</body>
</html>
